import 'package:catrin_abi_bsl/features/zoo/widgets/zoo_camera_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The zoo camera button: 56px on phone widths, 80px past the 600px
/// tablet breakpoint, pulses once on appearance, and reports taps.
void main() {
  Widget wrap(Widget child, Size size) => MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  testWidgets('is 56px wide on a phone-sized screen', (tester) async {
    await tester.pumpWidget(wrap(
      ZooCameraButton(tooltip: 'Take a picture', onPressed: () {}),
      const Size(400, 800),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 56);
  });

  testWidgets('is 80px wide past the tablet breakpoint', (tester) async {
    await tester.pumpWidget(wrap(
      ZooCameraButton(tooltip: 'Take a picture', onPressed: () {}),
      const Size(900, 1200),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 80);
  });

  testWidgets('pulses larger then settles, and reports taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      ZooCameraButton(
        tooltip: 'Take a picture',
        onPressed: () => tapped = true,
      ),
      const Size(400, 800),
    ));

    // Mid-pulse the button is scaled up past its resting size.
    await tester.pump(const Duration(milliseconds: 100));
    final midScale =
        tester
        .widget<ScaleTransition>(find.descendant(
          of: find.byType(ZooCameraButton),
          matching: find.byType(ScaleTransition),
        ))
        .scale
        .value;
    expect(midScale, greaterThan(1.0));

    // Pulse finished: back to resting scale.
    await tester.pump(const Duration(milliseconds: 400));
    final restScale =
        tester
        .widget<ScaleTransition>(find.descendant(
          of: find.byType(ZooCameraButton),
          matching: find.byType(ScaleTransition),
        ))
        .scale
        .value;
    expect(restScale, 1.0);

    await tester.tap(find.byType(ZooCameraButton));
    expect(tapped, isTrue);
  });
}
