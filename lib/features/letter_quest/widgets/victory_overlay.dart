import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../providers/letter_quest_provider.dart';

/// Full-screen victory overlay shown when all 5 words are collected.
///
/// Displays:
/// - "Well Done!" title
/// - All 5 completed words with their thumbnail images
/// - "Play Again" and "Home" action buttons
/// - Optional "Congratulations Level 4 unlocked" message with
///   "Play Level 4" button (shown only on Level 3 via [onPlayLevel4])
///
/// Follows the styling pattern from the existing confetti_overlay
/// and vowel_hand finished overlay.
class VictoryOverlay extends StatelessWidget {
  /// Callback when "Play Again" is tapped
  final VoidCallback onPlayAgain;

  /// Callback when "Home" is tapped
  final VoidCallback onHome;

  /// Optional callback when "Play Level 4" is tapped.
  /// When non-null, the unlock message and button are shown.
  final VoidCallback? onPlayLevel4;

  const VictoryOverlay({
    super.key,
    required this.onPlayAgain,
    required this.onHome,
    this.onPlayLevel4,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        return Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(AppSizes.spacingLarge),
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  AppSizes.borderRadiusLarge,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy icon
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.connectorGold,
                      size: 64,
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),

                    // Title
                    const Text(
                      'Well Done!',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeHeading,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),

                    // Subtitle
                    const Text(
                      'You collected all the words!',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeBody,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // All 5 completed words
                    ...provider.words.map((word) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.spacingSmall,
                          ),
                          child: _CompletedWordRow(
                            word: word.word,
                            vowel: word.vowel,
                          ),
                        )),

                    const SizedBox(height: AppSizes.spacingLarge),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Play Again
                        ElevatedButton.icon(
                          onPressed: onPlayAgain,
                          icon: const Icon(Icons.replay),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.abiPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMedium,
                              vertical: AppSizes.paddingSmall,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadiusMedium,
                              ),
                            ),
                          ),
                        ),

                        // Home
                        ElevatedButton.icon(
                          onPressed: onHome,
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.catrinBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMedium,
                              vertical: AppSizes.paddingSmall,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadiusMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Level 4 unlock section (only shown on Level 3)
                    if (onPlayLevel4 != null) ...[
                      const SizedBox(height: AppSizes.spacingLarge),

                      // Unlock message
                      const Text(
                        'Congratulations Level 4 unlocked',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeBody,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingMedium),

                      // Play Level 4 button
                      ElevatedButton.icon(
                        onPressed: onPlayLevel4,
                        icon: const Icon(Icons.park),
                        label: const Text('Play Level 4'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingLarge,
                            vertical: AppSizes.paddingSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A row showing a completed word with its thumbnail and letters.
class _CompletedWordRow extends StatelessWidget {
  final String word;
  final String vowel;

  const _CompletedWordRow({
    required this.word,
    required this.vowel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
          child: Image.asset(
            AssetPaths.wordThumbnail(word: word, vowel: vowel),
            height: 40,
            width: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 40,
                width: 40,
                color: AppColors.catrinBlue.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.image,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSizes.spacingMedium),

        // Word letters on green tiles
        for (int i = 0; i < word.length; i++) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
            ),
            child: Center(
              child: Text(
                word[i].toUpperCase(),
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (i < word.length - 1)
            const SizedBox(width: AppSizes.spacingXSmall),
        ],
      ],
    );
  }
}
