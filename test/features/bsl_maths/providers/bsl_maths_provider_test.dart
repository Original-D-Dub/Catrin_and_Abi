import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catrin_abi_bsl/features/bsl_maths/providers/bsl_maths_provider.dart';

void main() {
  // GameStatsService reads Supabase.instance.client on construction, so it
  // must be initialized before any BslMathsProvider is created. No test
  // here exercises a real network call (score never reaches the win
  // threshold), so a dummy project is sufficient. Supabase's local session
  // storage needs a mocked shared_preferences backend to initialize in tests.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('BslMathsLevel', () {
    test('all levels are defined', () {
      expect(BslMathsLevel.all.length, 12);
    });

    test('Level 1 has correct configuration', () {
      final level1 = BslMathsLevel.all[0];
      expect(level1.number, 1);
      expect(level1.name, 'bsl_maths.level1.name');
      expect(level1.maxAnswer, 10);
      expect(level1.isMissingOperand, false);
    });

    test('Level 2 has correct configuration', () {
      final level2 = BslMathsLevel.all[1];
      expect(level2.number, 2);
      expect(level2.name, 'bsl_maths.level2.name');
      expect(level2.maxAnswer, 10);
      expect(level2.isMissingOperand, true);
      expect(level2.fixedTarget, 10);
    });

    test('Level 3 has correct configuration', () {
      final level3 = BslMathsLevel.all[2];
      expect(level3.number, 3);
      expect(level3.name, 'bsl_maths.level3.name');
      expect(level3.maxAnswer, 19);
      expect(level3.useTeenKeys, true);
    });

    test('Level 6 has correct configuration', () {
      final level6 = BslMathsLevel.all[5];
      expect(level6.number, 6);
      expect(level6.name, 'bsl_maths.level6.name');
      expect(level6.maxAnswer, 10);
      expect(level6.isMissingOperand, false);
      expect(level6.hideDigits, true);
    });

    test('Level 10 has correct configuration', () {
      final level10 = BslMathsLevel.all[9];
      expect(level10.number, 10);
      expect(level10.name, 'bsl_maths.level10.name');
      expect(level10.isCompetition, true);
      expect(level10.hideDigits, true);
    });

    test('Level 12 (last level) has correct configuration', () {
      final level12 = BslMathsLevel.all[11];
      expect(level12.number, 12);
      expect(level12.name, 'bsl_maths.level12.name');
      expect(level12.maxAnswer, 10);
      expect(level12.isSubtraction, true);
      expect(level12.hideDigits, false);
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

      test('starts with no entered digit', () {
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

      test('clears any entered digit', () {
        provider.startGame();
        provider.enterDigit(5);
        expect(provider.unitsDigit, isNotNull);

        provider.startGame();
        expect(provider.unitsDigit, isNull);
      });
    });

    // Every key tap directly sets the digit and immediately checks the
    // answer — there's no separate accumulate-then-submit step.
    group('enterDigit', () {
      setUp(() {
        provider.setLevel(1);
        provider.startGame();
      });

      test('entering a digit sets it and locks input', () {
        provider.enterDigit(5);
        expect(provider.unitsDigit, 5);
        expect(provider.isInputLocked, true);
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

      test('further digit presses are ignored while locked', () {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;

        provider.enterDigit(correctAnswer);
        expect(provider.score, 1);

        // Locked - this should be ignored
        provider.enterDigit(wrongAnswer);
        expect(provider.score, 1);
        expect(provider.unitsDigit, correctAnswer);
      });
    });

    group('enteredAnswer computed property', () {
      setUp(() {
        provider.setLevel(1);
        provider.startGame();
      });

      test('returns null when no digit entered', () {
        expect(provider.enteredAnswer, isNull);
      });

      test('returns the entered digit', () {
        provider.enterDigit(7);
        expect(provider.enteredAnswer, 7);
      });
    });

    group('isMissingOperandLevel', () {
      test('returns false for Level 1', () {
        provider.setLevel(1);
        expect(provider.isMissingOperandLevel, false);
      });

      test('returns true for Level 2 (Make 10)', () {
        provider.setLevel(2);
        expect(provider.isMissingOperandLevel, true);
      });

      test('returns false for Level 3 (teen keys)', () {
        provider.setLevel(3);
        expect(provider.isMissingOperandLevel, false);
      });

      test('returns true for Level 4 (missing number)', () {
        provider.setLevel(4);
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
        provider.setLevel(4);
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

      test('wrong answer clears the entered digit after delay', () async {
        final correctAnswer = provider.correctAnswer!;
        final wrongAnswer = (correctAnswer + 1) % 11;

        provider.enterDigit(wrongAnswer);
        expect(provider.unitsDigit, wrongAnswer);

        // Wait for feedback timer
        await Future.delayed(
          const Duration(milliseconds: BslMathsProvider.wrongFeedbackDurationMs + 100),
        );

        expect(provider.unitsDigit, isNull);
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

      test('notifies on setLevel', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setLevel(2);
        expect(notifyCount, greaterThan(0));
      });
    });
  });
}
