import 'package:flame/extensions.dart';

import '../models/zoo_map_data.dart';
import '../providers/zoo_provider.dart';
import 'zoo_map_game_base.dart';

/// Flame game for the zoo exploration map.
///
/// The map world, player and camera come from [ZooMapGameBase]. Each frame
/// the player's position is checked against the building trigger zones
/// parsed from the SVG; enter/leave changes are pushed to [ZooProvider],
/// which the screen watches to show the Enter button.
class ZooQuestGame extends ZooMapGameBase {
  /// The game state provider (active trigger zone).
  final ZooProvider provider;

  /// Walkable-path and trigger-zone geometry parsed from the map SVG.
  late final ZooMapData mapData;

  ZooQuestGame({required this.provider});

  @override
  String get characterId => provider.characterId;

  @override
  bool isWalkable(Offset point) => mapData.isWalkable(point);

  @override
  Future<void> onLoad() async {
    mapData = await ZooMapData.load();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    final zone = mapData.triggerAt(player.position.toOffset());
    if (zone == null) {
      provider.setActiveZone(null);
      return;
    }

    // Screen point just above the building's entrance zone, so the Enter
    // button appears over the right building rather than a fixed spot.
    final zoom = camera.viewfinder.zoom;
    final camPos = camera.viewfinder.position;
    final anchor = Offset(
      (zone.rect.center.dx - camPos.x) * zoom + size.x / 2,
      (zone.rect.top - camPos.y) * zoom + size.y / 2,
    );
    provider.setActiveZone(zone, anchor);
  }
}
