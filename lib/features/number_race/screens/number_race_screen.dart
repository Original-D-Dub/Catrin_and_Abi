import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_path_map.dart';
import '../models/number_race_models.dart';
import '../providers/number_race_provider.dart';
import '../widgets/animated_racer_sprite.dart';

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
  bool _showingIntro = false;
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
    _playCharacterSelectIntro();
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
    await AudioService.playInstructionClipAndWait('number_race', 'title',
        locale: widget.locale, isCancelled: characterChosen);
    if (characterChosen()) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (characterChosen()) return;
    await AudioService.playInstructionClipAndWait('number_race', 'choose_character',
        locale: widget.locale, isCancelled: characterChosen);
  }

  Future<void> _chooseCharacter(NumberRaceProvider provider, RaceCharacter character) async {
    // Record the choice first so the intro sequence sees it immediately —
    // including a clip that's still loading, which stopAll() can't reach —
    // then interrupt whatever intro clip is playing and announce the
    // chosen character.
    provider.selectCharacter(character);
    await AudioService.stopAll();
    AudioService.playInstructionClip('number_race', 'character_${character.name}',
        locale: widget.locale);
  }

  void _chooseLevel(NumberRaceProvider provider, int level) {
    provider.selectLevel(level);
    setState(() => _showingIntro = true);
  }

  void _restartGame(NumberRaceProvider provider) {
    provider.resetForIntro();
    setState(() => _showingIntro = true);
  }

  void _nextLevel(NumberRaceProvider provider) {
    provider.selectLevel(provider.level + 1);
    setState(() => _showingIntro = true);
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showCharacterSelect
                      ? _buildCharacterSelect(context, provider, localizer)
                      : provider.showLevelMap
                          ? _buildLevelMap(context, provider, localizer)
                          : _buildGame(context, provider, localizer),
                ),
                if (!provider.showCharacterSelect && provider.isWon && !_showingIntro)
                  Positioned.fill(
                    child: Builder(builder: (context) {
                      // Where the player's own racer finished (0 = 1st, 1 =
                      // 2nd, 2 = 3rd) — the heading and summary line depend
                      // on the player's own result, not just on winning the
                      // race (every game ends once the player scores 5).
                      final playerPosition =
                          provider.standings.indexOf(provider.playerCharacter!);
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
                            '{character}', localizer(provider.playerCharacter!.nameKey)),
                        headingOverride: cameThird ? localizer('general.try_again') : null,
                        successAudioNameOverride: cameThird ? 'try_again' : null,
                        showPersonalBest: true,
                        isNewPersonalBest: provider.lastResult?.isNewPersonalBest ?? false,
                        personalBest: provider.lastResult?.personalBest,
                        personalBestSuffix: provider.isTimedLevel
                            ? localizer('number_race.time_suffix')
                            : localizer('number_race.attempts_suffix'),
                        onPlayAgain: () => _restartGame(provider),
                        onNextLevel: provider.level < NumberRaceProvider.totalLevels
                            ? () => _nextLevel(provider)
                            : null,
                        onChangeLevel: () => provider.showCharacterSelection(),
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
                                final podiumWidth =
                                    min(constraints.maxWidth, buttonContentWidth);
                                return SizedBox(
                                  width: podiumWidth,
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: _Podium(
                                      standings: provider.standings,
                                      playerCharacter: provider.playerCharacter,
                                      localizer: localizer,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
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
                      AudioService.playInstructionClip('number_race', 'question',
                          locale: widget.locale);
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
      BuildContext context, NumberRaceProvider provider, AppLocalizations localizer) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizer('number_race.choose_character'),
              textAlign: TextAlign.center,
              style: AppTheme.title.copyWith(
                fontSize: AppSizes.fontSizeTitle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Wrap(
              spacing: AppSizes.spacingMedium,
              runSpacing: AppSizes.spacingMedium,
              alignment: WrapAlignment.center,
              children: RaceCharacter.values.map((character) {
                return _CharacterCard(
                  character: character,
                  label: localizer(character.nameKey),
                  onTap: () => _chooseCharacter(provider, character),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Level map ────────────────────────────────────────────────────────────

  Widget _buildLevelMap(
      BuildContext context, NumberRaceProvider provider, AppLocalizations localizer) {
    return LevelPathMap(
      locale: widget.locale,
      unlockedLevels: NumberRaceProvider.totalLevels,
      isFinalLevel: NumberRaceProvider.isSectionEnd,
      onLevelSelected: (level) => _chooseLevel(provider, level),
    );
  }

  // ── Game layout ─────────────────────────────────────────────────────────

  Widget _buildGame(
      BuildContext context, NumberRaceProvider provider, AppLocalizations localizer) {
    final dotBoxHeight =
        _DotBox.naturalHeight(provider.dotCells.first.length, provider.gridColumns);
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showCharacterSelection(),
          scoreValue: '${provider.score}/${NumberRaceProvider.raceLength}',
          levelNumber: provider.level,
          centerContent: provider.isTimedLevel
              ? GameTimerDisplay(formattedTime: _formatDuration(provider.elapsedTime))
              : null,
        ),

        const SizedBox(height: 12),

        // Dot grid (plain 3x2 for levels 1-4, a single die-face 3x3 board
        // for 5-8, or two 3x3 boards side by side/domino-style for 9-12)
        // alongside the question, rather than stacked, so the pairing reads
        // as one "how many dots?" unit and the race track keeps more of the
        // screen's vertical space. The question container's height is set
        // explicitly to match the dot grid's own natural height — not via
        // `IntrinsicHeight`, which crashes here because `_DotBox` measures
        // itself with a `LayoutBuilder` internally.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DotBox(boards: provider.dotCells, columns: provider.gridColumns),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: Container(
                  height: dotBoxHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge,
                    vertical: AppSizes.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                  ),
                  child: Text(
                    localizer('number_race.question'),
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
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Race track
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
            child: _RaceTrack(
              progress: provider.progress,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // BSL answer buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _BslAnswerRow(
            options: provider.answerOptions,
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

  @override
  Widget build(BuildContext context) {
    final isWideDevice = MediaQuery.of(context).size.width > 600;
    final portraitSize = isWideDevice ? 128.0 : 96.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: portraitSize + 44,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(color: AppColors.catrinBlue, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: portraitSize,
              height: portraitSize,
              child: Image.asset(character.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot grid(s) ──────────────────────────────────────────────────────────
//
// A plain 3x2 grid for levels 1-4, a single die-face 3x3 board for 5-8, or
// two 3x3 boards side by side (domino-style) for 9-12.

class _DotBox extends StatelessWidget {
  final List<List<bool>> boards;
  final int columns;

  const _DotBox({required this.boards, required this.columns});

  static const double _boardGap = AppSizes.spacingMedium;
  static const double _dotSpacing = AppSizes.spacingSmall; // half of the previous spacingMedium gap
  static const double _borderWidth = 3.0;
  static const double _preferredDotSize = 34.0;

  /// The board's height at [_preferredDotSize] — i.e. the height it renders
  /// at whenever it isn't squeezed for width (as here, where it sits next
  /// to an `Expanded` sibling in a `Row` and so always gets its preferred
  /// size). Lets a sibling widget be sized to match without `IntrinsicHeight`,
  /// which this widget's internal `LayoutBuilder` can't support (Flutter
  /// throws "LayoutBuilder does not support returning intrinsic dimensions").
  static double naturalHeight(int cellCount, int columns) {
    final rows = (cellCount / columns).ceil();
    final gridHeight = rows * _preferredDotSize + (rows - 1) * _dotSpacing;
    return gridHeight + AppSizes.paddingMedium * 2 + _borderWidth * 2;
  }

  @override
  Widget build(BuildContext context) {
    // Size each board from its actual content (dots + the gap between them)
    // rather than a fixed pixel width, so tightening the gap between dots
    // also shrinks the board itself instead of just leaving more whitespace
    // around unchanged dots. Falls back to shrinking the dots themselves
    // only if a board still wouldn't fit the measured space (e.g. two
    // boards side by side on a narrow screen).
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardCount = boards.length;
        const boardGap = _boardGap;
        const dotSpacing = _dotSpacing;
        const borderWidth = _borderWidth;
        const preferredDotSize = _preferredDotSize;

        final maxBoardWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - boardGap * (boardCount - 1)) / boardCount
            : double.infinity;

        final naturalContentWidth = columns * preferredDotSize + (columns - 1) * dotSpacing;
        final naturalBoardWidth =
            naturalContentWidth + AppSizes.paddingMedium * 2 + borderWidth * 2;
        final boardWidth = min(naturalBoardWidth, maxBoardWidth);

        final availableForDots = boardWidth -
            AppSizes.paddingMedium * 2 -
            borderWidth * 2 -
            dotSpacing * (columns - 1);
        final dotSize = (availableForDots / columns).clamp(16.0, preferredDotSize);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < boardCount; i++) ...[
                if (i > 0) const SizedBox(width: boardGap),
                _DotBoard(
                  cells: boards[i],
                  columns: columns,
                  boardWidth: boardWidth,
                  dotSize: dotSize,
                  dotSpacing: dotSpacing,
                  borderWidth: borderWidth,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DotBoard extends StatelessWidget {
  final List<bool> cells;
  final int columns;
  final double boardWidth;
  final double dotSize;
  final double dotSpacing;
  final double borderWidth;

  const _DotBoard({
    required this.cells,
    required this.columns,
    required this.boardWidth,
    required this.dotSize,
    required this.dotSpacing,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boardWidth,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: AppColors.catrinBlue, width: borderWidth),
      ),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: dotSpacing,
        crossAxisSpacing: dotSpacing,
        children: cells.map((filled) {
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.abiPink : Colors.transparent,
                border: filled ? null : Border.all(color: const Color(0xFFEAEAEA), width: 2),
              ),
            ),
          );
        }).toList(),
      ),
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

  const _RaceTrack({required this.progress});

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
                  child: Container(height: 2, color: Colors.white.withValues(alpha: 0.6)),
                ),

              // Finish flags
              for (int i = 0; i < laneCount; i++)
                Positioned(
                  top: laneHeight * i,
                  right: 4,
                  width: 32,
                  height: laneHeight,
                  child: const Center(
                    child: Icon(Icons.flag, color: AppColors.accentRed, size: 26),
                  ),
                ),

              // Racers
              for (final character in RaceCharacter.values)
                AnimatedPositioned(
                  duration: _moveDuration,
                  curve: Curves.easeOut,
                  left: (widget.progress[character]! / NumberRaceProvider.raceLength) *
                      (trackWidth - charSize),
                  top: RaceCharacter.values.indexOf(character) * laneHeight +
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
          AnimatedRacerSprite(character: character, size: size, playing: isMoving),
        ],
      ),
    );
  }
}

// ── BSL answer button row ─────────────────────────────────────────────────

class _BslAnswerRow extends StatelessWidget {
  final List<int> options;
  final bool enabled;
  final ValueChanged<int> onTap;

  const _BslAnswerRow({
    required this.options,
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
    final slots = options.isEmpty ? List<int?>.filled(_slotCount, null) : options;
    return Row(
      children: slots.map((n) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
            child: n == null
                ? const _BslAnswerButton(placeholder: true)
                : GestureDetector(
                    onTap: enabled ? () => onTap(n) : null,
                    child: AnimatedOpacity(
                      opacity: enabled ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: _BslAnswerButton(value: n),
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
/// without showing a number.
class _BslAnswerButton extends StatelessWidget {
  final int? value;
  final bool placeholder;

  const _BslAnswerButton({this.value, this.placeholder = false}) : assert(placeholder || value != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingSmall),
      decoration: BoxDecoration(
        color: placeholder ? Colors.transparent : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(
          color: placeholder ? Colors.transparent : AppColors.catrinBlue,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          placeholder
              ? const SizedBox(height: 72)
              : SvgPicture.asset(
                  AssetPaths.bslNumber(value!),
                  height: 72,
                  fit: BoxFit.contain,
                ),
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
        Text(
          localizer('number_race.podium_title'),
          style: AppTheme.heading.copyWith(
            fontSize: AppSizes.fontSizeBody,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
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
                        AnimatedRacerSprite(character: character, size: 56, playing: false),
                        if (isPlayer)
                          Positioned(
                            top: -8,
                            right: -6,
                            child: Icon(Icons.star, color: AppColors.accentYellow, size: 22),
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
