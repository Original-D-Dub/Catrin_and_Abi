import 'package:catrin_abi_bsl/core/config/routes.dart';
import 'package:catrin_abi_bsl/features/zoo/screens/zoo_level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The zoo's choose-a-level screen: unlocked nodes for each entry in
/// [ZooLevelSelectScreen.levels], locked nodes for the rest, and tapping
/// a node opens that level's route with its building as an argument.
void main() {
  testWidgets('shows unlocked nodes and opens the tapped building',
      (tester) async {
    RouteSettings? pushed;

    await tester.pumpWidget(
      MaterialApp(
        home: const ZooLevelSelectScreen(),
        onGenerateRoute: (settings) {
          pushed = settings;
          return MaterialPageRoute(
            builder: (_) => const SizedBox(),
            settings: settings,
          );
        },
      ),
    );
    await tester.pump();

    // One numbered node per defined level, the rest locked.
    final unlocked = ZooLevelSelectScreen.levels.length;
    for (var level = 1; level <= unlocked; level++) {
      expect(find.text('$level'), findsOneWidget);
    }
    expect(
      find.byIcon(Icons.lock),
      findsNWidgets(16 - unlocked),
    );

    // Tapping level 1 opens the BSL video quiz in its building.
    await tester.tap(find.text('1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(pushed?.name, AppRoutes.zooQuiz);
    expect(
      (pushed?.arguments as Map?)?['building'],
      ZooLevelSelectScreen.levels[0].building,
    );

    // Back on the map, tapping level 2 sends the player to the zoo gate
    // to find the first walk building on foot.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(pushed?.name, AppRoutes.zooMap);
    expect(
      (pushed?.arguments as Map?)?['building'],
      ZooLevelSelectScreen.levels[1].building,
    );
  });
}
