import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';
import '../providers/bubble_pop_provider.dart';
import '../widgets/bubble_widget.dart';

/// Main screen for the Bubble Pop game.
///
/// Displays:
/// - Background image (math-background)
/// - Header bar: score circle (left), time (centre), level (right)
/// - White play area with purple border containing floating bubbles
/// - BSL sign overlapping bottom of play area
/// - "Find the letter" label in purple rounded container
/// - Game over overlay when time runs out
///
/// Uses [BubblePopProvider] for state management.
class BubblePopScreen extends StatefulWidget {
  const BubblePopScreen({super.key});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends State<BubblePopScreen> {
  bool _showingIntro = false;

  @override
  void initState() {
    super.initState();
    // Show level selection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BubblePopProvider>().showLevelSelection();
    });
  }

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

    return Consumer<BubblePopProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Bubble Pop',
                  onBack: () {
                    provider.stopGame();
                    Navigator.pop(context);
                  },
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
                  child: Stack(
                    children: [
                      // Level select or game content
                      provider.showLevelSelect
                          ? _buildLevelSelectScreen(context, provider, localizer)
                          : _buildGameContent(context, provider, localizer),

                      // Easter egg overlay
                      if (!provider.showLevelSelect &&
                          provider.easterEggTriggered != null)
                        _buildEasterEggOverlay(provider.easterEggTriggered!),
                    ],
                  ),
                ),

                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'bubble_pop',
                    characterImage: 'assets/characters/space-jamjam.png',
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                  ),

                // Game over overlay — outside SafeArea, covers full screen
                if (!provider.showLevelSelect && provider.gameOver)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'bubble_pop',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      imageAsset: 'assets/success/space-abi-jumping.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () => provider.startGame(),
                      onNextLevel: provider.currentLevel.number <
                              GameLevels.all.length
                          ? () {
                              provider.setLevel(
                                  provider.currentLevel.number + 1);
                              provider.startGame();
                            }
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

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      levels: GameLevels.all.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(level.number - 1),
          onTap: () {
            provider.setLevel(level.number);
            provider.prepareForIntro();
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // Game Content
  // ─────────────────────────────────────────

  /// Builds the main game content matching the mockup layout.
  ///
  /// Layout (Stack over background image):
  /// - Background: math-background-1080x1920.jpg
  /// - Header bar: score circle (left), time (centre), level (right)
  /// - Play area: white bg, purple border, contains bubbles
  /// - BSL sign: overlapping bottom of play area
  /// - "Find the letter" label: purple rounded container below BSL sign
  Widget _buildGameContent(
    BuildContext context,
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/backgrounds/math-background-1080x1920.jpg',
            fit: BoxFit.cover,
          ),
        ),

        // Game layout
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with score, time, level
            GameHeaderBar(
              onBack: () {
                provider.stopGame();
                Navigator.pop(context);
              },
              scoreValue: '${provider.score}',
              levelNumber: provider.currentLevel.number,
              centerContent: GameTimerDisplay(
                formattedTime: _formatTime(provider.timeRemaining),
              ),
            ),

            const SizedBox(height: 12),

            // Play area + BSL sign + label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPlayAreaWithBslSign(provider),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),

      ],
    );
  }

  /// Builds the header bar with score circle, time, and level number.
  ///
  /// Layout: Score circle overlapping left edge, purple rounded rectangle
  /// containing centred "Time" label + countdown, level number on right.

  /// Formats seconds into M:SS display.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Returns the BSL sign scale factor based on screen width.
  ///
  /// > 768 px → 2×  |  > 600 px → 1.5×  |  ≤ 600 px → 1×
  double _bslScale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 768) return 2.0;
    if (w > 600) return 1.5;
    return 1.0;
  }

  /// Builds the play area with BSL sign overlapping the top.
  Widget _buildPlayAreaWithBslSign(BubblePopProvider provider) {
    final scale = _bslScale(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White play area with outer wrapper
        Positioned.fill(
          top: 80 * scale,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.headerBackgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 2,
              ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Floating bubbles
                      ...provider.bubbles.map((bubble) {
                        final bubbleSize = BubbleSizes.defaultSize * scale;
                        return Positioned(
                          left: bubble.x * constraints.maxWidth -
                              bubbleSize / 2,
                          top: bubble.y * (constraints.maxHeight - 100) -
                              bubbleSize / 2,
                          child: BubbleWidget(
                            letter: bubble.letter,
                            color: bubble.color,
                            size: bubbleSize,
                            isPopping:
                                bubble.id == provider.lastPoppedBubbleId,
                            onTap: () {
                              if (provider.isPlaying) {
                                final isCorrect = provider.tapBubble(bubble.id);
                                if (isCorrect) {
                                  AudioService.playCorrect('bubble_pop');
                                } else {
                                  AudioService.playWrong('bubble_pop');
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            ),
          ),
        ),

        // BSL sign + "Find the letter" label at top
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _buildBslSignArea(provider, scale),
        ),
      ],
    );
  }

  /// Builds the BSL sign container overlapping the play area,
  /// with "Find the letter" label in a purple rounded container below.
  /// [scale] is 1×, 2×, or 3× depending on screen width.
  Widget _buildBslSignArea(BubblePopProvider provider, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BSL sign in rounded container
        Center(
          child: Container(
            width: 140 * scale,
            height: 120 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 4 * scale,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21 * scale),
              child: provider.targetLetter.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.all(8 * scale),
                      child: BslAlphabetSvg(
                        letter: provider.targetLetter,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        SizedBox(height: 4 * scale),

        // "Find the letter" label in purple container
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 20 * scale, vertical: 6 * scale),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Text(
              'Find the letter',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the easter egg overlay when cat or dog is spelled.
  Widget _buildEasterEggOverlay(String animal) {
    final isoCat = animal == 'cat';
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.5),
            duration: const Duration(milliseconds: 300),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Text(
              isoCat ? '🐱 Meow!' : '🐕 Woof!',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
