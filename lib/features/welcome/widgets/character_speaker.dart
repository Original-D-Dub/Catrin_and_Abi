import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/character_image.dart';
import 'speech_bubble.dart';

/// Displays a character with their speech bubble.
///
/// Used in the welcome screen story sequence to show
/// characters speaking their dialogue.
///
/// Layout: Character image with absolutely positioned speech bubble.
///
/// Usage:
/// ```dart
/// CharacterSpeaker(
///   characterImagePath: AssetPaths.catrinDefault,
///   dialogue: 'Hello! I am Catrin.',
///   characterOnLeft: true,
/// )
/// ```
class CharacterSpeaker extends StatelessWidget {
  /// Asset path to the character image.
  final String characterImagePath;

  /// The dialogue text to display in the speech bubble.
  final String dialogue;

  /// Whether the character appears on the left side.
  /// If false, character appears on the right.
  final bool characterOnLeft;

  /// Height of the character image (used as max height for flex).
  final double characterHeight;

  const CharacterSpeaker({
    super.key,
    required this.characterImagePath,
    required this.dialogue,
    this.characterOnLeft = true,
    this.characterHeight = AppSizes.characterHeightSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final characterMaxHeight = characterHeight;
    final characterFlex = screenWidth < 600 ? 0.35 : 0.3;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          final characterWidth = availableWidth * characterFlex;
          // Use the smaller of available height or max character height
          final effectiveHeight = availableHeight.isFinite
              ? availableHeight.clamp(0.0, characterMaxHeight)
              : characterMaxHeight;

          return SizedBox(
            height: effectiveHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: characterOnLeft
                  ? [
                      // Character on left
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: characterWidth,
                          maxHeight: effectiveHeight,
                        ),
                        child: CharacterImage(
                          assetPath: characterImagePath,
                          fit: BoxFit.contain,
                          semanticLabel: 'Character speaking',
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      // Speech bubble takes remaining space
                      Expanded(
                        child: SpeechBubble(
                          text: dialogue,
                          pointDirection: PointDirection.left,
                        ),
                      ),
                    ]
                  : [
                      // Speech bubble takes remaining space
                      Expanded(
                        child: SpeechBubble(
                          text: dialogue,
                          pointDirection: PointDirection.right,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      // Character on right
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: characterWidth,
                          maxHeight: effectiveHeight,
                        ),
                        child: CharacterImage(
                          assetPath: characterImagePath,
                          fit: BoxFit.contain,
                          semanticLabel: 'Character speaking',
                        ),
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}
