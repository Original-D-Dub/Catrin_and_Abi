import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// A rock obstacle in the outdoor map.
///
/// Renders procedurally as a grey rounded shape with slight
/// colour variation. Has a [RectangleHitbox] matching its full
/// visual size to prevent player passage.
///
/// Size: 40x40 world units
class RockComponent extends PositionComponent {
  /// Rock size (square)
  static const double rockSize = 40.0;

  /// Colour variation seed
  final int _colorSeed;

  late final Paint _rockPaint;
  late final Paint _highlightPaint;

  /// Creates a rock at the given world position.
  RockComponent({
    required super.position,
    int? colorSeed,
  })  : _colorSeed = colorSeed ?? Random().nextInt(3),
        super(
          size: Vector2.all(rockSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    final greys = [
      const Color(0xFF757575),
      const Color(0xFF9E9E9E),
      const Color(0xFF616161),
    ];
    _rockPaint = Paint()..color = greys[_colorSeed % greys.length];
    _highlightPaint = Paint()
      ..color = const Color(0x22FFFFFF);

    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final cx = rockSize / 2;
    final cy = rockSize / 2;

    // Main rock body (rounded rect)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 4, rockSize - 4, rockSize - 6),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, _rockPaint);

    // Highlight on top-left for 3D effect
    canvas.drawCircle(
      Offset(cx - 6, cy - 6),
      8,
      _highlightPaint,
    );
  }
}
