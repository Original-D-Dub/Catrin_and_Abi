import 'dart:math';

import 'package:catrin_abi_bsl/features/zoo/game/zoo_player_component.dart';
import 'package:catrin_abi_bsl/features/zoo/models/zoo_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the geometry parsed from the real zoo_map.svg asset:
/// the walkable outline and the building trigger zones the Enter
/// button relies on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ZooMapData mapData;

  setUpAll(() async {
    mapData = await ZooMapData.load();
  });

  test('parses the three building trigger zones', () {
    expect(
      mapData.triggers.map((z) => z.building).toSet(),
      {'aviary', 'reptile-house', 'aquarium'},
    );
  });

  test('trigger titleKey maps to translation key format', () {
    final reptiles =
        mapData.triggers.firstWhere((z) => z.building == 'reptile-house');
    expect(reptiles.titleKey, 'zoo.reptile_house');
  });

  test('entrance plaza is walkable (player spawn)', () {
    expect(mapData.isWalkable(const Offset(1000, 1242)), isTrue);
  });

  test('spawn point fits the player collision circle', () {
    const centre = Offset(1000, 1242);
    const radius = ZooPlayerComponent.collisionRadius;
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      expect(
        mapData.isWalkable(
          centre + Offset(cos(angle), sin(angle)) * radius,
        ),
        isTrue,
        reason: 'collision circle pokes off the plaza at angle $i*pi/4',
      );
    }
  });

  test('grass and water are not walkable', () {
    // Lion enclosure (top-left corner area).
    expect(mapData.isWalkable(const Offset(150, 100)), isFalse);
    // Lake centre.
    expect(mapData.isWalkable(const Offset(1080, 680)), isFalse);
    // Grass between the outer loop and the lake ring.
    expect(mapData.isWalkable(const Offset(700, 640)), isFalse);
  });

  test('gorilla island bridge is decoration, not walkable', () {
    expect(mapData.isWalkable(const Offset(936, 680)), isFalse);
  });

  test('every trigger zone overlaps the walkway', () {
    for (final zone in mapData.triggers) {
      final r = zone.rect;
      // Sample a coarse grid inside the zone — at least one point must be
      // on the path or the player could never activate the Enter button.
      var reachable = false;
      for (var fx = 0.1; fx < 1 && !reachable; fx += 0.2) {
        for (var fy = 0.1; fy < 1 && !reachable; fy += 0.2) {
          reachable = mapData.isWalkable(
            Offset(r.left + r.width * fx, r.top + r.height * fy),
          );
        }
      }
      expect(reachable, isTrue,
          reason: 'trigger-${zone.building} does not touch the walkway');
    }
  });
}
