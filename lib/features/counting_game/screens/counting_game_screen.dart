import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/counting_game_provider.dart';

/// Main screen for the Counting Game.
///
/// Each game has 5 rounds. Each round shows a collection of two-coloured
/// circles and asks three questions: colour A count, colour B count, total.
/// The player taps one of three BSL number buttons. Wrong answers are
/// greyed out; correct answers advance the question. All 15 correct → win.
class CountingGameScreen extends StatefulWidget {
  const CountingGameScreen({super.key});

  @override
  State<CountingGameScreen> createState() => _CountingGameScreenState();
}

class _CountingGameScreenState extends State<CountingGameScreen> {
  /// True while waiting for the 3-second pause after a correct answer.
  bool _isWaiting = false;

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
    final localizer = AppLocalizations(locale: 'en');
    return Consumer<CountingGameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Counting',
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
                      : _buildGame(context, provider),
                ),
                if (!provider.showLevelSelect &&
                    provider.state == CountingGameState.won)
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
      levels: List.generate(countingColourPairs.length, (i) {
        final pair = countingColourPairs[i];
        return LevelSelectItem(
          number: i + 1,
          name: localizer(pair.name),
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            AudioService.playIntro('counting_game');
          },
        );
      }),
    );
  }

  // ── Game layout ─────────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, CountingGameProvider provider) {
    final round = provider.currentRound;
    final colours = provider.colours;

    final questionText = _questionText(provider.currentQuestionType, colours);

    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              'Round ${provider.roundNumber} of ${CountingGameProvider.totalRounds}',
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: AppColors.accentRed, size: 24),
              SizedBox(width: AppSizes.spacingSmall),
              Text(
                'Try again!',
                style: TextStyle(
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

  String _questionText(QuestionType type, CircleColourPair colours) {
    switch (type) {
      case QuestionType.colourA:
        return 'How many ${colours.nameA} circles?';
      case QuestionType.colourB:
        return 'How many ${colours.nameB} circles?';
      case QuestionType.total:
        return 'How many circles altogether?';
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

        final circles = <Widget>[];
        for (int i = 0; i < round.total; i++) {
          final pos = round.positions[i];
          final color = i < round.countA ? colours.colorA : colours.colorB;

          circles.add(
            Positioned(
              left: pos.dx * w - radius,
              top: pos.dy * h - radius,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
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
                      // BSL hand sign SVG
                      SvgPicture.asset(
                        AssetPaths.bslNumber(n),
                        height: 72,
                        fit: BoxFit.contain,
                        colorFilter: isDisabled
                            ? const ColorFilter.mode(
                                Colors.grey, BlendMode.saturation)
                            : null,
                      ),
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
