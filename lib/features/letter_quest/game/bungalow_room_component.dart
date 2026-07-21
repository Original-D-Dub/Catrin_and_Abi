import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../models/bungalow_config.dart';
import 'base_letter_quest_game.dart';
import 'desk_component.dart';
import 'simple_room_component.dart';

/// Renders the bungalow floor plan for Letter Quest Level 5.
class BungalowRoomComponent extends PositionComponent
    with HasGameReference<BaseLetterQuestGame> {
  static const double _floorTileSize = 80.0;
  static const double _wallTileSize = 40.0;

  BungalowRoomComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(BungalowConfig.mapWidth, BungalowConfig.mapHeight),
        );

  @override
  Future<void> onLoad() async {
    _addTiledFloor();
    _addGardenFill();
    _addGardenShedAndPath();
    _addGardenBorder();
    _addBedroom1Furniture();
    _addBedroom2Furniture();
    _addBathroomFurniture();
    _addKitchenFurniture();
    _addLivingRoomFurniture();
    _addOuterWalls();
    _addInternalWalls();
  }

  // ── Floor ──────────────────────────────────────────────────────────────

  void _addTiledFloor() {
    final floorImage =
        game.images.fromCache('games/letter_quest/floor-tile-wood-pale.png');
    final sprite = Sprite(floorImage);
    final cols = (BungalowConfig.mapWidth / _floorTileSize).ceil();
    final rows = (BungalowConfig.mapHeight / _floorTileSize).ceil();
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

  void _addGardenFill() {
    const t = BungalowConfig.wallThickness;
    final grassImage =
        game.images.fromCache('games/letter_quest/bungalow/garden/Grass.jpg');
    final sprite = Sprite(grassImage);
    final w = BungalowConfig.gardenW - t * 2;
    final h = BungalowConfig.mapHeight - t * 2;
    final cols = (w / _floorTileSize).ceil();
    final rows = (h / _floorTileSize).ceil();
    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        add(SpriteComponent(
          sprite: sprite,
          position: Vector2(t + col * _floorTileSize, t + row * _floorTileSize),
          size: Vector2(_floorTileSize, _floorTileSize),
        ));
      }
    }
  }

  // ── Garden furniture ───────────────────────────────────────────────────

  void _addGardenBorder() {
    const t = BungalowConfig.wallThickness;
    final borderW = BungalowConfig.gardenW - t * 2;
    final borderH = borderW * (240.0 / 643.0);
    _placeSolidFurniture(
      'games/letter_quest/bungalow/garden/gardenborder.jpg',
      Vector2(t, BungalowConfig.mapHeight - t - borderH),
      Vector2(borderW, borderH),
    );
  }

  void _addGardenShedAndPath() {
    const t = BungalowConfig.wallThickness;
    const p = 'games/letter_quest/bungalow/garden';
    const doorY = BungalowConfig.gardenKitchenDoorY;

    // Shed against left wall, centred on doorway height
    const shedW = 700.0;
    const shedH = shedW * (658.0 / 1034.0);
    const shedX = t;
    const shedY = doorY - shedH / 2;
    _placeSolidFurniture('$p/shed2.png',
        Vector2(shedX, shedY), Vector2(shedW, shedH));

    // Tiled path from shed to doorway, 128px wide
    const pathTile = 64.0;
    const pathH = 128.0;
    final pathStartX = shedX + shedW;
    const pathY = doorY - pathH / 2;
    final pathEndX = BungalowConfig.indoorX;
    final pathSprite = Sprite(
      game.images.fromCache('$p/path.jpg'),
    );
    final cols = ((pathEndX - pathStartX) / pathTile).ceil();
    final rows = (pathH / pathTile).toInt();
    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        add(SpriteComponent(
          sprite: pathSprite,
          position: Vector2(pathStartX + col * pathTile, pathY + row * pathTile),
          size: Vector2(pathTile, pathTile),
        ));
      }
    }

    // Doorsteps (rendered above path)
    const doorW = BungalowConfig.doorwayWidth;
    const stepDepth = t + 8.0;
    const stepColor = Color(0xFFBDBDBD);

    // Kitchen-garden doorstep
    add(_ColorRect(
      position: Vector2(BungalowConfig.indoorX - 8, doorY - doorW / 2),
      size: Vector2(stepDepth, doorW),
      color: stepColor,
    )..priority = 1);

    // Bedroom-garden doorstep
    add(_ColorRect(
      position: Vector2(BungalowConfig.indoorX - 8,
          BungalowConfig.gardenBed1DoorY - doorW / 2),
      size: Vector2(stepDepth, doorW),
      color: stepColor,
    )..priority = 1);
  }

  // ── Bedroom 1 furniture ────────────────────────────────────────────────

  void _addBedroom1Furniture() {
    const p = 'games/letter_quest/bungalow/bedroom';
    const md = 'games/letter_quest/mum-dad-bedroom';
    const t = BungalowConfig.wallThickness;
    const ix = BungalowConfig.indoorX;

    // Bed — double bed centred against top wall (solid, house scale)
    const bedW = 500.0;
    const bedH = bedW * (627.0 / 609.0);
    _placeSolidFurniture('$p/bed.png',
        Vector2(ix + (BungalowConfig.bed1W - bedW) / 2, t + 5),
        Vector2(bedW, bedH));

    // Left bedside table (solid)
    const t1W = 150.0;
    const t1H = t1W * (149.0 / 186.0);
    _placeSolidFurniture('$md/md-table-1.png',
        Vector2(ix + (BungalowConfig.bed1W - bedW) / 2 - t1W - 8, t + 5),
        Vector2(t1W, t1H));

    // Right bedside table (decorative)
    const t2W = 150.0;
    const t2H = t2W * (153.0 / 203.0);
    _placeFurniture('$md/md-table-2.png',
        Vector2(ix + (BungalowConfig.bed1W + bedW) / 2 + 8, t + 5),
        Vector2(t2W, t2H));

    // Dressing table — bottom-left corner, flush against left & bottom walls (solid)
    const dtH = 333.0;
    const dtW = dtH * (145.0 / 343.0);
    _placeSolidFurniture('$p/dressing-table.png',
        Vector2(ix + t, BungalowConfig.topRowH - t - dtH),
        Vector2(dtW, dtH));

    // Right wardrobe — flush against right & top walls (solid)
    const wW = 158.0;
    const wH = 333.0;
    _placeSolidFurniture('$md/md-wardrobe-1.png',
        Vector2(ix + BungalowConfig.bed1W - t - wW, t),
        Vector2(wW, wH));

    // Plant — top-left corner (decorative)
    const plW = 120.0;
    const plH = plW * (145.0 / 151.0);
    _placeFurniture('$md/md-plant.png',
        Vector2(ix + t + 5, t + 10),
        Vector2(plW, plH));
  }

  // ── Bedroom 2 furniture ────────────────────────────────────────────────

  void _addBedroom2Furniture() {
    const abi = 'games/letter_quest/abi-bedroom';
    const md = 'games/letter_quest/mum-dad-bedroom';
    const p = 'games/letter_quest/bungalow/bedroom';
    const t = BungalowConfig.wallThickness;
    const bed2X =
        BungalowConfig.indoorX + BungalowConfig.bed1W + BungalowConfig.bathW;
    const roomRight = BungalowConfig.mapWidth - t;

    // Bed — top-left corner (solid)
    const bedW = 289.0;
    const bedH = 495.0;
    _placeSolidFurniture('$abi/abi-single-bed-messy-duvet.png',
        Vector2(bed2X + t + 8, t + 5), Vector2(bedW, bedH));

    // Nightstand — right of bed headboard (solid)
    const nsW = 120.0;
    const nsH = 101.0;
    _placeSolidFurniture('$abi/abi-night-stand-1.png',
        Vector2(bed2X + t + 8 + bedW + 8, t + 5), Vector2(nsW, nsH));

    // Wardrobe — right wall, top area (solid, same size as mum & dad's room)
    const wW = 158.0;
    const wH = 333.0;
    _placeSolidFurniture('$md/md-wardrobe-1.png',
        Vector2(roomRight - wW - 5, t + 5), Vector2(wW, wH));

    // Dog bed — below wardrobe, against right wall (decorative)
    const dbH = 150.0;
    const dbW = dbH * (99.0 / 120.0);
    _placeFurniture('$p/dogbed.png',
        Vector2(roomRight - dbW - 5, t + 5 + wH + 10),
        Vector2(dbW, dbH));

    // Pile of clothes — against right wall, below dog bed (decorative)
    const clothesW = 150.0;
    const clothesH = clothesW * (210.0 / 232.0);
    _placeFurniture('$p/pile-clothes.png',
        Vector2(roomRight - clothesW - 5, t + 5 + wH + 10 + dbH + 5),
        Vector2(clothesW, clothesH));

    // Desk — bottom-right corner (Pero walks under, Gary blocked)
    const deskW = 340.0;
    const deskH = deskW * (279.0 / 344.0);
    _placeDesk('$abi/abi-desk.png',
        Vector2(roomRight - deskW - 5, BungalowConfig.topRowH - t - deskH - 5),
        Vector2(deskW, deskH));

    // Chair — above desk (decorative)
    const chW = 207.0;
    const chH = 206.0;
    _placeFurniture('$abi/abi-chair.png',
        Vector2(
            roomRight - deskW - 15, BungalowConfig.topRowH - t - deskH - chH + 5),
        Vector2(chW, chH));

    // Shoes — scattered on floor (decorative)
    const rsW = 32.0;
    const rsH = 50.0;
    _placeFurniture('$abi/abi-Shoe Right.png',
        Vector2(bed2X + t + bedW + 55, 270), Vector2(rsW, rsH));

    const lsW = 50.0;
    const lsH = 40.0;
    _placeFurniture('$abi/abi-shoe-left.png',
        Vector2(bed2X + t + bedW + 30, 340), Vector2(lsW, lsH));
  }

  // ── Bathroom furniture ─────────────────────────────────────────────────

  void _addBathroomFurniture() {
    const p = 'games/letter_quest/bungalow/bathroom';
    const t = BungalowConfig.wallThickness;
    final bx = BungalowConfig.indoorX + BungalowConfig.bed1W + t; // 2690
    const bathRight = BungalowConfig.indoorX +
        BungalowConfig.bed1W +
        BungalowConfig.bathW; // 3200
    const by = t; // 40

    const toiletW = 148.0;
    const toiletH = 217.0;

    // Bath is the same width as the old shower tray; height keeps the
    // source image's aspect ratio (217×497).
    const tubW = 231.0;
    const tubH = tubW * 497.0 / 217.0;
    final tubX = bx;
    final tubY = BungalowConfig.topRowH - t - tubH;

    const matW = 163.0;
    const matH = 270.0;
    final matX = tubX + tubW + 20;
    final matY = tubY + tubH / 2 - matH / 2;

    _placeSolidFurniture('$p/sink-image.png',
        Vector2(bx + 5, by + 5), Vector2(201, 163));
    _placeSolidFurniture('$p/toilet.png',
        Vector2(bathRight - toiletW - 5, by + 5), Vector2(toiletW, toiletH));
    _placeSolidFurniture('$p/bath.png',
        Vector2(tubX, tubY), Vector2(tubW, tubH));
    _placeFurniture('$p/bathmat.png',
        Vector2(matX, matY), Vector2(matW, matH));
  }

  // ── Living room furniture ───────────────────────────────────────────────

  void _addLivingRoomFurniture() {
    const p = 'games/letter_quest/bungalow/livingroom';
    const t = BungalowConfig.wallThickness;
    const lx = BungalowConfig.hallwayX + t;
    const ly = BungalowConfig.bottomY + t;
    const lw = BungalowConfig.mapWidth - BungalowConfig.hallwayX - t * 2;
    const lh = BungalowConfig.mapHeight - BungalowConfig.bottomY - t * 2;
    const cx = lx + lw / 2;

    // TV — centred against bottom wall (walk-over)
    const tvW = 380.0;
    const tvH = 30.0;
    _placeFurniture('$p/TV.png',
        Vector2(cx - tvW / 2, ly + lh - tvH), Vector2(tvW, tvH));

    // Rug — centred in room (decorative)
    const rugW = 450.0;
    const rugH = 330.0;
    const rugX = cx - rugW / 2;
    const rugY = ly + (lh - rugH) / 2 + 140;
    _placeFurniture('$p/living-room-rug.jpg',
        Vector2(rugX, rugY), Vector2(rugW, rugH));

    // Coffee table — centred on rug (solid, new aspect ratio 358:177)
    const tableW = 220.0;
    const tableH = tableW * (177.0 / 358.0);
    _placeSolidFurniture('$p/coffeetable.png',
        Vector2(rugX + (rugW - tableW) / 2, rugY + (rugH - tableH) / 2),
        Vector2(tableW, tableH));

    // 4-seater sofa — centred horizontally, overlapping rug top by 32px (solid)
    const sofaW = 450.0;
    const sofaH = 183.0;
    _placeSolidFurniture('$p/4seater-pale-blue.png',
        Vector2(cx - sofaW / 2, rugY - sofaH - 20), Vector2(sofaW, sofaH));

    // Toybox — bottom-right corner (solid)
    const toyW = 320.0;
    const toyH = toyW * (654.0 / 803.0);
    _placeSolidFurniture('$p/toybox.png',
        Vector2(lx + lw - toyW, ly + lh - toyH), Vector2(toyW, toyH));

    // 2-seater sofa — left of rug, rotated 90° facing right (solid)
    const twoSeatW = 280.0;
    const twoSeatH = twoSeatW * (228.0 / 440.0);
    _placeRotatedSolidFurniture('$p/2seater-pale-blue.png',
        Vector2(rugX - twoSeatH - 42 + twoSeatH / 2,
            rugY + rugH / 2),
        Vector2(twoSeatW, twoSeatH),
        angle: -pi / 2);
  }

  // ── Kitchen furniture ───────────────────────────────────────────────────

  void _addKitchenFurniture() {
    const p = 'games/letter_quest/bungalow/kitchen';
    const t = BungalowConfig.wallThickness;
    const kx = BungalowConfig.indoorX + t;
    const ky = BungalowConfig.hallwayY + t;
    const kh = BungalowConfig.kitchenH - t * 2;
    const leftWallW = 170.0;
    const leftWallH = 476.0;
    const counterW = 450.0;
    const counterH = 179.0;

    // Decorative (walk-over) — coats and crocks along the top wall,
    // wellies and dog food on the left wall below the garden door
    _placeFurniture('$p/coats.png',
        Vector2(kx + 165, ky + 2), Vector2(320, 126));
    _placeFurniture('$p/crocks.png',
        Vector2(kx + 495, ky + 10), Vector2(70, 77));
    _placeFurniture('$p/wellies1.png',
        Vector2(kx + 5, ky + 340), Vector2(70, 105));
    _placeFurniture('$p/dogfood.png',
        Vector2(kx + 5, ky + 190), Vector2(100, 98));

    // Table — centred horizontally on the oak counter top
    const tableW = 340.0;
    const tableH = 260.0;
    const tableX = kx + leftWallW + (counterW - tableW) / 2;
    const tableY = ky + 360.0;
    _placeSolidFurniture('$p/table.png',
        Vector2(tableX, tableY), Vector2(tableW, tableH));

    // Chair butted against top edge of table, centred
    const chairW = 130.0;
    const chairH = 72.0;
    _placeSolidFurniture('$p/kitchen-chair.png',
        Vector2(tableX + (tableW - chairW) / 2, tableY - chairH),
        Vector2(chairW, chairH));

    // Bottom: left-wall and oak-counter side by side, bottom edges aligned
    const bottomEdge = ky + kh;
    _placeSolidFurniture('$p/left-wall.png',
        Vector2(kx, bottomEdge - leftWallH), Vector2(leftWallW, leftWallH));
    _placeSolidFurniture('$p/oak-counter-top.png',
        Vector2(kx + leftWallW, bottomEdge - counterH),
        Vector2(counterW, counterH));
  }

  void _placeDesk(String imageKey, Vector2 pos, Vector2 size) {
    final desk = DeskComponent(position: pos, size: size)
      ..add(RectangleHitbox())
      ..add(SpriteComponent(
        sprite: Sprite(game.images.fromCache(imageKey)),
        size: size,
      ));
    parent!.add(desk);
  }

  void _placeFurniture(String imageKey, Vector2 pos, Vector2 size) {
    add(SpriteComponent(
      sprite: Sprite(game.images.fromCache(imageKey)),
      position: pos,
      size: size,
    ));
  }

  void _placeRotatedSolidFurniture(String imageKey, Vector2 pos, Vector2 size,
      {required double angle}) {
    final hitSize = Vector2(size.y, size.x);
    final inset = hitSize * 0.05;
    final wall = TiledWallComponent(position: pos, size: hitSize)
      ..anchor = Anchor.center;
    add(wall..add(RectangleHitbox(
      position: inset,
      size: hitSize - inset * 2,
    )));
    add(SpriteComponent(
      sprite: Sprite(game.images.fromCache(imageKey)),
      position: pos,
      size: size,
      anchor: Anchor.center,
      angle: angle,
    ));
  }

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

  // ── Outer walls ────────────────────────────────────────────────────────

  void _addOuterWalls() {
    const w = BungalowConfig.mapWidth;
    const h = BungalowConfig.mapHeight;
    const t = BungalowConfig.wallThickness;
    _tw(pos: Vector2(0, 0), size: Vector2(w, t));
    _tw(pos: Vector2(0, h - t), size: Vector2(w, t));
    _tw(pos: Vector2(0, 0), size: Vector2(t, h), vert: true);
    _tw(pos: Vector2(w - t, 0), size: Vector2(t, h), vert: true);
  }

  // ── Internal walls ─────────────────────────────────────────────────────

  void _addInternalWalls() {
    const t = BungalowConfig.wallThickness;
    const d = BungalowConfig.doorwayWidth;
    const ix = BungalowConfig.indoorX;       // 1400
    const hx = BungalowConfig.hallwayX;      // 2100
    const hy = BungalowConfig.hallwayY;      // 860
    const by = BungalowConfig.bottomY;       // 1180
    const mw = BungalowConfig.mapWidth;      // 3950
    const mh = BungalowConfig.mapHeight;     // 1920

    // ── Garden | Indoor vertical wall at x=1400 ─────────────────────────
    // Top: Garden↔Bedroom1 (y=t .. hy)
    _vWallWithDoor(x: ix, yStart: t, yEnd: hy,
        doorCentreY: BungalowConfig.gardenBed1DoorY, d: d);
    // Bottom: Garden↔Kitchen (y=hy .. mh-t)
    _vWallWithDoor(x: ix, yStart: hy, yEnd: mh - t,
        doorCentreY: BungalowConfig.gardenKitchenDoorY, d: d);

    // ── Bedroom1 | Bathroom wall at x=2650 (top row only) ───────────────
    _tw(pos: Vector2(ix + BungalowConfig.bed1W, t),
        size: Vector2(t, hy - t), vert: true);

    // ── Bathroom | Bedroom2 wall at x=3200 (top row only) ───────────────
    _tw(pos: Vector2(ix + BungalowConfig.bed1W + BungalowConfig.bathW, t),
        size: Vector2(t, hy - t), vert: true);

    // ── Horizontal wall at y=860 ────────────────────────────────────────
    // Left section (bed1↔kitchen): solid wall, no doorway
    _tw(pos: Vector2(ix + t, hy), size: Vector2(hx - ix - t, t));
    // Right section (bed1/bath/bed2 ↔ hallway): x=hallwayX..3950
    _hWallWithDoors(y: hy, xStart: hx, xEnd: mw - t,
        doorCentresX: [
          BungalowConfig.bed1HallDoorX,
          BungalowConfig.bathHallDoorX,
          BungalowConfig.bed2HallDoorX,
        ], d: d);

    // ── Kitchen | Hallway+LivingRoom vertical wall at x=2100 ────────────
    // Top section (kitchen↔hallway): y=hy..by — open archway (no wall),
    // the horizontal walls at y=860 and y=1180 bound the gap.
    // Bottom section (kitchen↔livingRoom): y=by..mh
    _vWallWithDoor(x: hx, yStart: by + t, yEnd: mh - t,
        doorCentreY: BungalowConfig.kitchenLivingDoorY, d: d);

    // ── Hallway | Living Room horizontal wall at y=1180 ─────────────────
    _hWallWithDoors(y: by, xStart: hx + t, xEnd: mw - t,
        doorCentresX: [BungalowConfig.hallLivingDoorX], d: d);
  }

  // ── Wall helpers ───────────────────────────────────────────────────────

  void _tw({required Vector2 pos, required Vector2 size, bool vert = false}) {
    final wallSprite = Sprite(
      game.images.fromCache('games/letter_quest/wall-tile-brick.png'),
    );
    final wall = TiledWallComponent(position: pos, size: size)
      ..add(RectangleHitbox());
    if (vert) {
      final count = (size.y / _wallTileSize).ceil();
      for (int i = 0; i < count; i++) {
        wall.add(SpriteComponent(
          sprite: wallSprite,
          position: Vector2(size.x / 2, i * _wallTileSize + _wallTileSize / 2),
          size: Vector2(_wallTileSize, _wallTileSize),
          anchor: Anchor.center,
          angle: pi / 2,
        ));
      }
    } else {
      final count = (size.x / _wallTileSize).ceil();
      for (int i = 0; i < count; i++) {
        wall.add(SpriteComponent(
          sprite: wallSprite,
          position: Vector2(i * _wallTileSize, 0),
          size: Vector2(_wallTileSize, _wallTileSize),
        ));
      }
    }
    add(wall);
  }

  void _hWallWithDoors({
    required double y,
    required double xStart,
    required double xEnd,
    required List<double> doorCentresX,
    required double d,
  }) {
    const t = BungalowConfig.wallThickness;
    final sorted = List<double>.from(doorCentresX)..sort();
    double seg = xStart;
    for (final cx in sorted) {
      final gapStart = cx - d / 2;
      if (gapStart > seg) {
        _tw(pos: Vector2(seg, y), size: Vector2(gapStart - seg, t));
      }
      seg = cx + d / 2;
    }
    if (seg < xEnd) {
      _tw(pos: Vector2(seg, y), size: Vector2(xEnd - seg, t));
    }
  }

  void _vWallWithDoor({
    required double x,
    required double yStart,
    required double yEnd,
    required double doorCentreY,
    required double d,
  }) {
    const t = BungalowConfig.wallThickness;
    final gapStart = doorCentreY - d / 2;
    final gapEnd = doorCentreY + d / 2;
    if (gapStart > yStart) {
      _tw(pos: Vector2(x, yStart), size: Vector2(t, gapStart - yStart), vert: true);
    }
    if (gapEnd < yEnd) {
      _tw(pos: Vector2(x, gapEnd), size: Vector2(t, yEnd - gapEnd), vert: true);
    }
  }
}

class _ColorRect extends PositionComponent {
  final Color color;
  _ColorRect({required super.position, required super.size, required this.color});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
  }
}

