import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'outdoor_map_data.dart';

/// A boundary wall segment rendered with densely packed tree sprites.
///
/// Used for the outdoor map boundary to create a thick treeline barrier
/// that prevents the player from leaving the playable area.
///
/// Tree sprites are placed in a grid pattern, but positions that overlap
/// water cells (lake or streams) are skipped to allow water to flow
/// through the boundary naturally.
///
/// Provides collision detection via [RectangleHitbox] to block the player.
class BoundaryWallComponent extends PositionComponent with HasGameReference {
  /// Path to the tree sprite image (relative to assets/)
  static const String _spritePath = 'images/Tree2.png';

  /// Size of each tree sprite in pixels
  static const double _treeSpriteSize = 64.0;

  /// Reference to map data for water cell checking
  final OutdoorMapData mapData;

  /// The loaded tree sprite image
  Sprite? _sprite;

  /// Fallback paint if sprite fails to load (dark green)
  late final Paint _fallbackPaint;

  /// Pre-calculated tree positions for this wall segment
  final List<Vector2> _treePositions = [];

  /// Creates a boundary wall segment.
  ///
  /// Parameters:
  /// - [position]: Top-left corner in world coordinates
  /// - [size]: Width and height of the wall segment
  /// - [mapData]: Map data for checking water cell positions
  BoundaryWallComponent({
    required super.position,
    required super.size,
    required this.mapData,
  });

  @override
  Future<void> onLoad() async {
    // Fallback colour if sprite loading fails
    _fallbackPaint = Paint()..color = const Color(0xFF1B5E20);

    // Resize bounds to fit only complete sprites
    _resizeBoundsToFitSprites();

    // Attempt to load the tree sprite
    try {
      final image = await game.images.load(_spritePath);
      _sprite = Sprite(image);
    } catch (e) {
      // Sprite loading failed — will use fallback colour
      _sprite = null;
    }

    // Pre-calculate tree positions, skipping water cells
    _calculateTreePositions();

    // Add collision hitbox matching the wall's full size
    add(RectangleHitbox());
  }

  /// Resizes the component bounds to fit only complete sprites.
  ///
  /// Adjusts the size to be a multiple of the sprite size, ensuring
  /// no partial sprites are rendered at the edges.
  void _resizeBoundsToFitSprites() {
    // Calculate number of complete sprites that fit
    final cols = (size.x / _treeSpriteSize).floor();
    final rows = (size.y / _treeSpriteSize).floor();

    // Ensure at least 1 sprite fits
    final newWidth = (cols > 0 ? cols : 1) * _treeSpriteSize;
    final newHeight = (rows > 0 ? rows : 1) * _treeSpriteSize;

    // Update size to fit complete sprites only
    size = Vector2(newWidth, newHeight);
  }

  /// Calculates positions for trees across the wall area.
  ///
  /// Trees are arranged in a grid pattern. Positions that overlap
  /// water cells in the map grid are skipped.
  void _calculateTreePositions() {
    // Calculate number of columns and rows that fit
    final cols = (size.x / _treeSpriteSize).floor();
    final rows = (size.y / _treeSpriteSize).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final localX = col * _treeSpriteSize;
        final localY = row * _treeSpriteSize;

        // Convert to world coordinates for water check
        final worldX = position.x + localX + _treeSpriteSize / 2;
        final worldY = position.y + localY + _treeSpriteSize / 2;

        // Skip if this position overlaps water
        if (_isOverlappingWater(worldX, worldY)) {
          continue;
        }

        _treePositions.add(Vector2(localX, localY));
      }
    }
  }

  /// Checks if a world position overlaps a water cell.
  ///
  /// Returns true if the position is over lake or stream water.
  bool _isOverlappingWater(double worldX, double worldY) {
    // Bounds check
    if (worldX < 0 ||
        worldX >= mapData.worldWidth ||
        worldY < 0 ||
        worldY >= mapData.worldHeight) {
      return false;
    }

    // Convert to grid coordinates
    final gridCol = (worldX / mapData.cellSize).floor();
    final gridRow = (worldY / mapData.cellSize).floor();

    // Clamp to grid bounds
    final col = gridCol.clamp(0, mapData.gridCols - 1);
    final row = gridRow.clamp(0, mapData.gridRows - 1);

    // Check if cell is water (not bridge — bridges should have trees nearby)
    return mapData.grid[row][col] == CellType.water;
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      // Render trees at valid positions
      _renderPackedTrees(canvas);
    } else {
      // Fallback: solid colour rectangle
      canvas.drawRect(size.toRect(), _fallbackPaint);
    }
  }

  /// Renders tree sprites in a grid across the wall area.
  ///
  /// Only draws at pre-calculated positions (water cells are skipped).
  void _renderPackedTrees(Canvas canvas) {
    final sprite = _sprite!;

    // Draw each tree at its pre-calculated position
    for (final pos in _treePositions) {
      sprite.render(
        canvas,
        position: pos,
        size: Vector2.all(_treeSpriteSize),
      );
    }
  }
}
