import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/letter_quest/models/bungalow_config.dart';

void main() {
  test('every room has enough unblocked letter positions', () {
    for (final room in BungalowRoom.values) {
      final positions = BungalowConfig.letterPositionsFor(room);
      final free = positions
          .where((p) => !BungalowConfig.isPositionBlocked(p))
          .toList();
      final blocked = positions
          .where((p) => BungalowConfig.isPositionBlocked(p))
          .toList();
      // ignore: avoid_print
      print('$room: ${free.length}/${positions.length} free'
          '${blocked.isEmpty ? '' : ' — blocked: $blocked'}');
      expect(free.length, greaterThanOrEqualTo(2), reason: '$room');
      // All letters should be inside their own room
      for (final p in free) {
        expect(BungalowConfig.roomAt(p), room, reason: '$p');
      }
    }
  });

  test('doorway gaps are clear of solid furniture', () {
    const d = BungalowConfig.doorwayWidth;
    const t = BungalowConfig.wallThickness;
    // Pero's circular hitbox has radius 60; a doorway approach zone is the
    // gap extended `depth` world units either side of the wall.
    const depth = 130.0;

    final vertical = <String, Vector2>{
      'garden-bed1': Vector2(BungalowConfig.indoorX, BungalowConfig.gardenBed1DoorY),
      'garden-kitchen': Vector2(BungalowConfig.indoorX, BungalowConfig.gardenKitchenDoorY),
      'kitchen-living': Vector2(BungalowConfig.hallwayX, BungalowConfig.kitchenLivingDoorY),
    };
    final horizontal = <String, Vector2>{
      'bed1-hall': Vector2(BungalowConfig.bed1HallDoorX, BungalowConfig.hallwayY),
      'bath-hall': Vector2(BungalowConfig.bathHallDoorX, BungalowConfig.hallwayY),
      'bed2-hall': Vector2(BungalowConfig.bed2HallDoorX, BungalowConfig.hallwayY),
      'hall-living': Vector2(BungalowConfig.hallLivingDoorX, BungalowConfig.bottomY),
    };

    // Solid furniture only (decorative items are walk-over). Mirror the
    // solid subset of BungalowConfig.furnitureRects by name.
    final solid = BungalowConfig.furnitureRects;

    void check(String name, Rect zone) {
      for (final r in solid) {
        expect(r.overlaps(zone), isFalse,
            reason: '$name doorway zone $zone overlaps furniture $r');
      }
    }

    vertical.forEach((name, c) {
      // Zone must leave a 120px-wide clear corridor through the gap.
      check(name, Rect.fromLTRB(c.x - depth, c.y - d / 2 + 60,
          c.x + t + depth, c.y + d / 2 - 60));
    });
    horizontal.forEach((name, c) {
      check(name, Rect.fromLTRB(c.x - d / 2 + 60, c.y - depth,
          c.x + d / 2 - 60, c.y + t + depth));
    });
  });

  test('spawns are unblocked and in the right rooms', () {
    expect(BungalowConfig.roomAt(BungalowConfig.playerStart), BungalowRoom.hallway);
    expect(BungalowConfig.roomAt(BungalowConfig.garyStart), BungalowRoom.garden);
    expect(BungalowConfig.isPositionBlocked(BungalowConfig.playerStart), isFalse);
    expect(BungalowConfig.isPositionBlocked(BungalowConfig.garyStart), isFalse);
  });

  test('rooms tile the map exactly', () {
    expect(
        BungalowConfig.gardenW +
            BungalowConfig.bed1W +
            BungalowConfig.bathW +
            BungalowConfig.bed2W,
        BungalowConfig.mapWidth);
    expect(BungalowConfig.topRowH + BungalowConfig.hallwayH + BungalowConfig.livingH,
        BungalowConfig.mapHeight);
    expect(BungalowConfig.hallwayY + BungalowConfig.kitchenH,
        BungalowConfig.mapHeight);
    expect(BungalowConfig.hallwayX + BungalowConfig.hallwayW,
        BungalowConfig.mapWidth);
  });
}
