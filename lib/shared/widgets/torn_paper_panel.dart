import 'dart:math';

import 'package:flutter/material.dart';

/// A white paper panel with torn paper edges on its left and right sides.
///
/// [child] sits on a plain white background between the two edges. Each
/// edge shows a randomly chosen slice of a tall torn-edge image, so the
/// paper looks a little different every time the panel is built fresh
/// (give it a new key to get a new tear).
class TornPaperPanel extends StatefulWidget {
  /// Content shown on the white paper between the torn edges.
  final Widget child;

  const TornPaperPanel({super.key, required this.child});

  @override
  State<TornPaperPanel> createState() => _TornPaperPanelState();
}

class _TornPaperPanelState extends State<TornPaperPanel> {
  static const _leftAsset = 'assets/backgrounds/paper-edge-left.png';
  static const _rightAsset = 'assets/backgrounds/paper-edge-right.png';

  /// Native widths of the torn paper edge images.
  static const double _leftEdgeWidth = 93;
  static const double _rightEdgeWidth = 75;

  /// How far the white paper runs under each torn edge, so no hairline of
  /// background shows at the seam (the edges' inner columns are
  /// anti-aliased, and the right one's isn't fully opaque). Both images are
  /// solid white for well over this far in, even at the narrow-screen scale.
  static const double _edgeOverlap = 4;

  /// Where each torn edge's slice is taken from along the image (-1 top to
  /// 1 bottom).
  late final double _leftEdgeY;
  late final double _rightEdgeY;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _leftEdgeY = random.nextDouble() * 2 - 1;
    _rightEdgeY = random.nextDouble() * 2 - 1;
  }

  /// One torn paper edge, clipped to the panel's height and showing the
  /// slice of the tall image at [alignmentY].
  Widget _paperEdge(String asset, double width, double alignmentY) => ClipRect(
    child: OverflowBox(
      minWidth: width,
      maxWidth: width,
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment(0, alignmentY),
      child: Image.asset(asset, width: width, fit: BoxFit.fitWidth),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Narrow screens get the edges at 30% of their native width.
    final edgeScale = MediaQuery.sizeOf(context).width < 600 ? 0.3 : 1.0;
    final leftWidth = _leftEdgeWidth * edgeScale;
    final rightWidth = _rightEdgeWidth * edgeScale;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: leftWidth - _edgeOverlap,
            right: rightWidth - _edgeOverlap,
          ),
          child: ColoredBox(color: Colors.white, child: widget.child),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: leftWidth,
          child: _paperEdge(_leftAsset, leftWidth, _leftEdgeY),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: rightWidth,
          child: _paperEdge(_rightAsset, rightWidth, _rightEdgeY),
        ),
      ],
    );
  }
}
