import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../providers/letter_quest_provider.dart';

/// Bottom overlay showing the current word with letter tiles.
///
/// Displays:
/// - Word thumbnail image (from existing word_thumbnails assets)
/// - 3 letter tiles: empty rounded rectangles for uncollected,
///   solid green tiles with white letters for collected
///
/// When a word is complete, all tiles pulse briefly.
class WordProgressBar extends StatelessWidget {
  const WordProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized ||
            provider.phase == LetterQuestPhase.victory) {
          return const SizedBox.shrink();
        }

        final word = provider.currentWord;
        final isComplete = provider.phase == LetterQuestPhase.wordComplete;

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.borderRadiusMedium),
                topRight: Radius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Word thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusSmall,
                    ),
                    child: Image.asset(
                      AssetPaths.wordThumbnail(
                        word: word.word,
                        vowel: word.vowel,
                      ),
                      height: 56,
                      width: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 56,
                          width: 56,
                          color: AppColors.catrinBlue.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.image,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMedium),

                  // 3 letter tiles
                  for (int i = 0; i < 3; i++) ...[
                    _LetterTile(
                      letter: word.letterAt(i),
                      isCollected: word.collected[i],
                      isPulsing: isComplete,
                    ),
                    if (i < 2) const SizedBox(width: AppSizes.spacingSmall),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A single letter tile in the word progress bar.
///
/// States:
/// - **Uncollected**: Empty white rounded rectangle with grey dashed border
/// - **Collected**: Green background with white bold letter
/// - **Pulsing**: Scale animation when word is complete
class _LetterTile extends StatefulWidget {
  /// The letter character to display when collected
  final String letter;

  /// Whether this letter has been collected
  final bool isCollected;

  /// Whether to play the pulse animation (word complete)
  final bool isPulsing;

  const _LetterTile({
    required this.letter,
    required this.isCollected,
    required this.isPulsing,
  });

  @override
  State<_LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<_LetterTile>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulse effect
  late final AnimationController _pulseController;

  /// Scale animation (1.0 → 1.15 → 1.0)
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _LetterTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start pulsing when word is complete
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Width and height of each letter tile
  static const double _tileSize = 52.0;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _tileSize,
      height: _tileSize,
      decoration: BoxDecoration(
        color: widget.isCollected
            ? AppColors.success
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: widget.isCollected
              ? AppColors.success
              : AppColors.textSecondary.withValues(alpha: 0.4),
          width: widget.isCollected ? 3 : 2,
        ),
      ),
      child: Center(
        child: widget.isCollected
            ? Text(
                widget.letter.toUpperCase(),
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.letter.toUpperCase(),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
      ),
    );

    // Wrap with scale animation when pulsing
    if (widget.isPulsing) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: child,
      );
    }

    return child;
  }
}
