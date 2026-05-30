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
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/more_or_less_provider.dart';

class MoreOrLessScreen extends StatefulWidget {
  const MoreOrLessScreen({super.key});

  @override
  State<MoreOrLessScreen> createState() => _MoreOrLessScreenState();
}

class _MoreOrLessScreenState extends State<MoreOrLessScreen> {
  FlutterTts? _tts;
  String? _lastRoundKey;
  bool _isWaiting = false;

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

  void _onAnswerTapped(String n, MoreLessProvider provider) {
    if (_isWaiting) return;
    if (provider.disabledAnswers.contains(n)) return;

    if (n == provider.correctAnswer) {
      AudioService.playCorrect('more_or_less');
      setState(() => _isWaiting = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _isWaiting = false);
        provider.selectAnswer(n);
      });
    } else {
      AudioService.playWrong('more_or_less');
      provider.selectAnswer(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoreLessProvider>(
      builder: (context, provider, _) {
        // Speak question on new round
        if (!provider.showLevelSelect &&
            provider.state == MoreLessState.playing) {
          final key = '${provider.roundNumber}';
          if (key != _lastRoundKey) {
            _lastRoundKey = key;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _speak(_questionText(provider));
            });
          }
        }

        if (provider.state == MoreLessState.won && _lastRoundKey != 'won') {
          _lastRoundKey = 'won';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speak('Well Done!');
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'More or Less',
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
                      ? _buildLevelSelect(context, provider)
                      : _buildGame(context, provider),
                ),
                if (!provider.showLevelSelect &&
                    provider.state == MoreLessState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'more_or_less',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel:
                          provider.levelNumber < moreLessColourPairs.length
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

  // ── Level select ──────────────────────────────────────────────────────────

  Widget _buildLevelSelect(BuildContext context, MoreLessProvider provider) {
    return LevelSelectScreen(
      subtitle: 'More or less?',
      levels: List.generate(moreLessColourPairs.length, (i) {
        final pair = moreLessColourPairs[i];
        final nameA =
            '${pair.nameA[0].toUpperCase()}${pair.nameA.substring(1)}';
        final nameB =
            '${pair.nameB[0].toUpperCase()}${pair.nameB.substring(1)}';
        return LevelSelectItem(
          number: i + 1,
          name: '$nameA & $nameB',
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            AudioService.playIntro('more_or_less');
          },
        );
      }),
    );
  }

  // ── Game layout ───────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, MoreLessProvider provider) {
    final colours = provider.colours;

    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              'Round ${provider.roundNumber} of ${MoreLessProvider.totalRounds}',
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

        // Question + block rows in one container
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
            child: _styledContainer(
              child: Column(
                children: [
                  // Question text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      key: ValueKey(provider.roundNumber),
                      width: double.infinity,
                      height: 72,
                      child: Center(
                        child: Text(
                          _questionText(provider),
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

                  const Divider(height: 1, color: Colors.black26),
                  const SizedBox(height: 12),

                  // Block rows
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BlockRow(
                          count: provider.countA,
                          colour: colours.colorA,
                          colourName: colours.nameA,
                          number: provider.countA,
                        ),
                        _BlockRow(
                          count: provider.countB,
                          colour: colours.colorB,
                          colourName: colours.nameB,
                          number: provider.countB,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Try again
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

        // Answer buttons — full width, stacked
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _AnswerButton(
            n: provider.answerOptions[0],
            disabled: _isWaiting ||
                provider.disabledAnswers.contains(provider.answerOptions[0]),
            onTap: () =>
                _onAnswerTapped(provider.answerOptions[0], provider),
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _AnswerButton(
            n: provider.answerOptions[1],
            disabled: _isWaiting ||
                provider.disabledAnswers.contains(provider.answerOptions[1]),
            onTap: () =>
                _onAnswerTapped(provider.answerOptions[1], provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  Widget _styledContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.headerBorderDark, width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.accentWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
        ),
        child: child,
      ),
    );
  }

  String _questionText(MoreLessProvider provider) {
    final c = provider.colours;
    switch (provider.questionType) {
      case MoreLessQuestion.smallest:
        return 'Which number is the smallest?';
      case MoreLessQuestion.biggest:
        return 'Which number is the biggest?';
      case MoreLessQuestion.moreBlocks:
        return 'Are there more ${c.nameA} blocks or ${c.nameB} blocks?';
      case MoreLessQuestion.fewestBlocks:
        return 'Which colour has the fewest blocks?';
      case MoreLessQuestion.moreThan:
        return 'Are there more ${c.nameA} blocks than ${c.nameB} blocks?';
    }
  }
}

// ── Block row ─────────────────────────────────────────────────────────────────

class _BlockRow extends StatelessWidget {
  final int count;
  final Color colour;
  final String colourName;
  final int number;

  const _BlockRow({
    required this.count,
    required this.colour,
    required this.colourName,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Blocks
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(
              count,
              (_) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Number digit
        Text(
          '$number',
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: AppSizes.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(width: 8),

        // BSL symbol
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            AssetPaths.bslNumber(number),
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

// ── Answer button ─────────────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final String n;
  final bool disabled;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.n,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final parsedInt = int.tryParse(n);
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
            border: Border.all(color: AppColors.headerBorderDark, width: 2),
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
              border: Border.all(color: AppColors.headerBorderDark, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  n,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeHeading,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (parsedInt != null) ...[
                  const SizedBox(width: AppSizes.spacingMedium),
                  SvgPicture.asset(
                    AssetPaths.bslNumber(parsedInt),
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
