import 'package:flutter/material.dart';

import '../../../core/constants/asset_paths.dart';
import '../models/vowel_target.dart';

/// Displays the pointy finger image as a cursor following the player's touch.
///
/// The cursor is positioned so that the fingertip of the pointing finger
/// aligns with the touch position. The cursor is scaled proportionally
/// to match the open hand display size.
///
/// Image dimensions:
/// - pointy_finger_right.png: 594 x 1223
/// - open_hand_left.png: 823 x 1120
///
/// The pointer is drawn at the same pixel scale as the open hand so the
/// two green cuffs appear the same size on screen.
class PointyFingerCursor extends StatelessWidget {
  /// The position where the fingertip should be placed
  final Offset position;

  /// The size of the hand display (used to calculate proportional cursor size)
  final Size handSize;

  /// Whether to show the cursor
  final bool isVisible;

  const PointyFingerCursor({
    super.key,
    required this.position,
    required this.handSize,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    // PNG pixel dimensions for pointy finger
    const pointerImageWidth = 594.0;
    const pointerImageHeight = 1223.0;
    const pointerAspectRatio = pointerImageWidth / pointerImageHeight;

    // Draw the pointer at the same pixel scale as the open hand so both
    // cuffs (~340px wide in each PNG) render at the same size.
    final cursorWidth =
        handSize.width * pointerImageWidth / VowelHandConstants.imageWidth;
    final cursorHeight = cursorWidth / pointerAspectRatio;

    // The fingertip is at the top of the PNG, offset to align tip with touch
    // Measured from the PNG alpha: fingertip pad is ~62% from left, 3% from top
    const fingertipOffsetX = 0.62;
    const fingertipOffsetY = 0.03;

    final offsetX = position.dx - (cursorWidth * fingertipOffsetX);
    final offsetY = position.dy - (cursorHeight * fingertipOffsetY);

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: IgnorePointer(
        child: SizedBox(
          width: cursorWidth,
          height: cursorHeight,
          child: Image.asset(
            AssetPaths.vowelHandPointer,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
