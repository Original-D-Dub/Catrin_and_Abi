import 'package:flutter/material.dart';

/// Displays a character image (Catrin, Abi, or Pero) with consistent styling.
///
/// Handles image loading errors gracefully and provides consistent
/// sizing across the app.
///
/// Usage:
/// ```dart
/// CharacterImage(
///   assetPath: AssetPaths.catrinDefault,
///   height: 200,
/// )
/// ```
class CharacterImage extends StatelessWidget {
  /// The asset path to the character image.
  final String assetPath;

  /// Optional width constraint for the image.
  final double? width;

  /// Optional height constraint for the image.
  final double? height;

  /// How to fit the image within its bounds.
  /// Defaults to [BoxFit.contain].
  final BoxFit fit;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  const CharacterImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image fails to load
        debugPrint('Error loading character image: $error');
        return Container(
          width: width ?? 100,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 48,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
