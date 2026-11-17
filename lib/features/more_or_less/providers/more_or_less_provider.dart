import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

/// Which question(s) a level asks: always "more than", always "less than",
/// or a random mix of both.
enum MolQuestionType { more, less, mixed }

class MolLevel {
  final int number;
  final String name;
  final int minNumber;
  final int maxNumber;
  final MolQuestionType questionType;
  final int totalRounds;

  /// How long a timed level lasts; null for a level of [totalRounds] rounds.
  /// A timed level keeps asking questions until the clock runs out.
  final Duration? timeLimit;

  bool get isTimed => timeLimit != null;

  const MolLevel({
    required this.number,
    required this.name,
    required this.maxNumber,
    this.minNumber = 1,
    this.questionType = MolQuestionType.mixed,
    this.totalRounds = 10,
    this.timeLimit,
  });
}

const List<MolLevel> molLevels = [
  MolLevel(
    number: 1,
    name: 'more_or_less.level1.name',
    maxNumber: 5,
    questionType: MolQuestionType.more,
    totalRounds: 5,
  ),
  MolLevel(
    number: 2,
    name: 'more_or_less.level2.name',
    maxNumber: 7,
    questionType: MolQuestionType.more,
    totalRounds: 5,
  ),
  MolLevel(
    number: 3,
    name: 'more_or_less.level3.name',
    maxNumber: 10,
    questionType: MolQuestionType.more,
    totalRounds: 5,
  ),
  MolLevel(
    number: 4,
    name: 'more_or_less.level4.name',
    maxNumber: 10,
    questionType: MolQuestionType.more,
    timeLimit: Duration(minutes: 1),
  ),
  MolLevel(
    number: 5,
    name: 'more_or_less.level5.name',
    maxNumber: 5,
    questionType: MolQuestionType.less,
    totalRounds: 5,
  ),
  MolLevel(
    number: 6,
    name: 'more_or_less.level6.name',
    maxNumber: 7,
    questionType: MolQuestionType.less,
    totalRounds: 5,
  ),
  MolLevel(
    number: 7,
    name: 'more_or_less.level7.name',
    maxNumber: 10,
    questionType: MolQuestionType.less,
    totalRounds: 5,
  ),
  MolLevel(
    number: 8,
    name: 'more_or_less.level8.name',
    maxNumber: 10,
    questionType: MolQuestionType.less,
    timeLimit: Duration(minutes: 1),
  ),
  MolLevel(number: 9, name: 'more_or_less.level9.name', maxNumber: 5),
  MolLevel(number: 10, name: 'more_or_less.level10.name', maxNumber: 7),
  MolLevel(number: 11, name: 'more_or_less.level11.name', maxNumber: 10),
  MolLevel(
    number: 12,
    name: 'more_or_less.level12.name',
    maxNumber: 10,
    timeLimit: Duration(minutes: 1),
  ),
  MolLevel(number: 13, name: 'more_or_less.level13.name', maxNumber: 19),
];

enum MolGameState { playing, won }

class MoreOrLessProvider extends ChangeNotifier {
  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  MolLevel get currentLevel => molLevels[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;
  int get totalRounds => currentLevel.totalRounds;

  /// Counts down a timed level; ends the game when it reaches zero.
  Timer? _clock;
  int _secondsLeft = 0;
  int get secondsLeft => _secondsLeft;

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

  /// Called with the level number when a level is finished, so the level
  /// map can move the player on.
  ValueChanged<int>? onLevelFinished;

  MoreOrLessProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _stopClock();
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
    _stopClock();
    if (currentLevel.timeLimit case final limit?) {
      _secondsLeft = limit.inSeconds;
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _finish();
        } else {
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
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
    if (currentLevel.isTimed || nextRound < totalRounds) {
      _roundIndex = nextRound;
      _generateRound();
      notifyListeners();
      return;
    }
    _finish();
  }

  void _finish() {
    _stopClock();
    _state = MolGameState.won;
    _lastResult = null;
    notifyListeners();
    onLevelFinished?.call(levelNumber);
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
    _isHigherQuestion = switch (currentLevel.questionType) {
      MolQuestionType.more => true,
      MolQuestionType.less => false,
      MolQuestionType.mixed => _random.nextBool(),
    };
  }
}
