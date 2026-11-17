import 'package:catrin_abi_bsl/features/bubble_shooter/widgets/level_complete_modal.dart';
import 'package:catrin_abi_bsl/features/sports_collection/models/sport_card.dart';
import 'package:catrin_abi_bsl/shared/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AudioService.sfxEnabled = false;
    AudioService.instructionsEnabled = false;
  });

  // The audio plugin isn't available in widget tests; its errors aren't
  // what's under test here.
  void ignoreAudioErrors() {
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('MissingPluginException')) {
        return;
      }
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);
  }

  bool nextShown(WidgetTester tester) => !tester
      .widget<IgnorePointer>(find
          .ancestor(of: find.text('Next').first, matching: find.byType(IgnorePointer))
          .first)
      .ignoring;

  testWidgets('without a chest, Next shows straight away', (tester) async {
    ignoreAudioErrors();
    var nexts = 0;
    await tester.pumpWidget(MaterialApp(
      home: LevelCompleteModal(score: 120, onNext: () => nexts++),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('120'), findsOneWidget);
    expect(nextShown(tester), isTrue);
    await tester.tap(find.text('Next').first);
    expect(nexts, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a chest appears, opens on tap, then Next shows',
      (tester) async {
    ignoreAudioErrors();
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      home: LevelCompleteModal(
        score: 300,
        onNext: () {},
        openChest: () async {
          opened++;
          return SportCard.football;
        },
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('300'), findsOneWidget);
    expect(nextShown(tester), isFalse);

    await tester.pump(LevelCompleteModal.chestDelay);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('300'), findsNothing);
    expect(find.text('Tap the chest!'), findsWidgets);
    expect(nextShown(tester), isFalse);

    await tester.tap(find.bySemanticsLabel('Tap the chest!').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 1);
    expect(find.text('Football'), findsOneWidget);
    expect(nextShown(tester), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
