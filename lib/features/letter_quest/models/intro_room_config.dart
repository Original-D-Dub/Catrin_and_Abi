import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Configuration for the intro Level 1 room layout.
///
/// Level 1 uses a 900x1200 world divided in half by a vertical wall
/// with two doorways, creating a left half and right half.
///
/// Layout:
/// ```
/// +---------------------------+
/// |             |             |
/// |    Left     d    Right    |
/// |    Half     o    Half     |
/// |             o             |
/// |             r             |
/// |             |             |
/// |             d             |
/// |             o             |
/// |             o             |
/// |             r             |
/// |             |             |
/// +---------------------------+
/// ```
class IntroRoomConfig {
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
  /// Returns 3 positions spread across both halves of the room.
  /// Level 1 only shows the 3 correct letters (no distractors).
  static List<Vector2> get letterPositions {
    final margin = wallThickness + 60.0;
    final halfWidth = mapWidth / 2;

    return [
      // Left half - 2 positions
      Vector2(margin + 60, margin + 120),
      Vector2(margin + 60, mapHeight - margin - 120),

      // Right half - 1 position
      Vector2(halfWidth + margin + 60, mapHeight / 2),
    ];
  }

  /// Vertical position of the top doorway center
  static double get topDoorwayY => mapHeight * 0.25;

  /// Vertical position of the bottom doorway center
  static double get bottomDoorwayY => mapHeight * 0.75;
}
