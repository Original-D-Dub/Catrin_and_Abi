import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Colour pairs ──────────────────────────────────────────────────────────────

class BlockColourPair {
  final Color colorA;
  final Color colorB;
  final String nameA;
  final String nameB;

  const BlockColourPair({
    required this.colorA,
    required this.colorB,
    required this.nameA,
    required this.nameB,
  });
}

const List<BlockColourPair> moreLessColourPairs = [
  BlockColourPair(
    colorA: Color(0xFFEE009B),
    colorB: Color(0xFF43A047),
    nameA: 'pink',
    nameB: 'green',
  ),
  BlockColourPair(
    colorA: Color(0xFFFF6F00),
    colorB: Color(0xFF1E88E5),
    nameA: 'orange',
    nameB: 'blue',
  ),
  BlockColourPair(
    colorA: Color(0xFF8E24AA),
    colorB: Color(0xFFFDD835),
    nameA: 'purple',
    nameB: 'yellow',
  ),
];

// ── Question & answer types ───────────────────────────────────────────────────

enum MoreLessQuestion {
  smallest,     // number buttons — which number is smallest?
  biggest,      // number buttons — which number is biggest?
  moreBlocks,   // colour buttons — which colour has more?
  fewestBlocks, // colour buttons — which colour has fewest?
  moreThan,     // yes/no buttons — are there more [A] than [B]?
}

/// Determines how answer buttons are rendered in the screen.
enum MoreLessAnswerType { number, colour, yesNo }

extension MoreLessQuestionX on MoreLessQuestion {
  MoreLessAnswerType get answerType {
    switch (this) {
      case MoreLessQuestion.smallest:
      case MoreLessQuestion.biggest:
        return MoreLessAnswerType.number;
      case MoreLessQuestion.moreBlocks:
      case MoreLessQuestion.fewestBlocks:
        return MoreLessAnswerType.colour;
      case MoreLessQuestion.moreThan:
        return MoreLessAnswerType.yesNo;
    }
  }
}

// ── Game state ────────────────────────────────────────────────────────────────

enum MoreLessState { playing, won }

// ── Provider ──────────────────────────────────────────────────────────────────

class MoreLessProvider extends ChangeNotifier {
  static const int totalRounds = 10;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  // ── state ──────────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  BlockColourPair get colours => moreLessColourPairs[_levelIndex];

  int _roundIndex = 0;
  int get roundNumber => _roundIndex + 1;

  int _countA = 0;
  int _countB = 0;
  int get countA => _countA;
  int get countB => _countB;

  MoreLessQuestion _questionType = MoreLessQuestion.smallest;
  MoreLessQuestion get questionType => _questionType;
  MoreLessAnswerType get answerType => _questionType.answerType;

  /// String answer options for this round (numbers, colour names, or yes/no).
  List<String> answerOptions = [];

  /// Wrong answers the player has tried.
  final Set<String> disabledAnswers = {};

  /// The correct answer as a string (matches an entry in [answerOptions]).
  String correctAnswer = '';

  int _score = 0;
  int get score => _score;

  MoreLessState _state = MoreLessState.playing;
  MoreLessState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  MoreLessProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, moreLessColourPairs.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = MoreLessState.playing;
    _roundIndex = 0;
    _generateRound();
    notifyListeners();
  }

  // ── answer handling ────────────────────────────────────────────────────────

  void selectAnswer(String answer) {
    if (_state == MoreLessState.won) return;
    if (disabledAnswers.contains(answer)) return;

    if (answer == correctAnswer) {
      _score++;
      _advance();
    } else {
      disabledAnswers.add(answer);
      notifyListeners();
    }
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

    _state = MoreLessState.won;
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
    disabledAnswers.clear();

    do {
      _countA = _random.nextInt(10) + 1;
      _countB = _random.nextInt(10) + 1;
    } while (_countA == _countB);

    _questionType = MoreLessQuestion
        .values[_random.nextInt(MoreLessQuestion.values.length)];

    switch (_questionType) {
      case MoreLessQuestion.smallest:
        correctAnswer = min(_countA, _countB).toString();
        answerOptions = [_countA.toString(), _countB.toString()]
          ..shuffle(_random);

      case MoreLessQuestion.biggest:
        correctAnswer = max(_countA, _countB).toString();
        answerOptions = [_countA.toString(), _countB.toString()]
          ..shuffle(_random);

      case MoreLessQuestion.moreBlocks:
        correctAnswer =
            _countA > _countB ? colours.nameA : colours.nameB;
        answerOptions = [colours.nameA, colours.nameB]..shuffle(_random);

      case MoreLessQuestion.fewestBlocks:
        correctAnswer =
            _countA < _countB ? colours.nameA : colours.nameB;
        answerOptions = [colours.nameA, colours.nameB]..shuffle(_random);

      case MoreLessQuestion.moreThan:
        correctAnswer = _countA > _countB ? 'Yes' : 'No';
        answerOptions = ['Yes', 'No']..shuffle(_random);
    }
  }
}
