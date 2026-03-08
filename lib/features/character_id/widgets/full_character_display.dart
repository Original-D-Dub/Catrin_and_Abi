import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/game_character.dart';

/// Displays a complete character with all body parts stacked vertically.
///
/// Used in Level 1 where the player sees the full character and must
/// answer questions about their attributes (e.g., trouser colour).
class FullCharacterDisplay extends StatelessWidget {
  /// The character to display
  final GameCharacter character;

  /// Width of each body part image
  static const double _partWidth = 120.0;

  /// Height of each body part image
  static const double _partHeight = 80.0;

  /// Negative margin for legs to overlap with torso
  static const double _legsOverlap = 20.0;

  const FullCharacterDisplay({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(
          color: AppColors.abiPink.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      clipBehavior: Clip.none,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character name
          Text(
            character.characterName,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),

          // Head
          _buildPart(character.head.imagePath, 'Head'),
          // Torso
          _buildPart(character.torso.imagePath, 'Torso'),
          // Legs (with negative margin to overlap torso)
          Transform.translate(
            offset: const Offset(0, -_legsOverlap - 4),
            child: _buildPart(character.legs.imagePath, 'Legs'),
          ),
          // Feet (with negative margin to account for legs overlap)
          Transform.translate(
            offset: const Offset(0, -_legsOverlap - 8),
            child: _buildFeetPart(character.feet.imagePath),
          ),
        ],
      ),
    );
  }

  /// Builds a single body part widget.
  Widget _buildPart(String imagePath, String partType) {
    return SizedBox(
      width: _partWidth,
      height: _partHeight,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(partType);
        },
      ),
    );
  }

  /// Builds the feet part with aspect ratio matching the image.
  Widget _buildFeetPart(String imagePath) {
    return SizedBox(
      width: _partWidth,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder('Feet');
        },
      ),
    );
  }

  /// Builds a placeholder for a body part.
  Widget _buildPlaceholder(String partType) {
    return Container(
      width: _partWidth,
      height: _partHeight,
      decoration: BoxDecoration(
        color: AppColors.abiPink.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        border: Border.all(
          color: AppColors.abiPink,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          partType,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
