import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';
import '../providers/counting_game_provider.dart';

/// Main screen for the Counting Game.
///
/// Each game has 5 rounds. Each round shows a collection of circles and asks
/// one or more questions (single-colour levels just ask the total; two-colour
/// levels ask colour A count, colour B count, then total). The player taps
/// one of three BSL number buttons. Wrong answers are greyed out; correct
/// answers advance the question. Answering every round's questions wins.
class CountingGameScreen extends StatefulWidget {
  final String locale;

  const CountingGameScreen({super.key, this.locale = 'en'});

  @override
  State<CountingGameScreen> createState() => _CountingGameScreenState();
}

class _CountingGameScreenState extends State<CountingGameScreen>
    with LevelTransitionMixin<CountingGameScreen> {
  /// True while waiting for the 3-second pause after a correct answer.
  bool _isWaiting = false;

  /// True while the countdown intro is showing before a timed level starts.
  bool _showingIntro = false;

  /// Level index selected from the level-select screen, pending the
  /// countdown intro's completion for timed levels.
  int? _pendingLevelIndex;

  @override
  void initState() {
    super.initState();
    AudioService.playTitle('counting', locale: widget.locale);
  }

  void _onAnswerTapped(int n, CountingGameProvider provider) {
    if (_isWaiting) return;
    if (n == provider.correctAnswer) {
      HapticFeedback.mediumImpact();
      AudioService.playCorrect('counting_game');
      setState(() => _isWaiting = true);
      final delay = provider.currentQuestionType == QuestionType.total
          ? const Duration(seconds: 3)
          : const Duration(seconds: 2);
      Future.delayed(delay, () {
        if (!mounted) return;
        setState(() => _isWaiting = false);
        provider.selectAnswer(n);
      });
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) HapticFeedback.mediumImpact();
      });
      AudioService.playWrong('counting_game');
      setState(() => _isWaiting = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _isWaiting = false);
        provider.selectAnswer(n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<CountingGameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('counting.title'),
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
                      ? _buildLevelSelect(context, provider, localizer)
                      : _buildGame(context, provider, localizer),
                ),
                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'counting_game',
                    locale: widget.locale,
                    onComplete: () {
                      final levelIndex = _pendingLevelIndex;
                      setState(() {
                        _showingIntro = false;
                        _pendingLevelIndex = null;
                      });
                      if (levelIndex != null) provider.startGame(levelIndex);
                    },
                    onBack: () {
                      setState(() {
                        _showingIntro = false;
                        _pendingLevelIndex = null;
                      });
                      provider.showLevelSelection();
                    },
                  ),
                if (!provider.showLevelSelect &&
                    (provider.state == CountingGameState.won ||
                        provider.state == CountingGameState.timeUp))
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'counting_game',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel:
                          provider.levelNumber < countingColourPairs.length
                              ? () => provider.startGame(provider.levelNumber)
                              : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),

                Positioned.fill(
                  child: LevelTransitionOverlay(opacity: levelTransitionOpacity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level select ────────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, CountingGameProvider provider, AppLocalizations localizer) {
    return LevelSelectScreen(
      subtitle: localizer('counting_game.subtitle'),
      locale: localizer.locale,
      levels: List.generate(countingColourPairs.length, (i) {
        final pair = countingColourPairs[i];
        return LevelSelectItem(
          number: i + 1,
          name: localizer(pair.name),
          color: levelColor(i),
          onTap: () {
            if (pair.isTimed) {
              setState(() {
                _pendingLevelIndex = i;
                _showingIntro = true;
              });
            } else {
              startLevelWithTransition(
                gameId: 'counting_game',
                levelNumber: i + 1,
                locale: widget.locale,
                startLevel: () => provider.startGame(i),
              );
            }
          },
        );
      }),
    );
  }

  // ── Game layout ─────────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, CountingGameProvider provider,
      AppLocalizations localizer) {
    final round = provider.currentRound;
    final colours = provider.colours;

    final questionText =
        _questionText(provider.currentQuestionType, colours, round, localizer);

    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: provider.isTimedLevel
              ? GameTimerDisplay(
                  formattedTime:
                      GameTimerDisplay.format(Duration(seconds: provider.secondsRemaining)),
                )
              : Center(
                  child: Text(
                    '${localizer('counting_game.round_label')} ${provider.roundNumber} '
                    '${localizer('counting_game.of_label')} ${CountingGameProvider.totalRounds}',
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(
                  '${provider.roundNumber}-${provider.currentQuestionType}'),
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
                vertical: AppSizes.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusLarge),
              ),
              child: Text(
                questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Circle play area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusLarge),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusLarge),
                child: _CirclePlayArea(
                  key: ValueKey(provider.roundNumber),
                  round: round,
                  colours: colours,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Try again message (visible when any wrong answer is disabled)
        AnimatedOpacity(
          opacity: provider.disabledAnswers.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh, color: AppColors.accentRed, size: 24),
              const SizedBox(width: AppSizes.spacingSmall),
              Text(
                localizer('general.try_again'),
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // BSL answer buttons
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge),
          child: _BslAnswerRow(
            options: provider.answerOptions,
            disabledAnswers: _isWaiting
                ? provider.answerOptions.toSet()
                : provider.disabledAnswers,
            onTap: (n) => _onAnswerTapped(n, provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  String _questionText(QuestionType type, CircleColourPair colours,
      CountingRound round, AppLocalizations localizer) {
    // Levels 10 & 11 colour each group by its own count value, so the
    // colour name asked about must reflect that round's actual counts
    // rather than a level-fixed nameA/nameB.
    final String nameA = colours.usesNumberColours
        ? numberColourNames[round.countA]!
        : colours.nameA;
    final String nameB = colours.usesNumberColours
        ? numberColourNames[round.countB]!
        : colours.nameB;

    switch (type) {
      case QuestionType.colourA:
        return localizer('counting_game.question_colour')
            .replaceAll('{colour}', localizer('counting_game.colour.$nameA'));
      case QuestionType.colourB:
        return localizer('counting_game.question_colour')
            .replaceAll('{colour}', localizer('counting_game.colour.$nameB'));
      case QuestionType.total:
        return colours.singleColour
            ? localizer('counting_game.question_total_single')
                .replaceAll('{colour}', localizer('counting_game.colour.$nameA'))
            : localizer('counting_game.question_total_multi');
    }
  }
}

// ── Circle play area ──────────────────────────────────────────────────────────

class _CirclePlayArea extends StatelessWidget {
  final CountingRound round;
  final CircleColourPair colours;

  const _CirclePlayArea({
    super.key,
    required this.round,
    required this.colours,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final double radius = round.total <= 5
            ? 26
            : round.total <= 10
                ? 20
                : 14;

        // Composite dice counts (7-10) size each sub-pattern to a true pixel
        // square using the play area's actual w/h, rather than reading
        // pre-computed normalised positions that would stretch to fit
        // whatever aspect ratio the container happens to have.
        final diceCompositeCount = round.diceCompositeCount;

        // Levels 10 & 11 split the two groups into their own side-by-side
        // panels — one group's dice pattern on the left, the other's on the
        // right — so each group always keeps its own recognisable shape
        // instead of pips being scattered within one merged pattern.
        final bool isTwoPanel = colours.usesNumberColours;
        final double panelGap = w * 0.06;
        final double panelLeftWidth = (w - panelGap) / 2;

        final List<Offset> pixelPositions = isTwoPanel
            ? _twoPanelPipPositions(
                colours: colours,
                round: round,
                w: w,
                h: h,
                gap: panelGap,
                leftWidth: panelLeftWidth,
              )
            : diceCompositeCount == 10
                ? sideBySideDicePipPixelPositions(w, h)
                : diceCompositeCount != null
                    ? stackedDicePipPixelPositions(diceCompositeCount, w, h)
                    : round.positions
                        .map((p) => Offset(p.dx * w, p.dy * h))
                        .toList();

        final circles = <Widget>[
          if (round.showDivider)
            Positioned(
              left: w * 0.06,
              right: w * 0.06,
              top: h * 0.5 - 1,
              child: Container(height: 2, color: Colors.black26),
            ),
          if (isTwoPanel)
            ..._twoPanelDividers(
              colours: colours,
              round: round,
              w: w,
              h: h,
              gap: panelGap,
              leftWidth: panelLeftWidth,
            ),
        ];
        for (int i = 0; i < round.total; i++) {
          final pos = pixelPositions[i];
          final color = colours.usesNumberColours
              ? numberColours[i < round.countA ? round.countA : round.countB]!
              : (i < round.countA ? colours.colorA : colours.colorB);

          circles.add(
            Positioned(
              left: pos.dx - radius,
              top: pos.dy - radius,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  // White (Cuisenaire "1") needs an outline to stay visible
                  // against the light play-area background.
                  border: color == Colors.white
                      ? Border.all(color: Colors.black26, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Stack(children: circles);
      },
    );
  }
}

/// Pixel-space positions for levels 10 & 11's two-panel layout: colour A's
/// group on the left, colour B's on the right, each confined to its own
/// half so neither is stretched by the other's shape.
///
/// Both panels use the usual dice-face pattern for their count. Level 11's
/// left panel is always the fixed 10-block (two rows of 5); its right panel
/// falls back to that same stacked 10-block — rather than the dice
/// pattern's usual side-by-side fives — whenever it reaches 10, so both
/// panels show "10" identically.
List<Offset> _twoPanelPipPositions({
  required CircleColourPair colours,
  required CountingRound round,
  required double w,
  required double h,
  required double gap,
  required double leftWidth,
}) {
  final double rightWidth = w - gap - leftWidth;
  final Offset rightOffset = Offset(leftWidth + gap, 0);

  final List<Offset> leftPositions = colours.isTeenGrid
      ? tenBlockStackedPipPositions(leftWidth, h)
      : dicePatternPipPixelPositions(round.countA, leftWidth, h);

  final List<Offset> rightPositions = colours.isTeenGrid && round.countB == 10
      ? tenBlockStackedPipPositions(rightWidth, h)
      : dicePatternPipPixelPositions(round.countB, rightWidth, h);

  return [
    ...leftPositions,
    ...rightPositions.map((p) => p + rightOffset),
  ];
}

/// Divider lines for the two-panel layout: level 11's left panel always
/// shows one (it's always the stacked 5-over-5 "10" block), and either
/// panel also shows one whenever its own count (8, 9, or a right-panel 10
/// on level 11) uses a stacked pattern.
List<Widget> _twoPanelDividers({
  required CircleColourPair colours,
  required CountingRound round,
  required double w,
  required double h,
  required double gap,
  required double leftWidth,
}) {
  final double rightWidth = w - gap - leftWidth;
  final bool leftShowsDivider =
      colours.isTeenGrid || round.countA == 8 || round.countA == 9;
  final bool rightShowsDivider = round.countB == 8 ||
      round.countB == 9 ||
      (colours.isTeenGrid && round.countB == 10);

  return [
    if (leftShowsDivider)
      Positioned(
        left: leftWidth * 0.06,
        right: w - leftWidth + leftWidth * 0.06,
        top: h * 0.5 - 1,
        child: Container(height: 2, color: Colors.black26),
      ),
    if (rightShowsDivider)
      Positioned(
        left: leftWidth + gap + rightWidth * 0.06,
        right: rightWidth * 0.06,
        top: h * 0.5 - 1,
        child: Container(height: 2, color: Colors.black26),
      ),
  ];
}

// ── BSL answer button row ─────────────────────────────────────────────────────

class _BslAnswerRow extends StatelessWidget {
  final List<int> options;
  final Set<int> disabledAnswers;
  final ValueChanged<int> onTap;

  const _BslAnswerRow({
    required this.options,
    required this.disabledAnswers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((n) {
        final isDisabled = disabledAnswers.contains(n);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingSmall),
            child: GestureDetector(
              onTap: isDisabled ? null : () => onTap(n),
              child: AnimatedOpacity(
                opacity: isDisabled ? 0.35 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacingSmall),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.shade300
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusLarge),
                    border: Border.all(
                      color: isDisabled
                          ? Colors.grey.shade400
                          : AppColors.catrinBlue,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BSL hand sign (SVG for 0-10, Rive for teen numbers)
                      isDisabled
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                  Colors.grey, BlendMode.saturation),
                              child: BslNumberDisplay(number: n, size: 72),
                            )
                          : BslNumberDisplay(number: n, size: 72),
                      const SizedBox(height: 4),
                      // Numeral label below the sign
                      Text(
                        '$n',
                        style: TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: AppSizes.fontSizeHeading,
                          fontWeight: FontWeight.bold,
                          color: isDisabled
                              ? Colors.grey.shade500
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
