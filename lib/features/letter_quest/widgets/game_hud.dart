import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/letter_quest_provider.dart';

/// Top HUD overlay for the Letter Quest game.
///
/// Displays:
/// - Back button (left) — returns to home screen
/// - "Word X of 5" progress pill (center)
/// - 5 star icons (right) — filled for completed words, outlined for remaining
class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: AppSizes.paddingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Progress indicator: "Word X of 5"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                        vertical: AppSizes.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.catrinBlue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusMedium,
                        ),
                      ),
                      child: Text(
                        'Word ${provider.wordsCompleted + 1} of ${provider.totalWords}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Star counter (5 stars)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < provider.wordsCompleted
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.connectorGold,
                          size: AppSizes.iconMedium,
                        );
                      }),
                    ),
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
