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
import '../widgets/bsl_key_tile.dart';
import '../widgets/bsl_keyboard.dart';
import '../widgets/bsl_number_display.dart';
import '../../../shared/widgets/champion_rosette.dart';
import '../widgets/champion_mode_explainer.dart';
import '../widgets/champion_mode_unlocked_banner.dart';

/// Main screen for the BSL Maths addition game.
///
/// Displays:
/// - AppBar with level name and score badge
/// - Question display: [BSL operand1] + [BSL operand2] = [answer slot]
/// - Feedback area: "Correct!" with green tick or "Try again!" message
/// - BSL number keyboard — tapping a key directly submits the answer
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
  /// Corner radius of the question card.
  static const double _questionCardRadius = 16;

  // Sized up from 80 (and the keyboard's key-relative SVG size trimmed
  // down slightly) so the BSL signs read as similarly sized in both areas.
  static const double _questionSvgSize = 96.0;
  static const double _answerSlotSize = 96.0;

  /// Fixed-height chrome above/around the question card and keyboard:
  /// top gap (8) + GameHeaderBar (88) + mid gap (12) + bottom gap (8).
  /// Keep in sync with the SizedBox/GameHeaderBar heights in
  /// [_buildGameContent].
  static const double _fixedChromeHeight = 8 + 88 + 12 + 8;

  /// Smallest the question card is ever allowed to shrink to, so the
  /// keyboard (sized from available width — see [BslKeyboard]) never
  /// squeezes it into overflow on short screens.
  static const double _minQuestionCardHeight = 86.0;

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
                image: AssetImage('assets/backgrounds/felt-background.jpg'),
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
                    levelNumber: provider.currentLevel.number,
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
                      onNextLevel:
                          provider.currentLevel.number <
                              BslMathsLevel.all.length
                          ? () {
                              provider.setLevel(
                                provider.currentLevel.number + 1,
                              );
                              provider.startGame();
                            }
                          : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == BslMathsGameState.timeUp &&
                    provider.justUnlockedChampionMode)
                  Positioned.fill(
                    child: ChampionModeUnlockedBanner(
                      locale: widget.locale,
                      onContinue: () {
                        provider.dismissChampionModeUnlockedBanner();
                        provider.showLevelSelection();
                        showChampionModeExplainer(
                          context,
                          locale: widget.locale,
                          bodyKey: 'bsl_maths.champion_mode.explainer',
                          demo: const AnswerDigitsFadeDemo(),
                        );
                      },
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
      titleBadge: provider.isChampionModeUnlocked
          ? ChampionRosette(
              value: provider.championMode,
              onChanged: provider.setChampionMode,
              localizer: localizer,
            )
          : null,
      locale: widget.locale,
      sectionBreaks: {
        BslMathsLevel.all.indexWhere((l) => l.isSubtraction): localizer(
          'bsl_maths.subtraction_subtitle',
        ),
      },
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
  Widget _buildGameContent(
    BuildContext context,
    BslMathsProvider provider,
    AppLocalizations localizer,
  ) {
    final scale = MediaQuery.of(context).size.width >= 600 ? 1.4 : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap how tall the (width-driven, always-square) keyboard is
        // allowed to grow, so it never squeezes the question card below
        // its minimum on short screens.
        final maxKeyboardHeight =
            (constraints.maxHeight -
                    _fixedChromeHeight -
                    _minQuestionCardHeight * scale)
                .clamp(0.0, double.infinity);
        // The question card matches the keyboard's row of keys, outer edge
        // to outer edge. The keyboard gets the full column width and
        // maxKeyboardHeight (the Column passes non-flex children an
        // unbounded height, so the ConstrainedBox cap is what it sees).
        final questionCardWidth = BslKeyboard.rowWidthFor(
          availableWidth: constraints.maxWidth,
          maxHeight: maxKeyboardHeight,
          showTeenKeys: provider.useTeenKeys,
          scale: scale,
        );
        return _buildGameColumn(
          context,
          provider,
          localizer,
          scale,
          maxKeyboardHeight,
          questionCardWidth,
        );
      },
    );
  }

  Widget _buildGameColumn(
    BuildContext context,
    BslMathsProvider provider,
    AppLocalizations localizer,
    double scale,
    double maxKeyboardHeight,
    double questionCardWidth,
  ) {
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
                    localizer(
                      provider.currentLevel.name,
                    ).replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), ''),
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),

        // Question + feedback on a white card (no bevel) with the same
        // inset shadows as the keyboard keys' dished faces.
        // Padding here is kept tight so as much room as possible goes to the
        // actual question display — see _questionSvgSize/_answerSlotSize.
        Expanded(
          //flex: 2,
          child: Container(
            width: questionCardWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_questionCardRadius),
            ),
            child: CustomPaint(
              painter: BslInnerShadowPainter(
                radius: _questionCardRadius,
                shadows: BslKeyTile.faceInnerShadows,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacingXSmall,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.spacingXSmall),

                    // Question display area (BSL SVG operands + answer slot(s))
                    Expanded(child: _buildQuestionDisplay(provider, scale)),

                    // Feedback area (correct/wrong message)
                    SizedBox(
                      height: 44 * scale,
                      child: _buildFeedback(provider, scale, localizer),
                    ),

                    const SizedBox(height: AppSizes.spacingXSmall),
                  ],
                ),
              ),
            ),
          ),
        ),

        // BSL number keyboard — sizes itself from the available width so
        // keys stay perfectly square (see BslKeyboard), up to
        // maxKeyboardHeight. The question card above is Expanded, so on
        // taller/wider screens it absorbs whatever space the keyboard
        // doesn't need rather than the keyboard being squeezed to fit;
        // on short screens the height cap keeps keys from pushing the
        // card into overflow (see _minQuestionCardHeight).
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxKeyboardHeight),
          child: BslKeyboard(
            onKeyPressed: (number) => provider.enterDigit(number),
            isDisabled: provider.isInputLocked,
            enteredAnswer: provider.enteredAnswer,
            showTeenKeys: provider.useTeenKeys,
            showNumbers: !provider.championMode,
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

  /// Builds the question display showing BSL SVG operands and answer slot.
  ///
  /// Normal levels: operand1 + operand2 = [?]
  /// Missing operand levels: operand1 + [?] = answer
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
                horizontal: AppSizes.spacingSmall,
              ),
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
                horizontal: AppSizes.spacingSmall,
              ),
              child: Text(
                '=',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingSmall,
              ),
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
                horizontal: AppSizes.spacingSmall,
              ),
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

  /// Builds the single answer slot showing the entered digit, if any.
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

  /// Builds the feedback text area below the question display.
  Widget _buildFeedback(
    BslMathsProvider provider,
    double scale,
    AppLocalizations localizer,
  ) {
    if (provider.gameState == BslMathsGameState.correct) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: AppSizes.iconLarge * scale,
          ),
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
          Icon(
            Icons.refresh,
            color: AppColors.accentRed,
            size: AppSizes.iconLarge * scale,
          ),
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
