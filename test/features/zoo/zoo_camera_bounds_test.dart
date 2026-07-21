import 'package:catrin_abi_bsl/features/zoo/game/zoo_quest_game.dart';
import 'package:catrin_abi_bsl/features/zoo/providers/zoo_provider.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the camera clamp: with the device in portrait,
/// walking the player to the highest walkable point must bring the top
/// edge of the map into view (and never scroll past it).
///
/// Flame's `setBounds(considerViewport: true)` subtracted the viewport
/// size in screen pixels from world-unit bounds, which on portrait
/// screens taller than the target visible height (tablets, tall phones)
/// stopped the camera ~(screenHeight - 1000)/2 world units short of the
/// map top.
void main() {
  testWidgets('map top is in view when player is at the highest path point',
      (tester) async {
    // Tablet-portrait logical size — the case the old clamp failed on.
    tester.view.physicalSize = const Size(810, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final game = ZooQuestGame(provider: ZooProvider());
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();

      // Walk-teleport to the top of the north walkway (elephant area).
      game.player.position = Vector2(1000, 210);
      // Let the follow + bounds behaviors settle.
      for (var i = 0; i < 5; i++) {
        game.update(0.016);
      }

      final visible = game.camera.visibleWorldRect;
      expect(visible.top, closeTo(0, 0.5),
          reason: 'camera should rest exactly on the map top edge');

      // And at the bottom (entrance plaza) it must not scroll past the
      // bottom edge either.
      game.player.position = Vector2(1000, 1242);
      for (var i = 0; i < 5; i++) {
        game.update(0.016);
      }
      expect(game.camera.visibleWorldRect.bottom, closeTo(1400, 0.5),
          reason: 'camera should rest exactly on the map bottom edge');

      expect(tester.takeException(), isNull);
    });
  });
}
