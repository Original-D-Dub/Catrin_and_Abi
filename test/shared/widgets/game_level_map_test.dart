import 'package:catrin_abi_bsl/shared/widgets/game_level_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('levels past the current one are locked', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final played = <int>[];
    final chests = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GameLevelMap(
          levelCount: 12,
          highestCompleted: 2,
          characterThumb: 'assets/images/characters/abi_thumb.png',
          characterLabel: 'Abi',
          isChestLevel: (l) => l % 5 == 0,
          chestState: (_) => ChestState.locked,
          onLevelSelected: played.add,
          onChestTapped: chests.add,
          onCharacterTapped: () {},
          levelLabel: (l) => 'Level $l',
          chestLabel: (l) => 'Chest $l',
        ),
      ),
    ));

    // Done levels show their numbers; the current level (3) too.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // Locked levels don't.
    expect(find.text('4'), findsNothing);

    for (final level in [1, 3, 4, 7]) {
      await tester.tap(find.bySemanticsLabel('Level $level'),
          warnIfMissed: false);
    }
    await tester.tap(find.bySemanticsLabel('Chest 5'), warnIfMissed: false);
    expect(played, [1, 3]);
    expect(chests, isEmpty);
  });

  testWidgets('character walks from the level just finished to the next',
      (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget map({int? movedFrom}) => MaterialApp(
          home: Scaffold(
            body: GameLevelMap(
              levelCount: 12,
              highestCompleted: 2,
              movedFromLevel: movedFrom,
              characterThumb: 'assets/images/characters/harley_thumb.png',
              characterLabel: 'Harley',
              isChestLevel: (l) => l % 5 == 0,
              chestState: (_) => ChestState.locked,
              onLevelSelected: (_) {},
              onChestTapped: (_) {},
              onCharacterTapped: () {},
              levelLabel: (l) => 'Level $l',
              chestLabel: (l) => 'Chest $l',
            ),
          ),
        );
    Offset character() => tester.getCenter(find.bySemanticsLabel('Harley'));
    Offset level(int n) => tester.getCenter(find.bySemanticsLabel('Level $n'));

    await tester.pumpWidget(map(movedFrom: 2));
    final start = character();
    // Starts beside level 2, nearer it than level 3.
    expect((start - level(2)).distance, lessThan((start - level(3)).distance));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    final end = character();
    expect((end - level(3)).distance, lessThan((end - level(2)).distance));

    // Without a move it's already beside level 3.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(map());
    expect(character(), end);
  });

  testWidgets('sections paint their ground and signpost their first level',
      (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GameLevelMap(
          levelCount: 13,
          highestCompleted: 0,
          onLevelSelected: (_) {},
          levelLabel: (l) => 'Level $l',
          sections: const [
            MapSection(
              firstLevel: 1,
              lastLevel: 4,
              grassColour: Color(0xFF65A94F),
              label: 'More',
            ),
            MapSection(
              firstLevel: 5,
              lastLevel: 8,
              grassColour: Color(0xFF3F8E6A),
              groundPattern: MapGroundPattern.mownStripes,
              label: 'Less',
            ),
            MapSection(
              firstLevel: 9,
              lastLevel: 13,
              grassColour: Color(0xFF9DB843),
              groundPattern: MapGroundPattern.flowers,
              label: 'Mixed',
            ),
          ],
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
  });
}
