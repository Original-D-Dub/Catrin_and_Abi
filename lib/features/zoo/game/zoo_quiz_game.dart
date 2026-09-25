import 'dart:ui' show VoidCallback;

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../models/zoo_animal_zone.dart';
import '../models/zoo_map_data.dart';
import '../providers/zoo_quiz_provider.dart';
import 'zoo_map_game_base.dart';

/// Flame game for the zoo's level 1: the BSL video quiz, played as a
/// walk-around on the zoo map.
///
/// The map world, player and camera come from [ZooMapGameBase]. Each frame
/// the player's position is checked against the level's animal zones
/// ([ZooQuizProvider.zones]); enter/leave changes are pushed to
/// [ZooQuizProvider], which the screen watches. Tapping the map (the
/// animal) calls [onMapTapped] — the screen either takes the picture, if
/// the player is standing in an animal zone, or shows a "too far away"
/// message.
class ZooQuizGame extends ZooMapGameBase with TapCallbacks {
  /// The quiz state provider (questions + active animal zone).
  final ZooQuizProvider provider;

  /// Called when the player taps anywhere on the map.
  final VoidCallback onMapTapped;

  /// The walkway network parsed from the map SVG.
  late final Path walkable;

  ZooQuizGame({required this.provider, required this.onMapTapped});

  @override
  String get characterId => provider.characterId;

  @override
  bool isWalkable(Offset point) => walkable.contains(point);

  @override
  Future<void> onLoad() async {
    walkable = await ZooMapData.loadWalkable();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isLoaded) {
      provider.setActiveZone(
          ZooAnimalZone.zoneAt(provider.zones, player.position.toOffset()));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onMapTapped();
  }
}
