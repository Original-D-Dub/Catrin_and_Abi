import 'package:catrin_abi_bsl/features/zoo/providers/zoo_provider.dart';
import 'package:catrin_abi_bsl/features/zoo/screens/zoo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Reproduces the startup path taken when the home-screen tile is tapped:
/// the route builds ZooScreen under a ZooProvider, the screen constructs
/// ZooQuestGame, and onLoad loads the map PNG and parses geometry.
void main() {
  testWidgets('zoo screen mounts and game runs first frames without errors',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ZooProvider(),
          child: const MaterialApp(home: ZooScreen()),
        ),
      );

      // Let the async onLoad (map PNG load, geometry parsing) finish,
      // then run a few frames.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.takeException(), isNull);
    });
  });
}
