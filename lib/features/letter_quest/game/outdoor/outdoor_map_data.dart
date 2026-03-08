import 'package:flame/components.dart';

/// Types of terrain cells in the generation grid.
///
/// Used during procedural generation and for collision placement.
enum CellType {
  /// Walkable grass terrain
  land,

  /// Impassable water (lake or stream)
  water,

  /// Walkable bridge over water
  bridge,

  /// Tree trunk — solid obstacle
  tree,

  /// Rock — solid obstacle
  rock,

  /// Outside the playable boundary (dense treeline)
  boundary,
}

/// Data for a single bridge crossing.
///
/// Bridges create walkable gaps over water. They are positioned
/// at stream crossings and along the lake perimeter.
class BridgeData {
  /// Center position of the bridge in world coordinates
  final Vector2 position;

  /// Width of the bridge (perpendicular to crossing direction)
  final double width;

  /// Length of the bridge (parallel to crossing direction)
  final double length;

  /// Whether the bridge is horizontal (true) or vertical (false)
  final bool isHorizontal;

  /// Creates bridge data.
  const BridgeData({
    required this.position,
    required this.width,
    required this.length,
    required this.isHorizontal,
  });
}

/// Complete data for a procedurally generated outdoor map.
///
/// Contains all the geometry, obstacle positions, and metadata
/// needed to build the Flame game world.
///
/// The grid is used for collision placement and pathfinding validation.
/// Visual elements (terrain, trees, etc.) are rendered from the
/// position lists directly.
class OutdoorMapData {
  /// World width in units
  final double worldWidth;

  /// World height in units
  final double worldHeight;

  /// Grid cell size in world units
  final double cellSize;

  /// Number of grid columns
  final int gridCols;

  /// Number of grid rows
  final int gridRows;

  /// 2D grid of cell types [row][col]
  final List<List<CellType>> grid;

  /// Boundary polygon points (irregular map edge)
  final List<Vector2> boundaryPoints;

  /// Lake polygon points (deformed ellipse)
  final List<Vector2> lakePoints;

  /// Stream paths — each stream is a list of center points
  final List<List<Vector2>> streamPaths;

  /// Bridge crossing data
  final List<BridgeData> bridges;

  /// Tree positions in world coordinates
  final List<Vector2> treePositions;

  /// Rock positions in world coordinates
  final List<Vector2> rockPositions;

  /// Bush positions in world coordinates (decorative, no collision)
  final List<Vector2> bushPositions;

  /// Player starting position (center of map, on land)
  final Vector2 playerStart;

  /// Candidate positions for letter placement (validated as reachable)
  final List<Vector2> letterCandidatePositions;

  /// Creates outdoor map data.
  const OutdoorMapData({
    required this.worldWidth,
    required this.worldHeight,
    required this.cellSize,
    required this.gridCols,
    required this.gridRows,
    required this.grid,
    required this.boundaryPoints,
    required this.lakePoints,
    required this.streamPaths,
    required this.bridges,
    required this.treePositions,
    required this.rockPositions,
    required this.bushPositions,
    required this.playerStart,
    required this.letterCandidatePositions,
  });
}
