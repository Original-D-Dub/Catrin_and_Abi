import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'base_letter_quest_game.dart';
import '../models/simple_room_config.dart';

/// The simple room component for Letter Quest Level 2.
///
/// Renders a 900x1200 room divided in half by a horizontal wall
/// with two doorways.
///
/// Consists of:
/// - A tiled wood floor (80x80 tiles, even columns offset by 40px)
/// - Tiled brick walls on all 4 sides (40x40 tiles, rotated for vertical)
/// - A horizontal divider wall with two doorway gaps
class SimpleRoomComponent extends PositionComponent
    with HasGameReference<BaseLetterQuestGame> {
  /// Tile size for the floor texture.
  static const double _tileSize = 80.0;

  /// Vertical offset applied to even-numbered columns.
  static const double _evenColumnOffset = 40.0;

  /// Wall tile size (matches wall thickness).
  static const double _wallTileSize = 40.0;

  /// Creates the simple room.
  SimpleRoomComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(
            SimpleRoomConfig.mapWidth,
            SimpleRoomConfig.mapHeight,
          ),
        );

  @override
  Future<void> onLoad() async {
    // 1. Tiled wood floor
    _addFloorTiles();

    // 2. Outer walls
    _addOuterWalls();

    // 3. Horizontal divider wall with doorways
    _addDividerWall();
  }

  /// Adds the floor as a grid of 80x80 wood tiles.
  ///
  /// Even-numbered columns (0, 2, 4, …) are offset downward by 40px
  /// to create a brick-like staggered pattern.
  void _addFloorTiles() {
    final floorImage =
        game.images.fromCache('games/letter_quest/floor-tile-wood-pale.png');
    final sprite = Sprite(floorImage);

    final cols = (SimpleRoomConfig.mapWidth / _tileSize).ceil() + 1;
    final rows = (SimpleRoomConfig.mapHeight / _tileSize).ceil() + 2;

    for (int col = 0; col < cols; col++) {
      final isEvenColumn = col % 2 == 0;
      final yOffset = isEvenColumn ? _evenColumnOffset : 0.0;

      // Even columns need an extra tile at the top to fill the gap
      final startRow = isEvenColumn ? -1 : 0;

      for (int row = startRow; row < rows; row++) {
        final x = col * _tileSize;
        final y = row * _tileSize + yOffset;

        // Skip tiles entirely outside the map bounds
        if (x >= SimpleRoomConfig.mapWidth ||
            y + _tileSize <= 0 ||
            y >= SimpleRoomConfig.mapHeight) {
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
        // Position tile center within the wall, then rotate
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

  /// Adds outer walls on all 4 sides.
  void _addOuterWalls() {
    final w = SimpleRoomConfig.mapWidth;
    final h = SimpleRoomConfig.mapHeight;
    final t = SimpleRoomConfig.wallThickness;

    // Top wall (horizontal)
    _addTiledWall(
      wallPos: Vector2(0, 0),
      wallSize: Vector2(w, t),
    );

    // Bottom wall (horizontal)
    _addTiledWall(
      wallPos: Vector2(0, h - t),
      wallSize: Vector2(w, t),
    );

    // Left wall (vertical)
    _addTiledWall(
      wallPos: Vector2(0, 0),
      wallSize: Vector2(t, h),
      isVertical: true,
    );

    // Right wall (vertical)
    _addTiledWall(
      wallPos: Vector2(w - t, 0),
      wallSize: Vector2(t, h),
      isVertical: true,
    );
  }

  /// Adds the horizontal divider wall with two doorway gaps.
  void _addDividerWall() {
    final w = SimpleRoomConfig.mapWidth;
    final h = SimpleRoomConfig.mapHeight;
    final t = SimpleRoomConfig.wallThickness;
    final d = SimpleRoomConfig.doorwayWidth;

    // Y position of divider (center of map)
    final dividerY = h / 2 - t / 2;

    // Left doorway center
    final leftDoorX = SimpleRoomConfig.leftDoorwayX;
    // Right doorway center
    final rightDoorX = SimpleRoomConfig.rightDoorwayX;

    // Segment 1: From left wall to left doorway
    _addTiledWall(
      wallPos: Vector2(t, dividerY),
      wallSize: Vector2(leftDoorX - d / 2 - t, t),
    );

    // Segment 2: Between left and right doorways
    _addTiledWall(
      wallPos: Vector2(leftDoorX + d / 2, dividerY),
      wallSize: Vector2(rightDoorX - d / 2 - (leftDoorX + d / 2), t),
    );

    // Segment 3: From right doorway to right wall
    _addTiledWall(
      wallPos: Vector2(rightDoorX + d / 2, dividerY),
      wallSize: Vector2(w - t - (rightDoorX + d / 2), t),
    );
  }
}

/// A wall segment rendered with tiled brick sprites.
///
/// Used by [SimpleRoomComponent] for Level 2 walls. Identified by
/// [PlayerComponent] for collision resolution.
class TiledWallComponent extends PositionComponent {
  TiledWallComponent({required super.position, required super.size});
}
