import 'package:flame/components.dart';

/// Room layout for the top floor of Catrin and Abi's house.
///
/// Four rooms connected by a central landing corridor:
/// ```
/// +-------------------+--------------+  y=0
/// | Catrin's Bedroom  | Abi's        |
/// | (1090 × 752)      | Bedroom      |
/// |                   | (735 × 752)  |
/// +---[D]---+---------+---[D]-------+  y=752
/// |              LANDING             |
/// |           (1825 × 160)           |
/// +---[D]----+---------[D]----------+  y=912
/// | Bathroom  | Mum & Dad's Bedroom  |
/// | (700×851) | (1125 × 851)         |
/// +-----------+----------------------+  y=1763
/// ```
class HouseRoomConfig {
  // ── Room dimensions ───────────────────────────────────────────────────

  static const double catrinWidth = 1090.0;
  static const double catrinHeight = 752.0;

  static const double abiWidth = 735.0;
  static const double abiHeight = 752.0;

  static const double bathroomWidth = 700.0;
  static const double bathroomHeight = 851.0;

  static const double mumDadWidth = 1125.0;
  static const double mumDadHeight = 851.0;

  static const double landingHeight = 280.0;

  // ── Layout constants ──────────────────────────────────────────────────

  static const double wallThickness = 40.0;
  static const double doorwayWidth = 240.0;

  static const double mapWidth = catrinWidth + abiWidth; // 1825
  static const double topRowHeight = catrinHeight; // 752
  static const double bottomRowTop = topRowHeight + landingHeight; // 912
  static const double bottomRowHeight = bathroomHeight; // 851
  static const double mapHeight = bottomRowTop + bottomRowHeight; // 1763

  // ── Room positions ────────────────────────────────────────────────────

  static Vector2 get catrinPosition => Vector2.zero();
  static Vector2 get abiPosition => Vector2(catrinWidth, 0);
  static Vector2 get landingPosition => Vector2(0, topRowHeight);
  static Vector2 get bathroomPosition => Vector2(0, bottomRowTop);
  static Vector2 get mumDadPosition => Vector2(bathroomWidth, bottomRowTop);

  // ── Doorway centers (x for horizontal walls, y for vertical walls) ────

  static double get catrinDoorX => catrinWidth - 160;
  static double get abiDoorX => catrinWidth + 160;
  static double get bathroomDoorX => bathroomWidth / 2;
  static double get mumDadDoorX => bathroomWidth + mumDadWidth / 2;
  static double get catrinAbiDoorY => catrinHeight / 2;
  static double get bathMumDadDoorY => bottomRowTop + bottomRowHeight / 2;

  // ── Player spawn ──────────────────────────────────────────────────────

  static Vector2 get playerStart =>
      Vector2(catrinWidth / 2, catrinHeight / 2);

  // ── Letter placement ──────────────────────────────────────────────────

  static List<Vector2> get letterPositions {
    return [
      // Catrin's bedroom — clear floor away from bed, table, nightstand
      Vector2(160, 160),
      Vector2(550, 650),
      Vector2(900, 630),
      // Abi's bedroom — clear floor below bed and lamp
      Vector2(catrinWidth + 210, 620),
      Vector2(catrinWidth + 80, 650),
      // Bathroom — clear floor away from bath, toilet, sink
      Vector2(160, bottomRowTop + 160),
      Vector2(300, bottomRowTop + 300),
      Vector2(160, bottomRowTop + 420),
      // Mum & Dad's bedroom — clear floor left of bed and below bed
      Vector2(bathroomWidth + 100, bottomRowTop + 160),
      Vector2(bathroomWidth + 100, bottomRowTop + 500),
      Vector2(bathroomWidth + 350, bottomRowTop + 650),
      Vector2(bathroomWidth + 100, bottomRowTop + 650),
    ];
  }
}
