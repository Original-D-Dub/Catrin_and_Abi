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
import '../../../shared/widgets/level_select_screen.dart';
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

  void _restartGame() {
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
                      onPlayAgain: _restartGame,
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
    const nodeSize = 88.0;
    const svgWidth = 1498.0;
    const svgHeight = 1958.0;
    const totalMapNodes = 16;
    // Per-level y nudge in screen pixels (negative = up, positive = down).
    const Map<int, double> nodeYNudge = {2: -40.0};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizer('level_select.title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLarge),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final scale = screenWidth / svgWidth;
              final mapHeight = svgHeight * scale;
              final svgNodePoints = _svgMapNodePoints(totalMapNodes);

              // If any nudged node would go above y=0, push the whole map
              // (SVG + all nodes) down so nothing is clipped.
              double minRawTop = 0.0;
              for (int i = 0; i < totalMapNodes; i++) {
                final rawTop =
                    svgNodePoints[i].dy * scale - nodeSize / 2 + (nodeYNudge[i + 1] ?? 0.0);
                if (rawTop < minRawTop) minRawTop = rawTop;
              }
              final extraTop = minRawTop < 0 ? -minRawTop : 0.0;
              final totalHeight = mapHeight + extraTop;

              return SizedBox(
                width: screenWidth,
                height: totalHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: extraTop,
                      left: 0,
                      right: 0,
                      child: SvgPicture.asset(
                        'assets/images/number_race/map-path.svg',
                        width: screenWidth,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    for (int i = 0; i < totalMapNodes; i++)
                      Positioned(
                        left: (svgNodePoints[i].dx * scale - nodeSize / 2)
                            .clamp(0.0, screenWidth - nodeSize),
                        top: (svgNodePoints[i].dy * scale - nodeSize / 2 +
                                (nodeYNudge[i + 1] ?? 0.0) +
                                extraTop)
                            .clamp(0.0, totalHeight - nodeSize),
                        width: nodeSize,
                        height: nodeSize,
                        child: _LevelNode(
                          level: i + 1,
                          isFinal: NumberRaceProvider.isSectionEnd(i + 1),
                          isLocked: i >= NumberRaceProvider.totalLevels,
                          onTap: () => _chooseLevel(provider, i + 1),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
        _DotBox(dotCells: provider.dotCells, columns: provider.gridColumns),

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
    return Center(
      child: Container(
        width: 210 * columns / 3,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(color: AppColors.catrinBlue, width: 3),
        ),
        child: GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.spacingMedium,
          crossAxisSpacing: AppSizes.spacingMedium,
          children: dotCells.map((filled) {
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
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

// ── Level map ────────────────────────────────────────────────────────────

/// A single level circle on the level map, numbered and coloured by
/// [levelColor]. The final level gets a flag badge to mark it as the
/// end-of-section game.
class _LevelNode extends StatelessWidget {
  final int level;
  final bool isFinal;
  final bool isLocked;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.isFinal,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked ? Colors.grey.shade400 : levelColor(level - 1),
              border: Border.all(
                color: isLocked ? Colors.grey.shade300 : Colors.white,
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3)),
              ],
            ),
            child: Center(
              child: isLocked
                  ? Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.8), size: 32)
                  : Text(
                      '$level',
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: AppSizes.fontSizeHeading,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (isFinal && !isLocked)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Icon(Icons.flag, color: AppColors.accentRed, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

/// Returns [count] evenly arc-length-spaced points along the bezier path
/// defined in assets/images/number_race/map-path.svg (viewBox 1498×1958).
List<Offset> _svgMapNodePoints(int count) {
  const start = Offset(245.557, 141.314);
  // Each sub-list: [cp1x, cp1y, cp2x, cp2y, endX, endY] for one C segment.
  final segmentData = <List<double>>[
    [475.058, 141.314, 509.124, 62.6114, 691.058, 26.8136],
    [941.341, -22.4325, 1161.06, 4.31357, 1260.06, 141.314],
    [1335.98, 246.379, 1314.23, 368.538, 1217.56, 442.314],
    [1114.1, 521.271, 899.058, 556.814, 733.558, 514.814],
    [533.887, 464.142, 473.157, 437.54, 302.058, 425.814],
    [-18.942, 403.814, -156.815, 763.103, 281.558, 837.313],
    [568.058, 885.813, 771.496, 809.583, 927.058, 728.313],
    [1116.56, 629.313, 1272.06, 623.813, 1419.06, 742.813],
    [1510.19, 816.589, 1522.6, 978.103, 1431.56, 1135.81],
    [1387.4, 1212.31, 1239.48, 1288.6, 1143.06, 1303.31],
    [907.058, 1339.31, 791.558, 1264.81, 598.058, 1242.81],
    [404.558, 1220.81, 229.058, 1180.81, 116.058, 1273.31],
    [3.05801, 1365.81, -47.3452, 1590.28, 159.246, 1680.81],
    [273.348, 1730.81, 421.574, 1733.47, 561.268, 1680.81],
    [727.089, 1618.31, 787.558, 1571.81, 993.558, 1579.81],
    [1169.06, 1586.63, 1305.43, 1654.31, 1340.56, 1757.31],
    [1364.96, 1828.85, 1302.56, 1976.81, 1084.56, 1950.81],
    [866.558, 1924.81, 810.799, 1880.31, 598.058, 1888.31],
    [385.317, 1896.31, 180.574, 1930.31, 116.058, 1950.81],
  ];

  const samplesPerSegment = 40;
  final samples = <Offset>[start];
  var p0 = start;

  for (final seg in segmentData) {
    final p1 = Offset(seg[0], seg[1]);
    final p2 = Offset(seg[2], seg[3]);
    final p3 = Offset(seg[4], seg[5]);
    for (int s = 1; s <= samplesPerSegment; s++) {
      final t = s / samplesPerSegment;
      final u = 1.0 - t;
      samples.add(Offset(
        u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
        u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
      ));
    }
    p0 = p3;
  }

  final cumLength = <double>[0];
  for (int i = 1; i < samples.length; i++) {
    cumLength.add(cumLength.last + (samples[i] - samples[i - 1]).distance);
  }
  final totalLength = cumLength.last;

  Offset pointAtLength(double target) {
    int lo = 0, hi = cumLength.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cumLength[mid] < target) { lo = mid; } else { hi = mid; }
    }
    final segLen = cumLength[hi] - cumLength[lo];
    final f = segLen == 0 ? 0.0 : (target - cumLength[lo]) / segLen;
    return Offset.lerp(samples[lo], samples[hi], f)!;
  }

  return [
    for (int i = 0; i < count; i++)
      pointAtLength(totalLength * i / (count - 1)),
  ];
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
