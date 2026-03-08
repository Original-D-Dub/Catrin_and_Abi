import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// A solid wall segment in the Letter Quest game.
///
/// Walls form the boundaries of each room. The player cannot
/// pass through walls — collision is handled by [PlayerComponent].
///
/// Each wall is a simple coloured rectangle with a [RectangleHitbox]
/// for collision detection.
class WallComponent extends PositionComponent {
  /// The colour used to render this wall
  final Color color;

  /// Paint object for rendering (cached for performance)
  late final Paint _paint;

  /// Creates a wall segment.
  ///
  /// [position] is the top-left corner in world coordinates.
  /// [size] is the width and height of the wall.
  /// [color] is the rendering colour.
  WallComponent({
    required super.position,
    required super.size,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    _paint = Paint()..color = color;

    // Add collision hitbox matching the wall's full size
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }
}
