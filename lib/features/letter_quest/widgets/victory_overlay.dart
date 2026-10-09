import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../providers/letter_quest_provider.dart';

/// Victory overlay shown when all 5 words are collected.
///
/// Wraps the shared [GameSuccessOverlay]: "Well Done!" heading,
/// "You collected all the words!" in the score slot, the completed word list
/// as extra content, and the standard Play Again button and back arrow.
class VictoryOverlay extends StatelessWidget {
  /// Callback when "Play Again" is tapped
  final VoidCallback onPlayAgain;

  /// Callback when the back arrow is tapped
  final VoidCallback onHome;

  /// Optional callback for the standard "Next Level" button.
  final VoidCallback? onNextLevel;

  /// UI language for overlay text ('en' or 'cy').
  final String locale;

  const VictoryOverlay({
    super.key,
    required this.onPlayAgain,
    required this.onHome,
    this.onNextLevel,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        return GameSuccessOverlay(
          locale: locale,
          onPlayAgain: onPlayAgain,
          onChangeLevel: onHome,
          onNextLevel: onNextLevel,
          scoreStyle: SuccessScoreStyle.custom,
          customScoreLine: localizer('letter_quest.victory_subtitle'),
          extraContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final word in provider.words)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.spacingSmall,
                  ),
                  child: CompletedWordRow(word: word.word, vowel: word.vowel),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A row showing a completed word with its thumbnail and letters.
class CompletedWordRow extends StatelessWidget {
  final String word;
  final String vowel;

  const CompletedWordRow({
    super.key,
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
