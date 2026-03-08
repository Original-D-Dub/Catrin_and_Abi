import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../models/room_config.dart';
import 'base_letter_quest_game.dart';
import 'simple_room_component.dart';

/// A room in the Letter Quest map.
///
/// Each room consists of:
/// - A tiled wood floor (same sprite as Levels 1 & 2)
/// - Tiled brick walls on all 4 sides (with doorway gaps where configured)
///
/// Rooms are positioned in world coordinates based on [RoomConfig.worldPosition].
class RoomComponent extends PositionComponent
    with HasGameReference<BaseLetterQuestGame> {
  /// Configuration for this room (vowel, colours, doorways, etc.)
  final RoomConfig config;

  /// Tile size for the floor texture.
  static const double _tileSize = 80.0;

  /// Vertical offset applied to even-numbered columns.
  static const double _evenColumnOffset = 40.0;

  /// Wall tile size (matches wall thickness).
  static const double _wallTileSize = 40.0;

  /// Creates a room from its configuration.
  RoomComponent({required this.config})
      : super(
          position: config.worldPosition.clone(),
          size: Vector2(RoomConfig.roomWidth, RoomConfig.roomHeight),
        );

  @override
  Future<void> onLoad() async {
    // 1. Tiled wood floor
    _addFloorTiles();

    // 2. Tiled brick walls with doorway gaps
    _addWalls();
  }

  /// Adds the floor as a grid of 80x80 wood tiles.
  ///
  /// Even-numbered columns (0, 2, 4, …) are offset downward by 40px
  /// to create a brick-like staggered pattern. Same pattern as Levels 1 & 2.
  void _addFloorTiles() {
    final floorImage =
        game.images.fromCache('games/letter_quest/floor-tile-wood-pale.png');
    final sprite = Sprite(floorImage);

    final cols = (RoomConfig.roomWidth / _tileSize).ceil() + 1;
    final rows = (RoomConfig.roomHeight / _tileSize).ceil() + 2;

    for (int col = 0; col < cols; col++) {
      final isEvenColumn = col % 2 == 0;
      final yOffset = isEvenColumn ? _evenColumnOffset : 0.0;

      // Even columns need an extra tile at the top to fill the gap
      final startRow = isEvenColumn ? -1 : 0;

      for (int row = startRow; row < rows; row++) {
        final x = col * _tileSize;
        final y = row * _tileSize + yOffset;

        // Skip tiles entirely outside the room bounds
        if (x >= RoomConfig.roomWidth ||
            y + _tileSize <= 0 ||
            y >= RoomConfig.roomHeight) {
          continue;
        }

        add(SpriteComponent(
          sprite: sprite,
          position: Vector2(x, y),
          size: Vector2(_tileSize, _tileSize),
        ));
      }
    }
  }

  /// Creates a tiled brick wall with collision.
  ///
  /// [wallPos] and [wallSize] define the wall rectangle.
  /// [isVertical] rotates each tile 90° for vertical walls.
  void _addTiledWall({
    required Vector2 wallPos,
    required Vector2 wallSize,
    bool isVertical = false,
  }) {
    final wallSprite = Sprite(
      game.images.fromCache('games/letter_quest/wall-tile-brick.png'),
    );

    // Parent component for this wall segment (holds tiles + hitbox)
    final wall = TiledWallComponent(
      position: wallPos,
      size: wallSize,
    )..add(RectangleHitbox());

    if (isVertical) {
      // Tile along the height of the wall
      final tileCount = (wallSize.y / _wallTileSize).ceil();
      for (int i = 0; i < tileCount; i++) {
        final centerX = wallSize.x / 2;
        final centerY = i * _wallTileSize + _wallTileSize / 2;
        wall.add(SpriteComponent(
          sprite: wallSprite,
          position: Vector2(centerX, centerY),
          size: Vector2(_wallTileSize, _wallTileSize),
          anchor: Anchor.center,
          angle: pi / 2,
        ));
      }
    } else {
      // Tile along the width of the wall
      final tileCount = (wallSize.x / _wallTileSize).ceil();
      for (int i = 0; i < tileCount; i++) {
        wall.add(SpriteComponent(
          sprite: wallSprite,
          position: Vector2(i * _wallTileSize, 0),
          size: Vector2(_wallTileSize, _wallTileSize),
        ));
      }
    }

    add(wall);
  }

  /// Adds walls on all 4 sides, leaving gaps for doorways.
  ///
  /// Uses tiled brick sprites matching Levels 1 & 2.
  void _addWalls() {
    final w = RoomConfig.roomWidth;
    final h = RoomConfig.roomHeight;
    final t = RoomConfig.wallThickness;
    final d = RoomConfig.doorwayWidth;

    // Center of each side (for doorway gap calculation)
    final cx = w / 2;
    final cy = h / 2;

    // Top wall
    if (config.doorways.contains(DoorwaySide.top)) {
      _addTiledWall(
        wallPos: Vector2(0, 0),
        wallSize: Vector2(cx - d / 2, t),
      );
      _addTiledWall(
        wallPos: Vector2(cx + d / 2, 0),
        wallSize: Vector2(w - cx - d / 2, t),
      );
    } else {
      _addTiledWall(
        wallPos: Vector2(0, 0),
        wallSize: Vector2(w, t),
      );
    }

    // Bottom wall
    if (config.doorways.contains(DoorwaySide.bottom)) {
      _addTiledWall(
        wallPos: Vector2(0, h - t),
        wallSize: Vector2(cx - d / 2, t),
      );
      _addTiledWall(
        wallPos: Vector2(cx + d / 2, h - t),
        wallSize: Vector2(w - cx - d / 2, t),
      );
    } else {
      _addTiledWall(
        wallPos: Vector2(0, h - t),
        wallSize: Vector2(w, t),
      );
    }

    // Left wall
    if (config.doorways.contains(DoorwaySide.left)) {
      _addTiledWall(
        wallPos: Vector2(0, 0),
        wallSize: Vector2(t, cy - d / 2),
        isVertical: true,
      );
      _addTiledWall(
        wallPos: Vector2(0, cy + d / 2),
        wallSize: Vector2(t, h - cy - d / 2),
        isVertical: true,
      );
    } else {
      _addTiledWall(
        wallPos: Vector2(0, 0),
        wallSize: Vector2(t, h),
        isVertical: true,
      );
    }

    // Right wall
    if (config.doorways.contains(DoorwaySide.right)) {
      _addTiledWall(
        wallPos: Vector2(w - t, 0),
        wallSize: Vector2(t, cy - d / 2),
        isVertical: true,
      );
      _addTiledWall(
        wallPos: Vector2(w - t, cy + d / 2),
        wallSize: Vector2(t, h - cy - d / 2),
        isVertical: true,
      );
    } else {
      _addTiledWall(
        wallPos: Vector2(w - t, 0),
        wallSize: Vector2(t, h),
        isVertical: true,
      );
    }
  }
}
