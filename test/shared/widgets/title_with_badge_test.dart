import 'package:catrin_abi_bsl/shared/widgets/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget title, {double width = 600}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: Center(child: title),
        ),
      ),
    ),
  );

  testWidgets('rosette hangs off the last letter and is long-pressable', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      host(
        TitleWithBadge(
          text: 'Choose a Level',
          style: const TextStyle(fontSize: 32),
          badge: GestureDetector(
            key: const Key('badge'),
            onLongPress: () => pressed = true,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );

    final title = tester.getRect(find.byType(TitleWithBadge));
    final text = tester.getRect(find.text('Choose a Level'));
    final badge = tester.getRect(find.byKey(const Key('badge')));
    // No room reserved for the rosette: the title is just the text.
    expect(title, text);
    // Its circle touches the top of the last letter, so the rosette's
    // centre sits to the right of the text's end, level with its top half.
    expect(badge.center.dx, greaterThan(text.right));
    expect(badge.center.dy, lessThan(text.center.dy));
    expect(badge.center.dy, greaterThan(text.top - badge.height / 2));

    // Absolutely positioned outside the title's bounds, yet still pressable.
    await tester.longPress(find.byKey(const Key('badge')));
    expect(pressed, isTrue);
  });

  testWidgets('the rosette never moves the level select title', (tester) async {
    Future<Rect> titleRect({required bool withBadge}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(),
            body: LevelSelectScreen(
              titleBadge: withBadge ? const SizedBox.expand() : null,
              subtitle: 'Count the circles!',
              levels: [
                for (var i = 1; i <= 6; i++)
                  LevelSelectItem(number: i, color: Colors.red),
              ],
            ),
          ),
        ),
      );
      return tester.getRect(find.text('Choose a Level'));
    }

    final without = await titleRect(withBadge: false);
    expect(await titleRect(withBadge: true), without);
  });

  testWidgets('title stays on one line when space is tight', (tester) async {
    await tester.pumpWidget(
      host(
        const TitleWithBadge(
          text: 'Choose a Level',
          style: TextStyle(fontSize: 32),
          badge: SizedBox.expand(),
        ),
        width: 120,
      ),
    );
    final text = tester.getRect(find.text('Choose a Level'));
    expect(text.width, lessThanOrEqualTo(120));
    // A single line of 32px text, shrunk to fit — not wrapped.
    expect(text.height, lessThan(40));
  });

  testWidgets('shows the text alone without a badge', (tester) async {
    await tester.pumpWidget(
      host(
        const TitleWithBadge(
          text: 'Choose a Level',
          style: TextStyle(),
          badge: null,
        ),
      ),
    );
    expect(find.text('Choose a Level'), findsOneWidget);
    expect(find.byType(OverlayPortal), findsNothing);
  });
}
