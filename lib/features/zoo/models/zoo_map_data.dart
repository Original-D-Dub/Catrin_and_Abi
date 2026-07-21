import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';

/// A named rectangular area in front of an enterable building.
///
/// While the player stands inside one of these the UI shows the
/// floating Enter button for that building.
class ZooTriggerZone {
  /// Building identifier (`aviary`, `reptile-house`, `aquarium`).
  final String building;

  /// Zone bounds in map coordinates.
  final Rect rect;

  const ZooTriggerZone(this.building, this.rect);

  /// Translation key for the building's display name,
  /// e.g. `reptile-house` -> `zoo.reptile_house`.
  String get titleKey => 'zoo.${building.replaceAll('-', '_')}';

  /// Every enterable building's entrance zone, in map coordinates.
  ///
  /// The buildings are artwork baked into `zoo_map.png` (like the animal
  /// enclosures in `ZooAnimalZone`), so their zones are hardcoded here
  /// rather than parsed from the SVG — the map SVG only ever carries the
  /// `walkable` outline, never got `trigger-*` rects added, and the source
  /// artwork has no ids to derive positions from. Coordinates were sampled
  /// against the walkable path so each rect genuinely overlaps it (the
  /// player can only ever stand on the walkway).
  static const List<ZooTriggerZone> all = [
    ZooTriggerZone('reptile-house', Rect.fromLTWH(470, 790, 200, 100)),
    ZooTriggerZone('aviary', Rect.fromLTWH(1150, 380, 200, 100)),
    ZooTriggerZone('aquarium', Rect.fromLTWH(600, 1070, 200, 100)),
  ];
}

/// Game geometry for the zoo map.
///
/// The walkway network is parsed from `assets/games/zoo/zoo_map.svg` (the
/// only geometry actually authored there); building entrance zones come
/// from [ZooTriggerZone.all].
class ZooMapData {
  /// SVG asset location (also listed in pubspec.yaml).
  static const String assetPath = 'assets/games/zoo/zoo_map.svg';

  /// Map dimensions matching the SVG viewBox.
  static const double mapWidth = 2000;
  static const double mapHeight = 1400;

  /// The walkable surface. Even-odd fill so the grass "holes" enclosed by
  /// the path loops count as outside regardless of contour winding.
  final Path walkable;

  /// Enter-prompt zones, one per enterable building.
  final List<ZooTriggerZone> triggers;

  ZooMapData._(this.walkable, this.triggers);

  /// Whether [point] (map coordinates) is on the walkway network.
  bool isWalkable(Offset point) => walkable.contains(point);

  /// The trigger zone containing [point], or null.
  ZooTriggerZone? triggerAt(Offset point) {
    for (final zone in triggers) {
      if (zone.rect.contains(point)) return zone;
    }
    return null;
  }

  /// Parses just the walkable-path geometry from the map SVG asset.
  ///
  /// Throws [StateError] if the walkable path is missing — e.g. if a
  /// re-export of the SVG stripped the id again.
  static Future<Path> loadWalkable() async {
    final svg = await rootBundle.loadString(assetPath);

    final walkableMatch =
        RegExp(r'<path id="walkable" d="([^"]+)"').firstMatch(svg);
    if (walkableMatch == null) {
      throw StateError(
          'zoo_map.svg has no <path id="walkable"> — re-add the id after '
          'exporting from the design tool.');
    }
    return parseSvgPathData(walkableMatch.group(1)!)
      ..fillType = PathFillType.evenOdd;
  }

  /// Parses the map SVG asset and pairs it with [ZooTriggerZone.all].
  ///
  /// Throws [StateError] if the walkable path is missing — e.g. if a
  /// re-export of the SVG stripped the id again.
  static Future<ZooMapData> load() async {
    final walkable = await loadWalkable();
    return ZooMapData._(walkable, ZooTriggerZone.all);
  }
}
