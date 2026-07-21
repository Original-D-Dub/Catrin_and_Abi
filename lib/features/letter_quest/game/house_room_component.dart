import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../models/house_room_config.dart';
import 'base_letter_quest_game.dart';
import 'bed_component.dart';
import 'desk_component.dart';
import 'simple_room_component.dart';

/// Renders the top floor of Catrin and Abi's house for Letter Quest.
///
/// Four rooms surrounding a central landing corridor, each with its own
/// background image. Brick walls form the perimeter, room dividers, and
/// the landing boundaries, with doorway gaps connecting everything.
class HouseRoomComponent extends PositionComponent
    with HasGameReference<BaseLetterQuestGame> {
  static const double _wallTileSize = 40.0;
  static const double _floorTileSize = 80.0;

  HouseRoomComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(HouseRoomConfig.mapWidth, HouseRoomConfig.mapHeight),
        );

  @override
  Future<void> onLoad() async {
    // Tiled wood floor across the entire map
    _addTiledFloor();

    // Furniture (rendered above backgrounds, below walls)
    _addCatrinFurniture();
    _addAbiFurniture();
    _addBathroomFurniture();
    _addMumDadFurniture();

    // Walls
    _addOuterWalls();
    _addCatrinAbiWall();
    _addTopLandingWall();
    _addBottomLandingWall();
    _addBathroomMumDadWall();
  }

  // ── Floor ──────────────────────────────────────────────────────────────

  void _addTiledFloor() {
    final floorImage =
        game.images.fromCache('games/letter_quest/floor-tile-wood-pale.png');
    final sprite = Sprite(floorImage);

    final cols = (HouseRoomConfig.mapWidth / _floorTileSize).ceil();
    final rows = (HouseRoomConfig.mapHeight / _floorTileSize).ceil();
    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        add(SpriteComponent(
          sprite: sprite,
          position: Vector2(col * _floorTileSize, row * _floorTileSize),
          size: Vector2(_floorTileSize, _floorTileSize),
        ));
      }
    }
  }

  // ── Furniture ──────────────────────────────────────────────────────────

  /// Places a visual-only sprite at [pos].
  void _placeFurniture(String imageKey, Vector2 pos, Vector2 size) {
    add(SpriteComponent(
      sprite: Sprite(game.images.fromCache(imageKey)),
      position: pos,
      size: size,
    ));
  }

  /// Places a sprite at [pos] wrapped in a [TiledWallComponent] so the
  /// player and Gary collide with it.
  void _placeSolidFurniture(String imageKey, Vector2 pos, Vector2 size) {
    final inset = size * 0.05;
    final wall = TiledWallComponent(position: pos, size: size)
      ..add(RectangleHitbox(
        position: inset,
        size: size - inset * 2,
      ))
      ..add(SpriteComponent(
        sprite: Sprite(game.images.fromCache(imageKey)),
        size: size,
      ));
    add(wall);
  }

  /// Places a sprite at [pos] wrapped in a [DeskComponent] — Pero walks
  /// under it, Gary is blocked. Added to the World (not this room) so its
  /// priority (2) renders it above the player.
  void _placeDesk(String imageKey, Vector2 pos, Vector2 size) {
    final desk = DeskComponent(position: pos, size: size)
      ..add(RectangleHitbox())
      ..add(SpriteComponent(
        sprite: Sprite(game.images.fromCache(imageKey)),
        size: size,
      ));
    parent!.add(desk);
  }

  /// Places a visual-only sprite at [pos] in the World at priority 3,
  /// rendering above desks (priority 2).
  void _placeDeskItem(String imageKey, Vector2 pos, Vector2 size) {
    parent!.add(SpriteComponent(
      sprite: Sprite(game.images.fromCache(imageKey)),
      position: pos,
      size: size,
      priority: 3,
    ));
  }

  /// Places a sprite at [pos] wrapped in a [BedComponent] — blocks Gary
  /// but lets the player jump onto it.
  void _placeBed(String imageKey, Vector2 pos, Vector2 size) {
    final bed = BedComponent(position: pos, size: size)
      ..add(RectangleHitbox())
      ..add(SpriteComponent(
        sprite: Sprite(game.images.fromCache(imageKey)),
        size: size,
      ));
    add(bed);
  }

  /// Catrin's bedroom furniture — room origin (0, 0), 1090×752.
  void _addCatrinFurniture() {
    const p = 'games/letter_quest/catrin-bedroom';
    // Bed — center, headboard against top wall (jumpable)
    _placeBed('$p/catrin-Bed.png', Vector2(290, 40), Vector2(517, 532));
    // Night stand — flush against top wall, right of bed (solid)
    _placeSolidFurniture('$p/catrin-night-stand-1.png',
        Vector2(807, 40), Vector2(180, 180 * (102.0 / 121.0)));
    // Lamp — on the night stand
    _placeFurniture('$p/catrin-lamp.png', Vector2(815, 45), Vector2(151, 102));
    // Vase — on the night stand
    _placeFurniture('$p/catrin-vase.png', Vector2(940, 90), Vector2(59, 61));
    // Books stack — top-left area
    _placeFurniture('$p/catrin-books-1.png', Vector2(40, 50), Vector2(131, 104));
    // Table/desk — left side, vertical (Pero goes under, Gary blocked)
    _placeDesk('$p/catrin-table.png', Vector2(40, 230), Vector2(234, 430));
    // Books upright — on desk (priority 3, above desk's 2)
    _placeDeskItem('$p/catrin-books.png', Vector2(55, 280), Vector2(56, 109));
    // Computer, keyboard, mouse — on top of desk (priority 3, above desk's 2)
    _placeDeskItem('$p/catrin-computer.png', Vector2(110, 270), Vector2(83, 179));
    _placeDeskItem('$p/catrin-keyboard.png', Vector2(110, 460), Vector2(44, 93));
    _placeDeskItem('$p/catrin-mouse.png', Vector2(170, 490), Vector2(39, 33));
  }

  /// Abi's bedroom furniture — room origin (1090, 0), 735×752.
  void _addAbiFurniture() {
    const p = 'games/letter_quest/abi-bedroom';
    final ox = HouseRoomConfig.catrinWidth; // 1090
    // Night stand — right of bed (solid)
    _placeSolidFurniture('$p/abi-night-stand-2.png', Vector2(ox + 315, 40), Vector2(120, 101));
    // Items on night stand — images have transparent padding, so origin is offset left/up
    // to place the visible clock on the left half and the vase on the right half of the stand.
    _placeFurniture('$p/abi-clock.png', Vector2(ox + 279, 40), Vector2(127, 78));
    _placeFurniture('$p/abi-vase.png', Vector2(ox + 338, 28), Vector2(115, 89));
    _placeFurniture('$p/abi-table-lamp.png', Vector2(ox + 331, 42), Vector2(72, 69));
    _placeFurniture('$p/abi-Pencil.png', Vector2(ox + 380, 60), Vector2(19, 50));
    // Toybox — top-right corner, against right wall (decorative)
    const toyW = 180.0;
    const toyH = toyW * (654.0 / 803.0);
    _placeFurniture('games/letter_quest/bungalow/livingroom/toybox.png',
        Vector2(HouseRoomConfig.mapWidth - HouseRoomConfig.wallThickness - toyW - 5,
            HouseRoomConfig.wallThickness + 5),
        Vector2(toyW, toyH));
    // Bed — against central wall (jumpable)
    _placeBed('$p/abi-single-bed-messy-duvet.png', Vector2(ox + 20, 50), Vector2(289, 495));
    // Shoes
    _placeFurniture('$p/abi-shoe-left.png', Vector2(ox + 140, 570), Vector2(50, 40));
    _placeFurniture('$p/abi-Shoe Right.png', Vector2(ox + 360, 380), Vector2(32, 50));
    // Chair — in front of desk, tucked in (solid)
    _placeSolidFurniture('$p/abi-chair.png', Vector2(ox + 486, 370), Vector2(207, 206));
    // Desk — bottom-right, flush against bottom wall (Pero goes under, Gary blocked)
    _placeDesk('$p/abi-desk.png', Vector2(ox + 321, 450), Vector2(372, 302));
  }

  /// Bathroom furniture — room origin (0, 912), 700×851.
  void _addBathroomFurniture() {
    const p = 'games/letter_quest/bathroom';
    final oy = HouseRoomConfig.bottomRowTop; // 912
    // Shower tray — top-right, against shifted wall
    _placeFurniture('$p/shower-tray.png', Vector2(494, oy + 40), Vector2(231, 232));
    // Bath mat — center-left
    _placeFurniture('$p/bath-mat 1.png', Vector2(100, oy + 200), Vector2(227, 313));
    // Bath — right side, against shifted wall (solid)
    _placeSolidFurniture('$p/bath-image.png', Vector2(494, oy + 240), Vector2(239, 585));
    // Toilet — bottom-left, flush against left and bottom walls (solid)
    _placeSolidFurniture('$p/toilet-image.png',
        Vector2(HouseRoomConfig.wallThickness,
            oy + HouseRoomConfig.bottomRowHeight - HouseRoomConfig.wallThickness - 218),
        Vector2(136, 218));
    // Sink — bottom-center, flush against bottom wall (solid)
    _placeSolidFurniture('$p/sink-image.png',
        Vector2(280,
            oy + HouseRoomConfig.bottomRowHeight - HouseRoomConfig.wallThickness - 163),
        Vector2(201, 163));
  }

  /// Mum & Dad's bedroom furniture — room origin (700, 912), 1125×851.
  void _addMumDadFurniture() {
    const p = 'games/letter_quest/mum-dad-bedroom';
    final ox = HouseRoomConfig.bathroomWidth; // 700
    final oy = HouseRoomConfig.bottomRowTop; // 912
    // Rug — center, under bed area
    _placeFurniture('$p/md-rug.png', Vector2(ox + 200, oy + 380), Vector2(621, 408));
    // Bed — center, foot against lower wall (jumpable)
    _placeBed('$p/md-bed.png',
        Vector2(ox + 240, oy + HouseRoomConfig.bottomRowHeight - HouseRoomConfig.wallThickness - 577),
        Vector2(496, 577));
    // Plant — top-right, left of wardrobe
    _placeFurniture('$p/md-plant.png', Vector2(ox + 784, oy + 30), Vector2(151, 145));
    // Wardrobe left — right side, upper (solid)
    _placeSolidFurniture('$p/md-wardrobe-1.png', Vector2(ox + 940, oy + 50), Vector2(158, 333));
    // Wardrobe right — right side, lower (solid)
    _placeSolidFurniture('$p/md-wardrobe-2.png', Vector2(ox + 940, oy + 400), Vector2(158, 333));
    // Side table left — bottom-left (solid)
    _placeSolidFurniture('$p/md-table-1.png', Vector2(ox + 50, oy + 660), Vector2(186, 149));
    // Side table right — against bottom wall, next to bed (solid)
    _placeSolidFurniture('$p/md-table-2.png',
        Vector2(ox + 736, oy + HouseRoomConfig.bottomRowHeight - HouseRoomConfig.wallThickness - 107),
        Vector2(128, 107));
  }

  // ── Outer walls ───────────────────────────────────────────────────────

  void _addOuterWalls() {
    const w = HouseRoomConfig.mapWidth;
    const h = HouseRoomConfig.mapHeight;
    const t = HouseRoomConfig.wallThickness;

    _addTiledWall(wallPos: Vector2(0, 0), wallSize: Vector2(w, t));
    _addTiledWall(wallPos: Vector2(0, h - t), wallSize: Vector2(w, t));
    _addTiledWall(
        wallPos: Vector2(0, 0), wallSize: Vector2(t, h), isVertical: true);
    _addTiledWall(
        wallPos: Vector2(w - t, 0), wallSize: Vector2(t, h), isVertical: true);
  }

  // ── Internal walls ────────────────────────────────────────────────────

  /// Solid vertical wall between Catrin's and Abi's bedrooms (no doorway).
  void _addCatrinAbiWall() {
    const x = HouseRoomConfig.catrinWidth - HouseRoomConfig.wallThickness / 2;
    const t = HouseRoomConfig.wallThickness;
    const h = HouseRoomConfig.topRowHeight;
    _addTiledWall(
      wallPos: Vector2(x, t),
      wallSize: Vector2(t, h - t),
      isVertical: true,
    );
  }

  /// Horizontal wall between the top rooms and the landing.
  void _addTopLandingWall() {
    const y = HouseRoomConfig.topRowHeight;
    const t = HouseRoomConfig.wallThickness;
    const d = HouseRoomConfig.doorwayWidth;
    const w = HouseRoomConfig.mapWidth;

    final doors = [HouseRoomConfig.catrinDoorX, HouseRoomConfig.abiDoorX];
    _addHorizontalWallWithDoorways(y: y, totalWidth: w, doorCenters: doors, t: t, d: d);
  }

  /// Horizontal wall between the landing and the bottom rooms.
  void _addBottomLandingWall() {
    final y = HouseRoomConfig.bottomRowTop;
    const t = HouseRoomConfig.wallThickness;
    const d = HouseRoomConfig.doorwayWidth;
    const w = HouseRoomConfig.mapWidth;

    final doors = [HouseRoomConfig.bathroomDoorX, HouseRoomConfig.mumDadDoorX];
    _addHorizontalWallWithDoorways(y: y, totalWidth: w, doorCenters: doors, t: t, d: d);
  }

  /// Solid vertical wall between the bathroom and mum & dad's bedroom (no doorway).
  /// Shifted 64px right from the nominal bathroomWidth boundary.
  void _addBathroomMumDadWall() {
    const x = HouseRoomConfig.bathroomWidth + 64 - HouseRoomConfig.wallThickness / 2;
    final topY = HouseRoomConfig.bottomRowTop + HouseRoomConfig.wallThickness;
    final botY = HouseRoomConfig.mapHeight - HouseRoomConfig.wallThickness;
    const t = HouseRoomConfig.wallThickness;
    _addTiledWall(
      wallPos: Vector2(x, topY),
      wallSize: Vector2(t, botY - topY),
      isVertical: true,
    );
  }

  // ── Wall helpers ──────────────────────────────────────────────────────

  /// Adds a horizontal wall across [totalWidth] at vertical position [y],
  /// punching doorway gaps at each x in [doorCenters].
  void _addHorizontalWallWithDoorways({
    required double y,
    required double totalWidth,
    required List<double> doorCenters,
    required double t,
    required double d,
  }) {
    final sorted = List<double>.from(doorCenters)..sort();
    double segStart = 0;
    for (final doorX in sorted) {
      final segEnd = doorX - d / 2;
      if (segEnd > segStart) {
        _addTiledWall(
          wallPos: Vector2(segStart, y),
          wallSize: Vector2(segEnd - segStart, t),
        );
      }
      segStart = doorX + d / 2;
    }
    if (segStart < totalWidth) {
      _addTiledWall(
        wallPos: Vector2(segStart, y),
        wallSize: Vector2(totalWidth - segStart, t),
      );
    }
  }

  void _addTiledWall({
    required Vector2 wallPos,
    required Vector2 wallSize,
    bool isVertical = false,
  }) {
    final wallSprite = Sprite(
      game.images.fromCache('games/letter_quest/wall-tile-brick.png'),
    );

    final wall = TiledWallComponent(position: wallPos, size: wallSize)
      ..add(RectangleHitbox());

    if (isVertical) {
      final tileCount = (wallSize.y / _wallTileSize).ceil();
      for (int i = 0; i < tileCount; i++) {
        wall.add(SpriteComponent(
          sprite: wallSprite,
          position: Vector2(wallSize.x / 2, i * _wallTileSize + _wallTileSize / 2),
          size: Vector2(_wallTileSize, _wallTileSize),
          anchor: Anchor.center,
          angle: pi / 2,
        ));
      }
    } else {
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
}
