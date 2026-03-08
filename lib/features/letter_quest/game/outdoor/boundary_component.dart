import 'package:flame/components.dart';

import 'boundary_wall_component.dart';
import 'outdoor_map_data.dart';

/// Map boundary collision using [BoundaryWallComponent] segments.
///
/// Creates thick wall segments along the edges of the boundary polygon,
/// plus 4 outer walls at the world rectangle edges as a safety net.
///
/// Each wall segment is rendered with a repeating tree sprite pattern
/// to create a dense treeline visual effect.
class BoundaryBuilder {
  BoundaryBuilder._();

  /// Thickness of boundary wall segments
  static const double _wallThickness = 80.0;

  /// Builds boundary wall components from the map data and adds them
  /// to the given [world].
  ///
  /// Creates:
  /// - Wall segments along each edge of the boundary polygon
  /// - 4 outer world-edge walls as a safety fallback
  static void buildBoundary({
    required World world,
    required OutdoorMapData mapData,
  }) {
    // Outer safety walls at world rectangle edges
    _addOuterWalls(world, mapData);

    // Wall segments along the boundary polygon
    _addBoundarySegments(world, mapData);
  }

  /// Adds 4 outer wall rectangles at the world edges.
  static void _addOuterWalls(World world, OutdoorMapData mapData) {
    final w = mapData.worldWidth;
    final h = mapData.worldHeight;
    final t = _wallThickness;

    // Top wall
    world.add(BoundaryWallComponent(
      position: Vector2(0, -t),
      size: Vector2(w, t),
      mapData: mapData,
    ));
    // Bottom wall
    world.add(BoundaryWallComponent(
      position: Vector2(0, h),
      size: Vector2(w, t),
      mapData: mapData,
    ));
    // Left wall
    world.add(BoundaryWallComponent(
      position: Vector2(-t, 0),
      size: Vector2(t, h),
      mapData: mapData,
    ));
    // Right wall
    world.add(BoundaryWallComponent(
      position: Vector2(w, 0),
      size: Vector2(t, h),
      mapData: mapData,
    ));
  }

  /// Adds collision wall segments along the boundary polygon edges.
  ///
  /// Each polygon edge gets an axis-aligned wall segment that
  /// approximates the boundary line with a thick rectangle.
  /// Segments are rendered with a repeating tree sprite pattern.
  static void _addBoundarySegments(World world, OutdoorMapData mapData) {
    final points = mapData.boundaryPoints;
    if (points.length < 3) return;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      // Segment direction and length
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final length = Vector2(dx, dy).length;

      if (length < 10) continue;

      // Place an axis-aligned rectangle at the midpoint
      // Use the bounding box of the segment, thickened
      final minX = p1.x < p2.x ? p1.x : p2.x;
      final minY = p1.y < p2.y ? p1.y : p2.y;
      final segW = (p1.x - p2.x).abs().clamp(_wallThickness, double.infinity);
      final segH = (p1.y - p2.y).abs().clamp(_wallThickness, double.infinity);

      world.add(BoundaryWallComponent(
        position: Vector2(minX - _wallThickness / 2, minY - _wallThickness / 2),
        size: Vector2(segW + _wallThickness, segH + _wallThickness),
        mapData: mapData,
      ));
    }
  }
}
