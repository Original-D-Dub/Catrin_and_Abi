import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/asset_paths.dart';

/// Displays the pointy finger SVG as a cursor following the player's touch.
///
/// The cursor is positioned so that the fingertip of the pointing finger
/// aligns with the touch position. The cursor is scaled proportionally
/// to match the open hand display size.
///
/// SVG dimensions:
/// - pointy-finger-right.svg viewBox: 384.9 x 853.81
/// - open hand-left.svg viewBox: 695.94 x 726.2
///
/// The pointer is scaled to be approximately 1/4 the width of the hand,
/// matching the proportional size of a finger on the hand.
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

    // SVG viewBox dimensions for pointy finger
    const pointerSvgWidth = 384.9;
    const pointerSvgHeight = 853.81;
    const pointerAspectRatio = pointerSvgWidth / pointerSvgHeight;

    // Calculate cursor width as ~25% of the hand width (proportional to a finger)
    final cursorWidth = handSize.width * 0.5;
    final cursorHeight = cursorWidth / pointerAspectRatio;

    // The fingertip is at the top of the SVG, offset to align tip with touch
    // Based on SVG path data, fingertip is roughly at 35% from left, 3% from top
    const fingertipOffsetX = 0.35;
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
          child: SvgPicture.asset(
            AssetPaths.vowelHandPointer,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
