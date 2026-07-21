import 'dart:ui';

import 'package:catrin_abi_bsl/features/zoo/game/zoo_map_game_base.dart';
import 'package:catrin_abi_bsl/features/zoo/models/zoo_animal_zone.dart';
import 'package:catrin_abi_bsl/features/zoo/models/zoo_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the hand-placed animal zones against the real walkable path
/// parsed from zoo_map.svg: the player must be able to stand inside every
/// zone, and must spawn outside all of them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Path walkable;

  setUpAll(() async {
    walkable = await ZooMapData.loadWalkable();
  });

  test('spawn point is on the walkway and outside every zone', () {
    final spawn = Offset(
      ZooMapGameBase.startPosition.x,
      ZooMapGameBase.startPosition.y,
    );
    expect(walkable.contains(spawn), isTrue);
    expect(ZooAnimalZone.zoneAt(ZooAnimalZone.all, spawn), isNull);
    expect(ZooAnimalZone.zoneAt(ZooAnimalZone.farm, spawn), isNull);
  });

  test('every animal zone contains walkable ground to stand on', () {
    for (final zone in [...ZooAnimalZone.all, ...ZooAnimalZone.farm]) {
      var found = false;
      for (var x = zone.rect.left; x <= zone.rect.right && !found; x += 10) {
        for (var y = zone.rect.top; y <= zone.rect.bottom && !found; y += 10) {
          if (walkable.contains(Offset(x, y))) found = true;
        }
      }
      expect(found, isTrue,
          reason: 'zone "${zone.id}" has no walkable point — the player '
              'could never stand in it. Extend its rect over the adjacent '
              'walkway.');
    }
  });
}
