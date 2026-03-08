import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../models/word_puzzle.dart';

/// Height of the word thumbnail image.
///
/// Matches the font size of the word text (fontSizeTitle * 2 = 64.0)
/// so the image appears the same height as the letters.
const double _thumbnailHeight = AppSizes.fontSizeTitle * 2;

/// Displays a CVC word puzzle with a thumbnail image and the word text.
///
/// The thumbnail image appears to the left of the word, sized to match
/// the letter height. The word shows the vowel as underscore or filled in.
///
/// Shows three visual states:
/// - **Default**: Dark text with underscore, blue border
/// - **Correct**: Green text with correct vowel filled, green border
/// - **Wrong**: Red text with wrong vowel filled, red border
///
/// Uses [AnimatedContainer] for smooth color transitions between states.
///
/// Example:
/// ```dart
/// WordDisplay(
///   puzzle: WordPuzzle(word: 'cat'),
///   guessedVowel: null, // Shows cat.jpg + "c_t" with neutral styling
/// )
///
/// WordDisplay(
///   puzzle: WordPuzzle(word: 'cat'),
///   guessedVowel: 'a',
///   isCorrect: true, // Shows cat.jpg + "cat" in green
/// )
/// ```
class WordDisplay extends StatelessWidget {
  /// The current word puzzle to display
  final WordPuzzle puzzle;

  /// The vowel the player guessed (null = show underscore)
  final String? guessedVowel;

  /// Whether the guess was correct (null = no guess yet)
  final bool? isCorrect;

  const WordDisplay({
    super.key,
    required this.puzzle,
    this.guessedVowel,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the display text
    final displayText = guessedVowel != null
        ? puzzle.displayWithLetter(letter: guessedVowel!)
        : puzzle.displayWord;

    // Determine colors based on state
    final Color textColor;
    final Color borderColor;
    final Color backgroundColor;

    if (isCorrect == true) {
      // Correct guess - green styling
      textColor = AppColors.success;
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
    } else if (isCorrect == false) {
      // Wrong guess - red styling
      textColor = AppColors.accentRed;
      borderColor = AppColors.accentRed;
      backgroundColor = AppColors.accentRed.withValues(alpha: 0.1);
    } else {
      // Default state - neutral styling
      textColor = AppColors.textPrimary;
      borderColor = AppColors.catrinBlue;
      backgroundColor = AppColors.catrinBlue.withValues(alpha: 0.1);
    }

    // Build the thumbnail asset path
    final thumbnailPath = AssetPaths.wordThumbnail(
      word: puzzle.word,
      vowel: puzzle.vowel,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: borderColor,
          width: 3.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word thumbnail image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
            child: Image.asset(
              thumbnailPath,
              height: _thumbnailHeight,
              width: _thumbnailHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found - show empty space
                debugPrint('Word thumbnail not found: $thumbnailPath');
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(width: AppSizes.spacingMedium),

          // Word text
          Text(
            displayText,
            style: TextStyle(
              fontSize: AppSizes.fontSizeTitle * 2,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 8.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
