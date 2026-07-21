import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_path_map.dart';
import '../models/number_race_models.dart';
import '../providers/number_race_provider.dart';

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

  void _chooseCharacter(NumberRaceProvider provider, RaceCharacter character) {
    provider.selectCharacter(character);
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
                    child: GameSuccessOverlay(
                      gameId: 'number_race',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.custom,
                      score: provider.score,
                      customScoreLine: localizer('number_race.success_summary')
                          .replaceAll(
                              '{character}', localizer(provider.playerCharacter!.nameKey)),
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
                      changeLevelLabel: localizer('number_race.change_character'),
                      changeLevelIcon: Icons.people_alt,
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
                          _Podium(
                            standings: provider.standings,
                            playerCharacter: provider.playerCharacter,
                            localizer: localizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'number_race',
                    locale: widget.locale,
                    characterImage: provider.playerCharacter?.assetPath,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
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
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
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

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: Container(
            width: double.infinity,
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
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Dot grid (3x2 for levels 1-4, 4x2 for levels 5-8)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _DotBox(dotCells: provider.dotCells, columns: provider.gridColumns),
        ),

        const SizedBox(height: 12),

        // Race track
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
            child: _RaceTrack(
              progress: provider.progress,
              playerCharacter: provider.playerCharacter,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
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
              width: 96,
              height: 96,
              child: Image.asset(character.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot grid (3x2 or 4x2, depending on level) ───────────────────────────────

class _DotBox extends StatelessWidget {
  final List<bool> dotCells;
  final int columns;

  const _DotBox({required this.dotCells, required this.columns});

  @override
  Widget build(BuildContext context) {
    // Measure the space actually available before sizing and drawing the
    // grid, rather than assuming a fixed pixel width — keeps the dots from
    // overflowing narrower screens as `columns` grows with the level.
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = 210 * columns / 3;
        final boxWidth =
            constraints.maxWidth.isFinite ? min(constraints.maxWidth, targetWidth) : targetWidth;

        const dotSpacing = AppSizes.spacingMedium;
        const borderWidth = 3.0;
        final availableForDots = boxWidth -
            AppSizes.paddingMedium * 2 -
            borderWidth * 2 -
            dotSpacing * (columns - 1);
        final dotSize = (availableForDots / columns).clamp(20.0, 34.0);

        return Center(
          child: Container(
            width: boxWidth,
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
              children: dotCells.map((filled) {
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.abiPink : Colors.transparent,
                      border: filled ? null : Border.all(color: AppColors.lightGrey, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ── Race track ───────────────────────────────────────────────────────────

class _RaceTrack extends StatelessWidget {
  final Map<RaceCharacter, int> progress;
  final RaceCharacter? playerCharacter;

  const _RaceTrack({required this.progress, required this.playerCharacter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentLimeGreen.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final laneCount = RaceCharacter.values.length;
          final laneHeight = constraints.maxHeight / laneCount;
          final charSize = (laneHeight * 0.7).clamp(32.0, 90.0);

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
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  left: (progress[character]! / NumberRaceProvider.raceLength) *
                      (trackWidth - charSize),
                  top: RaceCharacter.values.indexOf(character) * laneHeight +
                      (laneHeight - charSize) / 2,
                  child: _Racer(
                    character: character,
                    size: charSize,
                    isPlayer: character == playerCharacter,
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
  final bool isPlayer;

  const _Racer({
    required this.character,
    required this.size,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: isPlayer ? AppColors.abiPink : Colors.white,
                width: isPlayer ? 3 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
            child: ClipOval(
              child: Image.asset(character.assetPath, fit: BoxFit.cover),
            ),
          ),
          if (isPlayer)
            Positioned(
              top: -size * 0.15,
              right: -size * 0.1,
              child: Icon(Icons.star, color: AppColors.accentYellow, size: size * 0.4),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((n) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
            child: GestureDetector(
              onTap: enabled ? () => onTap(n) : null,
              child: AnimatedOpacity(
                opacity: enabled ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacingSmall),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                    border: Border.all(color: AppColors.catrinBlue, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AssetPaths.bslNumber(n),
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$n',
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: AppSizes.fontSizeHeading,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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

// ── Podium ───────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<RaceCharacter> standings;
  final RaceCharacter? playerCharacter;
  final AppLocalizations localizer;

  const _Podium({
    required this.standings,
    required this.playerCharacter,
    required this.localizer,
  });

  // Block height and colour for 1st, 2nd and 3rd place.
  static const List<double> _blockHeights = [80, 60, 44];
  static const List<Color> _blockColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    // Render order left-to-right: 2nd, 1st, 3rd.
    const renderOrder = [1, 0, 2];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          localizer('number_race.podium_title'),
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: AppSizes.fontSizeBody,
            fontWeight: FontWeight.bold,
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
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: isPlayer ? AppColors.abiPink : Colors.white,
                              width: isPlayer ? 3 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(character.assetPath, fit: BoxFit.cover),
                          ),
                        ),
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
                  Text(
                    localizer(character.nameKey),
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 64,
                    height: _blockHeights[place],
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _blockColors[place],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      localizer('number_race.position.${place + 1}'),
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
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
