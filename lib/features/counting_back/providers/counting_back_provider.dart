import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Levels ────────────────────────────────────────────────────────────────────

class CountingBackLevel {
  final int number;
  final String name;

  /// Max starting number (X).
  final int maxX;

  /// Max amount to take away (Y), capped at X-1 at runtime.
  final int maxY;

  const CountingBackLevel({
    required this.number,
    required this.name,
    required this.maxX,
    required this.maxY,
  });
}

const List<CountingBackLevel> countingBackLevels = [
  CountingBackLevel(number: 1, name: 'Take away 1', maxX: 5, maxY: 1),
  CountingBackLevel(number: 2, name: 'Take away up to 2', maxX: 5, maxY: 2),
  CountingBackLevel(number: 3, name: 'Take away up to 4', maxX: 5, maxY: 4),
];

// ── State ─────────────────────────────────────────────────────────────────────

enum CountingBackState { playing, won }

// ── Provider ──────────────────────────────────────────────────────────────────

class CountingBackProvider extends ChangeNotifier {
  static const int totalRounds = 10;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  // ── state ──────────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  CountingBackLevel get currentLevel => countingBackLevels[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;

  int _x = 5;
  int _y = 2;
  int get startNumber => _x;
  int get takeAway => _y;
  int get correctAnswer => _x - _y;

  List<int> answerOptions = [];

  int _score = 0;
  int get score => _score;

  CountingBackState _state = CountingBackState.playing;
  CountingBackState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  CountingBackProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, countingBackLevels.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = CountingBackState.playing;
    _roundIndex = 0;
    _generateRound();
    notifyListeners();
  }

  /// Called by the screen when the correct answer animation completes.
  void recordCorrect() {
    _score++;
    _advance();
  }

  // ── internals ──────────────────────────────────────────────────────────────

  void _advance() {
    final next = _roundIndex + 1;
    if (next < totalRounds) {
      _roundIndex = next;
      _generateRound();
      notifyListeners();
      return;
    }

    _state = CountingBackState.won;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.countingBackGame, _score, level: levelNumber)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    });
  }

  void _generateRound() {
    final level = countingBackLevels[_levelIndex];
    _x = _random.nextInt(level.maxX - 1) + 2; // 2..maxX
    final maxY = min(_x - 1, level.maxY);
    _y = _random.nextInt(maxY) + 1; // 1..min(x-1, maxY)

    final correct = _x - _y;
    int wrong;
    do {
      wrong = _random.nextInt(4) + 1; // 1–4, within the number line range
    } while (wrong == correct);

    answerOptions = [correct, wrong]..shuffle(_random);
  }
}
