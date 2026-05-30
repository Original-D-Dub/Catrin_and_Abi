import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

class HolLevel {
  final int number;
  final String name;
  final int maxNumber;

  const HolLevel({
    required this.number,
    required this.name,
    required this.maxNumber,
  });
}

const List<HolLevel> holLevels = [
  HolLevel(number: 1, name: 'higher_or_lower.level1.name', maxNumber: 5),
  HolLevel(number: 2, name: 'higher_or_lower.level2.name', maxNumber: 7),
  HolLevel(number: 3, name: 'higher_or_lower.level3.name', maxNumber: 10),
];

enum HolGameState { playing, won }

class HigherOrLowerProvider extends ChangeNotifier {
  static const int totalRounds = 10;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  HolLevel get currentLevel => holLevels[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;

  int _firstNumber = 1;
  int _secondNumber = 2;
  bool _isHigherQuestion = true;

  int get firstNumber => _firstNumber;
  int get secondNumber => _secondNumber;
  bool get isHigherQuestion => _isHigherQuestion;

  String get questionText => _isHigherQuestion
      ? 'Is $_firstNumber higher than $_secondNumber?'
      : 'Is $_firstNumber lower than $_secondNumber?';

  bool get correctIsYes => _isHigherQuestion
      ? _firstNumber > _secondNumber
      : _firstNumber < _secondNumber;

  int _score = 0;
  int get score => _score;

  HolGameState _state = HolGameState.playing;
  HolGameState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  HigherOrLowerProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, holLevels.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = HolGameState.playing;
    _roundIndex = 0;
    _generateRound();
    notifyListeners();
  }

  /// Checks the player's answer. Returns true if correct.
  /// Awards a point for a correct answer.
  bool selectAnswer(bool isYes) {
    if (_state == HolGameState.won) return false;
    final isCorrect = isYes == correctIsYes;
    if (isCorrect) _score++;
    return isCorrect;
  }

  /// Advances to the next round (called by screen after feedback delay).
  void advance() {
    if (_state == HolGameState.won) return;
    final nextRound = _roundIndex + 1;
    if (nextRound < totalRounds) {
      _roundIndex = nextRound;
      _generateRound();
      notifyListeners();
      return;
    }
    _state = HolGameState.won;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.higherOrLower, _score, level: levelNumber)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    });
  }

  void _generateRound() {
    final max = currentLevel.maxNumber;
    _firstNumber = _random.nextInt(max) + 1;
    do {
      _secondNumber = _random.nextInt(max) + 1;
    } while (_secondNumber == _firstNumber);
    _isHigherQuestion = _random.nextBool();
  }
}
