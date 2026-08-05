import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../models/maths_question.dart';
import '../providers/bsl_maths_provider.dart';
import '../widgets/bsl_keyboard.dart';
import '../widgets/bsl_number_display.dart';

/// Main screen for the BSL Maths addition game.
///
/// Displays:
/// - AppBar with level name and score badge
/// - Question display: [BSL operand1] + [BSL operand2] = [answer slot(s)]
/// - Feedback area: "Correct!" with green tick or "Try again!" message
/// - BSL number keyboard with C (clear) button
///
/// Level 1: Single answer slot (sums 2-10)
/// Level 2: Two answer slots for tens/units (sums 2-20)
///
/// Uses [Consumer<BslMathsProvider>] to rebuild when game state changes.
class BslMathsScreen extends StatefulWidget {
  /// UI locale ('en' or 'cy') used for titles, level info, and overlay text.
  final String locale;

  const BslMathsScreen({super.key, this.locale = 'en'});

  @override
  State<BslMathsScreen> createState() => _BslMathsScreenState();
}

class _BslMathsScreenState extends State<BslMathsScreen> {
  static const double _questionSvgSize = 80.0;
  static const double _answerSlotSize = 80.0;

  bool _showingIntro = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AudioService.playTitle('bsl_maths', locale: widget.locale);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BslMathsProvider>().onAnswerResult = (isCorrect) {
        if (isCorrect) {
          AudioService.playCorrect('bsl_maths');
        } else {
          AudioService.playWrong('bsl_maths');
        }
      };
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<BslMathsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('bsl_maths.title'),
                  onBack: () => Navigator.of(context).pop(),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelectScreen(context, provider, localizer)
                      : _buildGameContent(context, provider, localizer),
                ),
                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'bsl_maths',
                    locale: widget.locale,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                    onBack: () {
                      setState(() => _showingIntro = false);
                      provider.showLevelSelection();
                    },
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == BslMathsGameState.timeUp)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'bsl_maths',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      imageAsset: 'assets/success/Star-glowing.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () => provider.startGame(),
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == BslMathsGameState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'bsl_maths',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.got10Correct,
                      showPersonalBest: false,
                      imageAsset: 'assets/success/Star-glowing.png',
                      onPlayAgain: () => provider.startGame(),
                      onNextLevel: provider.currentLevel.number <
                              BslMathsLevel.all.length
                          ? () {
                              provider.setLevel(
                                  provider.currentLevel.number + 1);
                              provider.startGame();
                            }
                          : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    BslMathsProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      subtitle: localizer('bsl_maths.subtitle'),
      locale: widget.locale,
      levels: BslMathsLevel.all.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(level.number - 1),
          onTap: () {
            provider.setLevel(level.number);
            if (level.isCompetition) {
              setState(() => _showingIntro = true);
            } else {
              provider.startGame();
              AudioService.playIntro('bsl_maths', locale: widget.locale);
            }
          },
        );
      }).toList(),
    );
  }

  /// Builds the main game content.
  Widget _buildGameContent(BuildContext context, BslMathsProvider provider, AppLocalizations localizer) {
    final scale = MediaQuery.of(context).size.width >= 600 ? 1.4 : 1.0;
    return Column(
      children: [
        const SizedBox(height: 8),
        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.currentLevel.number,
          centerContent: provider.isCompetitionLevel
              ? GameTimerDisplay(
                  formattedTime: _formatTime(provider.secondsRemaining),
                )
              : provider.currentLevel.name.isNotEmpty
                  ? Center(
                      child: Text(
                        localizer(provider.currentLevel.name),
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 12),

        // Question + feedback in glass container
        Expanded(
          //flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.paddingMedium),

                      // Question display area (BSL SVG operands + answer slot(s))
                      Expanded(
                        child: _buildQuestionDisplay(provider, scale),
                      ),

                      // Feedback area (correct/wrong message)
                      SizedBox(
                        height: 44 * scale,
                        child: _buildFeedback(provider, scale, localizer),
                      ),

                      const SizedBox(height: AppSizes.spacingSmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        // BSL number keyboard — height doubles on wide screens
        SizedBox(
          height: MediaQuery.of(context).size.width >= 600 ? 480.0 : 360.0,
          child: BslKeyboard(
            onKeyPressed: (number) => provider.enterDigit(number),
            onClearPressed: () => provider.clearAnswer(),
            onSubmitPressed: () => provider.submitAnswer(),
            isDisabled: provider.isInputLocked,
            enteredAnswer: provider.enteredAnswer,
            isCorrect: provider.gameState == BslMathsGameState.correct
                ? true
                : provider.gameState == BslMathsGameState.wrong
                    ? false
                    : null,
            showZeroKey: provider.requiresTwoDigitInput,
            showTeenKeys: provider.useTeenKeys,
            showNumbers: !provider.isCompetitionLevel,
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),
      ],
    );
  }

  /// Formats seconds as MM:SS.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }


  /// Builds the question display showing BSL SVG operands and answer slot(s).
  ///
  /// Normal levels: operand1 + operand2 = [?]
  /// Missing operand level (Level 3): operand1 + [?] = answer
  Widget _buildQuestionDisplay(BslMathsProvider provider, double scale) {
    final question = provider.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    if (provider.isMissingOperandLevel) {
      return _buildMissingOperandDisplay(provider, question, scale);
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BslNumberDisplay(
              number: question.operand1,
              size: _questionSvgSize * scale,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                question.operatorSymbol,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            BslNumberDisplay(
              number: question.operand2,
              size: _questionSvgSize * scale,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '=',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (provider.requiresTwoDigitInput)
              _buildTwoDigitAnswerSlots(provider, scale)
            else
              _buildSingleAnswerSlot(provider, scale),
          ],
        ),
      ),
    );
  }

  /// Builds the question display for "find the missing number" format.
  ///
  /// Shows: operand1 + [?] = answer
  Widget _buildMissingOperandDisplay(
    BslMathsProvider provider,
    MathsQuestion question,
    double scale,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BslNumberDisplay(
              number: question.operand1,
              size: _questionSvgSize * scale,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                question.operatorSymbol,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildSingleAnswerSlot(provider, scale),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '=',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            BslNumberDisplay(
              number: question.answer,
              size: _questionSvgSize * scale,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single answer slot for Level 1 (answers 2-10).
  Widget _buildSingleAnswerSlot(BslMathsProvider provider, double scale) {
    final slotSize = _answerSlotSize * scale;
    if (provider.unitsDigit == null) {
      return Container(
        width: slotSize,
        height: slotSize,
        decoration: BoxDecoration(
          color: AppColors.mathBackground.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(
            color: AppColors.accentWhite.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: AppSizes.fontSizeTitle * scale,
              fontWeight: FontWeight.bold,
              color: AppColors.accentWhite,
            ),
          ),
        ),
      );
    }

    final isCorrect = provider.gameState == BslMathsGameState.correct;
    final isWrong = provider.gameState == BslMathsGameState.wrong;
    final color = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.accentRed
            : AppColors.catrinBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: slotSize,
      height: slotSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: BslNumberDisplay(
          number: provider.enteredAnswer!,
          size: slotSize - 12,
        ),
      ),
    );
  }

  /// Builds two answer slots for Level 2 (tens column left, units column right).
  Widget _buildTwoDigitAnswerSlots(BslMathsProvider provider, double scale) {
    final isCorrect = provider.gameState == BslMathsGameState.correct;
    final isWrong = provider.gameState == BslMathsGameState.wrong;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDigitSlot(digit: provider.tensDigit, isCorrect: isCorrect, isWrong: isWrong, scale: scale),
        const SizedBox(width: AppSizes.spacingSmall),
        _buildDigitSlot(digit: provider.unitsDigit, isCorrect: isCorrect, isWrong: isWrong, scale: scale),
      ],
    );
  }

  /// Builds a single digit slot for two-digit answers.
  Widget _buildDigitSlot({
    required int? digit,
    required bool isCorrect,
    required bool isWrong,
    required double scale,
  }) {
    final hasDigit = digit != null;
    final color = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.accentRed
            : AppColors.accentWhite;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _answerSlotSize * 0.8 * scale,
      height: _answerSlotSize * scale,
      decoration: BoxDecoration(
        color: hasDigit
            ? color.withValues(alpha: 0.2)
            : AppColors.mathBackground.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: hasDigit ? AppColors.textPrimary : AppColors.accentWhite.withValues(alpha: 0.4),
          width: hasDigit ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          hasDigit ? '$digit' : '?',
          style: TextStyle(
            fontSize: AppSizes.fontSizeTitle * scale,
            fontWeight: FontWeight.bold,
            color: hasDigit ? AppColors.textPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Builds the feedback text area below the question display.
  Widget _buildFeedback(BslMathsProvider provider, double scale, AppLocalizations localizer) {
    if (provider.gameState == BslMathsGameState.correct) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: AppSizes.iconLarge * scale),
          const SizedBox(width: AppSizes.spacingSmall),
          Text(
            localizer('general.correct'),
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge * scale,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    if (provider.gameState == BslMathsGameState.wrong) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, color: AppColors.accentRed, size: AppSizes.iconLarge * scale),
          const SizedBox(width: AppSizes.spacingSmall),
          Text(
            localizer('general.try_again'),
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge * scale,
              fontWeight: FontWeight.bold,
              color: AppColors.accentRed,
            ),
          ),
        ],
      );
    }

    // // Playing state - show hint for Level 2
    // if (provider.requiresTwoDigitInput && provider.enteredAnswer != null) {
    //   return Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       const Icon(
    //         Icons.touch_app,
    //         color: AppColors.textSecondary,
    //         size: AppSizes.iconMedium,
    //       ),
    //       const SizedBox(width: AppSizes.spacingSmall),
    //       Text(
    //         'Tap = to submit (${provider.enteredAnswer})',
    //         style: const TextStyle(
    //           fontSize: AppSizes.fontSizeBody,
    //           color: AppColors.textSecondary,
    //         ),
    //       ),
    //     ],
    //   );
    // }

    return const SizedBox.shrink();
  }
}
