import 'dart:ui';

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
      // Catrin's bedroom
      Vector2(160, 160),
      Vector2(450, 650),
      Vector2(550, 650),
      Vector2(900, 630),
      // Abi's bedroom
      Vector2(catrinWidth + 210, 620),
      Vector2(catrinWidth + 80, 650),
      Vector2(catrinWidth + 500, 200),
      // Bathroom
      Vector2(160, bottomRowTop + 160),
      Vector2(300, bottomRowTop + 300),
      Vector2(160, bottomRowTop + 420),
      // Mum & Dad's bedroom
      Vector2(bathroomWidth + 100, bottomRowTop + 160),
      Vector2(bathroomWidth + 150, bottomRowTop + 350),
      Vector2(bathroomWidth + 100, bottomRowTop + 500),
      Vector2(bathroomWidth + 350, bottomRowTop + 650),
      Vector2(bathroomWidth + 100, bottomRowTop + 650),
    ];
  }

  // ── Furniture rects (for letter-placement blocking) ───────────────────

  static List<Rect> get furnitureRects {
    const ox = catrinWidth;
    const oy = bottomRowTop;
    const mdOx = bathroomWidth;
    const t = wallThickness;

    return [
      // ── Catrin's bedroom ──
      Rect.fromLTWH(290, 40, 517, 532),
      Rect.fromLTWH(807, 40, 180, 180 * 102 / 121),
      Rect.fromLTWH(40, 230, 234, 430),
      Rect.fromLTWH(815, 45, 151, 102),
      Rect.fromLTWH(940, 90, 59, 61),
      Rect.fromLTWH(40, 50, 131, 104),
      Rect.fromLTWH(55, 280, 56, 109),
      Rect.fromLTWH(110, 270, 83, 179),
      Rect.fromLTWH(110, 460, 44, 93),
      Rect.fromLTWH(170, 490, 39, 33),

      // ── Abi's bedroom ──
      Rect.fromLTWH(ox + 315, 40, 120, 101),
      Rect.fromLTWH(ox + 20, 50, 289, 495),
      Rect.fromLTWH(ox + 486, 370, 207, 206),
      Rect.fromLTWH(ox + 321, 450, 372, 302),
      Rect.fromLTWH(ox + 365, 42, 127, 78),
      Rect.fromLTWH(ox + 415, 100, 115, 89),
      Rect.fromLTWH(ox + 331, 42, 72, 69),
      Rect.fromLTWH(ox + 380, 60, 19, 50),
      Rect.fromLTWH(ox + 140, 570, 50, 40),
      Rect.fromLTWH(ox + 360, 380, 32, 50),

      // ── Bathroom ──
      Rect.fromLTWH(494, oy + 240, 239, 585),
      Rect.fromLTWH(t, oy + bottomRowHeight - t - 218, 136, 218),
      Rect.fromLTWH(280, oy + bottomRowHeight - t - 163, 201, 163),
      Rect.fromLTWH(494, oy + 40, 231, 232),
      Rect.fromLTWH(100, oy + 200, 227, 313),

      // ── Mum & Dad's bedroom ──
      Rect.fromLTWH(mdOx + 240, oy + bottomRowHeight - t - 577, 496, 577),
      Rect.fromLTWH(mdOx + 200, oy + 380, 621, 408),
      Rect.fromLTWH(mdOx + 784, oy + 30, 151, 145),
      Rect.fromLTWH(mdOx + 940, oy + 50, 158, 333),
      Rect.fromLTWH(mdOx + 940, oy + 400, 158, 333),
      Rect.fromLTWH(mdOx + 50, oy + 660, 186, 149),
      Rect.fromLTWH(mdOx + 736, oy + bottomRowHeight - t - 107, 128, 107),
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
}
