import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Levels ────────────────────────────────────────────────────────────────────

class NumberLineLevel {
  final int number;
  final String name;

  /// Maximum number of circles that can appear (min is always 1).
  final int maxCircles;

  /// The number line's length, and the target the player is trying to
  /// reach on make-N levels (5 or 10).
  final int targetNumber;

  /// When true the player counts the cakes already on the line ("How many
  /// cakes do you see?") instead of working out how many more are needed
  /// to make [targetNumber].
  final bool countCakes;

  /// When true the answer buttons show BSL signs only (no digit label).
  final bool showBslOnly;

  /// Number of questions per game for this level.
  final int totalRounds;

  const NumberLineLevel({
    required this.number,
    required this.name,
    required this.maxCircles,
    required this.targetNumber,
    this.countCakes = false,
    this.showBslOnly = false,
    this.totalRounds = 10,
  });
}

/// Levels 1–2 count the cakes on the 5 and 10 lines; levels 3–5 ask how
/// many more make the target. Each level's stats are recorded under its
/// [NumberLineLevel.number], so inserting levels means moving existing
/// `number_line_game_<n>` rows to match (see the 20261106000100 migration).
const List<NumberLineLevel> numberLineLevels = [
  NumberLineLevel(number: 1, name: 'number_line.count5.name', maxCircles: 5, targetNumber: 5, countCakes: true, totalRounds: 5),
  NumberLineLevel(number: 2, name: 'number_line.count10.name', maxCircles: 10, targetNumber: 10, countCakes: true),
  NumberLineLevel(number: 3, name: 'number_line.level1.name', maxCircles: 4, targetNumber: 5, totalRounds: 5),
  NumberLineLevel(number: 4, name: 'number_line.level2.name', maxCircles: 7, targetNumber: 10),
  NumberLineLevel(number: 5, name: 'number_line.level3.name', maxCircles: 9, targetNumber: 10, showBslOnly: true),
];

// ── Game state ────────────────────────────────────────────────────────────────

enum NumberLineGameState { playing, won }

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider for the Number Line game.
///
/// Structure:
/// - 10 rounds per game.
/// - Each round shows [circleCount] circles on the number line (positions 1–N).
/// - The player picks how many more counters are needed to reach the
///   target — or, on [NumberLineLevel.countCakes] levels, how many cakes
///   are on the line.
/// - Two answer buttons are shown: one correct, one distractor.
/// - A point is awarded only when the player taps correct on their first try.
class NumberLineGameProvider extends ChangeNotifier {
  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  // ── state ──────────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  NumberLineLevel get currentLevel => numberLineLevels[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;

  int _circleCount = 0;
  int get circleCount => _circleCount;

  int get correctAnswer => currentLevel.countCakes
      ? _circleCount
      : currentLevel.targetNumber - _circleCount;

  /// The two answer options: [correct, distractor], order shuffled.
  List<int> answerOptions = [];

  /// Whether the player already tried a wrong answer this round.
  bool _triedWrong = false;

  int _score = 0;
  int get score => _score;

  NumberLineGameState _state = NumberLineGameState.playing;
  NumberLineGameState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  NumberLineGameProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, numberLineLevels.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = NumberLineGameState.playing;
    _roundIndex = 0;
    _generateRound();
    notifyListeners();
  }

  // ── answer handling ────────────────────────────────────────────────────────

  void selectAnswer(int answer) {
    if (_state == NumberLineGameState.won) return;

    if (answer == correctAnswer) {
      if (!_triedWrong) _score++;
      _advance();
    } else {
      _triedWrong = true;
      notifyListeners();
    }
  }

  /// Called by the screen after the fill animation completes.
  /// Always advances the round; awards +1 only when [answer] is correct.
  void recordAnswer(int answer) {
    if (_state == NumberLineGameState.won) return;
    if (answer == correctAnswer) _score++;
    _advance();
  }

  // ── internals ──────────────────────────────────────────────────────────────

  void _advance() {
    final nextRound = _roundIndex + 1;
    if (nextRound < currentLevel.totalRounds) {
      _roundIndex = nextRound;
      _generateRound();
      notifyListeners();
      return;
    }

    _state = NumberLineGameState.won;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.numberLineGame, _score, level: levelNumber)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    });
  }

  void _generateRound() {
    _triedWrong = false;
    // Never the same number of cakes twice in a row (which would also
    // repeat the answer). The first round of a game has no previous count
    // to avoid — startGame resets it.
    final previous = _roundIndex == 0 ? null : _circleCount;
    do {
      _circleCount = _random.nextInt(currentLevel.maxCircles) + 1;
    } while (_circleCount == previous && currentLevel.maxCircles > 1);

    final correct = correctAnswer;
    // Counting answers run 1–target; make-N answers 1–(target - 1).
    final maxAnswer = currentLevel.countCakes
        ? currentLevel.targetNumber
        : currentLevel.targetNumber - 1;
    int wrong;
    do {
      wrong = _random.nextInt(maxAnswer) + 1;
    } while (wrong == correct);

    answerOptions = [correct, wrong]..shuffle(_random);
  }
}
