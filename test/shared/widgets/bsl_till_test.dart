import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/shared/widgets/bsl_till.dart';

void main() {
  Future<List<int>> pumpTill(
    WidgetTester tester, {
    bool enabled = true,
  }) async {
    final pressed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: BslTill(
              enabled: enabled,
              onKeyPressed: pressed.add,
            ),
          ),
        ),
      ),
    );
    return pressed;
  }

  testWidgets('each key reports its value', (tester) async {
    final pressed = await pumpTill(tester);
    final values = List.generate(12, (i) => i + 1);
    for (final v in values) {
      await tester.tap(find.bySemanticsLabel('BSL $v'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(pressed, values);
  });

  testWidgets('has keys 1 to 12 only', (tester) async {
    await pumpTill(tester);
    expect(find.bySemanticsLabel(RegExp(r'^BSL \d+$')), findsNWidgets(12));
    expect(find.bySemanticsLabel('BSL 20'), findsNothing);
  });

  testWidgets('disabled till ignores taps', (tester) async {
    final pressed = await pumpTill(tester, enabled: false);
    expect(find.bySemanticsLabel('BSL 1'), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(BslTill)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(pressed, isEmpty);
  });
}

