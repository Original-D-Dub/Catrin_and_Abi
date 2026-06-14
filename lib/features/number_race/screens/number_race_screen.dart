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
          appBar: provider.showCharacterSelect
              ? GameAppBar(
                  title: localizer('number_race.title'),
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
                  child: provider.showCharacterSelect
                      ? _buildCharacterSelect(context, provider, localizer)
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
                      personalBestSuffix: localizer('number_race.attempts_suffix'),
                      onPlayAgain: _restartGame,
                      onChangeLevel: () => provider.showCharacterSelection(),
                      changeLevelLabel: localizer('number_race.change_character'),
                      changeLevelIcon: Icons.people_alt,
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

  // ── Game layout ─────────────────────────────────────────────────────────

  Widget _buildGame(
      BuildContext context, NumberRaceProvider provider, AppLocalizations localizer) {
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showCharacterSelection(),
          scoreValue: '${provider.score}/${NumberRaceProvider.raceLength}',
          showLevel: false,
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

        // 3x2 dot grid
        _DotBox(dotCells: provider.dotCells),

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

// ── 3x2 dot grid ───────────────────────────────────────────────────────────

class _DotBox extends StatelessWidget {
  final List<bool> dotCells;

  const _DotBox({required this.dotCells});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(color: AppColors.catrinBlue, width: 3),
        ),
        child: GridView.count(
          crossAxisCount: 3,
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
