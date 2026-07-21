import 'package:catrin_abi_bsl/features/zoo/widgets/bsl_question_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The BSL question video container, exercised via the no-video
/// placeholder path (no video asset is recorded yet, so this avoids
/// needing a real video_player platform channel): starts full size with
/// a 44x44 close button that shrinks it to the reminder thumbnail, and
/// — until real footage exists — the placeholder auto-shrinks on its own
/// after 3 seconds.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
      );

  bool isThumbnailBox(Widget w) => w is SizedBox && w.width == 120;
  bool isFullWidthBox(Widget w) => w is ConstrainedBox &&
      w.constraints.maxWidth == 560;

  testWidgets('starts full size (not the thumbnail) with a close button',
      (tester) async {
    await tester.pumpWidget(wrap(const BslQuestionVideo(
      videoAssetPath: null,
      placeholderLabel: 'Watch the sign',
    )));
    await tester.pump();

    expect(find.text('Watch the sign'), findsOneWidget);
    expect(find.byWidgetPredicate(isFullWidthBox), findsOneWidget);
    expect(find.byWidgetPredicate(isThumbnailBox), findsNothing);

    // The close icon sits in a 44x44 tappable area.
    expect(find.byIcon(Icons.close), findsOneWidget);
    final closeBox = tester.widget<SizedBox>(find.ancestor(
      of: find.byIcon(Icons.close),
      matching: find.byType(SizedBox),
    ));
    expect(closeBox.width, 44);
    expect(closeBox.height, 44);
  });

  testWidgets('closing the video shrinks it to the thumbnail, not away',
      (tester) async {
    await tester.pumpWidget(wrap(const BslQuestionVideo(
      videoAssetPath: null,
      placeholderLabel: 'Watch the sign',
    )));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Still present (not dismissed) — just shrunk to the thumbnail size,
    // no longer full width — but the close icon itself is hidden, since
    // the thumbnail has no room for it and tapping the thumbnail already
    // grows the video back.
    expect(find.byWidgetPredicate(isThumbnailBox), findsOneWidget);
    expect(find.byWidgetPredicate(isFullWidthBox), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    // Tapping the thumbnail grows it back to full size (and the close
    // icon reappears).
    await tester.tap(find.byWidgetPredicate(isThumbnailBox));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byWidgetPredicate(isFullWidthBox), findsOneWidget);
    expect(find.byWidgetPredicate(isThumbnailBox), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets(
      'placeholder auto-shrinks to the thumbnail after 3 seconds',
      (tester) async {
    await tester.pumpWidget(wrap(const BslQuestionVideo(
      videoAssetPath: null,
      placeholderLabel: 'Watch the sign',
    )));
    await tester.pump();
    expect(find.byWidgetPredicate(isFullWidthBox), findsOneWidget);

    // Just under 3s: still full size.
    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.byWidgetPredicate(isFullWidthBox), findsOneWidget);

    // Past 3s, plus the shrink animation: thumbnail.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byWidgetPredicate(isThumbnailBox), findsOneWidget);
    expect(find.byWidgetPredicate(isFullWidthBox), findsNothing);
  });
}
