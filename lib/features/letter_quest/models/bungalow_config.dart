import 'dart:ui';

import 'package:flame/components.dart';

/// Rooms in the bungalow layout.
enum BungalowRoom { garden, bedroom1, bathroom, bedroom2, hallway, kitchen, livingRoom }

/// Layout for the bungalow level of Letter Quest.
///
/// Room and furniture dimensions match the Level 3 house scale
/// (Pero is 150×120 world units in every level).
///
/// ```
///  0       1400      2650  3200    3950
///  +--------+--------+------+------+ 0
///  |        |  Bed1   | Bath | Bed2 |
///  | Garden | 1250×860| 550× | 750× |
///  | 1400×  |         |  860 |  860 |
///  | 1980   +--[D]--+-[D]-+--[D]--+ 860
///  |  [D]   | Kit  [D]   Hallway    |
///  |  [D]   | 782  +[D]----[D]------+ 1180
///  |        | ×1120|   Living Room  |
///  |        |  [D] |    1768×800    |
///  +--------+------+----------------+ 1980
/// ```
class BungalowConfig {
  static const double mapWidth = 3950.0;
  static const double mapHeight = 1980.0;
  static const double wallThickness = 40.0;
  static const double doorwayWidth = 240.0;

  // ── Room dimensions ────────────────────────────────────────────────────

  static const double gardenW = 1400.0;
  static const double bed1W = 1250.0;
  static const double bathW = 550.0;
  static const double bed2W = 750.0;
  static const double kitchenW = 782.0;
  static const double kitchenH = 1120.0;
  static const double livingW = 1768.0;
  static const double livingH = 800.0;
  static const double hallwayW = 1768.0;
  static const double hallwayH = 320.0;

  static const double topRowH = 860.0;

  // ── Derived positions ──────────────────────────────────────────────────

  static const double indoorX = gardenW;                  // 1400
  static const double hallwayX = indoorX + kitchenW;      // 2100
  static const double hallwayY = topRowH;                 // 860
  static const double bottomY = hallwayY + hallwayH;      // 1180

  // ── Doorway centres (world coords) ─────────────────────────────────────

  // Vertical wall doors
  // Sits above centre so the dressing table in bedroom 1's bottom-left corner
  // leaves a full-width corridor through the door.
  static const double gardenBed1DoorY = 330.0;
  static const double gardenKitchenDoorY = kitchenHallDoorY;                // aligned with hallway
  static const double kitchenHallDoorY = hallwayY + hallwayH / 2;          // 1020
  static const double kitchenLivingDoorY = bottomY + livingH / 2;          // 1580

  // Horizontal wall doors
  static const double bed1HallDoorX = hallwayX + (indoorX + bed1W - hallwayX) / 2; // 2375
  static const double bathHallDoorX = indoorX + bed1W + bathW / 2 + 96;    // 3021
  static const double bed2HallDoorX = indoorX + bed1W + bathW + wallThickness + doorwayWidth / 2 + 20;
  static const double hallLivingDoorX = hallwayX + livingW / 2;            // 3025

  // ── Player / Gary spawn ────────────────────────────────────────────────

  static Vector2 get playerStart =>
      Vector2(hallwayX + hallwayW / 2, hallwayY + hallwayH / 2);

  static Vector2 get garyStart =>
      Vector2(gardenW * 0.75, mapHeight / 2);

  // ── Letter positions per room ──────────────────────────────────────────
  //
  // Generates a 200-unit grid across each room's inner bounds.
  // Positions that overlap solid furniture are filtered out by
  // BungalowRoomManager._safePositions via isPositionBlocked.

  static List<Vector2> letterPositionsFor(BungalowRoom room) {
    const step = 200.0;
    const margin = wallThickness + 80.0; // min clearance from each wall

    List<Vector2> grid(double x0, double y0, double x1, double y1) {
      final out = <Vector2>[];
      for (var x = x0; x <= x1; x += step) {
        for (var y = y0; y <= y1; y += step) {
          out.add(Vector2(x, y));
        }
      }
      return out;
    }

    return switch (room) {
      BungalowRoom.garden => grid(
          gardenW * 0.5, margin, gardenW - margin, mapHeight - margin),
      BungalowRoom.bedroom1 => grid(
          indoorX + margin, margin,
          indoorX + bed1W - margin, topRowH - margin),
      BungalowRoom.bathroom => grid(
          indoorX + bed1W + margin, margin,
          indoorX + bed1W + bathW - margin, topRowH - margin),
      BungalowRoom.bedroom2 => grid(
          indoorX + bed1W + bathW + margin, margin,
          mapWidth - margin, topRowH - margin),
      BungalowRoom.hallway => grid(
          hallwayX + margin, hallwayY + margin,
          mapWidth - margin, bottomY - margin),
      BungalowRoom.kitchen => grid(
          indoorX + margin, hallwayY + margin,
          hallwayX - margin, hallwayY + kitchenH - margin),
      BungalowRoom.livingRoom => grid(
          hallwayX + margin, bottomY + margin,
          mapWidth - margin, mapHeight - margin),
    };
  }

  // ── Solid furniture bounds (must mirror bungalow_room_component.dart) ──

  static List<Rect> get furnitureRects {
    const t = wallThickness;

    // ── Garden ──
    final gardenBorderW = gardenW - t * 2;
    final gardenBorderH = gardenBorderW * (240.0 / 643.0);
    const shedW = 700.0;
    const shedH = shedW * (658.0 / 1034.0);
    const shedX = t;
    const shedY = gardenKitchenDoorY - shedH / 2;
    const treeW = gardenW * 0.5;

    // ── Bathroom ──
    final bx = indoorX + bed1W + t;
    const toiletW = 148.0;
    const toiletH = 217.0;
    const tubW = 231.0;
    const tubH = tubW * 497.0 / 217.0;
    final tubY = topRowH - t - tubH;
    const matW = 163.0;
    const matH = 270.0;
    final matX = bx + tubW + 20;
    final matY = tubY + tubH / 2 - matH / 2;

    // ── Bedroom 1 ──
    const b1BedW = 500.0;
    const b1BedH = b1BedW * (627.0 / 609.0);
    const b1BedX = indoorX + (bed1W - b1BedW) / 2;
    const b1DressingTableH = 333.0;
    const b1DressingTableW = b1DressingTableH * (145.0 / 343.0);

    // ── Kitchen ──
    const kx = indoorX + t;
    const ky = hallwayY + t;
    const kh = kitchenH - t * 2;
    const leftWallW = 170.0;
    const leftWallH = 476.0;
    const counterW = 450.0;
    const counterH = 179.0;
    const kTableW = 340.0;
    const kTableH = 260.0;
    const kTableX = kx + leftWallW + (counterW - kTableW) / 2;
    const kTableY = ky + 360.0;
    const kChairW = 130.0;
    const kChairH = 72.0;
    const kBottom = ky + kh;

    // ── Living room ──
    const lx = hallwayX + t;
    const ly = bottomY + t;
    const lw = mapWidth - hallwayX - t * 2;
    const lh = mapHeight - bottomY - t * 2;
    const cx = lx + lw / 2;
    const rugW = 450.0;
    const rugH = 330.0;
    const rugX = cx - rugW / 2;
    const rugY = ly + (lh - rugH) / 2 + 140;
    const sofaW = 450.0;
    const sofaH = 183.0;
    const toyW = 320.0;
    const toyH = toyW * (654.0 / 803.0);
    const twoSeatH = 280.0 * (228.0 / 440.0);

    // ── Bedroom 2 ──
    const bed2X = indoorX + bed1W + bathW;
    const bed2Right = mapWidth - t;
    const bed2WardW = 158.0;
    const bed2WardH = 333.0;

    return [
      // ── Garden ──
      Rect.fromLTWH(shedX, shedY, shedW, shedH),
      Rect.fromLTWH(t, mapHeight - t - gardenBorderH, gardenBorderW, gardenBorderH),
      Rect.fromLTWH(t + 40, t + 40, treeW, treeW),

      // ── Bathroom ──
      Rect.fromLTWH(bx + 5, t + 5, 201, 163),
      Rect.fromLTWH(indoorX + bed1W + bathW - toiletW - 5, t + 5, toiletW, toiletH),
      Rect.fromLTWH(bx, tubY, tubW, tubH),
      Rect.fromLTWH(matX, matY, matW, matH),

      // ── Kitchen ──
      Rect.fromLTWH(kTableX, kTableY, kTableW, kTableH),
      Rect.fromLTWH(
          kTableX + (kTableW - kChairW) / 2, kTableY - kChairH, kChairW, kChairH),
      Rect.fromLTWH(kx, kBottom - leftWallH, leftWallW, leftWallH),
      Rect.fromLTWH(kx + leftWallW, kBottom - counterH, counterW, counterH),
      Rect.fromLTWH(kx + 165, ky + 2, 320, 126),
      Rect.fromLTWH(kx + 495, ky + 10, 70, 77),
      Rect.fromLTWH(kx + 5, ky + 340, 70, 105),
      Rect.fromLTWH(kx + 5, ky + 190, 100, 98),

      // ── Bedroom 1 ──
      Rect.fromLTWH(b1BedX, t + 5, b1BedW, b1BedH),
      Rect.fromLTWH(b1BedX - 150 - 8, t + 5, 150, 150 * 149 / 186),
      Rect.fromLTWH(b1BedX + b1BedW + 8, t + 5, 150, 150 * 153 / 203),
      Rect.fromLTWH(indoorX + t, topRowH - t - b1DressingTableH,
          b1DressingTableW, b1DressingTableH),
      Rect.fromLTWH(indoorX + bed1W - t - 158, t, 158, 333),
      Rect.fromLTWH(indoorX + t + 5, t + 10, 120, 120 * 145 / 151),

      // ── Bedroom 2 ──
      Rect.fromLTWH(bed2X + t + 8, t + 5, 289, 495),
      Rect.fromLTWH(bed2X + t + 8 + 289 + 8, t + 5, 120, 101),
      Rect.fromLTWH(bed2Right - bed2WardW - 5, t + 5, bed2WardW, bed2WardH),
      Rect.fromLTWH(bed2Right - 150 * 99 / 120 - 5,
          t + 5 + bed2WardH + 10, 150 * 99 / 120, 150),
      Rect.fromLTWH(bed2Right - 150 - 5,
          t + 5 + bed2WardH + 10 + 150 + 5, 150, 150 * 210 / 232),
      Rect.fromLTWH(bed2Right - 340 - 5,
          topRowH - t - 340 * 279 / 344 - 5, 340, 340 * 279 / 344),
      Rect.fromLTWH(bed2Right - 340 - 15,
          topRowH - t - 340 * 279 / 344 - 206 + 5, 207, 206),
      Rect.fromLTWH(bed2X + t + 289 + 55, 270, 32, 50),
      Rect.fromLTWH(bed2X + t + 289 + 30, 340, 50, 40),

      // ── Living room ──
      Rect.fromLTWH(rugX + (rugW - 220) / 2,
          rugY + (rugH - 220 * 177 / 358) / 2, 220, 220 * 177 / 358),
      Rect.fromLTWH(cx - sofaW / 2, rugY - sofaH - 20, sofaW, sofaH),
      Rect.fromLTWH(lx + lw - toyW, ly + lh - toyH, toyW, toyH),
      Rect.fromLTWH(rugX - twoSeatH - 42, rugY + rugH / 2 - 280 / 2,
          twoSeatH, 280),
      Rect.fromLTWH(cx - 380 / 2, ly + lh - 30, 380, 30),
      Rect.fromLTWH(rugX, rugY, rugW, rugH),
    ];
  }

  static bool isPositionBlocked(Vector2 pos) {
    const pad = 36.0;
    final point = Rect.fromCenter(
      center: Offset(pos.x, pos.y),
      width: pad * 2,
      height: pad * 2,
    );
    return furnitureRects.any((r) => r.overlaps(point));
  }

  // ── Room detection ─────────────────────────────────────────────────────

  static BungalowRoom roomAt(Vector2 p) {
    if (p.x < indoorX) return BungalowRoom.garden;
    if (p.y < hallwayY) {
      if (p.x < indoorX + bed1W) return BungalowRoom.bedroom1;
      if (p.x < indoorX + bed1W + bathW) return BungalowRoom.bathroom;
      return BungalowRoom.bedroom2;
    }
    if (p.x < hallwayX) return BungalowRoom.kitchen;
    if (p.y < bottomY) return BungalowRoom.hallway;
    return BungalowRoom.livingRoom;
  }

  // ── Pathfinding ────────────────────────────────────────────────────────

  static const Map<BungalowRoom, List<BungalowRoom>> _adjacency = {
    BungalowRoom.garden:     [BungalowRoom.bedroom1, BungalowRoom.kitchen],
    BungalowRoom.bedroom1:   [BungalowRoom.garden, BungalowRoom.hallway],
    BungalowRoom.bathroom:   [BungalowRoom.hallway],
    BungalowRoom.bedroom2:   [BungalowRoom.hallway],
    BungalowRoom.hallway:    [BungalowRoom.bedroom1, BungalowRoom.bathroom, BungalowRoom.bedroom2, BungalowRoom.kitchen, BungalowRoom.livingRoom],
    BungalowRoom.kitchen:    [BungalowRoom.garden, BungalowRoom.hallway, BungalowRoom.livingRoom],
    BungalowRoom.livingRoom: [BungalowRoom.hallway, BungalowRoom.kitchen],
  };

  static BungalowRoom nextRoomOnPath(BungalowRoom from, BungalowRoom to) {
    if (from == to) return to;
    final prev = <BungalowRoom, BungalowRoom>{};
    final queue = <BungalowRoom>[from];
    final visited = <BungalowRoom>{from};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbor in _adjacency[current]!) {
        if (visited.contains(neighbor)) continue;
        visited.add(neighbor);
        prev[neighbor] = current;
        if (neighbor == to) {
          var step = to;
          while (prev[step] != from) {
            step = prev[step]!;
          }
          return step;
        }
        queue.add(neighbor);
      }
    }
    return to;
  }

  // ── Navigation waypoints ───────────────────────────────────────────────

  static Vector2 waypointInto(BungalowRoom from, BungalowRoom to) {
    const past = wallThickness + 60.0;
    final pair = {from, to};

    // Vertical wall doorways ───────────────────────────────────────────
    if (pair.containsAll({BungalowRoom.garden, BungalowRoom.bedroom1})) {
      return to == BungalowRoom.bedroom1
          ? Vector2(indoorX + past, gardenBed1DoorY)
          : Vector2(indoorX - past, gardenBed1DoorY);
    }
    if (pair.containsAll({BungalowRoom.garden, BungalowRoom.kitchen})) {
      return to == BungalowRoom.kitchen
          ? Vector2(indoorX + past, gardenKitchenDoorY)
          : Vector2(indoorX - past, gardenKitchenDoorY);
    }
    if (pair.containsAll({BungalowRoom.kitchen, BungalowRoom.hallway})) {
      return to == BungalowRoom.hallway
          ? Vector2(hallwayX + past, kitchenHallDoorY)
          : Vector2(hallwayX - past, kitchenHallDoorY);
    }
    if (pair.containsAll({BungalowRoom.kitchen, BungalowRoom.livingRoom})) {
      return to == BungalowRoom.livingRoom
          ? Vector2(hallwayX + past, kitchenLivingDoorY)
          : Vector2(hallwayX - past, kitchenLivingDoorY);
    }

    // Horizontal wall doorways ─────────────────────────────────────────
    if (pair.containsAll({BungalowRoom.bedroom1, BungalowRoom.hallway})) {
      return to == BungalowRoom.hallway
          ? Vector2(bed1HallDoorX, hallwayY + past)
          : Vector2(bed1HallDoorX, hallwayY - past);
    }
    if (pair.containsAll({BungalowRoom.bathroom, BungalowRoom.hallway})) {
      return to == BungalowRoom.hallway
          ? Vector2(bathHallDoorX, hallwayY + past)
          : Vector2(bathHallDoorX, hallwayY - past);
    }
    if (pair.containsAll({BungalowRoom.bedroom2, BungalowRoom.hallway})) {
      return to == BungalowRoom.hallway
          ? Vector2(bed2HallDoorX, hallwayY + past)
          : Vector2(bed2HallDoorX, hallwayY - past);
    }
    if (pair.containsAll({BungalowRoom.hallway, BungalowRoom.livingRoom})) {
      return to == BungalowRoom.livingRoom
          ? Vector2(hallLivingDoorX, bottomY + past)
          : Vector2(hallLivingDoorX, bottomY - past);
    }

    return Vector2.zero();
  }

  static Vector2 doorwayCenter(BungalowRoom a, BungalowRoom b) {
    final pair = {a, b};
    if (pair.containsAll({BungalowRoom.garden, BungalowRoom.bedroom1})) {
      return Vector2(indoorX, gardenBed1DoorY);
    }
    if (pair.containsAll({BungalowRoom.garden, BungalowRoom.kitchen})) {
      return Vector2(indoorX, gardenKitchenDoorY);
    }
    if (pair.containsAll({BungalowRoom.kitchen, BungalowRoom.hallway})) {
      return Vector2(hallwayX, kitchenHallDoorY);
    }
    if (pair.containsAll({BungalowRoom.kitchen, BungalowRoom.livingRoom})) {
      return Vector2(hallwayX, kitchenLivingDoorY);
    }
    if (pair.containsAll({BungalowRoom.bedroom1, BungalowRoom.hallway})) {
      return Vector2(bed1HallDoorX, hallwayY);
    }
    if (pair.containsAll({BungalowRoom.bathroom, BungalowRoom.hallway})) {
      return Vector2(bathHallDoorX, hallwayY);
    }
    if (pair.containsAll({BungalowRoom.bedroom2, BungalowRoom.hallway})) {
      return Vector2(bed2HallDoorX, hallwayY);
    }
    if (pair.containsAll({BungalowRoom.hallway, BungalowRoom.livingRoom})) {
      return Vector2(hallLivingDoorX, bottomY);
    }
    return Vector2.zero();
  }

  // ── Category → room mapping (for Level 5 letter placement) ───────────────

  /// Returns the rooms that match a word's [category] from the Supabase table.
  /// Returns an empty list for unknown or null categories.
  /// "bedroom" maps to both bedrooms so letters spread between them.
  static List<BungalowRoom> categoryRooms(String? category) {
    if (category == null) return [];
    switch (category.toLowerCase()) {
      case 'bedroom':
        return [BungalowRoom.bedroom1, BungalowRoom.bedroom2];
      case 'bathroom':
        return [BungalowRoom.bathroom];
      case 'kitchen':
        return [BungalowRoom.kitchen];
      case 'garden':
        return [BungalowRoom.garden];
      case 'livingroom':
      case 'living':
        return [BungalowRoom.livingRoom];
      default:
        return [];
    }
  }

  static bool isDoorwayVertical(BungalowRoom a, BungalowRoom b) {
    final pair = {a, b};
    return pair.containsAll({BungalowRoom.garden, BungalowRoom.bedroom1}) ||
        pair.containsAll({BungalowRoom.garden, BungalowRoom.kitchen}) ||
        pair.containsAll({BungalowRoom.kitchen, BungalowRoom.hallway}) ||
        pair.containsAll({BungalowRoom.kitchen, BungalowRoom.livingRoom});
  }
}
