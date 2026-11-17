import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../features/home/models/trail_node.dart';
import '../../../features/home/providers/trail_provider.dart';
import '../../../features/home/widgets/trail_navigation.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/home/models/home_game_entry.dart'
    show gameGridTileHeight;
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../../shared/widgets/torn_paper_panel.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';
import '../../../shared/widgets/champion_rosette.dart';
import '../../bsl_maths/widgets/champion_mode_explainer.dart';
import '../../bsl_maths/widgets/champion_mode_unlocked_banner.dart';
import '../providers/counting_game_provider.dart';

/// The two level groups shown as tiles on the choose-a-level screen.
/// Patterns lists canonical levels 1-6; Random lists canonical 7-13
/// (renumbered 1-7 on screen — see [CountingGameProvider.displayLevelNumber]).
enum _LevelGroup { patterns, random }

/// Main screen for the Counting Game.
///
/// Each game has 5 rounds. Each round shows a collection of dots and asks
/// one or more questions (single-colour levels just ask the total; two-colour
/// levels ask colour A count, colour B count, then total). The player taps
/// one of three BSL number buttons. Wrong answers are greyed out; correct
/// answers advance the question. Answering every round's questions wins.
class CountingGameScreen extends StatefulWidget {
  final String locale;

  /// Set when launched from the "Learn BSL trail" — the id of the trail
  /// node this session represents. Null for normal play from the game's
  /// own home tile.
  final String? trailNodeId;

  const CountingGameScreen({super.key, this.locale = 'en', this.trailNodeId});

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

  /// The currently chosen level group, or null while the group tiles
  /// (stage 1 of the choose-a-level screen) are showing. Persists across
  /// returns from gameplay so the player lands back on their group's
  /// level list.
  _LevelGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    if (widget.trailNodeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<CountingGameProvider>();
        final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
        context.read<TrailProvider>().enterTrail(widget.trailNodeId!);
        provider.onLevelComplete = (score) {
          if (node.minScore == null || score >= node.minScore!) {
            context.read<TrailProvider>().completeNode(widget.trailNodeId!);
          }
        };
        // Timed levels aren't auto-started by CountingGameProvider's
        // initialLevelNumber (see its constructor) — show the same intro
        // countdown normal timed-level play gets, same as level-select's
        // onTap for isTimed levels below.
        if (countingColourPairs[node.level - 1].isTimed) {
          setState(() {
            _pendingLevelIndex = node.level - 1;
            _showingIntro = true;
          });
        }
      });
    }
  }

  void _onAnswerTapped(int n, CountingGameProvider provider) {
    if (_isWaiting) return;
    if (n == provider.correctAnswer) {
      HapticFeedback.mediumImpact();
      AudioService.playCorrect('counting_game');
      setState(() => _isWaiting = true);
      final delay = provider.isTimedLevel
          ? const Duration(milliseconds: 500)
          : provider.currentQuestionType == QuestionType.total
          ? const Duration(seconds: 1)
          : const Duration(milliseconds: 500);
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
      final wrongDelay = provider.isTimedLevel
          ? const Duration(milliseconds: 500)
          : const Duration(seconds: 2);
      Future.delayed(wrongDelay, () {
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
                  title: localizer('counting_game.title'),
                  onBack: () {
                    // Stage 2 (a group's level list) goes back to the
                    // group tiles first; stage 1 leaves the game.
                    if (_selectedGroup != null) {
                      setState(() => _selectedGroup = null);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/backgrounds/felt-background.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? (_selectedGroup == null
                            ? _buildGroupSelect(context, provider, localizer)
                            : _buildLevelSelect(context, provider, localizer))
                      : _buildGame(context, provider, localizer),
                ),
                // Intro countdown — outside SafeArea, covers full screen.
                // levelNumber stays canonical (1-17): it selects the
                // recorded level-name clip, it isn't displayed.
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'counting_game',
                    levelNumber: _pendingLevelIndex! + 1,
                    locale: widget.locale,
                    onComplete: () {
                      final levelIndex = _pendingLevelIndex;
                      setState(() {
                        _showingIntro = false;
                        _pendingLevelIndex = null;
                      });
                      if (levelIndex != null) {
                        provider.startGame(levelIndex);
                      }
                    },
                    onBack: () {
                      setState(() {
                        _showingIntro = false;
                        _pendingLevelIndex = null;
                      });
                      if (widget.trailNodeId != null) {
                        advanceTrail(context, context.read<TrailProvider>());
                      } else {
                        provider.showLevelSelection();
                      }
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
                      onNextLevel: _canAdvance(context, provider)
                          ? () => _onNextLevel(context, provider)
                          : null,
                      onChangeLevel: () {
                        final trail = context.read<TrailProvider>();
                        if (trail.activeNodeId != null) {
                          advanceTrail(context, trail);
                        } else {
                          provider.showLevelSelection();
                        }
                      },
                    ),
                  ),

                // One-time "Champion Mode Unlocked!" celebration — shows
                // over the success overlay after a qualifying level-4 game.
                if (!provider.showLevelSelect &&
                    provider.justUnlockedChampionMode)
                  Positioned.fill(
                    child: ChampionModeUnlockedBanner(
                      locale: widget.locale,
                      textKey: 'counting_game.champion_mode.unlocked_banner',
                      onContinue: () {
                        context.read<CountingGameProvider>()
                          ..dismissChampionModeUnlockedBanner()
                          ..showLevelSelection();
                        showChampionModeExplainer(
                          context,
                          locale: widget.locale,
                          bodyKey: 'counting_game.champion_mode.explainer',
                          demo: const AnswerDigitsFadeDemo(),
                        );
                      },
                    ),
                  ),

                Positioned.fill(
                  child: LevelTransitionOverlay(
                    opacity: levelTransitionOpacity,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Whether "Next Level" has anywhere to go — either the next trail node
  /// (when launched from the trail) or the next level in this game.
  bool _canAdvance(BuildContext context, CountingGameProvider provider) {
    if (context.watch<TrailProvider>().activeNodeId != null) return true;
    return CountingGameProvider.nextLevelNumber(provider.levelNumber) != null;
  }

  /// "Next Level" — advances the trail when this session came from it,
  /// otherwise behaves exactly as it always has (next level in this game).
  void _onNextLevel(BuildContext context, CountingGameProvider provider) {
    final trail = context.read<TrailProvider>();
    if (trail.activeNodeId != null) {
      advanceTrail(context, trail);
    } else {
      final next = CountingGameProvider.nextLevelNumber(provider.levelNumber);
      if (next != null) provider.startGame(next - 1);
    }
  }

  // ── Group select (stage 1) ──────────────────────────────────────────────────

  Widget _buildGroupSelect(
    BuildContext context,
    CountingGameProvider provider,
    AppLocalizations localizer,
  ) {
    // Same sizing as the home screens' "Learn BSL trail" banner tile:
    // full content width, height matched to the game grid via
    // [gameGridTileHeight], inside the same 8px page padding.
    //
    // Overlay.wrap gives the Champion rosette an overlay of this screen's
    // own to draw in — see [TitleWithBadge].
    return Overlay.wrap(
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingSmall),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileHeight = gameGridTileHeight(
              context,
              constraints.maxWidth,
            );
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                      ),
                      child: TitleWithBadge(
                        badge: provider.isChampionModeUnlocked
                            ? ChampionRosette(
                                value: provider.championMode,
                                onChanged: provider.setChampionMode,
                                localizer: localizer,
                              )
                            : null,
                        text: localizer('counting_game.subtitle'),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingMedium),
                    _GroupTile(
                      title: localizer('counting_game.group.patterns'),
                      image: (textRect) =>
                          _CornerPatternsTileImage(textRect: textRect),
                      height: tileHeight,
                      onTap: () =>
                          setState(() => _selectedGroup = _LevelGroup.patterns),
                    ),
                    const SizedBox(height: AppSizes.spacingMedium),
                    _GroupTile(
                      title: localizer('counting_game.group.random'),
                      image: (textRect) =>
                          _RandomPicturesTileImage(textRect: textRect),
                      height: tileHeight,
                      onTap: () =>
                          setState(() => _selectedGroup = _LevelGroup.random),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Level select (stage 2) ──────────────────────────────────────────────────

  Widget _buildLevelSelect(
    BuildContext context,
    CountingGameProvider provider,
    AppLocalizations localizer,
  ) {
    // The grid shows only the chosen group's levels, renumbered to start
    // at 1 within the group (canonical indices stay 0-16 everywhere else).
    // Canonical 14-17 (levels 1-4 with hidden digits) are Champion Mode's
    // rendition of 1-4, not levels in their own right.
    final canonicalLevels = _selectedGroup == _LevelGroup.patterns
        ? CountingGameProvider.patternTabLevels
        : CountingGameProvider.randomTabLevels;

    return LevelSelectScreen(
      titleBadge: provider.isChampionModeUnlocked
          ? ChampionRosette(
              value: provider.championMode,
              onChanged: provider.setChampionMode,
              localizer: localizer,
            )
          : null,
      subtitle: localizer(
        _selectedGroup == _LevelGroup.patterns
            ? 'counting_game.patterns.subtitle'
            : 'counting_game.random.subtitle',
      ),
      locale: localizer.locale,
      levels: List.generate(canonicalLevels.length, (i) {
        final index = canonicalLevels[i] - 1;
        final pair = countingColourPairs[index];
        return LevelSelectItem(
          number: i + 1,
          name: localizer(pair.name),
          color: levelColor(i),
          onTap: () {
            if (pair.isTimed) {
              setState(() {
                _pendingLevelIndex = index;
                _showingIntro = true;
              });
            } else {
              // levelNumber stays canonical (1-17) — it selects the
              // recorded '<gameId>_level<N>_name' speech clip.
              startLevelWithTransition(
                gameId: 'counting_game',
                levelNumber: index + 1,
                locale: widget.locale,
                startLevel: () => provider.startGame(index),
              );
            }
          },
        );
      }),
    );
  }

  // ── Game layout ─────────────────────────────────────────────────────────────

  Widget _buildGame(
    BuildContext context,
    CountingGameProvider provider,
    AppLocalizations localizer,
  ) {
    final round = provider.currentRound;
    final colours = provider.colours;

    final questionText = _questionText(
      provider.currentQuestionType,
      colours,
      round,
      localizer,
    );

    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () {
            final trail = context.read<TrailProvider>();
            if (trail.activeNodeId != null) {
              advanceTrail(context, trail);
            } else {
              provider.showLevelSelection();
            }
          },
          scoreValue: '${provider.score}',
          // Tab-relative number, matching what the child tapped on the
          // level select (Random tab shows levels 7-13 as 1-7).
          levelNumber: CountingGameProvider.displayLevelNumber(
            provider.levelNumber,
          ),
          centerContent: provider.isTimedLevel
              ? GameTimerDisplay(
                  formattedTime: GameTimerDisplay.format(
                    Duration(seconds: provider.secondsRemaining),
                  ),
                )
              : Center(
                  child: Text(
                    '${localizer('counting_game.round_label')} ${provider.roundNumber} '
                    '${localizer('counting_game.of_label')} ${CountingGameProvider.totalRounds}',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            // Solid white paper with torn edges; keyed per question so
            // each new question gets a fresh tear.
            child: TornPaperPanel(
              key: ValueKey(
                '${provider.roundNumber}-${provider.currentQuestionType}',
              ),
              child: Container(
                width: double.infinity,
                height: 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                  vertical: AppSizes.spacingSmall,
                ),
                child: Text(
                  questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Dot play area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
            ),
            // White play area with outer wrapper, matching Bubble Pop.
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.headerBackgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.headerBorderDark, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.headerBorderDark,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _DotPlayArea(
                    key: ValueKey(provider.roundNumber),
                    round: round,
                    colours: colours,
                  ),
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
                  fontFamily: 'Quicksand',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
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
            horizontal: AppSizes.paddingLarge,
          ),
          child: _BslAnswerRow(
            options: provider.answerOptions,
            disabledAnswers: _isWaiting
                ? provider.answerOptions.toSet()
                : provider.disabledAnswers,
            onTap: (n) => _onAnswerTapped(n, provider),
            // Hidden for levels that opt out, and for every level while
            // Champion Mode is on (the player must read the BSL sign).
            showNumbers: provider.showAnswerNumerals,
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  String _questionText(
    QuestionType type,
    DotColourPair colours,
    CountingRound round,
    AppLocalizations localizer,
  ) {
    final objectA = round.objectA;
    final objectB = round.objectB;
    if (objectA != null && objectB != null) {
      return _objectQuestionText(type, colours, objectA, objectB, localizer);
    }

    // Levels 10 & 11 colour each group by its own count value, so the
    // colour name asked about must reflect that round's actual counts
    // rather than a level-fixed nameA/nameB.
    final String nameA = colours.isSplitFives(round)
        ? splitFivesNameA
        : colours.usesNumberColours
        ? numberColourNames[round.countA]!
        : colours.nameA;
    final String nameB = colours.isSplitFives(round)
        ? splitFivesNameB
        : colours.usesNumberColours
        ? numberColourNames[round.countB]!
        : colours.nameB;

    // 5 + 5 on "Add to 10": "How many light/dark yellow dots are there?".
    if (colours.isSplitFives(round) && type != QuestionType.total) {
      final name = type == QuestionType.colourA ? nameA : nameB;
      return localizer(
        'counting_game.question_total_single',
      ).replaceAll('{colour}', localizer('counting_game.colour.$name'));
    }

    switch (type) {
      case QuestionType.colourA:
        return localizer(
          'counting_game.question_colour',
        ).replaceAll('{colour}', localizer('counting_game.colour.$nameA'));
      case QuestionType.colourB:
        return localizer(
          'counting_game.question_colour',
        ).replaceAll('{colour}', localizer('counting_game.colour.$nameB'));
      case QuestionType.total:
        return colours.singleColour
            ? localizer(
                'counting_game.question_total_single',
              ).replaceAll('{colour}', localizer('counting_game.colour.$nameA'))
            : localizer('counting_game.question_total_multi');
    }
  }

  /// Questions for picture rounds. Whole sentences per object (and colour)
  /// rather than templates, so Welsh can use the right noun and mutate the
  /// colour after a feminine noun (e.g. "Sawl het binc?").
  String _objectQuestionText(
    QuestionType type,
    DotColourPair colours,
    CountingObject objectA,
    CountingObject objectB,
    AppLocalizations localizer,
  ) {
    const base = 'counting_game.object';
    // "Add to 10": a different object in each group.
    if (objectA != objectB) {
      return switch (type) {
        QuestionType.colourA => localizer('$base.${objectA.name}.how_many'),
        QuestionType.colourB => localizer('$base.${objectB.name}.how_many'),
        QuestionType.total => localizer('$base.altogether'),
      };
    }
    final object = '$base.${objectA.name}';
    if (colours.singleColour || colours.usesNumberColours) {
      return localizer('$object.total');
    }
    return switch (type) {
      QuestionType.colourA => localizer('$object.${colours.nameA}'),
      QuestionType.colourB => localizer('$object.${colours.nameB}'),
      QuestionType.total => localizer('$object.altogether'),
    };
  }
}

// ── Dot play area ──────────────────────────────────────────────────────────

class _DotPlayArea extends StatelessWidget {
  final CountingRound round;
  final DotColourPair colours;

  const _DotPlayArea({super.key, required this.round, required this.colours});

  @override
  Widget build(BuildContext context) {
    // Objects with a row-of-10 picture (candles) show that one picture
    // cropped to the count, rather than scattered separate pictures.
    final object = round.objectA;
    final strip = object?.stripImage;
    if (strip != null && round.objectB == object) {
      return _StripPlayArea(
        image: strip,
        count: round.total,
        fraction: object!.stripFraction(round.total),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final double radius = round.total <= 5
            ? 26
            : round.total <= 10
            ? 20
            : 14;

        // Composite dice counts (6-10) size each sub-pattern to a true pixel
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
            : round.positions.map((p) => Offset(p.dx * w, p.dy * h)).toList();

        final dots = <Widget>[
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
          if (round.images.isNotEmpty) {
            // Picture levels: about twice the dot's size, so the
            // pictures (balloons, candles, hats...) read clearly — a little
            // smaller on the busiest rounds (11-19 items) so they don't
            // crowd each other.
            final size = radius * (round.total > 10 ? 3.0 : 3.9);
            dots.add(
              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                width: size,
                height: size,
                child: Image.asset(round.images[i], fit: BoxFit.contain),
              ),
            );
            continue;
          }
          final color = colours.isSplitFives(round)
              ? (i < round.countA ? splitFivesColourA : splitFivesColourB)
              : colours.usesNumberColours
              ? numberColours[i < round.countA ? round.countA : round.countB]!
              : (i < round.countA ? colours.colorA : colours.colorB);

          dots.add(
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
                  // against the light play-area background; light yellow
                  // (5 + 5 rounds) gets a dark yellow one for the same reason.
                  border: color == Colors.white
                      ? Border.all(color: Colors.black26, width: 2)
                      : color == splitFivesColourA
                      ? Border.all(color: splitFivesColourB, width: 2)
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

        return Stack(children: dots);
      },
    );
  }
}

/// Shows the left [fraction] of [image] — a picture of 10 items in a row —
/// so exactly [count] items are visible, sitting on the play area's bottom
/// edge, centred across it, with no padding. From 5 items up the full
/// picture is scaled to the play area's width, so each item stays the same
/// size; below 5 the cropped part is scaled up to fill the play area.
class _StripPlayArea extends StatelessWidget {
  final String image;
  final int count;
  final double fraction;

  const _StripPlayArea({
    required this.image,
    required this.count,
    required this.fraction,
  });

  /// [child] cropped to its left [fraction]: the Align reports only that
  /// width, and the ClipRect hides the rest.
  Widget _cropped(Widget child) => ClipRect(
    child: Align(
      alignment: Alignment.centerLeft,
      widthFactor: fraction,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (count < 5) {
      return SizedBox.expand(
        child: FittedBox(
          alignment: Alignment.bottomCenter,
          child: _cropped(Image.asset(image)),
        ),
      );
    }
    // Measure the play area so the full 10-item picture is exactly its
    // width.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox.expand(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _cropped(
            Image.asset(
              image,
              width: constraints.maxWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pixel-space positions for levels 5 & 6's two-panel layout: colour A's
/// group on the left, colour B's on the right, each confined to its own
/// half so neither is stretched by the other's shape.
///
/// Both panels use the usual dice-face pattern for their count. Level 11's
/// left panel is always the fixed 10-block (two rows of 5); its right panel
/// falls back to that same stacked 10-block — rather than the dice
/// pattern's usual side-by-side fives — whenever it reaches 10, so both
/// panels show "10" identically.
List<Offset> _twoPanelPipPositions({
  required DotColourPair colours,
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

  return [...leftPositions, ...rightPositions.map((p) => p + rightOffset)];
}

/// Divider lines for the two-panel layout: level 6's left panel always
/// shows one (it's always the stacked 5-over-5 "10" block), and either
/// panel also shows one whenever its own count (6, 8, 9, or a right-panel 10
/// on level 6) uses a stacked pattern.
List<Widget> _twoPanelDividers({
  required DotColourPair colours,
  required CountingRound round,
  required double w,
  required double h,
  required double gap,
  required double leftWidth,
}) {
  final double rightWidth = w - gap - leftWidth;
  final bool leftShowsDivider =
      colours.isTeenGrid ||
      round.countA == 6 ||
      round.countA == 8 ||
      round.countA == 9;
  final bool rightShowsDivider =
      round.countB == 6 ||
      round.countB == 8 ||
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

  /// False for levels that drill sign recognition without the numeral as
  /// a crutch — see [DotColourPair.showAnswerNumerals].
  final bool showNumbers;

  const _BslAnswerRow({
    required this.options,
    required this.disabledAnswers,
    required this.onTap,
    this.showNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((n) {
        final isDisabled = disabledAnswers.contains(n);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingSmall,
            ),
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
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusLarge,
                    ),
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
                      // BSL hand sign (PNG for 0-10, Rive for teen numbers)
                      isDisabled
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: BslNumberDisplay(number: n, size: 72),
                            )
                          : BslNumberDisplay(number: n, size: 72),
                      if (showNumbers) ...[
                        const SizedBox(height: 4),
                        // Numeral label below the sign
                        Text(
                          '$n',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: AppSizes.fontSizeHeading,
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? Colors.grey.shade500
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
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

/// One of the two group tiles (Patterns / Random) on the choose-a-level
/// screen — full width and sized to match the home screens' "Learn BSL
/// trail" banner tile (see [gameGridTileHeight]). White paper with torn
/// left and right edges, [image] filling it, and the group's title centred
/// on top in the success page's heading style (see [GameSuccessOverlay]):
/// corner dot patterns for Patterns, and for Random the same scatter of
/// pictures the Random levels count (see [_RandomPicturesTileImage]).
class _GroupTile extends StatelessWidget {
  final String title;

  /// Builds the tile's picture, given where the title sits (in the
  /// picture's own coordinates) so it can keep clear of it.
  final Widget Function(Rect textRect) image;

  /// Tile height — pass [gameGridTileHeight] so the tile matches the
  /// home screens' trail banner tile.
  final double height;
  final VoidCallback onTap;

  const _GroupTile({
    required this.title,
    required this.image,
    required this.height,
    required this.onTap,
  });

  /// The success page's heading size, and its outline/drop-shadow blue.
  static const double _titleFontSize = 48;
  static const Color _darkBlue = Color(0xFF002D97);

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTheme.celebrationAt(
      _titleFontSize,
    ).copyWith(fontWeight: FontWeight.bold);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TornPaperPanel(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                image(
                  _textRect(
                    context,
                    titleStyle,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
                // Beams of light radiating from behind the title, over the
                // picture, so the title stands out.
                const IgnorePointer(
                  child: CustomPaint(painter: _RadialFlarePainter()),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall,
                    ),
                    // Shrinks to fit on one line rather than wrapping (the
                    // Welsh may be longer).
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
                        children: [
                          // As on the success page: a dark-blue 2px stroke and
                          // solid drop shadow (2px right, 4px down) behind the
                          // fill — here light blue rather than white, on white paper.
                          Text(
                            title,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: titleStyle.copyWith(
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2
                                ..color = _darkBlue,
                              shadows: const [
                                Shadow(color: _darkBlue, offset: Offset(2, 4)),
                              ],
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: titleStyle.copyWith(
                              color: AppColors.catrinBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Space kept clear around the title.
  static const double _textClearance = 8;

  /// The title's box within a tile of [size], plus [_textClearance] — the
  /// title's laid-out size (scaled down as the FittedBox does when too
  /// wide), grown by its drop shadow and centred.
  Rect _textRect(BuildContext context, TextStyle style, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final available = size.width - 2 * AppSizes.paddingSmall;
    final fit = min(1.0, available / painter.width);
    final width = painter.width * fit + 2;
    final height = painter.height * fit + 4;
    painter.dispose();
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width + 2 * _textClearance,
      height: height + 2 * _textClearance,
    );
  }
}

/// A radial flare: wedge-shaped beams of white light fanning out from the
/// centre of the box, alternating long and short. Each beam widens as it
/// goes out and fades to nothing at its tip, so the light is strongest at
/// the centre.
class _RadialFlarePainter extends CustomPainter {
  const _RadialFlarePainter();

  static const int _beams = 16;

  /// Each beam's width at its tip, as a fraction of the gap between beam
  /// centres (so 0.5 = beams and gaps the same width).
  static const double _beamFraction = 0.5;

  /// Length of the long beams relative to the box's half-diagonal; short
  /// beams are [_shortFraction] of that.
  static const double _lengthFraction = 1.1;
  static const double _shortFraction = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final reach = (size.longestSide / 2) * _lengthFraction;
    final step = 2 * pi / _beams;
    final halfWidth = step * _beamFraction / 2;
    for (var i = 0; i < _beams; i++) {
      final length = i.isEven ? reach : reach * _shortFraction;
      final angle = i * step - pi / 2;
      Offset tip(double a) => centre + Offset(cos(a), sin(a)) * length;
      final beam = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(tip(angle - halfWidth).dx, tip(angle - halfWidth).dy)
        ..lineTo(tip(angle + halfWidth).dx, tip(angle + halfWidth).dy)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 1],
          ).createShader(Rect.fromCircle(center: centre, radius: length)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialFlarePainter oldDelegate) => false;
}

/// A white radial gradient from the box's centre: 80% opaque at the
/// centre, fading to transparent at a radius of half the box's height, so
/// it just reaches the top and bottom edges.
class _CentreWashPainter extends CustomPainter {
  const _CentreWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.height / 2,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(circle),
    );
  }

  @override
  bool shouldRepaint(covariant _CentreWashPainter oldDelegate) => false;
}

/// Stretches a [RadialGradient] — a circle sized to [rect]'s shortest side
/// — horizontally or vertically to fill [rect] as an oval.
class _StretchToRect extends GradientTransform {
  final Rect rect;

  const _StretchToRect(this.rect);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final shortest = rect.shortestSide;
    final centre = rect.center;
    return Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(rect.width / shortest, rect.height / shortest, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  }
}

/// The Patterns tile's image: die-face dot patterns (1-5) in the four
/// corners, plus one top centre and one bottom centre, each in its
/// in-game number colour (see [numberColours]), sized off the space
/// around the title in the middle. The numbers are picked at random once
/// per visit to the screen, so the tile changes each time but doesn't
/// reshuffle on rebuild.
class _CornerPatternsTileImage extends StatefulWidget {
  /// The title's box, which sets the patterns' size.
  final Rect textRect;

  const _CornerPatternsTileImage({required this.textRect});

  @override
  State<_CornerPatternsTileImage> createState() =>
      _CornerPatternsTileImageState();
}

class _CornerPatternsTileImageState extends State<_CornerPatternsTileImage> {
  /// Gap between each pattern and the tile's edges.
  static const double _inset = 12;

  /// Colour for 1's dot in place of the game's white — a mid green,
  /// darker than 3's light green so the two stay distinct.
  static const Color _oneColour = Color(0xFF43A047);

  /// Four different numbers, 1-5, for the corners (top-left, top-right,
  /// bottom-left, bottom-right), then any number 1-5 for each of top
  /// centre and bottom centre.
  late final List<int> _counts = () {
    final random = Random();
    return [
      ...([1, 2, 3, 4, 5]..shuffle(random)).take(4),
      random.nextInt(5) + 1,
      random.nextInt(5) + 1,
    ];
  }();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final text = widget.textRect;
        // Base size: the biggest square that clears the title, sitting
        // wholly above/below it or wholly beside it. Patterns are drawn at
        // twice that, so they may overlap the title, but capped so none of
        // the six overlap each other: two rows fit the height, and three
        // across (corner, centre, corner) fit the width.
        final aboveOrBelow = min(text.top, h - text.bottom) - _inset;
        final beside = min(text.left, w - text.right) - _inset;
        final face = min<double>(
          2 * max(aboveOrBelow, beside),
          min((h - _inset * 3) / 2, (w - _inset * 4) / 3),
        );
        if (face <= 0) return const SizedBox.shrink();
        final radius = face * 0.11;
        final centreX = (w - face) / 2;
        final bottomY = h - _inset - face;
        // (top-left of the pattern's square, number of dots)
        final patterns = [
          (const Offset(_inset, _inset), _counts[0]),
          (Offset(centreX, _inset), _counts[4]),
          (Offset(w - _inset - face, _inset), _counts[1]),
          (Offset(_inset, bottomY), _counts[2]),
          (Offset(centreX, bottomY), _counts[5]),
          (Offset(w - _inset - face, bottomY), _counts[3]),
        ];
        return Stack(
          children: [
            for (final (corner, count) in patterns)
              for (final p in dicePatternPipPixelPositions(count, face, face))
                Positioned(
                  left: corner.dx + p.dx - radius,
                  top: corner.dy + p.dy - radius,
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    // Each number in its in-game colour, except 1: the game's
                    // white would vanish on the white paper, so it's green.
                    decoration: BoxDecoration(
                      color: count == 1 ? _oneColour : numberColours[count],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// The Random tile's image: a scatter of pictures of the things the Random
/// levels count (balloons, candles, hats, …), laid out like the old
/// circle placeholder. Pictures are drawn at random from every
/// [CountingObject]'s images, without repeats, once per visit to the
/// screen — so the tile changes each time but doesn't reshuffle on rebuild.
class _RandomPicturesTileImage extends StatefulWidget {
  /// The title's box: the pictures are softly blurred behind it.
  final Rect textRect;

  const _RandomPicturesTileImage({required this.textRect});

  @override
  State<_RandomPicturesTileImage> createState() =>
      _RandomPicturesTileImageState();
}

class _RandomPicturesTileImageState extends State<_RandomPicturesTileImage> {
  /// How much bigger each picture is drawn than its spot's radius.
  static const double _pictureScale = 1.4;

  /// Strength of the blur behind the title, and how far past the title's
  /// box it fades out.
  static const double _blurSigma = 6;
  static const double _blurFeather = 24;

  /// Layout size the [_spots] are measured in; scaled to cover the tile the
  /// way [BoxFit.cover] would.
  static const Size _layoutSize = Size(640, 400);

  /// Centre (x, y) and radius of each picture, in [_layoutSize] pixels —
  /// packed densely so pictures overlap, and the title sits on top of them.
  static const List<(double, double, double)> _spots = [
    (60, 55, 40),
    (185, 70, 36),
    (300, 45, 42),
    (420, 75, 38),
    (540, 50, 40),
    (620, 95, 30),
    (30, 190, 30),
    (110, 165, 44),
    (235, 180, 38),
    (350, 150, 46),
    (470, 185, 40),
    (585, 200, 42),
    (70, 300, 40),
    (190, 285, 46),
    (310, 310, 38),
    (430, 290, 44),
    (555, 315, 38),
    (130, 375, 34),
    (260, 385, 30),
    (380, 380, 36),
    (500, 385, 32),
    (620, 370, 30),
  ];

  late final List<String> _pictures;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final pool = [
      for (final object in CountingObject.values)
        for (final file in object.images)
          'assets/images/counting_game/${object.name}/$file',
    ]..shuffle(random);
    _pictures = [for (var i = 0; i < _spots.length; i++) pool[i % pool.length]];
  }

  @override
  Widget build(BuildContext context) {
    // Transparent, so the tile's white paper shows through.
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = max(
            constraints.maxWidth / _layoutSize.width,
            constraints.maxHeight / _layoutSize.height,
          );
          final dx = (constraints.maxWidth - _layoutSize.width * scale) / 2;
          final dy = (constraints.maxHeight - _layoutSize.height * scale) / 2;
          final rects = [
            for (final (x, y, r) in _spots)
              Rect.fromCircle(
                center: Offset(dx + x * scale, dy + y * scale),
                radius: r * _pictureScale * scale,
              ),
          ];
          final pictures = Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var i = 0; i < _spots.length; i++)
                // Leave out pictures the left or right edge would cut off.
                if (rects[i].left >= 0 &&
                    rects[i].right <= constraints.maxWidth)
                  Positioned.fromRect(
                    rect: rects[i],
                    child: Image.asset(_pictures[i], fit: BoxFit.contain),
                  ),
            ],
          );
          // Soft blur behind the title: a blurred copy of the pictures on
          // top, faded out by an oval mask around the title, so the blur
          // is strongest behind the text and melts into the sharp pictures
          // with no hard edge.
          final blurArea = widget.textRect.inflate(_blurFeather);
          return Stack(
            fit: StackFit.expand,
            children: [
              pictures,
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (_) => RadialGradient(
                  colors: const [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.55, 1],
                  // Stretch the circle into an oval matching the title.
                  transform: _StretchToRect(blurArea),
                ).createShader(blurArea),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blurSigma,
                    sigmaY: _blurSigma,
                  ),
                  child: pictures,
                ),
              ),
              // White wash over the pictures: 80% at the centre, fading to
              // nothing where it reaches the top and bottom edges.
              const IgnorePointer(
                child: CustomPaint(painter: _CentreWashPainter()),
              ),
            ],
          );
        },
      ),
    );
  }
}
