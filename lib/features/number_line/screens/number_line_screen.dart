import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/services/audio_service.dart';
import '../../../core/tts_helper.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/number_line_provider.dart';

const List<String> _countWords = [
  'one', 'two', 'three', 'four', 'five',
  'six', 'seven', 'eight', 'nine', 'ten',
];

class NumberLineGameScreen extends StatefulWidget {
  const NumberLineGameScreen({super.key});

  @override
  State<NumberLineGameScreen> createState() => _NumberLineGameScreenState();
}

class _NumberLineGameScreenState extends State<NumberLineGameScreen> {
  FlutterTts? _tts;
  String? _lastRoundKey;

  bool _isAnimating = false;

  /// How many counters have moved onto the number line so far this animation.
  int _fillProgress = 0;

  /// The answer the player tapped (used to decide correct/wrong after anim).
  int? _animatingAnswer;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  void _speak(String text) {
    try {
      _tts?.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  // ── Answer handling ──────────────────────────────────────────────────────────

  void _onAnswerTapped(int answer, NumberLineGameProvider provider) {
    if (_isAnimating) return;

    // If wrong, mark it in the provider immediately so _triedWrong is set.
    if (answer != provider.correctAnswer) {
      provider.selectAnswer(answer);
    }

    setState(() {
      _isAnimating = true;
      _fillProgress = 0;
      _animatingAnswer = answer;
    });

    _fillNextSlot(1, answer, provider);
  }

  void _fillNextSlot(int next, int total, NumberLineGameProvider provider) {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _fillProgress = next);

      // Speak count word as each counter lands.
      final wordIndex = next - 1;
      if (wordIndex < _countWords.length) {
        _speak(_countWords[wordIndex]);
      }

      if (next < total) {
        _fillNextSlot(next + 1, total, provider);
      } else {
        // All counters placed — wait then play feedback sound and advance.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          final answer = _animatingAnswer!;
          final correct = provider.correctAnswer;
          final String feedback;
          if (answer == correct) {
            feedback = 'Well done';
            AudioService.playCorrect('number_line_game');
          } else if (answer > correct) {
            feedback = "Oh, we have too many!";
            AudioService.playWrong('number_line_game');
          } else {
            feedback = "We don't have enough.";
            AudioService.playWrong('number_line_game');
          }
          //add sound effect here for guessing correct
          // _speak(feedback);

          Future.delayed(const Duration(milliseconds: 3000), () {
            if (!mounted) return;
            setState(() {
              _isAnimating = false;
              _fillProgress = 0;
              _animatingAnswer = null;
            });
            // Advance — selectAnswer handles scoring if not already wrong.
            provider.selectAnswer(provider.correctAnswer);
          });
        });
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');
    return Consumer<NumberLineGameProvider>(
      builder: (context, provider, _) {
        // Speak question when round changes
        if (!provider.showLevelSelect &&
            provider.state == NumberLineGameState.playing) {
          final key = '${provider.roundNumber}';
          if (key != _lastRoundKey) {
            _lastRoundKey = key;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _speak('How many counters do we need to make ${provider.currentLevel.targetNumber}?');
            });
          }
        }

        // Speak "Well Done!" on win
        if (provider.state == NumberLineGameState.won &&
            _lastRoundKey != 'won') {
          _lastRoundKey = 'won';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speak('Well Done!');
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Number Line',
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
                    provider.state == NumberLineGameState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'number_line_game',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel:
                          provider.levelNumber < numberLineLevels.length
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

  // ── Level select ─────────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, NumberLineGameProvider provider, AppLocalizations localizer) {
    return LevelSelectScreen(
      subtitle: localizer('number_line.subtitle'),
      levels: List.generate(numberLineLevels.length, (i) {
        final level = numberLineLevels[i];
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            //AudioService.playIntro('number_line_game'); //commented out  because instructions are duplicated in game. safe to remove
          },
        );
      }),
    );
  }

  // ── Game layout ──────────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, NumberLineGameProvider provider) {
    // Pool needs enough circles to cover whichever button the player might tap.
    final poolSize = provider.answerOptions.reduce(max) + 1;

    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              'Round ${provider.roundNumber} of ${provider.currentLevel.totalRounds}',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Question + number line + pool circles — all in one container
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _styledContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many counters do we need to make ${provider.currentLevel.targetNumber}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _NumberLineWidget(
                  originalCount: provider.circleCount,
                  filledCount: _fillProgress,
                  divisions: provider.currentLevel.targetNumber,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white60),
                const SizedBox(height: 10),
                _PoolCircles(total: poolSize, used: _fillProgress),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Answer buttons
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _NumberAnswerButton(
            n: provider.answerOptions[0],
            disabled: _isAnimating,
            showBslOnly: provider.currentLevel.showBslOnly,
            onTap: () =>
                _onAnswerTapped(provider.answerOptions[0], provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _NumberAnswerButton(
            n: provider.answerOptions[1],
            disabled: _isAnimating,
            showBslOnly: provider.currentLevel.showBslOnly,
            onTap: () =>
                _onAnswerTapped(provider.answerOptions[1], provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  // ── Shared styled container (matches bubble_pop play area) ──────────────────

  Widget _styledContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.headerBorderDark,
          width: 2,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.accentWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.headerBorderDark,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ── Number line widget ────────────────────────────────────────────────────────

class _NumberLineWidget extends StatelessWidget {
  final int originalCount;
  final int filledCount;
  final int divisions;

  const _NumberLineWidget({
    required this.originalCount,
    required this.filledCount,
    this.divisions = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cellWidth = w / divisions;

        const double circleRadius = 14.0;
        const double lineY = 52.0;
        const double tickExtendAbove = 6.0;
        const double tickExtendBelow = 8.0;
        const double numberY = lineY + tickExtendBelow + 4.0;
        const double totalHeight = numberY + 24.0;

        final totalOnLine = originalCount + filledCount;
        final widgets = <Widget>[];

        // Horizontal line
        widgets.add(Positioned(
          left: cellWidth * 0.5,
          width: cellWidth * (divisions - 1).toDouble(),
          top: lineY,
          child: Container(height: 3, color: Colors.black87),
        ));

        for (int i = 0; i < divisions; i++) {
          final cx = cellWidth * (i + 0.5);

          // Tick mark
          widgets.add(Positioned(
            left: cx - 1.5,
            top: lineY - tickExtendAbove,
            child: Container(
              width: 3,
              height: tickExtendAbove + tickExtendBelow,
              color: Colors.black87,
            ),
          ));

          // Number label
          widgets.add(Positioned(
            left: cx - cellWidth * 0.45,
            top: numberY,
            width: cellWidth * 0.9,
            child: Text(
              '${i + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ));

          // Circle above tick
          if (i < totalOnLine) {
            final isOriginal = i < originalCount;
            final circleWidget = Container(
              width: circleRadius * 2,
              height: circleRadius * 2,
              decoration: BoxDecoration(
                color: isOriginal
                    ? AppColors.accentOrange
                    : AppColors.accentLimeGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
            );

            widgets.add(Positioned(
              left: cx - circleRadius,
              top: lineY - tickExtendAbove - circleRadius * 2 - 4,
              // Green circles scale in from 0 when first placed.
              child: isOriginal
                  ? circleWidget
                  : TweenAnimationBuilder<double>(
                      key: ValueKey('filled_$i'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: circleWidget,
                    ),
            ));
          }
        }

        return SizedBox(
          height: totalHeight,
          child: Stack(children: widgets),
        );
      },
    );
  }
}

// ── Pool circles ──────────────────────────────────────────────────────────────

class _PoolCircles extends StatelessWidget {
  final int total;
  final int used;

  const _PoolCircles({required this.total, required this.used});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(total, (i) {
        final isUsed = i < used;
        return AnimatedSlide(
          offset: isUsed ? const Offset(0, -1.5) : Offset.zero,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: AnimatedOpacity(
            opacity: isUsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentLimeGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Answer button ─────────────────────────────────────────────────────────────

class _NumberAnswerButton extends StatelessWidget {
  final int n;
  final bool disabled;
  final bool showBslOnly;
  final VoidCallback onTap;

  const _NumberAnswerButton({
    required this.n,
    required this.onTap,
    this.disabled = false,
    this.showBslOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.headerBackgroundLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.headerBorderDark,
              width: 2,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMedium,
              vertical: AppSizes.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 2,
              ),
            ),
            child: showBslOnly
                ? SvgPicture.asset(
                    AssetPaths.bslNumber(n),
                    height: 56,
                    fit: BoxFit.contain,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$n',
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: AppSizes.fontSizeHeading,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      SvgPicture.asset(
                        AssetPaths.bslNumber(n),
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
