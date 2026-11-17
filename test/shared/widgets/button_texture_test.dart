import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/core/constants/app_colors.dart';
import 'package:catrin_abi_bsl/shared/widgets/button.dart';

void main() {
  Finder byTypeName(String name) =>
      find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

  for (final (name, button, colours) in [
    (
      'PrimaryButton',
      PrimaryButton(label: 'Play', onPressed: () {}),
      const [
        AppColors.buttonPrimaryGradStart,
        AppColors.buttonPrimaryGrad1,
        AppColors.buttonPrimaryGrad1,
        AppColors.buttonPrimaryGradEnd,
      ],
    ),
    (
      'SecondaryButton',
      SecondaryButton(label: 'Play', onPressed: () {}),
      const [
        Color(0xFFFF62A1),
        AppColors.abiPink,
        AppColors.abiPink,
        Color(0xFFBD0745),
      ],
    ),
    (
      'TertiaryButton',
      TertiaryButton(label: 'Play', onPressed: () {}),
      const [
        Color(0xFF5FBBE1),
        Color(0xFF3979A7),
        Color(0xFF3979A7),
        Color(0xFF185B8D),
      ],
    ),
    (
      'WarningButton',
      WarningButton(label: 'Play', onPressed: () {}),
      const [
        AppColors.buttonWarningGradStart,
        AppColors.accentRed,
        AppColors.accentRed,
        AppColors.buttonWarningGradEnd,
      ],
    ),
  ]) {
    testWidgets('$name is a borderless gradient felt patch', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: button)),
      ));
      // Let the texture asset load.
      await tester.runAsync(() async {
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find
              .descendant(
                  of: byTypeName('FuzzTexture'),
                  matching: find.byType(CustomPaint))
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
      });

      // One texture layer, over the fill, loaded.
      final texture = byTypeName('FuzzTexture');
      expect(texture, findsOneWidget);
      expect(find.descendant(of: texture, matching: find.byType(CustomPaint)),
          findsOneWidget,
          reason: 'texture image loaded');

      // Fill gradient, then texture, then stitching, then the label on top.
      final stackFinder =
          find.ancestor(of: texture, matching: find.byType(Stack)).first;
      final children = tester.widget<Stack>(stackFinder).children;
      expect(children, hasLength(4));
      final fill = ((children[0] as Positioned).child as DecoratedBox)
          .decoration as BoxDecoration;
      final gradient = fill.gradient as LinearGradient;
      expect(gradient.colors, colours);
      expect(gradient.stops, [0.0, 0.1, 0.9, 1.0]);
      expect(((children[1] as Positioned).child as ClipRRect).child,
          isA<FuzzTexture>());
      expect(
        find.descendant(
            of: find.byWidget(children[2]),
            matching: find.byWidgetPredicate((w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_StitchPainter')),
        findsOneWidget,
      );
      expect(find.descendant(of: texture, matching: find.text('Play')),
          findsNothing);
      expect(find.descendant(of: stackFinder, matching: find.text('Play')),
          findsWidgets);

      // No border: nothing pads the button in for a stroke ring.
      expect(
          tester
              .widgetList<Padding>(find.ancestor(
                  of: find.byType(ElevatedButton),
                  matching: find.byType(Padding)))
              .where((p) => p.padding == const EdgeInsets.all(4)),
          isEmpty);
    });
  }

  testWidgets('backgroundColor replaces the gradient with a solid fill',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PrimaryButton(
              label: 'Play', backgroundColor: Colors.orange, onPressed: () {}),
        ),
      ),
    ));
    final gradients = tester
        .widgetList<DecoratedBox>(find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(DecoratedBox)))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.gradient != null);
    expect(gradients, isEmpty);
  });
}
