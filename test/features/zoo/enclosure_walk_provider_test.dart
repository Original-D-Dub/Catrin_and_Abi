import 'dart:math';

import 'package:catrin_abi_bsl/features/zoo/models/enclosure_level_config.dart';
import 'package:catrin_abi_bsl/features/zoo/providers/enclosure_walk_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The enclosure walk's BSL video quiz: three distinct questions drawn
/// from the building's enclosures, pictures only count in front of the
/// right animal, and the level completes after all three.
void main() {
  group('EnclosureWalkProvider', () {
    EnclosureWalkProvider makeProvider() => EnclosureWalkProvider(
          config: EnclosureLevelConfig.aquarium,
          random: Random(42),
        );

    test('draws 3 distinct questions from the level enclosures', () {
      final provider = makeProvider();

      expect(provider.questions.length, 3);
      expect(provider.questions.map((q) => q.id).toSet().length, 3);
      for (final question in provider.questions) {
        expect(
          EnclosureLevelConfig.aquarium.enclosures.contains(question),
          isTrue,
        );
      }
      expect(provider.currentQuestion, provider.questions.first);
      expect(provider.isComplete, isFalse);
      provider.dispose();
    });

    test('takeQuizPicture is a no-op while walking (no active enclosure)',
        () {
      final provider = makeProvider();
      expect(provider.takeQuizPicture(), isNull);
      expect(provider.answeredCount, 0);
      provider.dispose();
    });

    test('pictures answer the quiz only in front of the correct enclosure',
        () {
      final provider = makeProvider();
      final target = provider.currentQuestion!;
      final wrong = EnclosureLevelConfig.aquarium.enclosures
          .firstWhere((spec) => spec.id != target.id);

      // Wrong animal: rejected, question unchanged.
      provider.setActiveEnclosure(wrong);
      expect(provider.takeQuizPicture(), isFalse);
      expect(provider.currentQuestion, target);
      expect(provider.answeredCount, 0);

      // Correct animal: captured, badge set, next question up.
      provider.setActiveEnclosure(target);
      expect(provider.takeQuizPicture(), isTrue);
      expect(provider.lastCaptured, target);
      expect(provider.isPhotographed(target.id), isTrue);
      expect(provider.answeredCount, 1);
      expect(provider.currentQuestion, provider.questions[1]);
      provider.dispose();
    });

    test('completes after 3 correct answers and resets cleanly', () {
      final provider = makeProvider();

      for (final question in provider.questions) {
        provider.setActiveEnclosure(question);
        expect(provider.takeQuizPicture(), isTrue);
      }

      expect(provider.isComplete, isTrue);
      expect(provider.currentQuestion, isNull);
      expect(provider.answeredCount, 3);
      // Once complete, further pictures are no-ops.
      expect(provider.takeQuizPicture(), isNull);

      provider.reset();
      expect(provider.isComplete, isFalse);
      expect(provider.answeredCount, 0);
      expect(provider.questions.length, 3);
      expect(provider.lastCaptured, isNull);
      provider.dispose();
    });

    test(
        'forBuilding maps walk buildings and leaves others on the placeholder',
        () {
      expect(EnclosureLevelConfig.forBuilding('aquarium'),
          same(EnclosureLevelConfig.aquarium));
      expect(EnclosureLevelConfig.forBuilding('reptile-house'),
          same(EnclosureLevelConfig.reptileHouse));
      expect(EnclosureLevelConfig.forBuilding('aviary'), isNull);
    });
  });
}
