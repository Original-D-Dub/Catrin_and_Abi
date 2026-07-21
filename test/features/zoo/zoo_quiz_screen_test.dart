import 'package:catrin_abi_bsl/core/localization/app_localizations.dart';
import 'package:catrin_abi_bsl/features/zoo/game/zoo_quiz_game.dart';
import 'package:catrin_abi_bsl/features/zoo/providers/zoo_quiz_provider.dart';
import 'package:catrin_abi_bsl/features/zoo/screens/zoo_quiz_screen.dart';
import 'package:catrin_abi_bsl/features/zoo/widgets/zoo_camera_button.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The quiz screen mounts, the zoo map walk-around runs, and (with no BSL
/// videos recorded yet) the question container shows its placeholder —
/// currently the answer animal's name, standing in for the real sign video
/// during testing. Walking into the right animal's zone arms Take a
/// Picture; pressing it advances the quiz.
void main() {
  testWidgets('quiz screen mounts and answers a question', (tester) async {
    await tester.runAsync(() async {
      final provider = ZooQuizProvider();
      final localizer = AppLocalizations(locale: provider.locale);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: ZooQuizScreen()),
        ),
      );

      // Let the game load the map and the (missing) video fail over to
      // the placeholder, then run a few frames.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.text(localizer(provider.currentQuestion!.nameKey)),
          findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.byType(ZooCameraButton), findsNothing);

      // Walk the player into the current question's zone (the game's
      // update loop derives the active zone from the position).
      final game = tester
          .widget<GameWidget<ZooQuizGame>>(find.byType(GameWidget<ZooQuizGame>))
          .game!;
      final zone = provider.currentQuestion!;
      game.player.position.setValues(
        zone.rect.center.dx,
        zone.rect.center.dy,
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(find.byType(ZooCameraButton), findsOneWidget);

      // Let the reveal pulse animation finish before tapping, so the tap
      // lands once the button is back to its resting size.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(ZooCameraButton));
      await tester.pump();

      // Photo card up, progress advanced.
      expect(provider.answeredCount, 1);
      expect(find.text('1 / 3'), findsOneWidget);
      final secondQuestion = provider.currentQuestion!;
      expect(secondQuestion, isNot(zone));

      // Let the reveal delay elapse — 600ms before the success sound, then
      // 1600ms for the photo card — so the next question's BslQuestionVideo
      // mounts fresh (a new ValueKey, not the previous one left shrunk) —
      // then let its own async "no video yet" load failure resolve, the
      // same warm-up the first question needed above, before it shows the
      // placeholder full size.
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byKey(ValueKey(secondQuestion.id)), findsOneWidget);
      expect(find.text(localizer(secondQuestion.nameKey)), findsOneWidget);

      // Let remaining animations/timers (flash, placeholder shrink) settle
      // before teardown.
      await tester.pump(const Duration(seconds: 2));

      // The test environment has no native video_player plugin, so its
      // event channel reports MissingPluginException asynchronously —
      // that one is expected here; anything else is a real failure.
      expect(
        tester.takeException(),
        anyOf(isNull, isA<MissingPluginException>()),
      );
      provider.dispose();
    });
  });
}
