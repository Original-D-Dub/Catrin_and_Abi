import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../models/bungalow_config.dart';
import 'base_letter_quest_game.dart';
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
    _addBathroomFurniture();
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
    add(_ColorRect(
      position: Vector2(t, t),
      size: Vector2(BungalowConfig.gardenW - t * 2, BungalowConfig.mapHeight - t * 2),
      color: const Color(0xFF4CAF50),
    ));
  }

  // ── Bathroom furniture ─────────────────────────────────────────────────

  void _addBathroomFurniture() {
    const p = 'games/letter_quest/bungalow/bathroom';
    const t = BungalowConfig.wallThickness;
    final bx = BungalowConfig.indoorX + BungalowConfig.bed1W + t; // 1840
    const by = t; // 40

    _placeSolidFurniture('$p/sink-image.png',
        Vector2(bx + 5, by + 5), Vector2(130, 120));
    _placeSolidFurniture('$p/toilet-image.png',
        Vector2(bx + 360 - 100 - 5, by + 5), Vector2(100, 150));
    _placeFurniture('$p/bath-mat 1.png',
        Vector2(bx + (360 - 160) / 2, by + 190), Vector2(160, 210));
    _placeFurniture('$p/shower-tray.png',
        Vector2(bx + 5, by + 600 - 160 - 5), Vector2(160, 160));
  }

  void _placeFurniture(String imageKey, Vector2 pos, Vector2 size) {
    add(SpriteComponent(
      sprite: Sprite(game.images.fromCache(imageKey)),
      position: pos,
      size: size,
    ));
  }

  void _placeSolidFurniture(String imageKey, Vector2 pos, Vector2 size) {
    final wall = TiledWallComponent(position: pos, size: size)
      ..add(RectangleHitbox())
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
    const ix = BungalowConfig.indoorX;       // 900
    const hx = BungalowConfig.hallwayX;      // 1400
    const hy = BungalowConfig.hallwayY;      // 640
    const by = BungalowConfig.bottomY;       // 840
    const mw = BungalowConfig.mapWidth;      // 2700
    const mh = BungalowConfig.mapHeight;     // 1560

    // ── Garden | Indoor vertical wall at x=900 ──────────────────────────
    // Top: Garden↔Bedroom1 (y=t .. hy)
    _vWallWithDoor(x: ix, yStart: t, yEnd: hy,
        doorCentreY: BungalowConfig.gardenBed1DoorY, d: d);
    // Bottom: Garden↔Kitchen (y=hy .. mh-t)
    _vWallWithDoor(x: ix, yStart: hy, yEnd: mh - t,
        doorCentreY: BungalowConfig.gardenKitchenDoorY, d: d);

    // ── Bedroom1 | Bathroom wall at x=1800 (top row only) ───────────────
    _tw(pos: Vector2(ix + BungalowConfig.bed1W, t),
        size: Vector2(t, hy - t), vert: true);

    // ── Bathroom | Bedroom2 wall at x=2200 (top row only) ───────────────
    _tw(pos: Vector2(ix + BungalowConfig.bed1W + BungalowConfig.bathW, t),
        size: Vector2(t, hy - t), vert: true);

    // ── Horizontal wall at y=640 ────────────────────────────────────────
    // Left section (bed1↔kitchen): x=900..1400
    _hWallWithDoors(y: hy, xStart: ix + t, xEnd: hx,
        doorCentresX: [BungalowConfig.bed1KitchenDoorX], d: d);
    // Right section (bed1/bath/bed2 ↔ hallway): x=1400..2700
    _hWallWithDoors(y: hy, xStart: hx, xEnd: mw - t,
        doorCentresX: [
          BungalowConfig.bed1HallDoorX,
          BungalowConfig.bathHallDoorX,
          BungalowConfig.bed2HallDoorX,
        ], d: d);

    // ── Kitchen | Hallway+LivingRoom vertical wall at x=1400 ────────────
    // Top section (kitchen↔hallway): y=hy..by — open archway (no wall),
    // the horizontal walls at y=640 and y=840 bound the gap.
    // Bottom section (kitchen↔livingRoom): y=by..mh
    _vWallWithDoor(x: hx, yStart: by + t, yEnd: mh - t,
        doorCentreY: BungalowConfig.kitchenLivingDoorY, d: d);

    // ── Hallway | Living Room horizontal wall at y=840 ──────────────────
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
