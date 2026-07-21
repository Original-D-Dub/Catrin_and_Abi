import 'package:catrin_abi_bsl/features/zoo/game/enclosure_walk_game.dart';
import 'package:catrin_abi_bsl/features/zoo/models/enclosure_level_config.dart';
import 'package:catrin_abi_bsl/features/zoo/providers/enclosure_walk_provider.dart';
import 'package:catrin_abi_bsl/features/zoo/screens/enclosure_walk_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Reproduces the startup path taken when the aquarium is entered from
/// the zoo map: the route builds EnclosureWalkScreen under an
/// EnclosureWalkProvider, the screen constructs EnclosureWalkGame, and
/// onLoad lays out the world from the canvas size.
void main() {
  testWidgets('aquarium walk mounts and runs first frames without errors',
      (tester) async {
    final provider =
        EnclosureWalkProvider(config: EnclosureLevelConfig.aquarium);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: EnclosureWalkScreen()),
      ),
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tester.takeException(), isNull);
    provider.dispose();
  });

  testWidgets(
      'reptile house walk mounts and runs first frames without errors',
      (tester) async {
    final provider =
        EnclosureWalkProvider(config: EnclosureLevelConfig.reptileHouse);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: EnclosureWalkScreen()),
      ),
    );

    // Extra runAsync pump so the sandstone noise tile (async image decode
    // in the surface components' onLoad) completes and renders.
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tester.takeException(), isNull);
    provider.dispose();
  });

  testWidgets('tapping the exit door pops back to the previous screen',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const Scaffold(body: SizedBox()),
    ));

    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) =>
            EnclosureWalkProvider(config: EnclosureLevelConfig.aquarium),
        child: const EnclosureWalkScreen(),
      ),
    ));
    // Route transition, then a few game frames (pumpAndSettle would never
    // settle — Flame's ticker keeps scheduling frames).
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The current question's BSL video is up top and, at full size, can
    // overlap the door's screen position — shrink it to the corner
    // thumbnail first, exactly as a player would if it were in the way.
    // Incremental pumps (not one big jump) so the shrink's implicit
    // animations actually tick and settle at their target values.
    await tester.tap(find.byIcon(Icons.close));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final game = tester
        .widget<GameWidget<EnclosureWalkGame>>(
            find.byType(GameWidget<EnclosureWalkGame>))
        .game!;

    // Walk the player to the door; the camera centres on them there.
    game.player.position.x = game.layout.doorCenterX;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Door centre on screen: camera x is clamped to doorCenterX, so the
    // door is horizontally centred; tap mid-door height.
    final canvas = tester.getSize(find.byType(GameWidget<EnclosureWalkGame>));
    await tester.tapAt(Offset(
      canvas.width / 2,
      game.layout.floorTop - game.layout.doorHeight / 2,
    ));
    // Kick off the pop transition, then let it finish.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EnclosureWalkScreen), findsNothing);
  });
}
