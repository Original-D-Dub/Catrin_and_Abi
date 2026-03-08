import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// A tree obstacle in the outdoor map.
///
/// Renders procedurally with:
/// - A brown rectangle trunk at the base
/// - A green circle canopy above the trunk
/// - A subtle shadow offset below-right
///
/// Has a [RectangleHitbox] on the trunk area (smaller than the
/// visual canopy) so the player is blocked at the trunk but can
/// walk partially "under" the canopy, which feels natural.
///
/// Visual size: ~48x64 world units
/// Collision hitbox: ~32x24 at the trunk base
class TreeComponent extends PositionComponent {
  /// Total visual width of the tree
  static const double treeWidth = 48.0;

  /// Total visual height of the tree
  static const double treeHeight = 64.0;

  /// Trunk width
  static const double _trunkWidth = 12.0;

  /// Trunk height
  static const double _trunkHeight = 24.0;

  /// Canopy radius
  static const double _canopyRadius = 22.0;

  /// Colour variation seed for this tree
  final int _colorSeed;

  // Pre-built paints
  late final Paint _trunkPaint;
  late final Paint _canopyPaint;
  late final Paint _shadowPaint;

  /// Creates a tree at the given world position.
  TreeComponent({
    required super.position,
    int? colorSeed,
  })  : _colorSeed = colorSeed ?? Random().nextInt(3),
        super(
          size: Vector2(treeWidth, treeHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Trunk paint (brown)
    _trunkPaint = Paint()..color = const Color(0xFF5D4037);

    // Canopy paint (green variation based on seed)
    final greens = [
      const Color(0xFF388E3C),
      const Color(0xFF43A047),
      const Color(0xFF2E7D32),
    ];
    _canopyPaint = Paint()..color = greens[_colorSeed % greens.length];

    // Shadow paint
    _shadowPaint = Paint()..color = const Color(0x33000000);

    // Collision hitbox at the trunk base (smaller than visual)
    add(RectangleHitbox(
      position: Vector2(
        (treeWidth - _trunkWidth * 2.5) / 2,
        treeHeight - _trunkHeight - 4,
      ),
      size: Vector2(_trunkWidth * 2.5, _trunkHeight + 4),
    ));
  }

  @override
  void render(Canvas canvas) {
    final centerX = treeWidth / 2;

    // Shadow (offset circle below-right of canopy)
    canvas.drawCircle(
      Offset(centerX + 3, treeHeight * 0.35 + 3),
      _canopyRadius,
      _shadowPaint,
    );

    // Trunk (brown rectangle at bottom center)
    final trunkRect = Rect.fromCenter(
      center: Offset(centerX, treeHeight - _trunkHeight / 2),
      width: _trunkWidth,
      height: _trunkHeight,
    );
    canvas.drawRect(trunkRect, _trunkPaint);

    // Canopy (green circle above trunk)
    canvas.drawCircle(
      Offset(centerX, treeHeight * 0.35),
      _canopyRadius,
      _canopyPaint,
    );
  }
}
