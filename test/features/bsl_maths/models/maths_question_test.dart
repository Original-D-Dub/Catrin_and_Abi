import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bsl_maths/models/maths_question.dart';

void main() {
  group('MathsQuestion', () {
    test('creates question with correct properties', () {
      const question = MathsQuestion(
        operand1: 3,
        operand2: 4,
        answer: 7,
      );

      expect(question.operand1, 3);
      expect(question.operand2, 4);
      expect(question.answer, 7);
      expect(question.operatorSymbol, '+');
    });

    test('toString formats correctly', () {
      const question = MathsQuestion(
        operand1: 5,
        operand2: 3,
        answer: 8,
      );

      expect(question.toString(), '5 + 3 = 8');
    });

    test('equality compares operands only', () {
      const question1 = MathsQuestion(
        operand1: 2,
        operand2: 3,
        answer: 5,
      );
      const question2 = MathsQuestion(
        operand1: 2,
        operand2: 3,
        answer: 5,
      );
      const question3 = MathsQuestion(
        operand1: 3,
        operand2: 2,
        answer: 5,
      );

      expect(question1, equals(question2));
      expect(question1, isNot(equals(question3)));
    });

    test('hashCode is consistent with equality', () {
      const question1 = MathsQuestion(
        operand1: 4,
        operand2: 5,
        answer: 9,
      );
      const question2 = MathsQuestion(
        operand1: 4,
        operand2: 5,
        answer: 9,
      );

      expect(question1.hashCode, equals(question2.hashCode));
    });
  });

  group('MathsQuestionGenerator', () {
    late Random random;

    setUp(() {
      // Use seeded random for reproducible tests
      random = Random(42);
    });

    group('generateAddition', () {
      test('generates valid addition question', () {
        final question = MathsQuestionGenerator.generateAddition(
          random: random,
          maxAnswer: 10,
        );

        expect(question.operand1, greaterThanOrEqualTo(1));
        expect(question.operand2, greaterThanOrEqualTo(1));
        expect(question.answer, equals(question.operand1 + question.operand2));
      });

      test('answer does not exceed maxAnswer for Level 1 (max 10)', () {
        for (int i = 0; i < 100; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 10,
          );

          expect(question.answer, lessThanOrEqualTo(10));
          expect(question.operand1, greaterThanOrEqualTo(1));
          expect(question.operand2, greaterThanOrEqualTo(1));
        }
      });

      test('answer does not exceed maxAnswer for Level 2 (max 20)', () {
        for (int i = 0; i < 100; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 20,
          );

          expect(question.answer, lessThanOrEqualTo(20));
          expect(question.operand1, greaterThanOrEqualTo(1));
          expect(question.operand2, greaterThanOrEqualTo(1));
        }
      });

      test('operands are capped at 10 (BSL asset limit)', () {
        for (int i = 0; i < 100; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 20,
          );

          expect(question.operand1, lessThanOrEqualTo(10));
          expect(question.operand2, lessThanOrEqualTo(10));
        }
      });

      test('generates different question from previous', () {
        const previousQuestion = MathsQuestion(
          operand1: 3,
          operand2: 4,
          answer: 7,
        );

        // Generate many questions to ensure they differ
        for (int i = 0; i < 50; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 10,
            previousQuestion: previousQuestion,
          );

          // Should not be identical to previous
          expect(question, isNot(equals(previousQuestion)));
        }
      });

      test('generates questions with answer at least 2', () {
        // Minimum is 1+1=2
        for (int i = 0; i < 100; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 10,
          );

          expect(question.answer, greaterThanOrEqualTo(2));
        }
      });

      test('generates variety of operands over multiple calls', () {
        final operand1Set = <int>{};
        final operand2Set = <int>{};

        for (int i = 0; i < 200; i++) {
          final question = MathsQuestionGenerator.generateAddition(
            random: Random(),
            maxAnswer: 10,
          );
          operand1Set.add(question.operand1);
          operand2Set.add(question.operand2);
        }

        // Should have variety in operands (not always same number)
        expect(operand1Set.length, greaterThan(3));
        expect(operand2Set.length, greaterThan(3));
      });
    });
  });
}
