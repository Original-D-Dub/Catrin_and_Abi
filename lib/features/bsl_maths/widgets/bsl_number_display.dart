import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/asset_paths.dart';

/// Displays a BSL number sign SVG for a given number (0-10).
///
/// Used in both the question display area (showing operands) and
/// on keyboard keys (showing available answers).
///
/// The SVG is rendered with [BoxFit.contain] to maintain aspect ratio
/// within the given [size] constraints.
///
/// Example:
/// ```dart
/// BslNumberDisplay(number: 5, size: 80.0)
/// ```
class BslNumberDisplay extends StatelessWidget {
  /// The number to display (0-10), corresponding to a BSL hand sign SVG
  final int number;

  /// The width and height of the display area in logical pixels
  final double size;

  /// Default display size matching child-friendly tap target dimensions
  static const double defaultSize = 64.0;

  const BslNumberDisplay({
    super.key,
    required this.number,
    this.size = defaultSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        AssetPaths.bslNumber(number),
        fit: BoxFit.contain,
      ),
    );
  }
}
