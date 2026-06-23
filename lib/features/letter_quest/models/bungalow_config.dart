import 'package:flame/components.dart';

/// Rooms in the bungalow layout.
enum BungalowRoom { garden, bedroom1, bathroom, bedroom2, hallway, kitchen, livingRoom }

/// Layout for the bungalow level of Letter Quest.
///
/// ```
///  0       900  1400  1800     2200     2700
///  +-------+----+-----+--------+-------+ 0
///  |       |    Bed1   | Bath   | Bed2  |
///  | Garden|   900×640 | 400×640| 500×640|
///  | 900×  |           |        |       |
///  | 1560  +--[D]-+[D]-+--[D]--+--[D]--+ 640
///  |  [D]  | Kit [D]     Hallway        |
///  |  [D]  | 500 +[D]-------[D]---------+ 840
///  |       | ×920|     Living Room      |
///  |       |  [D]D      1300×720        |
///  +-------+-----+---------------------+ 1560
/// ```
class BungalowConfig {
  static const double mapWidth = 2700.0;
  static const double mapHeight = 1680.0;
  static const double wallThickness = 40.0;
  static const double doorwayWidth = 200.0;

  // ── Room dimensions ────────────────────────────────────────────────────

  static const double gardenW = 900.0;
  static const double bed1W = 900.0;
  static const double bathW = 400.0;
  static const double bed2W = 500.0;
  static const double kitchenW = 500.0;
  static const double kitchenH = 1040.0;
  static const double livingW = 1300.0;
  static const double livingH = 720.0;
  static const double hallwayW = 1300.0;
  static const double hallwayH = 320.0;

  static const double topRowH = 640.0;

  // ── Derived positions ──────────────────────────────────────────────────

  static const double indoorX = gardenW;                  // 900
  static const double hallwayX = indoorX + kitchenW;      // 1400
  static const double hallwayY = topRowH;                 // 640
  static const double bottomY = hallwayY + hallwayH;      // 840

  // ── Doorway centres (world coords) ─────────────────────────────────────

  // Vertical wall doors
  static const double gardenBed1DoorY = topRowH / 2;                        // 320
  static const double gardenKitchenDoorY = hallwayY + kitchenH / 2;         // 1100
  static const double kitchenHallDoorY = hallwayY + hallwayH / 2;          // 740
  static const double kitchenLivingDoorY = bottomY + livingH / 2;          // 1200

  // Horizontal wall doors
  static const double bed1KitchenDoorX = indoorX + kitchenW / 2;           // 1150
  static const double bed1HallDoorX = hallwayX + (indoorX + bed1W - hallwayX) / 2; // 1600
  static const double bathHallDoorX = indoorX + bed1W + bathW / 2 + 96;    // 2096
  static const double bed2HallDoorX = indoorX + bed1W + bathW + bed2W / 2; // 2450
  static const double hallLivingDoorX = hallwayX + livingW / 2;            // 2050

  // ── Player / Gary spawn ────────────────────────────────────────────────

  static Vector2 get playerStart =>
      Vector2(hallwayX + hallwayW / 2, hallwayY + hallwayH / 2);

  static Vector2 get garyStart =>
      Vector2(gardenW / 2, mapHeight / 2);

  // ── Letter positions per room ──────────────────────────────────────────

  static List<Vector2> letterPositionsFor(BungalowRoom room) {
    const m = wallThickness + 50.0;
    return switch (room) {
      BungalowRoom.garden => [
        Vector2(m, m),
        Vector2(gardenW / 2, m + 200),
        Vector2(m, mapHeight / 2),
        Vector2(gardenW / 2, mapHeight - m),
        Vector2(m, mapHeight - m - 200),
      ],
      BungalowRoom.bedroom1 => [
        Vector2(indoorX + m, m),
        Vector2(indoorX + bed1W - m, m),
        Vector2(indoorX + bed1W / 2, topRowH / 2),
        Vector2(indoorX + m, topRowH - m - 60),
        Vector2(indoorX + bed1W - m, topRowH - m - 60),
      ],
      BungalowRoom.bathroom => [
        Vector2(indoorX + bed1W + m, 250),
        Vector2(indoorX + bed1W + bathW - m, 250),
        Vector2(indoorX + bed1W + bathW / 2, topRowH / 2),
      ],
      BungalowRoom.bedroom2 => [
        Vector2(indoorX + bed1W + bathW + m, m),
        Vector2(mapWidth - m, m),
        Vector2(indoorX + bed1W + bathW + bed2W / 2, topRowH / 2),
        Vector2(mapWidth - m, topRowH - m - 60),
      ],
      BungalowRoom.hallway => [
        Vector2(hallwayX + m + 60, hallwayY + hallwayH / 2),
        Vector2(mapWidth - m - 60, hallwayY + hallwayH / 2),
      ],
      BungalowRoom.kitchen => [
        Vector2(indoorX + m, hallwayY + m),
        Vector2(hallwayX - m, hallwayY + m),
        Vector2(indoorX + kitchenW / 2, hallwayY + kitchenH / 2),
        Vector2(indoorX + m, mapHeight - m),
        Vector2(hallwayX - m, mapHeight - m),
      ],
      BungalowRoom.livingRoom => [
        Vector2(hallwayX + m, bottomY + m),
        Vector2(mapWidth - m, bottomY + m),
        Vector2(hallwayX + livingW / 2, bottomY + livingH / 2),
        Vector2(mapWidth - m, mapHeight - m),
        Vector2(hallwayX + m, mapHeight - m),
      ],
    };
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
    BungalowRoom.bedroom1:   [BungalowRoom.garden, BungalowRoom.kitchen, BungalowRoom.hallway],
    BungalowRoom.bathroom:   [BungalowRoom.hallway],
    BungalowRoom.bedroom2:   [BungalowRoom.hallway],
    BungalowRoom.hallway:    [BungalowRoom.bedroom1, BungalowRoom.bathroom, BungalowRoom.bedroom2, BungalowRoom.kitchen, BungalowRoom.livingRoom],
    BungalowRoom.kitchen:    [BungalowRoom.garden, BungalowRoom.bedroom1, BungalowRoom.hallway, BungalowRoom.livingRoom],
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
    if (pair.containsAll({BungalowRoom.bedroom1, BungalowRoom.kitchen})) {
      return to == BungalowRoom.kitchen
          ? Vector2(bed1KitchenDoorX, hallwayY + past)
          : Vector2(bed1KitchenDoorX, hallwayY - past);
    }
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
    if (pair.containsAll({BungalowRoom.bedroom1, BungalowRoom.kitchen})) {
      return Vector2(bed1KitchenDoorX, hallwayY);
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

  static bool isDoorwayVertical(BungalowRoom a, BungalowRoom b) {
    final pair = {a, b};
    return pair.containsAll({BungalowRoom.garden, BungalowRoom.bedroom1}) ||
        pair.containsAll({BungalowRoom.garden, BungalowRoom.kitchen}) ||
        pair.containsAll({BungalowRoom.kitchen, BungalowRoom.hallway}) ||
        pair.containsAll({BungalowRoom.kitchen, BungalowRoom.livingRoom});
  }
}
