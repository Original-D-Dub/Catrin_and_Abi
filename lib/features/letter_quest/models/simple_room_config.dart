import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Configuration for the simple Level 2 room layout.
///
/// Level 2 uses a 1200x1200 world divided in half by a horizontal wall
/// with two doorways, creating a top half and bottom half.
///
/// Layout:
/// ```
/// +---------------------------+
/// |                           |
/// |        Top Half           |
/// |      (play area)          |
/// |                           |
/// +---+                   +---+
/// |   |   doorway   doorway   |
/// +---+                   +---+
/// |                           |
/// |       Bottom Half         |
/// |      (play area)          |
/// |                           |
/// +---------------------------+
/// ```
class SimpleRoomConfig {
  /// Total width of the map in world units
  static const double mapWidth = 900.0;

  /// Total height of the map in world units
  static const double mapHeight = 1200.0;

  /// Thickness of outer walls and divider wall
  static const double wallThickness = 40.0;

  /// Width of doorway openings in the divider wall
  static const double doorwayWidth = 160.0;

  /// Floor color for the entire room
  static final Color floorColor = AppColors.vowelPairColors['i']!;

  /// Wall color (darker shade of floor)
  static Color get wallColor {
    final hsl = HSLColor.fromColor(floorColor);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  /// Center of the map (player spawn position)
  static Vector2 get mapCenter => Vector2(mapWidth / 2, mapHeight / 2);

  /// Pre-defined positions for letter placement.
  ///
  /// Returns 5 positions spread across both halves of the room,
  /// avoiding the center, walls, and doorway areas.
  static List<Vector2> get letterPositions {
    final margin = wallThickness + 60.0;
    final halfHeight = mapHeight / 2;

    return [
      // Top half - 2 positions
      Vector2(margin + 60, margin + 60),
      Vector2(mapWidth - margin - 100, margin + 60),

      // Bottom half - 3 positions
      Vector2(margin + 60, halfHeight + margin + 60),
      Vector2(mapWidth / 2, halfHeight + margin + 120),
      Vector2(margin + 100, mapHeight - margin - 60),
     
    ];
  }

  /// Horizontal position of the left doorway center
  static double get leftDoorwayX => mapWidth * 0.25;

  /// Horizontal position of the right doorway center
  static double get rightDoorwayX => mapWidth * 0.75;
}
