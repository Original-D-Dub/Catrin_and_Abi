import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

class MolLevel {
  final int number;
  final String name;
  final int minNumber;
  final int maxNumber;

  const MolLevel({
    required this.number,
    required this.name,
    required this.maxNumber,
    this.minNumber = 1,
  });
}

const List<MolLevel> molLevels = [
  MolLevel(number: 1, name: 'more_or_less.level1.name', maxNumber: 5),
  MolLevel(number: 2, name: 'more_or_less.level2.name', maxNumber: 7),
  MolLevel(number: 3, name: 'more_or_less.level3.name', maxNumber: 10),
  MolLevel(number: 4, name: 'more_or_less.level4.name', maxNumber: 19),
  MolLevel(number: 5, name: 'more_or_less.level5.name', minNumber: 20, maxNumber: 99),
];

enum MolGameState { playing, won }

class MoreOrLessProvider extends ChangeNotifier {
  static const int totalRounds = 10;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  MolLevel get currentLevel => molLevels[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;

  int _firstNumber = 1;
  int _secondNumber = 2;
  bool _isHigherQuestion = true;

  int get firstNumber => _firstNumber;
  int get secondNumber => _secondNumber;
  bool get isHigherQuestion => _isHigherQuestion;

  String get questionText => _isHigherQuestion
      ? 'Is $_firstNumber more than $_secondNumber?'
      : 'Is $_firstNumber less than $_secondNumber?';

  bool get correctIsYes => _isHigherQuestion
      ? _firstNumber > _secondNumber
      : _firstNumber < _secondNumber;

  int _score = 0;
  int get score => _score;

  MolGameState _state = MolGameState.playing;
  MolGameState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  MoreOrLessProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, molLevels.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = MolGameState.playing;
    _roundIndex = 0;
    _generateRound();
    notifyListeners();
  }

  /// Checks the player's answer. Returns true if correct.
  /// Awards a point for a correct answer.
  bool selectAnswer(bool isYes) {
    if (_state == MolGameState.won) return false;
    final isCorrect = isYes == correctIsYes;
    if (isCorrect) _score++;
    return isCorrect;
  }

  /// Advances to the next round (called by screen after feedback delay).
  void advance() {
    if (_state == MolGameState.won) return;
    final nextRound = _roundIndex + 1;
    if (nextRound < totalRounds) {
      _roundIndex = nextRound;
      _generateRound();
      notifyListeners();
      return;
    }
    _state = MolGameState.won;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.moreLessGame, _score, level: levelNumber)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    });
  }

  void _generateRound() {
    final min = currentLevel.minNumber;
    final max = currentLevel.maxNumber;
    final span = max - min + 1;
    _firstNumber = min + _random.nextInt(span);
    do {
      _secondNumber = min + _random.nextInt(span);
    } while (_secondNumber == _firstNumber);
    _isHigherQuestion = _random.nextBool();
  }
}
