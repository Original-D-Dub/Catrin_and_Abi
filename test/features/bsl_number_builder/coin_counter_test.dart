import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/widgets/coin_counter.dart';

void main() {
  Future<void> pumpCounter(WidgetTester tester, int coins) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CoinCounter(coins: coins)),
    ),
  );

  Set<String> visibleNumbers(WidgetTester tester) => {
    for (final text in tester.widgetList<Text>(find.byType(Text)))
      if (text.data != null) text.data!,
  };

  testWidgets('a rise counts up through every number in ones', (tester) async {
    await pumpCounter(tester, 3);
    await pumpCounter(tester, 9);

    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 15));
      seen.addAll(visibleNumbers(tester));
    }
    for (var n = 3; n <= 9; n++) {
      expect(seen, contains('$n'));
    }
    expect(visibleNumbers(tester), {'9'});
  });

  testWidgets('a reset snaps straight to the new total', (tester) async {
    await pumpCounter(tester, 12);
    await pumpCounter(tester, 0);
    expect(visibleNumbers(tester), {'0'});
  });
}
