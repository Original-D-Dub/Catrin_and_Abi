import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/asset_paths.dart';

/// Displays the right-hand pointing-finger cursor at the position of
/// the player's detected right index fingertip.
///
/// [cursorPosition] is a normalised Offset (0–1) within [containerSize].
/// When null (no right hand detected) the cursor is hidden.
///
/// When [rivFilePath] is provided the widget shows a Rive animation;
/// otherwise it falls back to the SVG asset.
///
/// ## Rive spec (for when .riv files are created)
/// - Artboard: `"RightFinger"`
/// - Animation: `"Idle"` (looping idle animation)
class FingerCursorOverlay extends StatelessWidget {
  const FingerCursorOverlay({
    super.key,
    required this.containerSize,
    required this.cursorPosition,
    this.rivFilePath,
  });

  final Size containerSize;

  /// Normalised (0–1) position of the right index fingertip, or null
  /// when no right hand is detected.
  final Offset? cursorPosition;

  /// Optional path to a .riv file, e.g.
  /// `'assets/games/bsl_camera_vowels/finger_cursor.riv'`
  final String? rivFilePath;

  /// Cursor rendered width in logical pixels.
  static const double _cursorWidth = 48.0;

  /// Cursor rendered height in logical pixels (maintains SVG aspect ratio).
  /// SVG viewBox is 384.9 × 853.81 → height ≈ width × 2.22
  static const double _cursorHeight = _cursorWidth * 2.22;

  /// Fingertip offset within the SVG: 35 % from left, 3 % from top.
  static const double _tipOffsetX = _cursorWidth * 0.35;
  static const double _tipOffsetY = _cursorHeight * 0.03;

  @override
  Widget build(BuildContext context) {
    if (cursorPosition == null) return const SizedBox.shrink();

    final screenX = cursorPosition!.dx * containerSize.width;
    final screenY = cursorPosition!.dy * containerSize.height;

    return Positioned(
      left: screenX - _tipOffsetX,
      top: screenY - _tipOffsetY,
      child: IgnorePointer(
        child: SizedBox(
          width: _cursorWidth,
          height: _cursorHeight,
          child: rivFilePath != null
              ? RiveAnimation.asset(
                  rivFilePath!,
                  artboard: 'RightFinger',
                  animations: const ['Idle'],
                  fit: BoxFit.contain,
                )
              : SvgPicture.asset(
                  AssetPaths.vowelHandPointer,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
