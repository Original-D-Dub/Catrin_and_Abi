import 'dart:math';

import 'package:flutter/material.dart';

/// A horizontal conveyor belt's brushed-steel front rail, filling whatever
/// box it's given. The rail is skewed into a parallelogram, its bottom edge
/// [railSkew] right of its top; its left end is cut vertical. The belt bed above the rail is the dark wall behind it
/// (see [FactoryBackground]), so items ride on that.
class ConveyorBelt extends StatelessWidget {
  const ConveyorBelt({super.key});

  /// Fraction of the belt's height where the bed ends and the front rail
  /// begins.
  static const double railTop = 0.53;

  /// How far the rail's bottom edge sits right of its top edge.
  static const double railSkew = 45;

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _ConveyorBeltPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _ConveyorBeltPainter extends CustomPainter {
  const _ConveyorBeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Start the rail [railSkew] left of the box and clip to it, so the
    // skew's slanted left edge is cut off and the rail ends in a vertical
    // edge at the box's left side.
    canvas.clipRect(Offset.zero & size);
    _paintRail(
      canvas,
      Rect.fromLTWH(
        -ConveyorBelt.railSkew,
        h * ConveyorBelt.railTop,
        w + ConveyorBelt.railSkew,
        h * (0.97 - ConveyorBelt.railTop),
      ),
      const [
        Color(0xFF6A6D70),
        Color(0xFFE4E6E8),
        Color(0xFF9EA1A4),
        Color(0xFF55585B),
      ],
    );
  }

  void _paintRail(Canvas canvas, Rect rect, List<Color> colors) {
    canvas.save();
    // Skew about the top edge so it stays put.
    canvas.translate(0, rect.top);
    canvas.transform(
      Matrix4.skewX(atan(ConveyorBelt.railSkew / rect.height)).storage,
    );
    canvas.translate(0, -rect.top);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(rect),
    );

    // Brushed-metal streaks: fixed pattern so the belt doesn't shimmer
    // between repaints.
    final streak = Paint()..strokeWidth = 1;
    for (var y = rect.top + 2, i = 0; y < rect.bottom - 1; y += 3, i++) {
      final alpha = (i * 37) % 5 == 0 ? 0.16 : 0.06;
      streak.color = Colors.white.withValues(alpha: alpha);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), streak);
    }

    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConveyorBeltPainter oldDelegate) => false;
}
