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
import '../../bsl_maths/models/maths_question.dart';
import '../../bsl_maths/providers/bsl_maths_provider.dart';
import '../../bsl_maths/widgets/bsl_keyboard.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';

/// Welsh-language version of the BSL Maths game.
///
/// Identical game logic and layout to [BslMathsScreen], but all UI text
/// and audio instructions are in Welsh (Cymraeg).
///
/// Uses the same [BslMathsProvider] for state management and the same
/// [BslMathsLevel] definitions. Translation keys are resolved against the
/// Welsh ('cy') locale.
class WelshMathsScreen extends StatefulWidget {
  const WelshMathsScreen({super.key});

  @override
  State<WelshMathsScreen> createState() => _WelshMathsScreenState();
}

class _WelshMathsScreenState extends State<WelshMathsScreen> {
  static const double _questionSvgSize = 80.0;
  static const double _answerSlotSize = 80.0;

  final _localizer = AppLocalizations(locale: 'cy');
  bool _showingIntro = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BslMathsProvider>().onAnswerResult = (isCorrect) {
        if (isCorrect) {
          AudioService.playCorrect('welsh_maths');
          AudioService.speakWelsh(_localizer('general.correct'));
        } else {
          AudioService.playWrong('welsh_maths');
          AudioService.speakWelsh(_localizer('general.try_again'));
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
    final localizer = _localizer;
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
                image: AssetImage(
                    'assets/backgrounds/math-background-1080x1920.jpg'),
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
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'welsh_maths',
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == BslMathsGameState.timeUp)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'welsh_maths',
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
                      gameId: 'welsh_maths',
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

  Widget _buildLevelSelectScreen(
    BuildContext context,
    BslMathsProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      subtitle: localizer('bsl_maths.subtitle'),
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
              AudioService.playIntro('welsh_maths');
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildGameContent(
    BuildContext context,
    BslMathsProvider provider,
    AppLocalizations localizer,
  ) {
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
        Expanded(
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
                      Expanded(
                        child: _buildQuestionDisplay(provider, scale),
                      ),
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

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSmall),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSmall),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSmall),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSmall),
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

  Widget _buildTwoDigitAnswerSlots(BslMathsProvider provider, double scale) {
    final isCorrect = provider.gameState == BslMathsGameState.correct;
    final isWrong = provider.gameState == BslMathsGameState.wrong;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDigitSlot(
            digit: provider.tensDigit,
            isCorrect: isCorrect,
            isWrong: isWrong,
            scale: scale),
        const SizedBox(width: AppSizes.spacingSmall),
        _buildDigitSlot(
            digit: provider.unitsDigit,
            isCorrect: isCorrect,
            isWrong: isWrong,
            scale: scale),
      ],
    );
  }

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
          color: hasDigit
              ? AppColors.textPrimary
              : AppColors.accentWhite.withValues(alpha: 0.4),
          width: hasDigit ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          hasDigit ? '$digit' : '?',
          style: TextStyle(
            fontSize: AppSizes.fontSizeTitle * scale,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(
      BslMathsProvider provider, double scale, AppLocalizations localizer) {
    if (provider.gameState == BslMathsGameState.correct) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle,
              color: AppColors.success, size: AppSizes.iconLarge * scale),
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
          Icon(Icons.refresh,
              color: AppColors.accentRed, size: AppSizes.iconLarge * scale),
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

    return const SizedBox.shrink();
  }
}
