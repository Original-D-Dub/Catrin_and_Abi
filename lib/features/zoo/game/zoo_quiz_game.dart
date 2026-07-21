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
/// [ZooQuizProvider], which the screen watches to show the Take a Picture
/// button.
class ZooQuizGame extends ZooMapGameBase {
  /// The quiz state provider (questions + active animal zone).
  final ZooQuizProvider provider;

  /// The walkway network parsed from the map SVG.
  late final Path walkable;

  ZooQuizGame({required this.provider});

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
}
