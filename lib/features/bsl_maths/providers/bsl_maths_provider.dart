import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';
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

  /// Player reached 10 correct answers (levels 1–4)
  won,
}

/// Game level configuration for BSL Maths.
///
/// Each level defines:
/// - [number]: Level number for display
/// - [name]: Display name for level selection
/// - [maxAnswer]: Maximum sum allowed for questions
/// - [isMissingOperand]: Whether to show "a + ? = c" format (find missing number)
/// - [fixedTarget]: When set, every question's sum equals exactly this value.
///   Used by "Make 10" (Level 2) where questions always have the form
///   `operand1 + ? = 10`. Requires [isMissingOperand] to be true.
/// - [isCompetition]: Whether this is a timed competition mode
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

  /// Optional fixed target sum for missing-operand levels.
  ///
  /// When non-null, every generated question has operand1 + operand2 == [fixedTarget]
  /// exactly, so the displayed answer is always the same number.
  /// Requires [isMissingOperand] == true.
  final int? fixedTarget;

  /// Whether this level is a timed competition mode.
  ///
  /// When true, a 60-second countdown timer runs and wrong answers
  /// deduct a point from the score.
  final bool isCompetition;

  /// Whether this level uses subtraction instead of addition.
  final bool isSubtraction;

  /// For subtraction levels, the maximum value of the first operand.
  /// Defaults to 10 when not set.
  final int maxSubtrahend;

  /// Whether this level uses teen number keys (11–19) instead of 1–9.
  ///
  /// When true, the keyboard shows 11–19 and questions always have answers
  /// in that range. Each key press auto-submits (no two-digit entry).
  final bool useTeenKeys;

  const BslMathsLevel({
    required this.number,
    required this.name,
    required this.maxAnswer,
    this.isMissingOperand = false,
    this.fixedTarget,
    this.isCompetition = false,
    this.isSubtraction = false,
    this.maxSubtrahend = 10,
    this.useTeenKeys = false,
  });

  /// All available levels
  static const List<BslMathsLevel> all = [
    BslMathsLevel(number: 1, name: 'bsl_maths.level1.name', maxAnswer: 10),

    BslMathsLevel(
      number: 2,
      name: 'bsl_maths.level2.name',
      maxAnswer: 10,
      isMissingOperand: true,
      fixedTarget: 10,
    ),
    BslMathsLevel(
      number: 3,
      name: 'bsl_maths.level3.name',
      maxAnswer: 19,
      useTeenKeys: true,
    ),

    BslMathsLevel(
      number: 4,
      name: 'bsl_maths.level4.name',
      maxAnswer: 10,
      isMissingOperand: true,
    ),

    BslMathsLevel(
      number: 5,
      name: 'bsl_maths.level5.name',
      maxAnswer: 10,
      isCompetition: true,
    ),

    BslMathsLevel(
      number: 6,
      name: 'bsl_maths.level6.name',
      maxAnswer: 5,
      isSubtraction: true,
      maxSubtrahend: 5,
    ),

    BslMathsLevel(
      number: 7,
      name: 'bsl_maths.level7.name',
      maxAnswer: 10,
      isSubtraction: true,
    ),
  ];
}

/// Provider for managing the BSL maths game state.
///
/// Handles:
/// - Level selection
/// - Random addition/subtraction question generation
/// - Answer entry: each key tap directly submits and checks the answer
/// - Score tracking (increments on correct answers)
/// - Timed feedback display (green tick or "try again")
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
  final GameStatsService _statsService = GameStatsService();

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

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

  /// Points scored in this session. Normally +1 per correct answer; in
  /// Champion Mode see [championCorrectPoints]/[championWrongPoints].
  int _score = 0;
  int get score => _score;

  /// Number of correct answers given in this session. Drives the
  /// "10 correct" win condition independently of [score], which is
  /// weighted differently in Champion Mode.
  int _correctCount = 0;

  /// Units digit of the entered answer (null if empty)
  int? _unitsDigit;
  int? get unitsDigit => _unitsDigit;

  /// Whether keyboard input is currently blocked (during feedback display)
  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  /// Called after answer checking with `true` for correct, `false` for wrong.
  Function(bool isCorrect)? onAnswerResult;

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

  /// Score required on the Competition level (level 5) to unlock Champion Mode.
  static const int championModeUnlockScore = 10;

  /// The level number whose personal best gates Champion Mode.
  static const int championModeUnlockLevel = 5;

  /// Points awarded for a correct answer in Champion Mode.
  static const int championCorrectPoints = 10;

  /// Points deducted for a wrong answer in Champion Mode.
  static const int championWrongPoints = 5;

  /// Whether Champion Mode is enabled — hides the numeral labels on the
  /// keyboard so the player must recognise the BSL number sign alone, and
  /// scores [championCorrectPoints]/-[championWrongPoints] per answer.
  bool _championMode = false;
  bool get championMode => _championMode;

  /// Whether the player has unlocked Champion Mode by scoring at least
  /// [championModeUnlockScore] on level [championModeUnlockLevel].
  bool _isChampionModeUnlocked = false;
  bool get isChampionModeUnlocked => _isChampionModeUnlocked;

  /// True for one session only: the player just crossed the Champion Mode
  /// unlock threshold (see [championModeUnlockScore]) for the first time.
  /// The screen shows a celebratory banner while this is true, then calls
  /// [dismissChampionModeUnlockedBanner] to clear it.
  bool _justUnlockedChampionMode = false;
  bool get justUnlockedChampionMode => _justUnlockedChampionMode;

  // -------------------------
  // Computed Properties
  // -------------------------

  /// The currently entered answer value (computed from the entered digit).
  ///
  /// Returns null if no digit has been entered.
  int? get enteredAnswer => _unitsDigit;

  /// Whether the current level uses teen number keys (11–19).
  bool get useTeenKeys => _currentLevel.useTeenKeys;

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
    // Record score when leaving a non-competition game mid-session (not already recorded via won/timeUp)
    if (!_showLevelSelect &&
        !_currentLevel.isCompetition &&
        _score > 0 &&
        _gameState != BslMathsGameState.won &&
        _gameState != BslMathsGameState.timeUp) {
      _statsService.recordGameResult(
        GameIds.bslMaths,
        _score,
        level: _currentLevel.number,
      );
    }
    _showLevelSelect = true;
    _feedbackTimer?.cancel();
    _competitionTimer?.cancel();
    _refreshChampionModeUnlock();
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

  /// Unlocks Champion Mode from the player's personal best on
  /// [championModeUnlockLevel], if it isn't already unlocked.
  ///
  /// Only ever raises [isChampionModeUnlocked], never lowers it: guest play
  /// isn't persisted by [GameStatsService] (it no-ops for anonymous users),
  /// so this DB lookup always comes back empty for guests — if it were
  /// allowed to clear the flag, a guest who just unlocked Champion Mode by
  /// scoring in this session would see it re-locked the moment they
  /// returned to level select.
  Future<void> _refreshChampionModeUnlock() async {
    if (_isChampionModeUnlocked) return;
    final best = await _statsService.getPersonalBest(
      '${GameIds.bslMaths}_$championModeUnlockLevel',
    );
    if ((best ?? 0) >= championModeUnlockScore) {
      _isChampionModeUnlocked = true;
      _championMode = !_championModeOffThisSession;
      notifyListeners();
    }
  }

  /// Set when the player long-presses the Champion rosette to switch
  /// Champion Mode off. Static so it lasts for the rest of the app session
  /// (every new provider starts with Champion Mode off), then resets — once
  /// unlocked, Champion Mode is on by default.
  static bool _championModeOffThisSession = false;

  /// Enables or disables Champion Mode for the rest of this app session
  /// (see [_championModeOffThisSession]). No-ops if not yet unlocked.
  void setChampionMode(bool value) {
    if (!_isChampionModeUnlocked) return;
    _championMode = value;
    _championModeOffThisSession = !value;
    notifyListeners();
  }

  // -------------------------
  // Game Control
  // -------------------------

  /// Starts or restarts the game, resetting score and generating a new question.
  void startGame() {
    _showLevelSelect = false;
    _score = 0;
    _correctCount = 0;
    _lastResult = null;
    _clearDigits();
    _isInputLocked = false;
    _gameState = BslMathsGameState.playing;
    _justUnlockedChampionMode = false;
    _feedbackTimer?.cancel();
    _competitionTimer?.cancel();
    _currentQuestion = _generateQuestion();

    // Start countdown timer for competition mode
    if (_currentLevel.isCompetition) {
      _secondsRemaining = competitionDurationSeconds;
      _competitionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _competitionTimer?.cancel();
          _feedbackTimer?.cancel();
          _isInputLocked = true;
          _lastResult = null;
          _gameState = BslMathsGameState.timeUp;
          _statsService
              .recordGameResult(
                GameIds.bslMaths,
                _score,
                level: _currentLevel.number,
              )
              .then((result) {
                _lastResult = result;
                if (_currentLevel.number == championModeUnlockLevel &&
                    !_isChampionModeUnlocked &&
                    _score >= championModeUnlockScore) {
                  _isChampionModeUnlocked = true;
                  _championMode = !_championModeOffThisSession;
                  _justUnlockedChampionMode = true;
                }
                notifyListeners();
              });
        }
        notifyListeners();
      });
    }

    notifyListeners();
  }

  /// Clears [justUnlockedChampionMode] once the unlock banner has been
  /// shown and dismissed.
  void dismissChampionModeUnlockedBanner() {
    _justUnlockedChampionMode = false;
    notifyListeners();
  }

  /// Internal method to reset digit state.
  void _clearDigits() {
    _unitsDigit = null;
  }

  /// Handles a digit key press and directly submits it as the answer.
  ///
  /// [digit] is the number the player tapped on the keyboard.
  void enterDigit(int digit) {
    if (_isInputLocked || _currentQuestion == null) return;

    _unitsDigit = digit;
    notifyListeners();
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
    _correctCount++;
    _score += _championMode ? championCorrectPoints : 1;
    _gameState = BslMathsGameState.correct;
    onAnswerResult?.call(true);
    notifyListeners();

    // Halved in Champion Mode on the competition level to keep the pace up.
    final feedbackMs = _championMode && _currentLevel.isCompetition
        ? correctFeedbackDurationMs ~/ 2
        : correctFeedbackDurationMs;
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(Duration(milliseconds: feedbackMs), () {
      if (!_currentLevel.isCompetition && _correctCount >= 10) {
        _isInputLocked = true;
        _lastResult = null;
        _gameState = BslMathsGameState.won;
        _statsService
            .recordGameResult(
              GameIds.bslMaths,
              _score,
              level: _currentLevel.number,
            )
            .then((result) {
              _lastResult = result;
              notifyListeners();
            });
        notifyListeners();
      } else {
        _nextQuestion();
      }
    });
  }

  /// Handles a wrong answer: show red feedback, then unlock for retry.
  ///
  /// In Champion Mode, deducts [championWrongPoints]. Otherwise, in
  /// competition mode, deducts a point. Competition mode then moves to the
  /// next question; other levels retry the same question.
  void _handleWrongAnswer() {
    if (_championMode) {
      _score -= championWrongPoints;
    } else if (_currentLevel.isCompetition) {
      _score--;
    }
    _gameState = BslMathsGameState.wrong;
    onAnswerResult?.call(false);
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

  /// Generates a question appropriate for the current level.
  ///
  /// Uses [MathsQuestionGenerator.generateAdditionWithFixedTarget] when the
  /// level has a [BslMathsLevel.fixedTarget] (e.g. "Make 10"), otherwise
  /// uses [MathsQuestionGenerator.generateAddition] for varying sums.
  MathsQuestion _generateQuestion({MathsQuestion? previous}) {
    if (_currentLevel.isSubtraction) {
      return MathsQuestionGenerator.generateSubtraction(
        random: _random,
        maxOperand1: _currentLevel.maxSubtrahend,
        previousQuestion: previous,
      );
    }
    if (_currentLevel.fixedTarget != null) {
      return MathsQuestionGenerator.generateAdditionWithFixedTarget(
        random: _random,
        target: _currentLevel.fixedTarget!,
        previousQuestion: previous,
      );
    }
    return MathsQuestionGenerator.generateAddition(
      random: _random,
      maxAnswer: _currentLevel.maxAnswer,
      minAnswer: _currentLevel.useTeenKeys ? 11 : 2,
      previousQuestion: previous,
    );
  }

  /// Generates the next question and resets input state.
  void _nextQuestion() {
    _currentQuestion = _generateQuestion(previous: _currentQuestion);
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
