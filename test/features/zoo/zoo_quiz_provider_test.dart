import 'dart:math';

import 'package:catrin_abi_bsl/features/zoo/models/zoo_animal_zone.dart';
import 'package:catrin_abi_bsl/features/zoo/providers/zoo_quiz_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The BSL video photo quiz: three distinct questions drawn from the
/// map's animal zones, pictures only count in the right animal's zone,
/// and the quiz completes after all three.
void main() {
  ZooQuizProvider makeProvider() => ZooQuizProvider(random: Random(42));

  test('draws 3 distinct questions from the animal zones', () {
    final provider = makeProvider();

    expect(provider.questions.length, 3);
    expect(provider.questions.map((q) => q.id).toSet().length, 3);
    for (final question in provider.questions) {
      expect(ZooAnimalZone.all.contains(question), isTrue);
    }
    expect(provider.currentQuestion, provider.questions.first);
    expect(provider.isComplete, isFalse);
    provider.dispose();
  });

  test('pictures answer the quiz only in the correct animal zone', () {
    final provider = makeProvider();
    final target = provider.currentQuestion!;
    final wrong =
        ZooAnimalZone.all.firstWhere((zone) => zone.id != target.id);

    // Walking (no active zone): no-op.
    expect(provider.takeQuizPicture(), isNull);

    // Wrong animal: rejected, question unchanged.
    provider.setActiveZone(wrong);
    expect(provider.takeQuizPicture(), isFalse);
    expect(provider.currentQuestion, target);
    expect(provider.answeredCount, 0);

    // Correct animal: captured, next question up.
    provider.setActiveZone(target);
    expect(provider.takeQuizPicture(), isTrue);
    expect(provider.lastCaptured, target);
    expect(provider.answeredCount, 1);
    expect(provider.currentQuestion, provider.questions[1]);
    provider.dispose();
  });

  test('farm level draws its 3 questions from the farm zones only', () {
    final provider =
        ZooQuizProvider(zones: ZooAnimalZone.farm, random: Random(7));

    expect(provider.zones, ZooAnimalZone.farm);
    expect(provider.questions.length, 3);
    expect(provider.questions.map((q) => q.id).toSet().length, 3);
    for (final question in provider.questions) {
      expect(ZooAnimalZone.farm.contains(question), isTrue);
    }
    provider.dispose();
  });

  test('completes after 3 correct answers and resets cleanly', () {
    final provider = makeProvider();

    for (final question in provider.questions) {
      provider.setActiveZone(question);
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
}
