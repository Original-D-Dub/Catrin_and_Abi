import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
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
  @override
  void initState() {
    super.initState();
    // Show level selection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BubblePopProvider>().showLevelSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

    return Consumer<BubblePopProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.accentWhite),
                    onPressed: () {
                      provider.stopGame();
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text(
                    'Bubble Pop',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWhite,
                    ),
                  ),
                  centerTitle: true,
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
            child: SafeArea(
              child: provider.showLevelSelect
                  ? _buildLevelSelectScreen(context, provider)
                  : Stack(
                      children: [
                        // Main game content
                        _buildGameContent(context, provider, localizer),

                        // Game over overlay
                        if (provider.gameOver)
                          _buildGameOverOverlay(context, provider, localizer),

                        // Easter egg overlay
                        if (provider.easterEggTriggered != null)
                          _buildEasterEggOverlay(provider.easterEggTriggered!),
                      ],
                    ),
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
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Choose a Level',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons in 2-column grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingSmall,
              crossAxisSpacing: AppSizes.spacingSmall,
              childAspectRatio: 1.3,
              children: GameLevels.all.map((level) {
                return _buildLevelButton(
                  context: context,
                  provider: provider,
                  level: level,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button.
  Widget _buildLevelButton({
    required BuildContext context,
    required BubblePopProvider provider,
    required GameLevel level,
  }) {
    return GestureDetector(
      onTap: () {
        provider.setLevel(level.number);
        provider.startGame();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          image: DecorationImage(
            image: AssetImage(
              'assets/games/bubble_pop/Level ${level.number}.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium)
          ),
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Level ${level.number}',
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXSmall),
              Text(
                level.name,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeBody,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
            _buildHeaderBar(provider),

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

        // Back button overlay (top-left)
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              provider.stopGame();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  /// Builds the header bar with score circle, time, and level number.
  ///
  /// Layout: Score circle overlapping left edge, purple rounded rectangle
  /// containing centred "Time" label + countdown, level number on right.
  Widget _buildHeaderBar(BubblePopProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Purple header rectangle (offset right to make room for score circle)
            Positioned(
              left: 40,
              right: 0,
              top: 8,
              bottom: 8,
              child: Container(
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
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                child: Row(
                  children: [
                    // Spacer for score circle area
                    const SizedBox(width: 48),

                    // Time section (centred)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.timeContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              _formatTime(provider.timeRemaining),
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Level section (right)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Level',
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${provider.currentLevel.number}',
                            style: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),

            // Score circle (overlapping left edge)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.headerBackgroundLight,
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.headerBackground,
                      border: Border.all(
                        color: AppColors.headerBorderDark,
                        width: 2,
                      ),
                    ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Score',
                        style: TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${provider.score}',
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats seconds into M:SS display.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Builds the play area with BSL sign overlapping the bottom.
  Widget _buildPlayAreaWithBslSign(BubblePopProvider provider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White play area with outer wrapper
        Positioned.fill(
          bottom: 80,
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
                        return Positioned(
                          left: bubble.x * constraints.maxWidth -
                              BubbleSizes.defaultSize / 2,
                          top: bubble.y * (constraints.maxHeight - 100) -
                              BubbleSizes.defaultSize / 2,
                          child: BubbleWidget(
                            letter: bubble.letter,
                            color: bubble.color,
                            isPopping:
                                bubble.id == provider.lastPoppedBubbleId,
                            onTap: () {
                              if (provider.isPlaying) {
                                final isCorrect =
                                    provider.tapBubble(bubble.id);
                                try {
                                  if (isCorrect) {
                                    FlameAudio.play(
                                        'bubble_pop/pop_correct.wav');
                                  } else {
                                    FlameAudio.play('bubble_pop/pop.wav');
                                  }
                                } catch (_) {}
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

        // BSL sign + "Find the letter" label at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBslSignArea(provider),
        ),
      ],
    );
  }

  /// Builds the BSL sign container overlapping the play area,
  /// with "Find the letter" label in a purple rounded container below.
  Widget _buildBslSignArea(BubblePopProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BSL sign in rounded container
        Center(
          child: Container(
            width: 140,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 4,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: provider.targetLetter.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        AssetPaths.bslLetter(provider.targetLetter),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildLetterFallback(provider.targetLetter);
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // "Find the letter" label in purple container
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Find the letter',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback display when BSL image is not available.
  Widget _buildLetterFallback(String letter) {
    return Center(
      child: Text(
        letter.toLowerCase(),
        style: const TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.abiPink,
        ),
      ),
    );
  }

  /// Builds the game over overlay with score and options.
  Widget _buildGameOverOverlay(
    BuildContext context,
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSizes.paddingLarge),
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.accentWhite,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score display
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.connectorGold.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.connectorGold,
                      size: AppSizes.iconLarge,
                    ),
                    const SizedBox(width: AppSizes.spacingSmall),
                    Text(
                      'You scored ${provider.score}',
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
              const SizedBox(height: AppSizes.spacingLarge),
              // Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play again button
                      ElevatedButton.icon(
                        onPressed: () => provider.startGame(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.abiPink,
                          foregroundColor: AppColors.accentWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMedium,
                            vertical: AppSizes.paddingSmall,
                          ),
                        ),
                        icon: const Icon(Icons.replay),
                        label: const Text('Play Again'),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      // Home button
                      OutlinedButton.icon(
                        onPressed: () => _navigateToHome(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMedium,
                            vertical: AppSizes.paddingSmall,
                          ),
                        ),
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  // Change level button
                  TextButton.icon(
                    onPressed: () => provider.showLevelSelection(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.catrinBlue,
                    ),
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Change Level'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  /// Navigates back to the home screen.
  void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }
}
