import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/maths_question.dart';

/// Game state for the BSL maths game.
///
/// Controls what feedback is shown and whether input is accepted.
enum BslMathsGameState {
  /// Game is active - waiting for player to tap an answer key
  playing,

  /// Correct answer submitted - showing green feedback before advancing
  correct,

  /// Wrong answer submitted - showing "try again" feedback before retry
  wrong,

  /// Competition timer has expired
  timeUp,
}

/// Game level configuration for BSL Maths.
///
/// Each level defines:
/// - [number]: Level number for display
/// - [name]: Display name for level selection
/// - [maxAnswer]: Maximum sum allowed for questions
/// - [isMissingOperand]: Whether to show "a + ? = c" format (find missing number)
class BslMathsLevel {
  /// Level number (1-based)
  final int number;

  /// Display name for the level
  final String name;

  /// Maximum answer value for questions in this level
  final int maxAnswer;

  /// Whether this level uses the "find the missing number" format.
  ///
  /// When true, questions display as "operand1 + ? = answer"
  /// and the player must find operand2.
  /// When false, questions display as "operand1 + operand2 = ?"
  /// and the player must find the answer.
  final bool isMissingOperand;

  /// Whether this level is a timed competition mode.
  ///
  /// When true, a 60-second countdown timer runs and wrong answers
  /// deduct a point from the score.
  final bool isCompetition;

  const BslMathsLevel({
    required this.number,
    required this.name,
    required this.maxAnswer,
    this.isMissingOperand = false,
    this.isCompetition = false,
  });

  /// All available levels
  static const List<BslMathsLevel> all = [
    BslMathsLevel(number: 1, name: 'Sums to 10', maxAnswer: 10),
    BslMathsLevel(number: 2, name: 'Sums to 20', maxAnswer: 20),
    BslMathsLevel(
      number: 3,
      name: 'Find the Missing Number',
      maxAnswer: 10,
      isMissingOperand: true,
    ),
    BslMathsLevel(
      number: 4,
      name: 'Competition',
      maxAnswer: 10,
      isCompetition: true,
    ),
  ];
}

/// Provider for managing the BSL maths game state.
///
/// Handles:
/// - Level selection (Level 1: sums to 10, Level 2: sums to 20)
/// - Random addition question generation
/// - Two-digit answer input (tens and units columns)
/// - Answer submission and correctness validation
/// - Score tracking (increments on correct answers)
/// - Clear button functionality
/// - Timed feedback display (green tick or "try again")
///
/// Two-digit input system (Level 2):
/// - First tap: digit goes to units column (right)
/// - Second tap: first digit shifts to tens column (left), new digit to units
/// - Answer calculated as: (tens × 10) + units
/// - Clear button (C) resets both columns
class BslMathsProvider extends ChangeNotifier {
  // -------------------------
  // Constants
  // -------------------------

  /// Duration to show correct answer feedback before advancing (milliseconds)
  static const int correctFeedbackDurationMs = 1000;

  /// Duration to show wrong answer feedback before allowing retry (milliseconds)
  static const int wrongFeedbackDurationMs = 1500;

  // -------------------------
  // State
  // -------------------------

  final Random _random = Random();

  /// Whether to show level selection screen
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// Current selected level
  BslMathsLevel _currentLevel = BslMathsLevel.all[0];
  BslMathsLevel get currentLevel => _currentLevel;

  /// Current game state controlling feedback display and input acceptance
  BslMathsGameState _gameState = BslMathsGameState.playing;
  BslMathsGameState get gameState => _gameState;

  /// Current question being displayed to the player
  MathsQuestion? _currentQuestion;
  MathsQuestion? get currentQuestion => _currentQuestion;

  /// Number of correct answers given in this session
  int _score = 0;
  int get score => _score;

  /// Tens digit of the entered answer (null if empty)
  int? _tensDigit;
  int? get tensDigit => _tensDigit;

  /// Units digit of the entered answer (null if empty)
  int? _unitsDigit;
  int? get unitsDigit => _unitsDigit;

  /// Whether keyboard input is currently blocked (during feedback display)
  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  /// Timer controlling feedback display duration before state transition
  Timer? _feedbackTimer;

  /// Countdown timer for competition mode (ticks every second)
  Timer? _competitionTimer;

  /// Seconds remaining in competition mode
  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  /// Whether the current level is competition mode
  bool get isCompetitionLevel => _currentLevel.isCompetition;

  /// Competition duration in seconds
  static const int competitionDurationSeconds = 60;

  // -------------------------
  // Computed Properties
  // -------------------------

  /// The currently entered answer value (computed from digits)
  ///
  /// Returns null if no digits entered.
  /// For single digit: returns units value.
  /// For two digits: returns (tens × 10) + units.
  int? get enteredAnswer {
    if (_unitsDigit == null) return null;
    if (_tensDigit == null) return _unitsDigit;
    return (_tensDigit! * 10) + _unitsDigit!;
  }

  /// Whether the current question requires two-digit input.
  ///
  /// Level 2 uses two-digit input (sums to 20).
  /// Level 3 (missing operand) uses single-digit input (operands 1-10).
  bool get requiresTwoDigitInput =>
      _currentLevel.maxAnswer > 10 && !_currentLevel.isMissingOperand;

  /// Whether the current level uses "find the missing number" format.
  bool get isMissingOperandLevel => _currentLevel.isMissingOperand;

  /// The correct answer the player needs to enter.
  ///
  /// For normal levels: the sum (operand1 + operand2).
  /// For missing operand levels: operand2 (the missing number).
  int? get correctAnswer {
    if (_currentQuestion == null) return null;
    return _currentLevel.isMissingOperand
        ? _currentQuestion!.operand2
        : _currentQuestion!.answer;
  }

  // -------------------------
  // Lifecycle
  // -------------------------

  /// Initialises the provider and shows level selection.
  BslMathsProvider() {
    showLevelSelection();
  }

  // -------------------------
  // Level Selection
  // -------------------------

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    _feedbackTimer?.cancel();
    _competitionTimer?.cancel();
    notifyListeners();
  }

  /// Sets the current level and starts the game.
  ///
  /// [levelNumber] is the 1-based level number to select.
  void setLevel(int levelNumber) {
    final level = BslMathsLevel.all.firstWhere(
      (l) => l.number == levelNumber,
      orElse: () => BslMathsLevel.all[0],
    );
    _currentLevel = level;
    notifyListeners();
  }

  // -------------------------
  // Game Control
  // -------------------------

  /// Starts or restarts the game, resetting score and generating a new question.
  void startGame() {
    _showLevelSelect = false;
    _score = 0;
    _clearDigits();
    _isInputLocked = false;
    _gameState = BslMathsGameState.playing;
    _feedbackTimer?.cancel();
    _competitionTimer?.cancel();
    _currentQuestion = MathsQuestionGenerator.generateAddition(
      random: _random,
      maxAnswer: _currentLevel.maxAnswer,
    );

    // Start countdown timer for competition mode
    if (_currentLevel.isCompetition) {
      _secondsRemaining = competitionDurationSeconds;
      _competitionTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          _secondsRemaining--;
          if (_secondsRemaining <= 0) {
            _competitionTimer?.cancel();
            _feedbackTimer?.cancel();
            _isInputLocked = true;
            _gameState = BslMathsGameState.timeUp;
          }
          notifyListeners();
        },
      );
    }

    notifyListeners();
  }

  /// Clears the entered digits (called when C button pressed or after feedback).
  void clearAnswer() {
    if (_isInputLocked) return;
    _clearDigits();
    notifyListeners();
  }

  /// Internal method to reset digit state.
  void _clearDigits() {
    _tensDigit = null;
    _unitsDigit = null;
  }

  /// Handles a digit key press (0-10).
  ///
  /// [digit] is the number (0-10) the player tapped on the keyboard.
  /// For single-digit answers: directly submits.
  /// For two-digit answers: builds up the answer digit by digit.
  void enterDigit(int digit) {
    if (_isInputLocked || _currentQuestion == null) return;

    if (requiresTwoDigitInput) {
      // Two-digit input mode
      if (_unitsDigit == null) {
        // First digit goes to units
        _unitsDigit = digit;
      } else {
        // Second digit: shift first to tens, new digit to units
        _tensDigit = _unitsDigit;
        _unitsDigit = digit;
      }
      notifyListeners();
    } else {
      // Single-digit mode (Level 1): treat as direct answer submission
      _unitsDigit = digit;
      notifyListeners();
      _checkAnswer();
    }
  }

  /// Submits the current answer for the current question (Level 2).
  ///
  /// Called when player has entered digits and confirms.
  /// For Level 1, this is called automatically after digit entry.
  void submitAnswer() {
    if (_isInputLocked || _currentQuestion == null) return;
    if (enteredAnswer == null) return;

    _checkAnswer();
  }

  /// Checks if the entered answer matches the correct answer.
  ///
  /// For normal levels, compares against the sum.
  /// For missing operand levels, compares against operand2.
  void _checkAnswer() {
    if (enteredAnswer == null) return;

    _isInputLocked = true;

    if (enteredAnswer == correctAnswer) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  /// Handles a correct answer: increment score, show green feedback, then advance.
  void _handleCorrectAnswer() {
    _score++;
    _gameState = BslMathsGameState.correct;
    notifyListeners();

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: correctFeedbackDurationMs),
      () {
        _nextQuestion();
      },
    );
  }

  /// Handles a wrong answer: show red feedback, then unlock for retry.
  ///
  /// In competition mode, deducts a point and moves to the next question.
  void _handleWrongAnswer() {
    if (_currentLevel.isCompetition) {
      _score--;
    }
    _gameState = BslMathsGameState.wrong;
    notifyListeners();

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: wrongFeedbackDurationMs),
      () {
        if (_currentLevel.isCompetition) {
          // Competition mode: move to next question after wrong answer
          _nextQuestion();
        } else {
          // Normal mode: retry the same question
          _gameState = BslMathsGameState.playing;
          _clearDigits();
          _isInputLocked = false;
          notifyListeners();
        }
      },
    );
  }

  /// Generates the next question and resets input state.
  void _nextQuestion() {
    _currentQuestion = MathsQuestionGenerator.generateAddition(
      random: _random,
      maxAnswer: _currentLevel.maxAnswer,
      previousQuestion: _currentQuestion,
    );
    _clearDigits();
    _isInputLocked = false;
    _gameState = BslMathsGameState.playing;
    notifyListeners();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _competitionTimer?.cancel();
    super.dispose();
  }
}
