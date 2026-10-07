import 'package:flutter/material.dart';

import '../../../core/constants/asset_paths.dart';
import '../models/vowel_target.dart';

/// Displays the open hand image with fingertip hit targets for vowel selection.
///
/// The fingertip hit targets themselves are defined in
/// [VowelHandConstants.targets] and hit-tested by the provider.
///
/// The hand displays with fingers spread, showing the BSL vowel positions:
/// - Thumb: 'a'
/// - Index finger: 'e'
/// - Middle finger: 'i'
/// - Ring finger: 'o'
/// - Little finger: 'u'
///
/// The parent must give this widget an exact size at the image's aspect
/// ratio ([VowelHandConstants.imageWidth] x [VowelHandConstants.imageHeight]);
/// the screen calculates that size up front so nothing resizes after layout.
class HandDisplay extends StatelessWidget {
  /// When true, the image is clipped just below the ribbed cuff so the
  /// sleeve isn't drawn. Layout size is unchanged, so hit targets still align.
  final bool clipBelowCuff;

  const HandDisplay({
    super.key,
    this.clipBelowCuff = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipPath(
        clipper: clipBelowCuff ? const _CuffClipper() : null,
        clipBehavior: clipBelowCuff ? Clip.antiAlias : Clip.none,
        child: Image.asset(
          AssetPaths.vowelHandOpen,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

/// Clips the hand image along the curved bottom edge of the ribbed cuff.
class _CuffClipper extends CustomClipper<Path> {
  const _CuffClipper();

  @override
  Path getClip(Size size) {
    final edge = [
      for (final p in VowelHandConstants.cuffBottomEdge)
        Offset(p.dx * size.width, p.dy * size.height),
    ];
    // Keep everything above the curve: across the top, down the right side
    // to the curve's right end, along the curve right-to-left, then back up.
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, edge.last.dy);
    for (final p in edge.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path
      ..lineTo(0, edge.first.dy)
      ..close();
  }

  @override
  bool shouldReclip(_CuffClipper oldClipper) => false;
}
