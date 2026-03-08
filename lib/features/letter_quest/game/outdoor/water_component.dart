import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// Invisible collision segment covering a water grid cell.
///
/// Water components prevent the player from crossing lakes and streams.
/// They are placed on every water-type grid cell EXCEPT bridge cells,
/// which creates walkable gaps at bridge locations.
///
/// The player collision handler pushes back when colliding with
/// this component, using the same logic as [WallComponent].
///
/// These components are invisible — the visual water rendering is
/// handled by [OutdoorTerrainComponent] via canvas drawing.
class WaterComponent extends PositionComponent {
  /// Creates a water collision segment.
  ///
  /// [position] is the top-left corner in world coordinates.
  /// [size] is the cell dimensions (typically 64x64).
  WaterComponent({
    required super.position,
    required super.size,
  });

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
}
