import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bsl_maths/providers/bsl_maths_provider.dart';

void main() {
  group('BslMathsLevel', () {
    test('all levels are defined', () {
      expect(BslMathsLevel.all.length, 3);
    });

    test('Level 1 has correct configuration', () {
      final level1 = BslMathsLevel.all[0];
      expect(level1.number, 1);
      expect(level1.name, 'Sums to 10');
      expect(level1.maxAnswer, 10);
      expect(level1.isMissingOperand, false);
    });

    test('Level 2 has correct configuration', () {
      final level2 = BslMathsLevel.all[1];
      expect(level2.number, 2);
      expect(level2.name, 'Sums to 20');
      expect(level2.maxAnswer, 20);
      expect(level2.isMissingOperand, false);
    });

    test('Level 3 has correct configuration', () {
      final level3 = BslMathsLevel.all[2];
      expect(level3.number, 3);
      expect(level3.name, 'Find the Missing Number');
      expect(level3.maxAnswer, 10);
      expect(level3.isMissingOperand, true);
    });
  });

  group('BslMathsProvider', () {
    late BslMathsProvider provider;

    setUp(() {
      provider = BslMathsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('initialization', () {
      test('starts with level selection visible', () {
        expect(provider.showLevelSelect, true);
      });

      test('starts with default level (Level 1)', () {
        expect(provider.currentLevel.number, 1);
      });

      test('starts with zero score', () {
        expect(provider.score, 0);
      });

      test('starts with no entered digits', () {
        expect(provider.tensDigit, isNull);
        expect(provider.unitsDigit, isNull);
        expect(provider.enteredAnswer, isNull);
      });

      test('starts with input not locked', () {
        expect(provider.isInputLocked, false);
      });
    });

    group('level selection', () {
      test('setLevel changes current level', () {
        provider.setLevel(2);
        expect(provider.currentLevel.number, 2);

        provider.setLevel(3);
        expect(provider.currentLevel.number, 3);
      });

      test('setLevel with invalid number defaults to Level 1', () {
        provider.setLevel(99);
        expect(provider.currentLevel.number, 1);
      });

      test('showLevelSelection sets showLevelSelect to true', () {
        provider.startGame();
        expect(provider.showLevelSelect, false);

        provider.showLevelSelection();
        expect(provider.showLevelSelect, true);
      });
    });

    group('startGame', () {
      test('hides level selection', () {
        provider.startGame();
        expect(provider.showLevelSelect, false);
      });

      test('resets score to zero', () {
        provider.startGame();
        // Simulate getting correct answer
        provider.enterDigit(provider.correctAnswer!);
        expect(provider.score, greaterThan(0));

        // Restart should reset
        provider.startGame();
        expect(provider.score, 0);
      });

      test('generates a question', () {
        expect(provider.currentQuestion, isNull);
        provider.startGame();
        expect(provider.currentQuestion, isNotNull);
      });

      test('sets game state to playing', () {
        provider.startGame();
        expect(provider.gameState, BslMathsGameState.playing);
      });

      test('clears any entered digits', () {
        provider.startGame();
        provider.setLevel(2);
        provider.startGame();
        provider.enterDigit(5);
        expect(provider.unitsDigit, 5);

        provider.startGame();
        expect(provider.tensDigit, isNull);
        expect(provider.unitsDigit, isNull);
      });
    });

    group('enterDigit - Level 1 (single digit mode)', () {
      setUp(() {
        provider.setLevel(1);
        provider.startGame();
      });

      test('entering digit sets units digit', () {
        provider.enterDigit(5);
        expect(provider.unitsDigit, 5);
      });

      test('entering correct answer increments score', () {
        final correctAnswer = provider.correctAnswer!;
        expect(provider.score, 0);

        provider.enterDigit(correctAnswer);
        expect(provider.score, 1);
      });

      test('entering correct answer sets state to correct', () {
        final correctAnswer = provider.correctAnswer!;
        provider.enterDigit(correctAnswer);
        expect(provider.gameState, BslMathsGameState.correct);
      });

      test('entering wrong answer sets state to wrong', () {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;

        provider.enterDigit(wrongAnswer);
        expect(provider.gameState, BslMathsGameState.wrong);
      });

      test('entering wrong answer does not increment score', () {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;

        provider.enterDigit(wrongAnswer);
        expect(provider.score, 0);
      });

      test('input is locked after answer submission', () {
        final correctAnswer = provider.correctAnswer!;
        provider.enterDigit(correctAnswer);
        expect(provider.isInputLocked, true);
      });
    });

    group('enterDigit - Level 2 (two digit mode)', () {
      setUp(() {
        provider.setLevel(2);
        provider.startGame();
      });

      test('first digit goes to units', () {
        provider.enterDigit(5);
        expect(provider.unitsDigit, 5);
        expect(provider.tensDigit, isNull);
        expect(provider.enteredAnswer, 5);
      });

      test('second digit shifts first to tens', () {
        provider.enterDigit(1);
        provider.enterDigit(5);

        expect(provider.tensDigit, 1);
        expect(provider.unitsDigit, 5);
        expect(provider.enteredAnswer, 15);
      });

      test('requires explicit submit in two digit mode', () {
        provider.enterDigit(5);
        // Should still be playing - not auto-submitted
        expect(provider.gameState, BslMathsGameState.playing);
      });
    });

    group('submitAnswer - Level 2', () {
      setUp(() {
        provider.setLevel(2);
        provider.startGame();
      });

      test('does nothing if no digits entered', () {
        provider.submitAnswer();
        expect(provider.gameState, BslMathsGameState.playing);
      });

      test('submitting correct answer increments score', () {
        final correctAnswer = provider.correctAnswer!;

        if (correctAnswer >= 10) {
          provider.enterDigit(correctAnswer ~/ 10);
          provider.enterDigit(correctAnswer % 10);
        } else {
          provider.enterDigit(correctAnswer);
        }

        provider.submitAnswer();
        expect(provider.score, 1);
      });

      test('submitting correct answer sets state to correct', () {
        final correctAnswer = provider.correctAnswer!;

        if (correctAnswer >= 10) {
          provider.enterDigit(correctAnswer ~/ 10);
          provider.enterDigit(correctAnswer % 10);
        } else {
          provider.enterDigit(correctAnswer);
        }

        provider.submitAnswer();
        expect(provider.gameState, BslMathsGameState.correct);
      });
    });

    group('clearAnswer', () {
      setUp(() {
        provider.setLevel(2);
        provider.startGame();
      });

      test('clears entered digits', () {
        provider.enterDigit(1);
        provider.enterDigit(5);
        expect(provider.enteredAnswer, 15);

        provider.clearAnswer();
        expect(provider.tensDigit, isNull);
        expect(provider.unitsDigit, isNull);
        expect(provider.enteredAnswer, isNull);
      });

      test('does nothing when input is locked', () {
        final correctAnswer = provider.correctAnswer!;
        if (correctAnswer >= 10) {
          provider.enterDigit(correctAnswer ~/ 10);
          provider.enterDigit(correctAnswer % 10);
        } else {
          provider.enterDigit(correctAnswer);
        }
        provider.submitAnswer();

        // Input is now locked
        expect(provider.isInputLocked, true);

        // Clear should do nothing
        provider.clearAnswer();
        expect(provider.unitsDigit, isNotNull);
      });
    });

    group('enteredAnswer computed property', () {
      setUp(() {
        provider.setLevel(2);
        provider.startGame();
      });

      test('returns null when no digits entered', () {
        expect(provider.enteredAnswer, isNull);
      });

      test('returns units value for single digit', () {
        provider.enterDigit(7);
        expect(provider.enteredAnswer, 7);
      });

      test('calculates two digit value correctly', () {
        provider.enterDigit(1);
        provider.enterDigit(8);
        expect(provider.enteredAnswer, 18);
      });

      test('handles zero in units place', () {
        provider.enterDigit(1);
        provider.enterDigit(0);
        expect(provider.enteredAnswer, 10);
      });

      test('handles zero in tens place', () {
        provider.enterDigit(0);
        provider.enterDigit(5);
        expect(provider.enteredAnswer, 5);
      });
    });

    group('requiresTwoDigitInput', () {
      test('returns false for Level 1', () {
        provider.setLevel(1);
        provider.startGame();
        expect(provider.requiresTwoDigitInput, false);
      });

      test('returns true for Level 2', () {
        provider.setLevel(2);
        provider.startGame();
        expect(provider.requiresTwoDigitInput, true);
      });

      test('returns false for Level 3 (missing operand)', () {
        provider.setLevel(3);
        provider.startGame();
        expect(provider.requiresTwoDigitInput, false);
      });
    });

    group('isMissingOperandLevel', () {
      test('returns false for Level 1', () {
        provider.setLevel(1);
        expect(provider.isMissingOperandLevel, false);
      });

      test('returns false for Level 2', () {
        provider.setLevel(2);
        expect(provider.isMissingOperandLevel, false);
      });

      test('returns true for Level 3', () {
        provider.setLevel(3);
        expect(provider.isMissingOperandLevel, true);
      });
    });

    group('correctAnswer', () {
      test('returns null when no question', () {
        expect(provider.correctAnswer, isNull);
      });

      test('returns sum for normal levels', () {
        provider.setLevel(1);
        provider.startGame();

        final question = provider.currentQuestion!;
        expect(provider.correctAnswer, question.answer);
        expect(provider.correctAnswer, question.operand1 + question.operand2);
      });

      test('returns operand2 for missing operand level', () {
        provider.setLevel(3);
        provider.startGame();

        final question = provider.currentQuestion!;
        expect(provider.correctAnswer, question.operand2);
      });
    });

    group('game state transitions', () {
      setUp(() {
        provider.setLevel(1);
        provider.startGame();
      });

      test('starts in playing state', () {
        expect(provider.gameState, BslMathsGameState.playing);
      });

      test('transitions to correct on right answer', () {
        final correctAnswer = provider.correctAnswer!;
        provider.enterDigit(correctAnswer);
        expect(provider.gameState, BslMathsGameState.correct);
      });

      test('transitions to wrong on incorrect answer', () {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;
        provider.enterDigit(wrongAnswer);
        expect(provider.gameState, BslMathsGameState.wrong);
      });
    });

    group('feedback timers', () {
      setUp(() {
        provider.setLevel(1);
        provider.startGame();
      });

      test('correct answer advances to next question after delay', () async {
        final originalQuestion = provider.currentQuestion;
        final correctAnswer = provider.correctAnswer!;

        provider.enterDigit(correctAnswer);

        // Wait for feedback timer
        await Future.delayed(
          const Duration(milliseconds: BslMathsProvider.correctFeedbackDurationMs + 100),
        );

        expect(provider.currentQuestion, isNot(equals(originalQuestion)));
        expect(provider.gameState, BslMathsGameState.playing);
      });

      test('wrong answer returns to playing after delay', () async {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;

        provider.enterDigit(wrongAnswer);
        expect(provider.gameState, BslMathsGameState.wrong);

        // Wait for feedback timer
        await Future.delayed(
          const Duration(milliseconds: BslMathsProvider.wrongFeedbackDurationMs + 100),
        );

        expect(provider.gameState, BslMathsGameState.playing);
        expect(provider.isInputLocked, false);
      });

      test('wrong answer clears digits after delay', () async {
        provider.setLevel(2);
        provider.startGame();

        // Enter a wrong answer
        provider.enterDigit(9);
        provider.enterDigit(9);
        provider.submitAnswer();

        expect(provider.unitsDigit, 9);

        // Wait for feedback timer
        await Future.delayed(
          const Duration(milliseconds: BslMathsProvider.wrongFeedbackDurationMs + 100),
        );

        expect(provider.unitsDigit, isNull);
        expect(provider.tensDigit, isNull);
      });
    });

    group('notifyListeners', () {
      test('notifies on startGame', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.startGame();
        expect(notifyCount, greaterThan(0));
      });

      test('notifies on enterDigit', () {
        provider.startGame();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.enterDigit(5);
        expect(notifyCount, greaterThan(0));
      });

      test('notifies on clearAnswer', () {
        provider.setLevel(2);
        provider.startGame();
        provider.enterDigit(5);

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearAnswer();
        expect(notifyCount, greaterThan(0));
      });

      test('notifies on setLevel', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setLevel(2);
        expect(notifyCount, greaterThan(0));
      });
    });
  });
}
