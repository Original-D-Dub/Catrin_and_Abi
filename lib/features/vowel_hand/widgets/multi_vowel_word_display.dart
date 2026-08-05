import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/multi_vowel_puzzle.dart';

/// Displays a [MultiVowelPuzzle] word with unguessed vowels shown as
/// underscores and guessed vowels filled in.
///
/// Border and text colour shift green (correct) or red (wrong) to give
/// feedback after each tap.
class MultiVowelWordDisplay extends StatelessWidget {
  final MultiVowelPuzzle puzzle;

  /// null = neutral, true = correct vowel, false = wrong vowel
  final bool? isCorrect;

  const MultiVowelWordDisplay({
    super.key,
    required this.puzzle,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color borderColor;
    final Color bgColor;

    if (isCorrect == true) {
      textColor = AppColors.success;
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.1);
    } else if (isCorrect == false) {
      textColor = AppColors.accentRed;
      borderColor = AppColors.accentRed;
      bgColor = AppColors.accentRed.withValues(alpha: 0.1);
    } else {
      textColor = AppColors.textPrimary;
      borderColor = AppColors.catrinBlue;
      bgColor = AppColors.catrinBlue.withValues(alpha: 0.1);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: borderColor, width: 3.0),
      ),
      child: Text(
        puzzle.displayWord,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppSizes.fontSizeTitle * 2,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 8.0,
          color: textColor,
        ),
      ),
    );
  }
}
