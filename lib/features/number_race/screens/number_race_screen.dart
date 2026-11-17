import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_instructions_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/torn_paper_panel.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/felt_grass_texture.dart';
import '../../../shared/widgets/game_level_map.dart';
import '../../counting_game/providers/counting_game_provider.dart'
    show dicePatternPipPixelPositions;
import '../models/number_race_models.dart';
import '../providers/number_race_provider.dart';
import '../widgets/animated_racer_sprite.dart';
import '../widgets/big_number_card.dart';
import '../widgets/level_intro.dart';
import '../widgets/race_grandstand.dart';
import '../widgets/running_track.dart';

/// Main screen for Number Race.
///
/// The player first picks a racer (Gary, Pero or JamJam), then answers a
/// series of "how many dots?" questions using BSL number signs. A correct
/// answer moves the player's racer along the track; a wrong answer moves
/// the other two racers instead. Reaching the finish line first (5 correct
/// answers) wins the race.
class NumberRaceScreen extends StatefulWidget {
  final String locale;

  const NumberRaceScreen({super.key, this.locale = 'en'});

  @override
  State<NumberRaceScreen> createState() => _NumberRaceScreenState();
}

class _NumberRaceScreenState extends State<NumberRaceScreen> {
  /// Felt meadow green behind the level map, matching [GameLevelMap].
  static const Color _meadowGreen = Color(0xFF65A94F);

  bool _showingIntro = false;

  /// The level's own introduction (see [LevelIntroConfig]), shown before
  /// the countdown when the level is picked from the map.
  LevelIntroConfig? _levelIntro;
  bool _isWaiting = false;

  /// Highest level finished, as on Bubble Shooter's map: levels up to it
  /// show as done (gold) and the player's racer stands on the next one.
  /// Every level stays playable whatever this is.
  int _highestCompleted = 0;

  /// The level just finished, when it moved the player on to a new level —
  /// the map then shows the racer walking from it to the next one.
  int? _movedFromLevel;

  /// Levels the player has passed — finished 1st or 2nd — in any order. A
  /// chest is ready to open once its own level is in here.
  Set<int> _completedLevels = {};

  /// Chest levels whose chest this player has already opened.
  Set<int> _openedChests = {};

  /// Remembers passed levels and opened chests per player (in memory only
  /// for guests).
  final _progressService = GameInstructionsService();

  static String _chestId(int level) => 'number_race_chest_$level';
  static String _passedId(int level) => 'number_race_passed_$level';

  /// Whether the player's racer finished in a passing place (1st or 2nd).
  static bool _placedToPass(NumberRaceProvider provider) =>
      provider.standings.indexOf(provider.playerCharacter!) <= 1;

  @override
  void initState() {
    super.initState();
    _playCharacterSelectIntro();
    _loadProgress();
    context.read<NumberRaceProvider>().onRaceFinished = _onRaceFinished;
  }

  /// Finishing 1st or 2nd passes the level: it's remembered for this
  /// player and counts as completed on the map. Passing a level past the
  /// furthest one so far sets up the walk to the next. Coming 3rd doesn't
  /// move the player on.
  void _onRaceFinished(int level) {
    if (!mounted) return;
    if (!_placedToPass(context.read<NumberRaceProvider>())) return;
    _progressService.markInstructionsSeen(_passedId(level));
    setState(() {
      if (level > _highestCompleted && level < NumberRaceProvider.totalLevels) {
        _movedFromLevel = level;
      }
      _highestCompleted = max(_highestCompleted, level);
      _completedLevels = {..._completedLevels, level};
    });
  }

  /// Finds which levels the player has passed and which chests they've
  /// opened. Guests' progress lasts for this app session only.
  Future<void> _loadProgress() async {
    final passed = await Future.wait([
      for (var level = 1; level <= NumberRaceProvider.totalLevels; level++)
        _progressService.hasSeenInstructions(_passedId(level)),
    ]);
    final chestLevels = [
      for (var level = 1; level <= NumberRaceProvider.totalLevels; level++)
        if (NumberRaceProvider.isSectionEnd(level)) level,
    ];
    final opened = await Future.wait([
      for (final level in chestLevels)
        _progressService.hasSeenInstructions(_chestId(level)),
    ]);
    if (!mounted) return;
    setState(() {
      // Merged with this session's progress, which may be ahead of what's
      // saved (a result still being written).
      _completedLevels = {
        ..._completedLevels,
        for (var i = 0; i < passed.length; i++)
          if (passed[i]) i + 1,
      };
      _highestCompleted = _completedLevels.fold(_highestCompleted, max);
      _openedChests = {
        for (var i = 0; i < chestLevels.length; i++)
          if (opened[i]) chestLevels[i],
      };
    });
  }

  ChestState _chestState(int level) {
    if (_openedChests.contains(level)) return ChestState.opened;
    return _completedLevels.contains(level)
        ? ChestState.ready
        : ChestState.locked;
  }

  /// A chest level: once its level is completed and the chest not yet
  /// opened, opens it and awards that level's big-number card; otherwise
  /// plays the level, like any other.
  Future<void> _onChestTapped(
    NumberRaceProvider provider,
    int level,
    AppLocalizations localizer,
  ) async {
    final number = BigNumber.forLevel(level);
    if (number == null || _chestState(level) != ChestState.ready) {
      _chooseLevel(provider, level);
      return;
    }
    setState(() => _openedChests = {..._openedChests, level});
    _progressService.markInstructionsSeen(_chestId(level));
    AudioService.playCorrect('number_race');
    await showBigNumberWon(context, number: number, localizer: localizer);
  }

  /// Plays the "Number Race" title clip, then — once it has finished — a
  /// 1.5 second pause before the "choose your character" instruction. Either
  /// clip is interrupted early if the player taps a character card first
  /// (see [_chooseCharacter]); once a character's been chosen, the
  /// "choose your character" clip is skipped entirely rather than starting
  /// (or resuming) after the interruption.
  Future<void> _playCharacterSelectIntro() async {
    final provider = context.read<NumberRaceProvider>();
    bool characterChosen() => !mounted || provider.playerCharacter != null;
    await AudioService.playInstructionClipAndWait(
      'number_race',
      'title',
      locale: widget.locale,
      isCancelled: characterChosen,
    );
    if (characterChosen()) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (characterChosen()) return;
    await AudioService.playInstructionClipAndWait(
      'number_race',
      'choose_character',
      locale: widget.locale,
      isCancelled: characterChosen,
    );
  }

  Future<void> _chooseCharacter(
    NumberRaceProvider provider,
    RaceCharacter character,
  ) async {
    // Record the choice first so the intro sequence sees it immediately —
    // including a clip that's still loading, which stopAll() can't reach —
    // then interrupt whatever intro clip is playing and announce the
    // chosen character.
    provider.selectCharacter(character);
    _loadProgress();
    await AudioService.stopAll();
    AudioService.playInstructionClip(
      'number_race',
      'character_${character.name}',
      locale: widget.locale,
    );
  }

  void _chooseLevel(NumberRaceProvider provider, int level) {
    // The walk has been seen; don't replay it on the next visit to the map.
    _movedFromLevel = null;
    provider.selectLevel(level);
    setState(() {
      _levelIntro = LevelIntroConfig.forLevel(level);
      _showingIntro = _levelIntro == null;
    });
  }

  void _restartGame(NumberRaceProvider provider) {
    provider.resetForIntro();
    setState(() => _showingIntro = true);
  }

  /// Next Level, as on Bubble Shooter: back to the level map, where the
  /// racer walks on to the next level (see [_onRaceFinished]).
  void _nextLevel(NumberRaceProvider provider) {
    provider.showLevelMapScreen();
  }

  void _onAnswerTapped(int n, NumberRaceProvider provider) {
    if (_isWaiting) return;
    HapticFeedback.mediumImpact();
    if (n == provider.currentDotCount) {
      AudioService.playCorrect('number_race');
    } else {
      AudioService.playWrong('number_race');
    }
    setState(() => _isWaiting = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      provider.selectAnswer(n);
      setState(() => _isWaiting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<NumberRaceProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: (provider.showCharacterSelect || provider.showLevelMap)
              ? GameAppBar(
                  title: localizer('number_race.title'),
                  onBack: () {
                    if (provider.showCharacterSelect) {
                      Navigator.of(context).pop();
                    } else {
                      provider.showCharacterSelection();
                    }
                  },
                )
              : null,
          body: Container(
            // The level map and the racer select paint their own felt
            // meadow.
            decoration: provider.showLevelMap || provider.showCharacterSelect
                ? const BoxDecoration(color: _meadowGreen)
                : const BoxDecoration(
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
                  // The map runs full-bleed to the bottom edge so the
                  // meadow covers the bottom safe area too. The racer
                  // select runs full-bleed on every side (sky to the top,
                  // grass to the bottom) and pads its own content.
                  top: !provider.showCharacterSelect,
                  left: !provider.showCharacterSelect,
                  right: !provider.showCharacterSelect,
                  bottom:
                      !provider.showLevelMap && !provider.showCharacterSelect,
                  child: provider.showCharacterSelect
                      // Builder so the racer select reads MediaQuery from
                      // inside the Scaffold body, where the top padding
                      // includes the app bar's height.
                      ? Builder(
                          builder: (context) => _buildCharacterSelect(
                            context,
                            provider,
                            localizer,
                          ),
                        )
                      : provider.showLevelMap
                      ? _buildLevelMap(context, provider, localizer)
                      : _buildGame(context, provider, localizer),
                ),
                if (!provider.showCharacterSelect &&
                    !provider.showLevelMap &&
                    provider.isWon &&
                    !_showingIntro &&
                    _levelIntro == null)
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        // Where the player's own racer finished (0 = 1st, 1 =
                        // 2nd, 2 = 3rd) — the heading and summary line depend
                        // on the player's own result, not just on winning the
                        // race (every game ends once the player scores 5).
                        final playerPosition = provider.standings.indexOf(
                          provider.playerCharacter!,
                        );
                        final summaryKey = switch (playerPosition) {
                          0 => 'number_race.success_summary',
                          1 => 'number_race.success_summary_second',
                          _ => 'number_race.success_summary_third',
                        };
                        final cameThird = playerPosition == 2;

                        return GameSuccessOverlay(
                          gameId: 'number_race',
                          locale: widget.locale,
                          scoreStyle: SuccessScoreStyle.custom,
                          score: provider.score,
                          customScoreLine: localizer(summaryKey).replaceAll(
                            '{character}',
                            localizer(provider.playerCharacter!.nameKey),
                          ),
                          headingOverride: cameThird
                              ? localizer('general.try_again')
                              : null,
                          successAudioNameOverride: cameThird
                              ? 'try_again'
                              : null,
                          showPersonalBest: true,
                          isNewPersonalBest:
                              provider.lastResult?.isNewPersonalBest ?? false,
                          personalBest: provider.lastResult?.personalBest,
                          personalBestSuffix: provider.isTimedLevel
                              ? localizer('number_race.time_suffix')
                              : localizer('number_race.attempts_suffix'),
                          onPlayAgain: () => _restartGame(provider),
                          // Only a 1st or 2nd place moves the player on.
                          onNextLevel:
                              !cameThird &&
                                  provider.level <
                                      NumberRaceProvider.totalLevels
                              ? () => _nextLevel(provider)
                              : null,
                          onChangeLevel: () =>
                              provider.showCharacterSelection(),
                          centerExtraContent: true,
                          extraContent: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (provider.isTimedLevel) ...[
                                _TimeResult(
                                  elapsed: provider.elapsedTime,
                                  localizer: localizer,
                                ),
                                const SizedBox(height: AppSizes.spacingMedium),
                              ],
                              // Scaled up to the same width as the Play Again
                              // button below (min(680, screen width) minus its
                              // own horizontal padding), so the podium reads as
                              // a prominent centrepiece rather than a small aside.
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const buttonContentWidth =
                                      680.0 - AppSizes.paddingLarge * 2;
                                  final podiumWidth = min(
                                    constraints.maxWidth,
                                    buttonContentWidth,
                                  );
                                  return SizedBox(
                                    width: podiumWidth,
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: _Podium(
                                        standings: provider.standings,
                                        playerCharacter:
                                            provider.playerCharacter,
                                        localizer: localizer,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (_levelIntro != null)
                  LevelIntro(
                    config: _levelIntro!,
                    locale: widget.locale,
                    onComplete: () => setState(() {
                      _levelIntro = null;
                      _showingIntro = true;
                    }),
                  ),
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'number_race',
                    levelNumber: provider.level,
                    locale: widget.locale,
                    characterImage: provider.playerCharacter?.assetPath,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                      AudioService.playInstructionClip(
                        'number_race',
                        'question',
                        locale: widget.locale,
                      );
                    },
                    onBack: () {
                      setState(() => _showingIntro = false);
                      provider.showCharacterSelection();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Character select ────────────────────────────────────────────────────

  Widget _buildCharacterSelect(
    BuildContext context,
    NumberRaceProvider provider,
    AppLocalizations localizer,
  ) {
    // Drawn outside the SafeArea so the sky reaches the top edge (behind
    // the app bar) and the grass the bottom edge; this padding keeps the
    // content itself clear of the app bar, notch and home indicator.
    final safe = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Felt grass behind the whole screen, matching the level map's
        // meadow. It fills the screen whatever the scroll position, so the
        // grass always reaches the bottom edge.
        const ColoredBox(color: _meadowGreen),
        const IgnorePointer(child: FeltGrassTexture()),
        LayoutBuilder(
          builder: (context, constraints) {
            // Where the grandstand's railing (and the grass) begins.
            final grandstandBottom =
                safe.top +
                AppSizes.paddingMedium +
                RaceGrandstand.heightFor(context);
            final tileHeight = _CharacterCard.heightFor(context);
            // The tiles, the gap after each, and the bottom padding.
            final tilesBlock =
                RaceCharacter.values.length *
                    (tileHeight + AppSizes.spacingMedium) +
                AppSizes.paddingMedium +
                safe.bottom;
            // Gap between the railing and the first tile: 32px when
            // there's room. On shorter screens it shrinks, then goes
            // negative so the tiles ride up over the crowd, until the
            // first tile's top is 32px below the top of the stand. Only
            // past that does the screen have to scroll.
            const maxGap = 32.0;
            final minGap = -(RaceGrandstand.standHeightFor(context) - 32);
            final gap = (constraints.maxHeight - grandstandBottom - tilesBlock)
                .clamp(minGap, maxGap);
            return SingleChildScrollView(
              // No overscroll bounce, which would show grass above the sky.
              physics: const ClampingScrollPhysics(),
              child: Stack(
                children: [
                  // Felt sky behind the jumbotron, running edge to edge and
                  // up under the app bar; the grandstand's railing meets
                  // the grass.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: safe.top + AppSizes.paddingMedium,
                      ),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/games/bubble_shooter/background/sky_felt.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: RaceGrandstand(
                        message: localizer('number_race.choose_character'),
                      ),
                    ),
                  ),
                  // Race track along the top of the grass: from the
                  // grandstand's railing down to the middle of the first
                  // (Gary's) tile, edge to edge behind the tiles. Gone if
                  // the tiles ride up far enough to hide it.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: grandstandBottom,
                    height: max(0.0, gap + tileHeight / 2),
                    child: const RunningTrack(),
                  ),
                  // Last, so the tiles paint over the crowd when they
                  // overlap it.
                  Padding(
                    padding: EdgeInsets.only(
                      top: grandstandBottom + gap,
                      left: safe.left + AppSizes.paddingLarge,
                      right: safe.right + AppSizes.paddingLarge,
                      bottom: safe.bottom + AppSizes.paddingMedium,
                    ),
                    child: Column(
                      children: [
                        for (final character in RaceCharacter.values) ...[
                          _CharacterCard(
                            character: character,
                            label: localizer(character.nameKey),
                            onTap: () => _chooseCharacter(provider, character),
                          ),
                          const SizedBox(height: AppSizes.spacingMedium),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Level map ────────────────────────────────────────────────────────────

  Widget _buildLevelMap(
    BuildContext context,
    NumberRaceProvider provider,
    AppLocalizations localizer,
  ) {
    String playLabel(int level) =>
        localizer('number_race.play_level').replaceAll('{n}', '$level');
    // The timed end-of-section levels (5, 9 and 13) are treasure chests.
    // Completing one makes its chest ready; opening it wins a big-number
    // card — 1,000, 1,000,000 and 1,000,000,000 — whose signing video
    // plays when the card is tapped.
    return GameLevelMap(
      levelCount: NumberRaceProvider.totalLevels,
      highestCompleted: _highestCompleted,
      characterThumb: provider.playerCharacter?.assetPath,
      characterLabel: provider.playerCharacter == null
          ? null
          : localizer(provider.playerCharacter!.nameKey),
      // Tapping the racer goes back to choose a different one.
      onCharacterTapped: provider.showCharacterSelection,
      movedFromLevel: _movedFromLevel,
      lockAhead: false,
      isChestLevel: NumberRaceProvider.isSectionEnd,
      chestState: _chestState,
      onLevelSelected: (level) => _chooseLevel(provider, level),
      onChestTapped: (level) => _onChestTapped(provider, level, localizer),
      levelLabel: playLabel,
      chestLabel: (level) =>
          '${playLabel(level)}, ${localizer('number_race.chest_title')}',
      scenery: _mapScenery,
      scatterScenery: true,
    );
  }

  /// Decorations beside the level map's path, by gap between stops (gap 0
  /// is between levels 1 and 2): fewer trees than the default meadow, with
  /// the three racers standing among them. The gaps either side of the
  /// chest levels (5, 9, 13) are kept clear of racers so they don't crowd
  /// the chests.
  static const _sceneryDir = 'assets/games/bubble_shooter/background';
  static final Map<int, MapScenery> _sceneryByGap = {
    1: const MapScenery('$_sceneryDir/tree_small.png', 0.24, aspectRatio: 0.95),
    2: MapScenery(RaceCharacter.gary.assetPath, 0.2, aspectRatio: 1.2),
    3: const MapScenery('$_sceneryDir/daffodils.png', 0.22, aspectRatio: 0.71),
    // Level with level 7, just right of the middle of the screen.
    5: MapScenery(
      RaceCharacter.pero.assetPath,
      0.2,
      aspectRatio: 0.93,
      nearLevel: 7,
      towardCentre: 1.3,
    ),
    6: const MapScenery('$_sceneryDir/tree_large.png', 0.3, aspectRatio: 1.05),
    7: const MapScenery('$_sceneryDir/daffodils.png', 0.22, aspectRatio: 0.71),
    9: MapScenery(RaceCharacter.jamjam.assetPath, 0.2, aspectRatio: 1.18),
    10: const MapScenery(
      '$_sceneryDir/tree_small.png',
      0.24,
      aspectRatio: 0.95,
    ),
    11: const MapScenery('$_sceneryDir/daffodils.png', 0.22, aspectRatio: 0.71),
  };

  static MapScenery? _mapScenery(int gap) => _sceneryByGap[gap];

  // ── Game layout ─────────────────────────────────────────────────────────

  Widget _buildGame(
    BuildContext context,
    NumberRaceProvider provider,
    AppLocalizations localizer,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showCharacterSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.level,
          centerContent: provider.isTimedLevel
              ? GameTimerDisplay(
                  formattedTime: _formatDuration(provider.elapsedTime),
                )
              : Center(
                  child: Text(
                    '${localizer('number_race.question_label')} ${provider.questionNumber} '
                    '${localizer('number_race.of_label')} ${provider.raceLength}',
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

        // One box: the question across the top, the dot pattern in a row
        // beneath it. The box is a fixed size whatever the count, so
        // nothing jumps between rounds.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
          ),
          child: _QuestionBox(
            question: localizer('number_race.question'),
            count: provider.currentDotCount,
          ),
        ),

        const SizedBox(height: 12),

        // Race track
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
            ),
            child: _RaceTrack(
              progress: provider.progress,
              raceLength: provider.raceLength,
            ),
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
            showDigits: provider.showAnswerDigits,
            enabled: !_isWaiting,
            onTap: (n) => _onAnswerTapped(n, provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }
}

// ── Character select card ───────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final RaceCharacter character;
  final String label;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.label,
    required this.onTap,
  });

  static const double _borderWidth = 3;

  /// Side of a (non-Gary) portrait: Gary's is larger, but his smaller
  /// padding keeps his tile the same height.
  static double portraitSizeFor(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600 ? 120.0 : 80.0;

  /// Height of every tile. The name is shorter than the portrait, so the
  /// portrait sets it.
  static double heightFor(BuildContext context) =>
      portraitSizeFor(context) + 2 * AppSizes.paddingMedium + 2 * _borderWidth;

  @override
  Widget build(BuildContext context) {
    final isWideDevice = MediaQuery.of(context).size.width > 600;
    final portraitSize = portraitSizeFor(context);
    // Gary and Pero's artwork faces left; flip it so all three racers face
    // the same way.
    final flip = character != RaceCharacter.jamjam;
    // Gary gets half the padding around him, and his portrait takes the
    // space it frees, so his tile stays the same height as the others.
    final isGary = character == RaceCharacter.gary;
    final padding = isGary
        ? AppSizes.paddingMedium / 2
        : AppSizes.paddingMedium;
    final portrait = isGary
        ? portraitSize + AppSizes.paddingMedium
        : portraitSize;
    // Gary's artwork has ~12% empty space above and below him; scaling it
    // up trims that so he fills his portrait.
    final imageScale = isGary ? 1.15 : 1.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(color: AppColors.catrinBlue, width: _borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: portrait,
              height: portrait,
              child: Transform.scale(
                scale: imageScale,
                child: Transform.flip(
                  flipX: flip,
                  child: Image.asset(character.assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
            // Gary's wider portrait and smaller padding even out, so all
            // three names start at the same point.
            SizedBox(
              width:
                  AppSizes.spacingLarge -
                  (portrait - portraitSize) +
                  (AppSizes.paddingMedium - padding),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: isWideDevice ? 36 : AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question box ─────────────────────────────────────────────────────────
//
// The counting game's near-equal "five" patterns, laid out in a row: a die
// face for 1-5, and two die faces side by side split by a dividing line for
// 6-10 (3 and 3, 3 and 4, 4 and 4, 4 and 5, 5 and 5).

class _QuestionBox extends StatelessWidget {
  final String question;

  /// Dots to show (1-10); anything else shows an empty row.
  final int count;

  const _QuestionBox({required this.question, required this.count});

  /// Side of each square die face. The pattern helpers put neighbouring
  /// pips about 0.28 of a face apart.
  static const double _cell = 104.0;

  /// Space between the two die faces of a 6-10 pattern, with the dividing
  /// line down its middle.
  static const double _gap = _cell * 0.3;

  static const double _dotSize = 24.0;

  /// The two die faces side by side that make up counts 6-10.
  static const Map<int, List<int>> _splits = {
    6: [3, 3],
    7: [3, 4],
    8: [4, 4],
    9: [4, 5],
    10: [5, 5],
  };

  @override
  Widget build(BuildContext context) {
    // Solid white paper with torn left and right edges, matching the
    // counting game's question box.
    return TornPaperPanel(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            SizedBox(
              height: _cell,
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildDots(constraints.maxWidth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(double width) {
    if (count < 1 || count > 10) return const SizedBox.shrink();

    final faces = _splits[count] ?? [count];
    // Narrow screens shrink the faces to fit the row.
    final cell = min(_cell, (width - _gap * (faces.length - 1)) / faces.length);
    final rowWidth = cell * faces.length + _gap * (faces.length - 1);
    final rowLeft = (width - rowWidth) / 2;
    final top = (_cell - cell) / 2;

    final positions = <Offset>[
      for (var i = 0; i < faces.length; i++)
        for (final pip in dicePatternPipPixelPositions(faces[i], cell, cell))
          pip + Offset(rowLeft + i * (cell + _gap), top),
    ];

    return Stack(
      children: [
        if (faces.length == 2)
          Positioned(
            left: rowLeft + cell + _gap / 2 - 1,
            top: top,
            bottom: top,
            child: Container(width: 2, color: Colors.black26),
          ),
        for (final pos in positions)
          Positioned(
            left: pos.dx - _dotSize / 2,
            top: pos.dy - _dotSize / 2,
            child: Container(
              width: _dotSize,
              height: _dotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.abiPink,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Race track ───────────────────────────────────────────────────────────

/// Dusty, stony colour for the race track's play area — the original
/// 0xA89E90 stone tone with its distance to white shrunk to a third (i.e.
/// three times lighter), keeping the same warm hue.
const Color _trackBackground = Color(0xFFE2DFDA);

class _RaceTrack extends StatefulWidget {
  final Map<RaceCharacter, int> progress;

  /// Spaces from start to finish line.
  final int raceLength;

  const _RaceTrack({required this.progress, required this.raceLength});

  @override
  State<_RaceTrack> createState() => _RaceTrackState();
}

class _RaceTrackState extends State<_RaceTrack> {
  // Matches the AnimatedPositioned duration below, so the walk-cycle
  // animation plays for exactly as long as the racer is actually sliding
  // along the track, then holds on the current frame once it stops. Slowed
  // to twice the original speed to give the player time to see the legs
  // move.
  static const _moveDuration = Duration(milliseconds: 1000);

  late Map<RaceCharacter, int> _previousProgress;
  final Set<RaceCharacter> _moving = {};
  final Map<RaceCharacter, Timer> _moveTimers = {};

  @override
  void initState() {
    super.initState();
    _previousProgress = Map.of(widget.progress);
  }

  @override
  void didUpdateWidget(covariant _RaceTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final character in RaceCharacter.values) {
      final previous = _previousProgress[character] ?? 0;
      final current = widget.progress[character] ?? 0;
      if (current == previous) continue;

      _moving.add(character);
      _moveTimers[character]?.cancel();
      _moveTimers[character] = Timer(_moveDuration, () {
        if (!mounted) return;
        setState(() => _moving.remove(character));
      });
    }
    _previousProgress = Map.of(widget.progress);
  }

  @override
  void dispose() {
    for (final timer in _moveTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: _trackBackground),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final laneCount = RaceCharacter.values.length;
          final laneHeight = constraints.maxHeight / laneCount;
          final charSize = (laneHeight * 0.7).clamp(32.0, 128.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Lane dividers
              for (int i = 1; i < laneCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: laneHeight * i,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),

              // Finish flags
              for (int i = 0; i < laneCount; i++)
                Positioned(
                  top: laneHeight * i,
                  right: 4,
                  width: 32,
                  height: laneHeight,
                  child: const Center(
                    child: Icon(
                      Icons.flag,
                      color: AppColors.accentRed,
                      size: 26,
                    ),
                  ),
                ),

              // Racers
              for (final character in RaceCharacter.values)
                AnimatedPositioned(
                  duration: _moveDuration,
                  curve: Curves.easeOut,
                  left:
                      (widget.progress[character]! / widget.raceLength) *
                      (trackWidth - charSize),
                  top:
                      RaceCharacter.values.indexOf(character) * laneHeight +
                      (laneHeight - charSize) / 2,
                  child: _Racer(
                    character: character,
                    size: charSize,
                    isMoving: _moving.contains(character),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Racer extends StatelessWidget {
  final RaceCharacter character;
  final double size;
  final bool isMoving;

  const _Racer({
    required this.character,
    required this.size,
    this.isMoving = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedRacerSprite(
            character: character,
            size: size,
            playing: isMoving,
          ),
        ],
      ),
    );
  }
}

// ── BSL answer button row ─────────────────────────────────────────────────

class _BslAnswerRow extends StatelessWidget {
  final List<int> options;
  final bool showDigits;
  final bool enabled;
  final ValueChanged<int> onTap;

  const _BslAnswerRow({
    required this.options,
    required this.showDigits,
    required this.enabled,
    required this.onTap,
  });

  /// Answer options are always generated three at a time (see
  /// `_buildOptions` in [NumberRaceProvider]). While [options] is still
  /// empty — e.g. during the intro countdown, before the first question is
  /// built — this many invisible placeholder slots are rendered instead, so
  /// the row keeps the same height throughout. Without this, the row starts
  /// at zero height and then jumps to full height once questions begin,
  /// which shrinks the race track above it and shifts every racer's lane
  /// vertically.
  static const int _slotCount = 3;

  @override
  Widget build(BuildContext context) {
    final slots = options.isEmpty
        ? List<int?>.filled(_slotCount, null)
        : options;
    return Row(
      children: slots.map((n) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingSmall,
            ),
            child: n == null
                ? _BslAnswerButton(placeholder: true, showDigit: showDigits)
                : GestureDetector(
                    onTap: enabled ? () => onTap(n) : null,
                    child: AnimatedOpacity(
                      opacity: enabled ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: _BslAnswerButton(value: n, showDigit: showDigits),
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

/// A single BSL-number answer button, or — with [placeholder] set — an
/// invisible slot of identical size that reserves the button's layout space
/// without showing a number. [showDigit] adds the digit under the sign.
class _BslAnswerButton extends StatelessWidget {
  final int? value;
  final bool placeholder;
  final bool showDigit;

  const _BslAnswerButton({
    this.value,
    this.placeholder = false,
    this.showDigit = true,
  }) : assert(placeholder || value != null);

  static const double _signHeight = 72;

  /// The BSL sign for [n] from the PNG sign art in assets/bsl_numbers_png.
  /// The two-handed "10" is composed from its left and right hand images.
  static Widget _bslSign(int n) {
    if (n == 10) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AssetPaths.bslNumber10LeftPng, height: _signHeight),
          const SizedBox(width: 4),
          Image.asset(AssetPaths.bslNumber10RightPng, height: _signHeight),
        ],
      );
    }
    return Image.asset(AssetPaths.bslNumberPng(n), height: _signHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingSmall),
      decoration: BoxDecoration(
        color: placeholder
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(
          color: placeholder ? Colors.transparent : AppColors.catrinBlue,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _signHeight,
            child: placeholder ? null : FittedBox(child: _bslSign(value!)),
          ),
          if (showDigit) ...[
            const SizedBox(height: 4),
            Text(
              placeholder ? '' : '$value',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: AppSizes.fontSizeHeading,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Podium ───────────────────────────────────────────────────────────────

class _Podium extends StatefulWidget {
  final List<RaceCharacter> standings;
  final RaceCharacter? playerCharacter;
  final AppLocalizations localizer;

  const _Podium({
    required this.standings,
    required this.playerCharacter,
    required this.localizer,
  });

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  // Block height and colour for 1st, 2nd and 3rd place.
  static const List<double> _blockHeights = [80, 60, 44];
  static const List<Color> _blockColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  // Drives the podium blocks' glint sweep — one shared controller, with each
  // block offset a third of a cycle apart so they don't all flash at once.
  late final AnimationController _glintController;

  @override
  void initState() {
    super.initState();
    _glintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _glintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final standings = widget.standings;
    final playerCharacter = widget.playerCharacter;
    final localizer = widget.localizer;
    // Render order left-to-right: 2nd, 1st, 3rd.
    const renderOrder = [1, 0, 2];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: renderOrder.map((place) {
            final character = standings[place];
            final isPlayer = character == playerCharacter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedRacerSprite(
                          character: character,
                          size: 56,
                          playing: false,
                        ),
                        if (isPlayer)
                          Positioned(
                            top: -8,
                            right: -6,
                            child: Icon(
                              Icons.star,
                              color: AppColors.accentYellow,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MetallicPodiumBlock(
                    width: 64,
                    height: _blockHeights[place],
                    color: _blockColors[place],
                    glint: _glintController,
                    glintOffset: place / 3,
                    child: Text(
                      localizer('number_race.position.${place + 1}'),
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Names sit below the blocks; columns are bottom-aligned,
                  // so all three names line up in one row.
                  const SizedBox(height: 4),
                  Text(
                    localizer(character.nameKey),
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// A podium block filled with a diagonal light-to-dark gradient (so gold,
/// silver and bronze read as brushed metal rather than flat colour), plus a
/// narrow white highlight band that sweeps across it on a loop for a
/// glinting effect. [glintOffset] (0-1) staggers the sweep between blocks so
/// all three don't flash in sync.
class _MetallicPodiumBlock extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Animation<double> glint;
  final double glintOffset;
  final Widget child;

  const _MetallicPodiumBlock({
    required this.width,
    required this.height,
    required this.color,
    required this.glint,
    required this.glintOffset,
    required this.child,
  });

  static const _borderRadius = BorderRadius.vertical(top: Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final lightShade = Color.lerp(color, Colors.white, 0.4)!;
    final darkShade = Color.lerp(color, Colors.black, 0.25)!;
    return ClipRRect(
      borderRadius: _borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lightShade, color, darkShade],
                  stops: const [0.0, 0.5, 1.0],
                ),
                // Matches the clip so the white border follows the rounded
                // top corners instead of being cut off by them.
                borderRadius: _borderRadius,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: child,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: glint,
                  builder: (context, _) {
                    // The sweep travels across a wider range than the
                    // visible [-1, 1] band, so most of each loop it sits
                    // off the block entirely — a brief glint rather than a
                    // constant shimmer.
                    final t = (glint.value + glintOffset) % 1.0;
                    final pos = -2.5 + t * 6.0;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(pos - 0.3, -1),
                          end: Alignment(pos + 0.3, 1),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time result (timed levels) ──────────────────────────────────────────────

/// Shows the player's completion time at the top of the success screen,
/// above the podium, for a timed level (the last level of each section).
class _TimeResult extends StatelessWidget {
  final Duration elapsed;
  final AppLocalizations localizer;

  const _TimeResult({required this.elapsed, required this.localizer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.timeContainer,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            '${localizer('number_race.your_time')} ${_formatDuration(elapsed)}',
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a [Duration] as `m:ss`, e.g. "1:23".
String _formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
