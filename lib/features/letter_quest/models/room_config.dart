import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Configuration for a single room in the Letter Quest map.
///
/// Each room corresponds to one vowel and has a distinct floor colour.
/// Rooms are connected via doorways — Room I (center hub) connects to all 4 others.
///
/// World coordinate layout (each room 640x480):
/// ```
///              (640, 0)
///             +--------+
///             | Room E |
///             | (navy) |
///   (0, 480)  +--------+ (1280, 480)
///  +--------+ +--------+ +--------+
///  | Room A | | Room I | | Room O |
///  | (red)  | | (green)| |(orange)|
///  +--------+ +--------+ +--------+
///   (0, 960)  (640, 960) (1280, 960)
///             +--------+
///             | Room U |
///             |(purple)|
///             +--------+
/// ```
class RoomConfig {
  /// Which vowel this room represents
  final String vowel;

  /// Top-left corner position in world coordinates
  final Vector2 worldPosition;

  /// Floor colour (soft pastel, from vowelPairColors)
  final Color floorColor;

  /// Wall colour (slightly darker shade)
  final Color wallColor;

  /// Which sides have doorways connecting to other rooms
  final Set<DoorwaySide> doorways;

  /// Creates a room configuration.
  const RoomConfig({
    required this.vowel,
    required this.worldPosition,
    required this.floorColor,
    required this.wallColor,
    required this.doorways,
  });

  /// Width of each room in world units
  static const double roomWidth = 900.0;

  /// Height of each room in world units
  static const double roomHeight = 680.0;

  /// Thickness of room walls
  static const double wallThickness = 40.0;

  /// Width of doorway openings in walls
  static const double doorwayWidth = 120.0;

  /// Size of the playable area inside walls
  static Vector2 get innerSize => Vector2(
        roomWidth - wallThickness * 2,
        roomHeight - wallThickness * 2,
      );

  /// Center point of this room in world coordinates
  Vector2 get center => Vector2(
        worldPosition.x + roomWidth / 2,
        worldPosition.y + roomHeight / 2,
      );

  /// Pre-defined positions within a room where letters can be placed.
  ///
  /// Positions are offsets from the room's worldPosition, avoiding
  /// the center (where player enters) and near walls/doorways.
  /// Returns 8 possible positions for letter placement.
  List<Vector2> get letterPositions {
    final cx = roomWidth / 2;
    final margin = wallThickness + 48.0;

    return [
      // Top-left quadrant
      Vector2(margin + 40, margin + 30),
      Vector2(cx - 80, margin + 30),
      // Top-right quadrant
      Vector2(cx + 80, margin + 30),
      Vector2(roomWidth - margin - 40, margin + 30),
      // Bottom-left quadrant
      Vector2(margin + 40, roomHeight - margin - 30),
      Vector2(cx - 80, roomHeight - margin - 30),
      // Bottom-right quadrant
      Vector2(cx + 80, roomHeight - margin - 30),
      Vector2(roomWidth - margin - 40, roomHeight - margin - 30),
    ];
  }

  /// Generates all 5 room configurations in the cross layout.
  ///
  /// Room I is the central hub with doorways on all 4 sides.
  /// Each edge room has one doorway connecting back to Room I.
  static List<RoomConfig> generateAllRooms() {
    return [
      // Room A — left of center
      RoomConfig(
        vowel: 'a',
        worldPosition: Vector2(0, roomHeight),
        floorColor: AppColors.vowelPairColors['a']!,
        wallColor: _darken(AppColors.vowelPairColors['a']!),
        doorways: {DoorwaySide.right},
      ),
      // Room E — above center
      RoomConfig(
        vowel: 'e',
        worldPosition: Vector2(roomWidth, 0),
        floorColor: AppColors.vowelPairColors['e']!,
        wallColor: _darken(AppColors.vowelPairColors['e']!),
        doorways: {DoorwaySide.bottom},
      ),
      // Room I — center hub
      RoomConfig(
        vowel: 'i',
        worldPosition: Vector2(roomWidth, roomHeight),
        floorColor: AppColors.vowelPairColors['i']!,
        wallColor: _darken(AppColors.vowelPairColors['i']!),
        doorways: {
          DoorwaySide.top,
          DoorwaySide.bottom,
          DoorwaySide.left,
          DoorwaySide.right,
        },
      ),
      // Room O — right of center
      RoomConfig(
        vowel: 'o',
        worldPosition: Vector2(roomWidth * 2, roomHeight),
        floorColor: AppColors.vowelPairColors['o']!,
        wallColor: _darken(AppColors.vowelPairColors['o']!),
        doorways: {DoorwaySide.left},
      ),
      // Room U — below center
      RoomConfig(
        vowel: 'u',
        worldPosition: Vector2(roomWidth, roomHeight * 2),
        floorColor: AppColors.vowelPairColors['u']!,
        wallColor: _darken(AppColors.vowelPairColors['u']!),
        doorways: {DoorwaySide.top},
      ),
    ];
  }

  /// Returns a darker version of the given colour for wall rendering.
  static Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Sides of a room where a doorway can be placed.
enum DoorwaySide {
  top,
  bottom,
  left,
  right,
}
