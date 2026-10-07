import 'dart:math';

import 'package:flutter/material.dart';

import 'conveyor_belt.dart';

/// Backdrop for the Number Builder scene: a dark wall that runs down to the
/// belt's front rail (forming the belt bed), a skewed diamond-plate panel in
/// the top-right corner, and a red floor below.
///
/// [beltTop] and [beltBottom] are fractions of the height where the
/// conveyor belt sits, so the wall/floor split and the belt's shadow line up.
class FactoryBackground extends StatelessWidget {
  final double beltTop;
  final double beltBottom;

  const FactoryBackground({
    super.key,
    required this.beltTop,
    required this.beltBottom,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FactoryBackgroundPainter(beltTop, beltBottom),
      child: const SizedBox.expand(),
    );
  }
}

class _FactoryBackgroundPainter extends CustomPainter {
  final double beltTop;
  final double beltBottom;

  const _FactoryBackgroundPainter(this.beltTop, this.beltBottom);

  /// How far the diamond plate's bottom edge sits right of its top edge.
  static const double _plateSkew = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final railTop =
        h * (beltTop + (beltBottom - beltTop) * ConveyorBelt.railTop);

    // Runs behind the belt down to the floor, so it shows as the belt bed.
    final wall = Rect.fromLTWH(0, 0, w, h * beltBottom);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF262626), Color(0xFF1B1B1B)],
        ).createShader(wall),
    );

    _paintDiamondPlate(canvas, Rect.fromLTRB(w * 0.58, 0, w, railTop));

    final floor = Rect.fromLTRB(0, h * beltBottom, w, h);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC4121A), Color(0xFF8E0A10)],
        ).createShader(floor),
    );

    // Shadow cast by the belt onto the floor.
    final shadow = Rect.fromLTWH(0, h * beltBottom, w, h * 0.06);
    canvas.drawRect(
      shadow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(shadow),
    );
  }

  /// Paints the plate in [rect], skewed into a parallelogram whose bottom
  /// edge is [_plateSkew] right of its top; the dimples skew with it.
  void _paintDiamondPlate(Canvas canvas, Rect rect) {
    canvas.save();
    // Skew about the top edge so it stays put.
    canvas.translate(0, rect.top);
    canvas.transform(Matrix4.skewX(atan(_plateSkew / rect.height)).storage);
    canvas.translate(0, -rect.top);
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8BBBE), Color(0xFFE2E4E6), Color(0xFF9FA3A6)],
        ).createShader(rect),
    );

    const spacing = 14.0;
    final dark = Paint()..color = const Color(0xFF6F7376);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.7);
    var row = 0;
    for (var y = rect.top + spacing / 2; y < rect.bottom; y += spacing, row++) {
      final offset = row.isEven ? 0.0 : spacing / 2;
      for (var x = rect.left + offset; x < rect.right; x += spacing) {
        canvas.drawCircle(Offset(x + 0.8, y + 0.8), 2.4, dark);
        canvas.drawCircle(Offset(x - 0.6, y - 0.6), 1.2, light);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FactoryBackgroundPainter oldDelegate) =>
      oldDelegate.beltTop != beltTop || oldDelegate.beltBottom != beltBottom;
}
