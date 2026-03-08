import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/character_part.dart';
import '../models/mixed_character.dart';

/// Displays a mixed-up character with stacked body parts.
///
/// The four parts (head, torso, legs, feet) are stacked vertically
/// to look like a single person. Uses Image.asset() with a fallback
/// placeholder when images aren't available.
///
/// The widget is responsive and scales based on available space.
class MixedCharacterDisplay extends StatelessWidget {
  /// The mixed character to display
  final MixedCharacter character;

  /// Minimum width for each body part
  static const double _minPartWidth = 80.0;

  /// Maximum width for each body part
  static const double _maxPartWidth = 200.0;

  /// Aspect ratio of part height to width
  static const double _partAspectRatio = 0.67;

  /// Overlap ratio for legs (relative to part height)
  static const double _overlapRatio = 0.25;

  const MixedCharacterDisplay({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        // Account for 4 parts with some overlap
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Calculate part width based on available width (with padding)
        final paddingTotal = AppSizes.paddingMedium * 2;
        var partWidth = (availableWidth - paddingTotal).clamp(
          _minPartWidth,
          _maxPartWidth,
        );

        // Calculate part height based on aspect ratio
        var partHeight = partWidth * _partAspectRatio;

        // Calculate total character height (4 parts minus overlaps)
        final overlap = partHeight * _overlapRatio;
        final totalCharHeight = (partHeight * 4) - (overlap * 2) + paddingTotal;

        // If character would be too tall, scale down
        if (totalCharHeight > availableHeight) {
          final scale = availableHeight / totalCharHeight;
          partWidth *= scale;
          partHeight *= scale;
          partWidth = partWidth.clamp(_minPartWidth, _maxPartWidth);
          partHeight = partWidth * _partAspectRatio;
        }

        final actualOverlap = partHeight * _overlapRatio;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            border: Border.all(
              color: AppColors.catrinBlue.withValues(alpha: 0.5),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Head
              _buildPart(
                character.head,
                character.headSource,
                'Head',
                partWidth,
                partHeight,
              ),
              // Torso
              _buildPart(
                character.torso,
                character.torsoSource,
                'Torso',
                partWidth,
                partHeight,
              ),
              // Legs (with negative margin to overlap torso)
              Transform.translate(
                offset: Offset(0, -actualOverlap - 4),
                child: _buildPart(
                  character.legs,
                  character.legsSource,
                  'Legs',
                  partWidth,
                  partHeight,
                ),
              ),
              // Feet (with negative margin to account for legs overlap)
              Transform.translate(
                offset: Offset(0, -actualOverlap - 8),
                child: _buildFeetPart(
                  character.feet,
                  character.feetSource,
                  partWidth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a single body part widget.
  Widget _buildPart(
    CharacterPart part,
    String sourceName,
    String partType,
    double width,
    double height,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        part.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fall back to placeholder on error
          return _buildPlaceholder(part, sourceName, partType, width, height);
        },
      ),
    );
  }

  /// Builds the feet part with aspect ratio matching the image.
  Widget _buildFeetPart(CharacterPart part, String sourceName, double width) {
    return SizedBox(
      width: width,
      child: Image.asset(
        part.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fall back to placeholder on error
          return _buildPlaceholder(
            part,
            sourceName,
            'Feet',
            width,
            width * _partAspectRatio,
          );
        },
      ),
    );
  }

  /// Builds a coloured placeholder for a body part.
  ///
  /// Shows the source character name and clothing description.
  Widget _buildPlaceholder(
    CharacterPart part,
    String sourceName,
    String partType,
    double width,
    double height,
  ) {
    // Generate a colour based on the source name
    final colour = _getColourForName(sourceName);

    // Get clothing description from attributes
    final clothingDesc = part.getPrimaryClothingDescription();

    // Scale font sizes based on part size
    final fontScale = (width / 120.0).clamp(0.7, 1.3);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        border: Border.all(
          color: colour,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Source character name
          Text(
            sourceName,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall * fontScale,
              fontWeight: FontWeight.bold,
              color: _getContrastingTextColor(colour),
            ),
          ),
          // Part type
          Text(
            partType,
            style: TextStyle(
              fontSize: 10 * fontScale,
              color: _getContrastingTextColor(colour).withValues(alpha: 0.8),
            ),
          ),
          // Clothing description (if available)
          if (clothingDesc != null)
            Text(
              clothingDesc,
              style: TextStyle(
                fontSize: 9 * fontScale,
                fontStyle: FontStyle.italic,
                color: _getContrastingTextColor(colour).withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Returns a colour associated with a character name.
  Color _getColourForName(String name) {
    // Generate a consistent colour from the name
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  /// Returns black or white text colour based on background luminance.
  Color _getContrastingTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
