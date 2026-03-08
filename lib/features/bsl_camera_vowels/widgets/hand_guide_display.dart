import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/asset_paths.dart';

/// Displays the left-hand guide illustration.
///
/// When [rivFilePath] is provided and the file exists the widget shows a
/// Rive animation; otherwise it falls back to the SVG asset.
///
/// ## Rive spec (for when .riv files are created)
/// - Artboard: `"LeftHand"`
/// - State machine: `"FingertipHighlight"`
/// - Boolean inputs: `"thumb_active"`, `"index_active"`, `"middle_active"`,
///   `"ring_active"`, `"pinky_active"`
/// - Boolean inputs: `"thumb_wrong"`, `"index_wrong"`, `"middle_wrong"`,
///   `"ring_wrong"`, `"pinky_wrong"`
class HandGuideDisplay extends StatelessWidget {
  const HandGuideDisplay({
    super.key,
    /// Optional path to a .riv file, e.g.
    /// `'assets/games/bsl_camera_vowels/open_hand.riv'`
    this.rivFilePath,
  });

  final String? rivFilePath;

  @override
  Widget build(BuildContext context) {
    if (rivFilePath != null) {
      return RiveAnimation.asset(
        rivFilePath!,
        artboard: 'LeftHand',
        animations: const ['Idle'],
        fit: BoxFit.contain,
      );
    }

    return SvgPicture.asset(
      AssetPaths.vowelHandOpen,
      fit: BoxFit.contain,
    );
  }
}
