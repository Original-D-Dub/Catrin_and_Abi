import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';
import '../models/dressed_character.dart';

/// Game state for the Character Identification game.
enum CharacterIdGameState {
  /// Showing level selection screen
  levelSelect,

  /// Game is active - waiting for player to guess
  playing,

  /// Correct answer selected
  correct,

  /// Wrong answer selected
  wrong,

  /// Level completed (10 correct answers, or Level 3 timer expired)
  finished,
}

/// Represents a level in the Character Identification game.
class CharacterIdLevel {
  final int number;

  const CharacterIdLevel({required this.number});

  /// All available levels.
  static const List<CharacterIdLevel> all = [
    CharacterIdLevel(number: 1),
    CharacterIdLevel(number: 2),
    CharacterIdLevel(number: 3),
    CharacterIdLevel(number: 4),
  ];
}

/// Provider for managing the Character Identification game state.
///
/// Handles:
/// - Level selection and management
/// - Levels 1-4: clothing colour questions about a randomly dressed character
/// - Tracking player guesses and score
/// - Managing game state (correct/wrong feedback)
class CharacterIdProvider extends ChangeNotifier {
  // -------------------------
  // Constants
  // -------------------------

  /// Duration to show correct feedback before generating next character
  static const int correctFeedbackDurationMs = 1500;

  /// Duration to show wrong feedback before allowing retry
  static const int wrongFeedbackDurationMs = 1000;


  /// Time limit for the Level 4 speed round in seconds
  static const int speedRoundTimeLimitSeconds = 60;

  /// The only colours used in Level 1
  static const List<String> starterColours = ['red', 'blue', 'green'];

  // -------------------------
  // State
  // -------------------------

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  /// Called after answer checking with `true` for correct, `false` for wrong.
  Function(bool isCorrect)? onAnswerResult;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  /// Current game state
  CharacterIdGameState _gameState = CharacterIdGameState.levelSelect;
  CharacterIdGameState get gameState => _gameState;

  /// Current level
  CharacterIdLevel _currentLevel = CharacterIdLevel.all[0];
  CharacterIdLevel get currentLevel => _currentLevel;

  /// Whether to show level selection
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// The character currently being displayed
  DressedCharacter? _currentCharacter;
  DressedCharacter? get currentCharacter => _currentCharacter;

  /// Which clothing slot the current question asks about (alternates)
  ClothingSlot _questionSlot = ClothingSlot.bottom;

  /// The answer choices (clothing colours)
  List<String> _answerChoices = [];
  List<String> get answerChoices => _answerChoices;

  /// The correct answer for the current round
  String? _correctAnswer;
  String? get correctAnswer => _correctAnswer;

  /// The garment the current question asks about — always one the
  /// displayed character is wearing.
  ClothingItem? get questionItem =>
      _currentCharacter?.wornIn(_questionSlot).item;

  /// The question text for the current round
  String get currentQuestion {
    final item = questionItem;
    if (item == null) return '';
    return item.isPlural
        ? 'What colour ${item.type} am I wearing?'
        : 'What colour is the ${item.type}?';
  }

  /// The answer that was last selected (for highlighting)
  String? _selectedAnswer;
  String? get selectedAnswer => _selectedAnswer;

  /// Current score (number of correct answers)
  int _score = 0;
  int get score => _score;

  /// Total number of rounds played
  int _roundsPlayed = 0;
  int get roundsPlayed => _roundsPlayed;

  /// Timer for the Level 4 speed round
  Timer? _timer;

  /// Remaining seconds for the Level 4 speed round
  int _remainingSeconds = speedRoundTimeLimitSeconds;
  int get remainingSeconds => _remainingSeconds;

  // -------------------------
  // Computed Properties
  // -------------------------

  /// Level 1: red, blue and green only, with colour hints (5 to win)
  bool get usesStarterColours => _currentLevel.number == 1;

  /// Number of questions (correct answers) needed to complete the level.
  /// The speed round has no target — it plays until the timer expires.
  int get questionsPerLevel => _currentLevel.number == 1 ? 5 : 10;

  /// Levels 1 and 2 colour the answer buttons as a hint
  bool get showsColourHints => _currentLevel.number <= 2;

  /// Level 4: Speed Round - 60 seconds, no colour hints
  bool get isSpeedRound => _currentLevel.number == 4;

  /// Colours available in the current level
  List<String> get _levelColours =>
      usesStarterColours ? starterColours : clothingColours;

  // -------------------------
  // Level Selection
  // -------------------------

  /// Shows the level selection screen.
  void showLevelSelection() {
    _stopTimer();
    _showLevelSelect = true;
    _gameState = CharacterIdGameState.levelSelect;
    notifyListeners();
  }

  /// Selects a level and starts the game.
  void selectLevel(int levelNumber) {
    _currentLevel = CharacterIdLevel.all.firstWhere(
      (l) => l.number == levelNumber,
      orElse: () => CharacterIdLevel.all[0],
    );
    _showLevelSelect = false;
    _score = 0;
    _roundsPlayed = 0;
    _startLevel();
    notifyListeners();
  }

  /// Starts the current level.
  void _startLevel() {
    // Stop any existing timer
    _stopTimer();

    // All levels use the same clothing colour questions
    _generateRound();

    // Reset timer display for the speed round — timer starts via startSpeedRound()
    if (isSpeedRound) {
      _remainingSeconds = speedRoundTimeLimitSeconds;
    }
    _gameState = CharacterIdGameState.playing;
  }

  /// Starts the countdown timer for the speed round.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();

      if (_remainingSeconds <= 0) {
        _stopTimer();
        _lastResult = null;
        _gameState = CharacterIdGameState.finished;
        notifyListeners();
        _statsService.recordGameResult(GameIds.characterId, _score, level: _currentLevel.number).then((result) {
          _lastResult = result;
          notifyListeners();
        });
      }
    });
  }

  /// Called by the screen after the intro countdown completes.
  void startSpeedRound() {
    if (!isSpeedRound) return;
    _startTimer();
    notifyListeners();
  }

  /// Stops the countdown timer.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // -------------------------
  // Round Logic
  // -------------------------

  /// Generates a new round.
  ///
  /// Dresses a random body in a random top and bottom, each in a random
  /// colour, then asks about the colour of one of them (alternating
  /// top/bottom). Answer choices are the correct colour plus 2 others from
  /// the level's colours.
  void _generateRound() {
    _questionSlot = _questionSlot == ClothingSlot.top
        ? ClothingSlot.bottom
        : ClothingSlot.top;

    _currentCharacter = _randomCharacter();
    _correctAnswer = _currentCharacter!.wornIn(_questionSlot).colour;

    final wrongChoices = _levelColours
        .where((c) => c != _correctAnswer)
        .toList()
      ..shuffle(_random);

    _answerChoices = [_correctAnswer!, ...wrongChoices.take(2)]
      ..shuffle(_random);
    _selectedAnswer = null;
  }

  /// Returns a randomly dressed character in the level's colours, avoiding
  /// an exact repeat of the previous outfit and a top and bottom in the same
  /// colour. Items that can't be shown in any level colour (e.g. the orange
  /// coat in Level 1) are skipped.
  DressedCharacter _randomCharacter() {
    T pick<T>(List<T> items) => items[_random.nextInt(items.length)];
    final colours = _levelColours;

    WornItem randomWorn(ClothingSlot slot) {
      final item = pick(ClothingItem.inSlot(slot)
          .where((c) => c.availableColours.any(colours.contains))
          .toList());
      return WornItem(
        item,
        pick(item.availableColours.where(colours.contains).toList()),
      );
    }

    DressedCharacter next;
    do {
      next = DressedCharacter(
        body: pick(CharacterBody.all),
        top: randomWorn(ClothingSlot.top),
        bottom: randomWorn(ClothingSlot.bottom),
      );
    } while (next.top.colour == next.bottom.colour ||
        next.sameOutfitAs(_currentCharacter));
    return next;
  }

  /// Called when the player selects an answer.
  void selectLevel1Answer(String answer) {
    if (_gameState != CharacterIdGameState.playing) return;
    if (_correctAnswer == null) return;

    _selectedAnswer = answer;

    if (answer == _correctAnswer) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  /// Handles a correct answer.
  void _handleCorrectAnswer() {
    _score++;
    _roundsPlayed++;
    _gameState = CharacterIdGameState.correct;
    onAnswerResult?.call(true);
    notifyListeners();

    // Check if Level 1-3 is complete (5 or 10 correct answers)
    // The speed round has no win condition - plays until timer expires
    if (!isSpeedRound && _score >= questionsPerLevel) {
      Future.delayed(
        const Duration(milliseconds: correctFeedbackDurationMs),
        () {
          _lastResult = null;
          _gameState = CharacterIdGameState.finished;
          notifyListeners();
          _statsService.recordGameResult(GameIds.characterId, _score, level: _currentLevel.number).then((result) {
            _lastResult = result;
            notifyListeners();
          });
        },
      );
      return;
    }

    // Show feedback then generate next round
    Future.delayed(
      const Duration(milliseconds: correctFeedbackDurationMs),
      () {
        _selectedAnswer = null;
        _generateRound();
        _gameState = CharacterIdGameState.playing;
        notifyListeners();
      },
    );
  }

  /// Handles a wrong answer.
  void _handleWrongAnswer() {
    _gameState = CharacterIdGameState.wrong;
    onAnswerResult?.call(false);
    notifyListeners();

    // Show feedback then allow retry
    Future.delayed(
      const Duration(milliseconds: wrongFeedbackDurationMs),
      () {
        _selectedAnswer = null;
        _gameState = CharacterIdGameState.playing;
        notifyListeners();
      },
    );
  }

  /// Resets the game to start fresh.
  void resetGame() {
    _score = 0;
    _roundsPlayed = 0;
    _lastResult = null;
    _selectedAnswer = null;
    _startLevel();
    notifyListeners();
  }

  /// Skips to the next round without scoring.
  void skipRound() {
    if (_gameState != CharacterIdGameState.playing) return;

    _roundsPlayed++;
    _selectedAnswer = null;
    _generateRound();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
