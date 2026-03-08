import 'package:flutter/material.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/app_sizes.dart';

/// Displays the Catrin & Abi logo with language awareness.
///
/// Shows the English or Welsh version of the logo based on the
/// [isWelsh] parameter.
///
/// Usage:
/// ```dart
/// AppLogo(isWelsh: false) // English logo
/// AppLogo(isWelsh: true, width: 150) // Welsh logo, custom width
/// ```
class AppLogo extends StatelessWidget {
  /// Whether to display the Welsh version of the logo.
  final bool isWelsh;

  /// Optional custom width for the logo.
  /// If null, uses [AppSizes.logoWidthWelcome].
  final double? width;

  /// Optional custom height for the logo.
  /// If null, maintains aspect ratio based on width.
  final double? height;

  const AppLogo({
    super.key,
    this.isWelsh = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath =
        isWelsh ? AssetPaths.logoWelshColour : AssetPaths.logoEnglishColour;

    return Image.asset(
      logoPath,
      width: width ?? AppSizes.logoWidthWelcome,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image fails to load
        debugPrint('Error loading logo: $error');
        return SizedBox(
          width: width ?? AppSizes.logoWidthWelcome,
          height: height ?? AppSizes.logoHeightWelcome,
          child: const Center(
            child: Text(
              'Catrin & Abi',
              style: TextStyle(
                fontSize: AppSizes.fontSizeHeading,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
