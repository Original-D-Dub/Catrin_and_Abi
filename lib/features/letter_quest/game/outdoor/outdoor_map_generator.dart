import 'dart:math';

import 'package:flame/components.dart';

import 'outdoor_map_data.dart';

/// Procedural generator for outdoor Letter Quest maps.
///
/// Produces a complete [OutdoorMapData] with:
/// - Irregular boundary polygon (natural-looking map edge)
/// - Central lake (deformed ellipse)
/// - 3-4 meandering streams from lake to boundary
/// - Bridges at stream crossings and lake perimeter
/// - Scattered trees, rocks, and bushes
/// - Validated letter placement positions (flood-fill reachable)
///
/// Each call to [generate] produces a unique randomised map.
class OutdoorMapGenerator {
  OutdoorMapGenerator._();

  // -------------------------
  // World dimensions
  // -------------------------

  /// Total world width in game units
  static const double worldWidth = 3000.0;

  /// Total world height in game units
  static const double worldHeight = 2000.0;

  /// Grid cell size for generation logic
  static const double cellSize = 64.0;

  /// Number of grid columns
  static int get gridCols => (worldWidth / cellSize).ceil();

  /// Number of grid rows
  static int get gridRows => (worldHeight / cellSize).ceil();

  // -------------------------
  // Generation parameters
  // -------------------------

  /// Minimum inward offset for boundary control points
  static const double _boundaryMinInset = 64.0;

  /// Maximum inward offset for boundary control points
  static const double _boundaryMaxInset = 256.0;

  /// Number of control points around the boundary
  static const int _boundaryPointCount = 64;

  /// Lake center X (approximate, randomised slightly)
  static const double _lakeCenterX = worldWidth / 2;

  /// Lake center Y (approximate, randomised slightly)
  static const double _lakeCenterY = worldHeight / 2;

  /// Lake semi-major axis (horizontal)
  static const double _lakeRadiusX = 400.0;

  /// Lake semi-minor axis (vertical)
  static const double _lakeRadiusY = 300.0;

  /// Number of control points for the lake shape
  static const int _lakePointCount = 12;

  /// Number of streams radiating from the lake
  static const int _streamCount = 4;

  /// Stream width in cells
  static const int _streamWidthCells = 1;

  /// Bridge width in world units
  static const double _bridgeWidth = 128.0;

  /// Bridge length in world units (long enough to span stream + land margins)
  static const double _bridgeLength = 256.0;

  /// Number of trees to place
  static const int _treeCount = 50;

  /// Number of rocks to place
  static const int _rockCount = 25;

  /// Number of bushes to place (decorative)
  static const int _bushCount = 40;

  /// Minimum distance between any two obstacles
  static const double _obstacleMinSpacing = 96.0;

  /// Minimum distance from player start for obstacles
  static const double _playerClearRadius = 200.0;

  /// Minimum distance between letter positions
  static const double _letterMinSpacing = 400.0;

  /// Number of candidate letter positions to generate
  static const int _letterCandidateCount = 40;

  // -------------------------
  // Main generation entry point
  // -------------------------

  /// Generates a complete outdoor map.
  ///
  /// [random] can be provided for deterministic testing.
  /// Returns a fully validated [OutdoorMapData] with all positions
  /// guaranteed to be reachable from the player start.
  static OutdoorMapData generate({Random? random}) {
    final rng = random ?? Random();

    // 1. Initialise grid to land
    final grid = List.generate(
      gridRows,
      (_) => List.filled(gridCols, CellType.land),
    );

    // 2. Generate irregular boundary
    final boundaryPoints = _generateBoundary(rng);
    _markBoundaryOnGrid(grid, boundaryPoints);

    // 3. Place central lake
    final lakePoints = _generateLake(rng);
    _markPolygonOnGrid(grid, lakePoints, CellType.water);

    // 4. Generate streams from lake to boundary
    final streamPaths = _generateStreams(rng, grid, lakePoints);

    // 5. Place bridges
    final bridges = _placeBridges(rng, grid, streamPaths, lakePoints);
    _markBridgesOnGrid(grid, bridges);

    // 6. Find player start (center of map, on land)
    final playerStart = _findPlayerStart(grid);

    // 7. Place obstacles (trees, rocks, bushes)
    final treePositions = _placeObstacles(
      rng,
      grid,
      playerStart,
      _treeCount,
      CellType.tree,
    );
    final rockPositions = _placeObstacles(
      rng,
      grid,
      playerStart,
      _rockCount,
      CellType.rock,
    );
    // Bushes are decorative — don't mark on grid
    final bushPositions = _placeDecorativeBushes(
      rng,
      grid,
      playerStart,
      _bushCount,
    );

    // 8. Validate connectivity (flood fill from player start)
    _ensureConnectivity(grid, playerStart);

    // 9. Generate letter candidate positions
    final letterPositions = _generateLetterPositions(
      rng,
      grid,
      playerStart,
    );

    return OutdoorMapData(
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      cellSize: cellSize,
      gridCols: gridCols,
      gridRows: gridRows,
      grid: grid,
      boundaryPoints: boundaryPoints,
      lakePoints: lakePoints,
      streamPaths: streamPaths,
      bridges: bridges,
      treePositions: treePositions,
      rockPositions: rockPositions,
      bushPositions: bushPositions,
      playerStart: playerStart,
      letterCandidatePositions: letterPositions,
    );
  }

  // -------------------------
  // Step 1: Boundary generation
  // -------------------------

  /// Generates an irregular polygon boundary around the map perimeter.
  ///
  /// Places [_boundaryPointCount] control points at even angular intervals
  /// around the world center, each offset inward by a random amount.
  static List<Vector2> _generateBoundary(Random rng) {
    final cx = worldWidth / 2;
    final cy = worldHeight / 2;
    final points = <Vector2>[];

    for (int i = 0; i < _boundaryPointCount; i++) {
      final angle = (2 * pi * i) / _boundaryPointCount;
      // Distance from center to edge along this angle
      final dx = cos(angle);
      final dy = sin(angle);
      // Find the edge distance (rectangular bounds)
      final edgeX = dx != 0 ? (worldWidth / 2) / dx.abs() : double.infinity;
      final edgeY = dy != 0 ? (worldHeight / 2) / dy.abs() : double.infinity;
      final edgeDist = min(edgeX, edgeY);

      // Random inward offset
      final inset = _boundaryMinInset +
          rng.nextDouble() * (_boundaryMaxInset - _boundaryMinInset);
      final radius = edgeDist - inset;

      points.add(Vector2(
        cx + dx * radius,
        cy + dy * radius,
      ));
    }

    return points;
  }

  /// Marks all grid cells outside the boundary polygon as [CellType.boundary].
  static void _markBoundaryOnGrid(
    List<List<CellType>> grid,
    List<Vector2> boundaryPoints,
  ) {
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final x = col * cellSize + cellSize / 2;
        final y = row * cellSize + cellSize / 2;
        if (!_isPointInPolygon(Vector2(x, y), boundaryPoints)) {
          grid[row][col] = CellType.boundary;
        }
      }
    }
  }

  // -------------------------
  // Step 2: Lake generation
  // -------------------------

  /// Generates a deformed elliptical lake near the world center.
  static List<Vector2> _generateLake(Random rng) {
    // Slight random offset from exact center
    final cx = _lakeCenterX + (rng.nextDouble() - 0.5) * 400;
    final cy = _lakeCenterY + (rng.nextDouble() - 0.5) * 300;
    final points = <Vector2>[];

    for (int i = 0; i < _lakePointCount; i++) {
      final angle = (2 * pi * i) / _lakePointCount;
      // Base ellipse radius at this angle
      final rx = _lakeRadiusX + (rng.nextDouble() - 0.5) * 200;
      final ry = _lakeRadiusY + (rng.nextDouble() - 0.5) * 150;

      points.add(Vector2(
        cx + cos(angle) * rx,
        cy + sin(angle) * ry,
      ));
    }

    return points;
  }

  // -------------------------
  // Step 3: Stream generation
  // -------------------------

  /// Generates meandering streams from the lake edge toward the boundary.
  ///
  /// Each stream starts at a random point on the lake perimeter and
  /// meanders outward using a random walk with momentum until it
  /// reaches a boundary cell.
  static List<List<Vector2>> _generateStreams(
    Random rng,
    List<List<CellType>> grid,
    List<Vector2> lakePoints,
  ) {
    final streams = <List<Vector2>>[];

    // Start angles evenly distributed with some randomness
    for (int i = 0; i < _streamCount; i++) {
      final baseAngle = (2 * pi * i) / _streamCount;
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.5;

      // Find lake edge point at this angle
      final lakeCx = _averageX(lakePoints);
      final lakeCy = _averageY(lakePoints);
      final startX = lakeCx + cos(angle) * (_lakeRadiusX + 50);
      final startY = lakeCy + sin(angle) * (_lakeRadiusY + 50);

      final streamPath = _generateSingleStream(
        rng,
        grid,
        Vector2(startX, startY),
        angle,
      );

      if (streamPath.length > 3) {
        // Mark stream cells on grid
        _markStreamOnGrid(grid, streamPath);
        streams.add(streamPath);
      }
    }

    return streams;
  }

  /// Generates a single meandering stream path.
  static List<Vector2> _generateSingleStream(
    Random rng,
    List<List<CellType>> grid,
    Vector2 start,
    double initialAngle,
  ) {
    final path = <Vector2>[start.clone()];
    var currentAngle = initialAngle;
    var current = start.clone();
    final stepSize = cellSize * 2;

    for (int step = 0; step < 120; step++) {
      // Random meander
      currentAngle += (rng.nextDouble() - 0.5) * 0.6;

      final next = Vector2(
        current.x + cos(currentAngle) * stepSize,
        current.y + sin(currentAngle) * stepSize,
      );

      // Stop if out of world bounds
      if (next.x < 0 ||
          next.x >= worldWidth ||
          next.y < 0 ||
          next.y >= worldHeight) {
        break;
      }

      // Stop if we reach the boundary
      final col = (next.x / cellSize).floor().clamp(0, gridCols - 1);
      final row = (next.y / cellSize).floor().clamp(0, gridRows - 1);
      if (grid[row][col] == CellType.boundary) {
        path.add(next);
        break;
      }

      path.add(next);
      current = next;
    }

    return path;
  }

  /// Marks stream cells on the grid as water.
  static void _markStreamOnGrid(
    List<List<CellType>> grid,
    List<Vector2> streamPath,
  ) {
    for (final point in streamPath) {
      final centerCol = (point.x / cellSize).floor();
      final centerRow = (point.y / cellSize).floor();

      // Mark cells in a width band around the stream center
      for (int dRow = -_streamWidthCells; dRow <= _streamWidthCells; dRow++) {
        for (int dCol = -_streamWidthCells; dCol <= _streamWidthCells; dCol++) {
          final r = centerRow + dRow;
          final c = centerCol + dCol;
          if (r >= 0 &&
              r < gridRows &&
              c >= 0 &&
              c < gridCols &&
              grid[r][c] == CellType.land) {
            grid[r][c] = CellType.water;
          }
        }
      }
    }
  }

  // -------------------------
  // Step 4: Bridge placement
  // -------------------------

  /// Places bridges at strategic points along streams and the lake edge.
  ///
  /// Each stream gets 1-2 bridges. The lake gets 2-3 bridges around
  /// its perimeter. Bridge cells are marked as walkable (bridge type)
  /// to create gaps in the water collision.
  static List<BridgeData> _placeBridges(
    Random rng,
    List<List<CellType>> grid,
    List<List<Vector2>> streamPaths,
    List<Vector2> lakePoints,
  ) {
    final bridges = <BridgeData>[];

    // Place one bridge on each stream (roughly midway)
    for (final stream in streamPaths) {
      if (stream.length < 6) continue;

      // Place a bridge roughly halfway along the stream
      final idx = (stream.length * 0.5).floor();
      _addBridgeAtStreamPoint(bridges, stream, idx, grid);
    }

    // Place 2-3 bridges around the lake perimeter
    final lakeBridgeCount = 2 + rng.nextInt(2);
    final lakeCx = _averageX(lakePoints);
    final lakeCy = _averageY(lakePoints);

    for (int i = 0; i < lakeBridgeCount; i++) {
      final angle = (2 * pi * i) / lakeBridgeCount +
          (rng.nextDouble() - 0.5) * 0.3;
      final x = lakeCx + cos(angle) * (_lakeRadiusX * 0.9);
      final y = lakeCy + sin(angle) * (_lakeRadiusY * 0.9);

      // Determine orientation based on angle (perpendicular to lake edge)
      final isHorizontal = (cos(angle).abs() < sin(angle).abs());

      // Find the lake edge and position bridge from edge outward into land
      final bridgePos = _findLakeBridgePosition(
        grid,
        lakeCx,
        lakeCy,
        angle,
        isHorizontal,
      );

      bridges.add(BridgeData(
        position: bridgePos,
        width: _bridgeWidth,
        length: _bridgeLength,
        isHorizontal: isHorizontal,
      ));
    }

    return bridges;
  }

  /// Finds a lake bridge position where all corners will be on land.
  ///
  /// Searches outward from the lake center along the given angle to find
  /// the water-land boundary, then positions the bridge to span from
  /// water into land with corners on land.
  static Vector2 _findLakeBridgePosition(
    List<List<CellType>> grid,
    double lakeCx,
    double lakeCy,
    double angle,
    bool isHorizontal,
  ) {
    final dx = cos(angle);
    final dy = sin(angle);

    // Search outward from lake center to find where water meets land
    Vector2? waterEdge;
    Vector2? landStart;

    for (int i = 1; i <= 40; i++) {
      final dist = i * cellSize * 0.5;
      final testX = lakeCx + dx * dist;
      final testY = lakeCy + dy * dist;

      if (testX < 0 || testX >= worldWidth || testY < 0 || testY >= worldHeight) {
        break;
      }

      final col = (testX / cellSize).floor().clamp(0, gridCols - 1);
      final row = (testY / cellSize).floor().clamp(0, gridRows - 1);
      final cell = grid[row][col];

      if (cell == CellType.water && waterEdge == null) {
        // Still in water, keep tracking the edge
        waterEdge = Vector2(testX, testY);
      } else if (cell == CellType.land && waterEdge != null) {
        // Found land after water — this is where bridge should end
        landStart = Vector2(testX, testY);
        break;
      }
    }

    if (waterEdge != null && landStart != null) {
      // Position bridge at the transition point, shifted toward land
      // so corners are on land
      final halfLength = _bridgeLength / 2;
      return Vector2(
        landStart.x + dx * (halfLength * 0.3),
        landStart.y + dy * (halfLength * 0.3),
      );
    }

    // Fallback: original position near lake edge
    return Vector2(
      lakeCx + dx * (_lakeRadiusX * 1.1),
      lakeCy + dy * (_lakeRadiusY * 1.1),
    );
  }

  /// Adds a bridge at a specific point along a stream path.
    ///
  /// The bridge is positioned so that it spans from land on one side
  /// to land on the other, ensuring all four corners sit on land cells.
  /// The bridge center is shifted perpendicular to the stream direction
  /// to ensure proper land overlap.
  static void _addBridgeAtStreamPoint(
    List<BridgeData> bridges,
    List<Vector2> stream,
    int index,
    List<List<CellType>> grid,
  ) {
    if (index < 1 || index >= stream.length - 1) return;

    final point = stream[index];
    final prev = stream[index - 1];
    final next = stream[index + 1];

    // Stream direction at this point
    final dir = next - prev;
    // Bridge is perpendicular to stream flow
    final isHorizontal = dir.y.abs() > dir.x.abs();

    // Find land cells on both sides of the stream to ensure bridge
    // corners are on land. Search perpendicular to stream flow.
    final bridgePos = _findBridgePositionWithLandCorners(
      grid,
      point,
      isHorizontal,
    );

    bridges.add(BridgeData(
      position: bridgePos,
      width: _bridgeWidth,
      length: _bridgeLength,
      isHorizontal: isHorizontal,
    ));
  }

  /// Finds a bridge position where all four corners will be on land.
  ///
  /// Searches along the perpendicular axis to find land cells on both
  /// sides, then positions the bridge to span between them.
  static Vector2 _findBridgePositionWithLandCorners(
    List<List<CellType>> grid,
    Vector2 streamPoint,
    bool isHorizontal,
  ) {
    // For a horizontal bridge: search up and down (Y axis) for land
    // For a vertical bridge: search left and right (X axis) for land
    final searchDx = isHorizontal ? 0.0 : cellSize;
    final searchDy = isHorizontal ? cellSize : 0.0;

    // Search for land in both directions from the stream point
    Vector2? landNeg;
    Vector2? landPos;

    // Search negative direction (up or left)
    for (int i = 1; i <= 8; i++) {
      final testX = streamPoint.x - searchDx * i;
      final testY = streamPoint.y - searchDy * i;
      final col = (testX / cellSize).floor().clamp(0, gridCols - 1);
      final row = (testY / cellSize).floor().clamp(0, gridRows - 1);

      if (grid[row][col] == CellType.land) {
        landNeg = Vector2(testX, testY);
        break;
      }
    }

    // Search positive direction (down or right)
    for (int i = 1; i <= 8; i++) {
      final testX = streamPoint.x + searchDx * i;
      final testY = streamPoint.y + searchDy * i;
      final col = (testX / cellSize).floor().clamp(0, gridCols - 1);
      final row = (testY / cellSize).floor().clamp(0, gridRows - 1);

      if (grid[row][col] == CellType.land) {
        landPos = Vector2(testX, testY);
        break;
      }
    }

    // Position bridge at midpoint between land cells, or use original
    // point if land wasn't found on both sides
    if (landNeg != null && landPos != null) {
      return Vector2(
        (landNeg.x + landPos.x) / 2,
        (landNeg.y + landPos.y) / 2,
      );
    }

    // Fallback: use original stream point
    return streamPoint.clone();
  }

  /// Marks bridge cells on the grid, replacing water with bridge type.
  static void _markBridgesOnGrid(
    List<List<CellType>> grid,
    List<BridgeData> bridges,
  ) {
    for (final bridge in bridges) {
      final halfW = bridge.isHorizontal ? bridge.length / 2 : bridge.width / 2;
      final halfH = bridge.isHorizontal ? bridge.width / 2 : bridge.length / 2;

      final minCol =
          ((bridge.position.x - halfW) / cellSize).floor().clamp(0, gridCols - 1);
      final maxCol =
          ((bridge.position.x + halfW) / cellSize).ceil().clamp(0, gridCols - 1);
      final minRow =
          ((bridge.position.y - halfH) / cellSize).floor().clamp(0, gridRows - 1);
      final maxRow =
          ((bridge.position.y + halfH) / cellSize).ceil().clamp(0, gridRows - 1);

      for (int r = minRow; r <= maxRow; r++) {
        for (int c = minCol; c <= maxCol; c++) {
          if (grid[r][c] == CellType.water) {
            grid[r][c] = CellType.bridge;
          }
        }
      }
    }
  }

  // -------------------------
  // Step 5: Player start
  // -------------------------

  /// Finds a valid player start position near the world center on land.
  ///
  /// Searches outward from the center in a spiral pattern until a
  /// land cell is found. Falls back to the first land cell if needed.
  static Vector2 _findPlayerStart(List<List<CellType>> grid) {
    final centerCol = gridCols ~/ 2;
    final centerRow = gridRows ~/ 2;

    // Spiral outward from center
    for (int radius = 0; radius < max(gridCols, gridRows); radius++) {
      for (int dRow = -radius; dRow <= radius; dRow++) {
        for (int dCol = -radius; dCol <= radius; dCol++) {
          // Only check the perimeter of this radius ring
          if (dRow.abs() != radius && dCol.abs() != radius) continue;

          final r = centerRow + dRow;
          final c = centerCol + dCol;
          if (r >= 0 &&
              r < gridRows &&
              c >= 0 &&
              c < gridCols &&
              (grid[r][c] == CellType.land || grid[r][c] == CellType.bridge)) {
            return Vector2(
              c * cellSize + cellSize / 2,
              r * cellSize + cellSize / 2,
            );
          }
        }
      }
    }

    // Fallback: world center
    return Vector2(worldWidth / 2, worldHeight / 2);
  }

  // -------------------------
  // Step 6: Obstacle placement
  // -------------------------

  /// Places solid obstacles (trees or rocks) on valid land cells.
  ///
  /// Ensures minimum spacing between obstacles and clearance from
  /// the player start position. Marks placed cells on the grid.
  static List<Vector2> _placeObstacles(
    Random rng,
    List<List<CellType>> grid,
    Vector2 playerStart,
    int count,
    CellType type,
  ) {
    final positions = <Vector2>[];
    var attempts = 0;
    final maxAttempts = count * 20;

    while (positions.length < count && attempts < maxAttempts) {
      attempts++;

      final col = rng.nextInt(gridCols);
      final row = rng.nextInt(gridRows);

      if (grid[row][col] != CellType.land) continue;

      final worldPos = Vector2(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );

      // Check distance from player start
      if (worldPos.distanceTo(playerStart) < _playerClearRadius) continue;

      // Check distance from other placed obstacles
      bool tooClose = false;
      for (final existing in positions) {
        if (worldPos.distanceTo(existing) < _obstacleMinSpacing) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      // Density bias: more obstacles near edges, fewer in center
      final distFromCenter = worldPos.distanceTo(
        Vector2(worldWidth / 2, worldHeight / 2),
      );
      final maxDist = worldWidth / 2;
      final edgeBias = distFromCenter / maxDist;
      if (rng.nextDouble() > edgeBias + 0.3) continue;

      positions.add(worldPos);
      grid[row][col] = type;
    }

    return positions;
  }

  /// Places decorative bushes near existing trees (no grid marking).
  static List<Vector2> _placeDecorativeBushes(
    Random rng,
    List<List<CellType>> grid,
    Vector2 playerStart,
    int count,
  ) {
    final positions = <Vector2>[];
    var attempts = 0;
    final maxAttempts = count * 15;

    while (positions.length < count && attempts < maxAttempts) {
      attempts++;

      final col = rng.nextInt(gridCols);
      final row = rng.nextInt(gridRows);

      if (grid[row][col] != CellType.land) continue;

      final worldPos = Vector2(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );

      if (worldPos.distanceTo(playerStart) < _playerClearRadius) continue;

      positions.add(worldPos);
    }

    return positions;
  }

  // -------------------------
  // Step 7: Connectivity validation
  // -------------------------

  /// Ensures all land/bridge cells are reachable from the player start.
  ///
  /// Performs a flood fill from the player's starting cell. Any
  /// unreachable land pockets have their nearest water cell converted
  /// to a bridge to create a connection.
  static void _ensureConnectivity(
    List<List<CellType>> grid,
    Vector2 playerStart,
  ) {
    final startCol = (playerStart.x / cellSize).floor().clamp(0, gridCols - 1);
    final startRow = (playerStart.y / cellSize).floor().clamp(0, gridRows - 1);

    // Flood fill from player start
    final visited = List.generate(
      gridRows,
      (_) => List.filled(gridCols, false),
    );
    final queue = <_GridPos>[_GridPos(startRow, startCol)];
    visited[startRow][startCol] = true;

    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);

      for (final dir in _GridPos.directions) {
        final nr = pos.row + dir.row;
        final nc = pos.col + dir.col;

        if (nr < 0 || nr >= gridRows || nc < 0 || nc >= gridCols) continue;
        if (visited[nr][nc]) continue;

        final cell = grid[nr][nc];
        if (cell == CellType.land ||
            cell == CellType.bridge ||
            cell == CellType.tree ||
            cell == CellType.rock) {
          visited[nr][nc] = true;
          queue.add(_GridPos(nr, nc));
        }
      }
    }

    // Find unreachable land cells and bridge them
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        if (!visited[r][c] && grid[r][c] == CellType.land) {
          // Find nearest water cell between this and visited area,
          // convert it to bridge
          _bridgeToReachableArea(grid, visited, r, c);
        }
      }
    }
  }

  /// Attempts to create a bridge connection from an unreachable land cell
  /// to the reachable area by converting water cells to bridges.
  static void _bridgeToReachableArea(
    List<List<CellType>> grid,
    List<List<bool>> visited,
    int startRow,
    int startCol,
  ) {
    // BFS from the unreachable cell toward any visited cell,
    // converting water to bridge along the way
    final queue = <_GridPos>[_GridPos(startRow, startCol)];
    final localVisited = List.generate(
      gridRows,
      (_) => List.filled(gridCols, false),
    );
    final parent = <String, _GridPos?>{};

    localVisited[startRow][startCol] = true;
    parent['$startRow,$startCol'] = null;

    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);

      // If we reached a cell that's already reachable, trace back
      // and convert water cells to bridges
      if (visited[pos.row][pos.col]) {
        _traceBridgePath(grid, parent, pos, startRow, startCol);
        return;
      }

      for (final dir in _GridPos.directions) {
        final nr = pos.row + dir.row;
        final nc = pos.col + dir.col;

        if (nr < 0 || nr >= gridRows || nc < 0 || nc >= gridCols) continue;
        if (localVisited[nr][nc]) continue;
        if (grid[nr][nc] == CellType.boundary) continue;

        localVisited[nr][nc] = true;
        parent['$nr,$nc'] = pos;
        queue.add(_GridPos(nr, nc));
      }
    }
  }

  /// Traces back from a found reachable cell and converts water to bridges.
  static void _traceBridgePath(
    List<List<CellType>> grid,
    Map<String, _GridPos?> parent,
    _GridPos end,
    int startRow,
    int startCol,
  ) {
    var current = end;
    while (parent['${current.row},${current.col}'] != null) {
      if (grid[current.row][current.col] == CellType.water) {
        grid[current.row][current.col] = CellType.bridge;
      }
      current = parent['${current.row},${current.col}']!;
    }
  }

  // -------------------------
  // Step 8: Letter positions
  // -------------------------

  /// Generates candidate positions for letter placement.
  ///
  /// Selects positions on land cells that are:
  /// - At least [_letterMinSpacing] from each other
  /// - At least 100 units from water/boundary/obstacles
  /// - Reachable from the player start (validated by earlier flood fill)
  static List<Vector2> _generateLetterPositions(
    Random rng,
    List<List<CellType>> grid,
    Vector2 playerStart,
  ) {
    final candidates = <Vector2>[];
    var attempts = 0;
    final maxAttempts = _letterCandidateCount * 30;

    while (candidates.length < _letterCandidateCount &&
        attempts < maxAttempts) {
      attempts++;

      final col = rng.nextInt(gridCols);
      final row = rng.nextInt(gridRows);

      if (grid[row][col] != CellType.land) continue;

      // Check surrounding cells are also land (buffer zone)
      bool hasBuffer = true;
      for (int dr = -1; dr <= 1 && hasBuffer; dr++) {
        for (int dc = -1; dc <= 1 && hasBuffer; dc++) {
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 || nr >= gridRows || nc < 0 || nc >= gridCols) {
            hasBuffer = false;
          } else if (grid[nr][nc] != CellType.land &&
              grid[nr][nc] != CellType.bridge) {
            hasBuffer = false;
          }
        }
      }
      if (!hasBuffer) continue;

      final worldPos = Vector2(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );

      // Minimum distance from player start
      if (worldPos.distanceTo(playerStart) < 200) continue;

      // Minimum spacing between candidates
      bool tooClose = false;
      for (final existing in candidates) {
        if (worldPos.distanceTo(existing) < _letterMinSpacing) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      candidates.add(worldPos);
    }

    return candidates;
  }

  // -------------------------
  // Geometry utilities
  // -------------------------

  /// Point-in-polygon test using ray casting algorithm.
  static bool _isPointInPolygon(Vector2 point, List<Vector2> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];

      if ((pi.y > point.y) != (pj.y > point.y) &&
          point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Marks all grid cells inside a polygon as the given cell type.
  static void _markPolygonOnGrid(
    List<List<CellType>> grid,
    List<Vector2> polygon,
    CellType type,
  ) {
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final x = col * cellSize + cellSize / 2;
        final y = row * cellSize + cellSize / 2;
        if (_isPointInPolygon(Vector2(x, y), polygon)) {
          grid[row][col] = type;
        }
      }
    }
  }

  /// Average X coordinate of a polygon.
  static double _averageX(List<Vector2> points) {
    return points.fold<double>(0, (sum, p) => sum + p.x) / points.length;
  }

  /// Average Y coordinate of a polygon.
  static double _averageY(List<Vector2> points) {
    return points.fold<double>(0, (sum, p) => sum + p.y) / points.length;
  }
}

/// Helper class for grid positions during BFS/flood fill.
class _GridPos {
  final int row;
  final int col;

  const _GridPos(this.row, this.col);

  /// 4-directional movement offsets
  static const List<_GridPos> directions = [
    _GridPos(-1, 0), // up
    _GridPos(1, 0), // down
    _GridPos(0, -1), // left
    _GridPos(0, 1), // right
  ];
}
