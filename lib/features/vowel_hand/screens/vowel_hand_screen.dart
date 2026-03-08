import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/vowel_target.dart';
import '../providers/vowel_hand_provider.dart';
import '../widgets/hand_display.dart';
import '../widgets/pointy_finger_cursor.dart';
import '../widgets/word_display.dart';

/// Main screen for the BSL vowel hand learning game.
///
/// Players must tap the correct fingertip on the open hand SVG that
/// corresponds to the vowel displayed at the bottom of the screen.
/// The game runs for 60 seconds and tracks the player's score.
///
/// **Level 1 (Vowel Match)**: Shows a vowel letter; tap the matching fingertip.
/// **Level 2 (Vowel Words)**: Shows a CVC word with missing vowel; tap the correct fingertip.
///
/// Fingertip mapping (BSL vowels on left hand):
/// - Thumb: a
/// - Index finger: e
/// - Middle finger: i
/// - Ring finger: o
/// - Little finger: u
class VowelHandScreen extends StatefulWidget {
  const VowelHandScreen({super.key});

  @override
  State<VowelHandScreen> createState() => _VowelHandScreenState();
}

class _VowelHandScreenState extends State<VowelHandScreen> {
  /// Current size of the hand display widget (for coordinate calculations)
  Size _handSize = Size.zero;

  /// Key for the hand display to get its render box position
  final GlobalKey _handKey = GlobalKey();

  /// Key for the gesture detector to get correct coordinate conversion
  final GlobalKey _gestureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Show level selection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VowelHandProvider>().showLevelSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VowelHandProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    'BSL Vowels',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWhite,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.accentWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
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
                      Column(
                        children: [
                          const SizedBox(height: 8),

                          // Header bar with score, time, level
                          _buildHeaderBar(provider),

                          const SizedBox(height: 12),

                          // Main game area
                          Expanded(
                            child: _buildGameArea(context, provider),
                          ),

                          // Bottom display (vowel or word)
                          _buildBottomDisplay(provider),

                          const SizedBox(height: AppSizes.spacingLarge),
                        ],
                      ),

                      // Back button overlay (top-left)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => provider.showLevelSelection(),
                        ),
                      ),
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
    VowelHandProvider provider,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Choose a Level',
              style: TextStyle(
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXLarge),

            // Level buttons (full width, stacked)
            _buildLevelButton(
              context: context,
              provider: provider,
              level: VowelHandLevel.vowelMatch,
              color: AppColors.abiPink,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildLevelButton(
              context: context,
              provider: provider,
              level: VowelHandLevel.vowelWords,
              color: AppColors.accentPurple,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button.
  Widget _buildLevelButton({
    required BuildContext context,
    required VowelHandProvider provider,
    required VowelHandLevel level,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => provider.startGame(level: level),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Level ${level.number}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              level.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeHeading,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              level.description,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeBody,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header bar with score circle, time, and level number.
  Widget _buildHeaderBar(VowelHandProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Purple header rectangle
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
                                provider.formattedTime,
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
                              '${provider.selectedLevel.number}',
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

  /// Builds the main game area with hand display and touch detection.
  Widget _buildGameArea(BuildContext context, VowelHandProvider provider) {
    // Game finished - show overlay
    if (provider.gameState == VowelHandGameState.finished) {
      return _buildFinishedOverlay(context, provider);
    }

    // Playing state - show hand with touch detection
    return GestureDetector(
      key: _gestureKey,
      onPanStart: (details) => _handleTouch(details.localPosition, provider),
      onPanUpdate: (details) => _handleTouch(details.localPosition, provider),
      onPanEnd: (details) => _handleTouchEnd(provider),
      child: Stack(
        children: [
          // Hand display centered
          Center(
            child: HandDisplay(
              key: _handKey,
              onSizeChanged: (size) {
                setState(() {
                  _handSize = size;
                });
              },
            ),
          ),

          // Pointy finger cursor (proportionally sized to hand)
          if (provider.isPointerVisible && provider.pointerPosition != null)
            PointyFingerCursor(
              position: _getGlobalToLocalPosition(provider.pointerPosition!),
              handSize: _handSize,
              isVisible: true,
            ),
        ],
      ),
    );
  }

  /// Handles touch events on the game area.
  void _handleTouch(Offset position, VowelHandProvider provider) {
    // Convert global position to position relative to the hand widget
    final handPosition = _getHandLocalPosition(position);
    if (handPosition != null) {
      provider.onTouchUpdate(handPosition);
    }
  }

  /// Handles touch end (finger lifted).
  void _handleTouchEnd(VowelHandProvider provider) {
    debugPrint('_handleTouchEnd called');
    debugPrint('pointerPosition: ${provider.pointerPosition}');
    debugPrint('_handSize: $_handSize');
    if (provider.pointerPosition != null && _handSize != Size.zero) {
      provider.onTouchEnd(
        position: provider.pointerPosition!,
        handSize: _handSize,
      );
    } else {
      debugPrint('Skipping - pointerPosition null or handSize is zero');
    }
  }

  /// Converts a position relative to the gesture detector to
  /// a position relative to the hand widget.
  Offset? _getHandLocalPosition(Offset localPosition) {
    try {
      final RenderBox? handBox =
          _handKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? gestureBox =
          _gestureKey.currentContext?.findRenderObject() as RenderBox?;
      if (handBox != null && gestureBox != null) {
        // Convert from gesture detector local → global → hand local
        final globalPos = gestureBox.localToGlobal(localPosition);
        return handBox.globalToLocal(globalPos);
      }
    } catch (e) {
      // Ignore errors during coordinate conversion
    }
    return localPosition;
  }

  /// Converts pointer position back for display purposes.
  Offset _getGlobalToLocalPosition(Offset handLocalPosition) {
    try {
      final RenderBox? handBox =
          _handKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? gestureBox =
          _gestureKey.currentContext?.findRenderObject() as RenderBox?;
      if (handBox != null && gestureBox != null) {
        // Convert from hand local → global → gesture detector local
        final globalPos = handBox.localToGlobal(handLocalPosition);
        return gestureBox.globalToLocal(globalPos);
      }
    } catch (e) {
      // Ignore errors during coordinate conversion
    }
    return handLocalPosition;
  }

  /// Builds the game finished overlay showing final score.
  Widget _buildFinishedOverlay(
      BuildContext context, VowelHandProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.celebration,
            size: AppSizes.iconXLarge * 2,
            color: AppColors.connectorGold,
          ),
          const SizedBox(height: AppSizes.spacingLarge),
          const Text(
            'You scored',
            style: TextStyle(
              fontSize: AppSizes.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            '${provider.score}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeTitle * 2,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXLarge),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Play Again button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge * 2),
                child: ElevatedButton(
                  onPressed: () => provider.startGame(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge * 2,
                      vertical: AppSizes.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusLarge),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              // Home button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge * 2),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textPrimary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge * 2,
                      vertical: AppSizes.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusLarge),
                    ),
                  ),
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              // Change Level button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge * 2),
                child: TextButton.icon(
                  onPressed: () => provider.showLevelSelection(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.grid_view),
                  label: const Text(
                    'Change Level',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeBody,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the bottom display area - delegates to vowel or word display.
  Widget _buildBottomDisplay(VowelHandProvider provider) {
    if (provider.gameState != VowelHandGameState.playing) {
      return const SizedBox.shrink();
    }

    if (provider.selectedLevel == VowelHandLevel.vowelMatch) {
      return _buildVowelDisplay(provider);
    } else {
      return _buildWordDisplay(provider);
    }
  }

  /// Builds the current vowel display at the bottom of the screen (Level 1).
  Widget _buildVowelDisplay(VowelHandProvider provider) {
    // Get color for the current vowel (green flash when scoring)
    final isScoring = provider.showScoreAnimation;
    final vowelColor = isScoring
        ? AppColors.success
        : (AppColors.vowelPairColors[provider.currentVowel] ??
            AppColors.abiPink);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge * 2,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: isScoring
            ? AppColors.success.withValues(alpha: 0.4)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
        border: Border.all(
          color: vowelColor,
          width: isScoring ? 5 : 3,
        ),
      ),
      child: Text(
        provider.currentVowel,
        style: TextStyle(
          fontSize: AppSizes.fontSizeTitle * 2,
          fontWeight: FontWeight.bold,
          color: vowelColor,
        ),
      ),
    );
  }

  /// Builds the word display at the bottom of the screen (Level 2).
  Widget _buildWordDisplay(VowelHandProvider provider) {
    if (provider.currentPuzzle == null) {
      return const SizedBox.shrink();
    }

    return WordDisplay(
      puzzle: provider.currentPuzzle!,
      guessedVowel: provider.guessedVowel,
      isCorrect: provider.isGuessCorrect,
    );
  }
}
