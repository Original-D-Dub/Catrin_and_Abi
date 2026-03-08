import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// A decorative bush in the outdoor map.
///
/// Renders as a small green blob. Has NO collision hitbox — the
/// player walks through bushes freely. They exist purely for
/// visual richness.
///
/// Size: 32x28 world units
class BushComponent extends PositionComponent {
  /// Bush width
  static const double bushWidth = 32.0;

  /// Bush height
  static const double bushHeight = 28.0;

  /// Colour variation seed
  final int _colorSeed;

  late final Paint _bushPaint;

  /// Creates a decorative bush at the given world position.
  BushComponent({
    required super.position,
    int? colorSeed,
  })  : _colorSeed = colorSeed ?? Random().nextInt(3),
        super(
          size: Vector2(bushWidth, bushHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    final greens = [
      const Color(0xFF558B2F),
      const Color(0xFF689F38),
      const Color(0xFF33691E),
    ];
    _bushPaint = Paint()..color = greens[_colorSeed % greens.length];
  }

  @override
  void render(Canvas canvas) {
    final cx = bushWidth / 2;
    final cy = bushHeight / 2;

    // Two overlapping circles for a bush shape
    canvas.drawCircle(Offset(cx - 5, cy), 12, _bushPaint);
    canvas.drawCircle(Offset(cx + 5, cy - 2), 11, _bushPaint);
    canvas.drawCircle(Offset(cx, cy + 3), 10, _bushPaint);
  }
}
