import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Colour pairs ─────────────────────────────────────────────────────────────

/// The two circle colours used in one game session.
class CircleColourPair {
  final Color colorA;
  final Color colorB;
  /// Translation key for the level select display name.
  final String name;
  final String nameA;
  final String nameB;

  const CircleColourPair({
    required this.colorA,
    required this.colorB,
    required this.name,
    required this.nameA,
    required this.nameB,
  });
}

const List<CircleColourPair> countingColourPairs = [
  CircleColourPair(
    colorA: Color(0xFFEE009B),
    colorB: Color(0xFFcca815),
    name: 'counting_game.level1.name',
    nameA: 'pink',
    nameB: 'yellow',
  ),
  CircleColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level2.name',
    nameA: 'blue',
    nameB: 'red',
  ),
  CircleColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level3.name',
    nameA: 'green',
    nameB: 'purple',
  ),
];

// ── Question types ────────────────────────────────────────────────────────────

enum QuestionType { colourA, colourB, total }

// ── Round ─────────────────────────────────────────────────────────────────────

/// One round = one collection of circles + the 3 questions about it.
class CountingRound {
  final int countA;
  final int countB;

  /// Pre-computed normalised positions (0–1) within the play area.
  final List<Offset> positions;

  const CountingRound({
    required this.countA,
    required this.countB,
    required this.positions,
  });

  int get total => countA + countB;

  int answerFor(QuestionType type) {
    switch (type) {
      case QuestionType.colourA:
        return countA;
      case QuestionType.colourB:
        return countB;
      case QuestionType.total:
        return total;
    }
  }
}

// ── Game state ────────────────────────────────────────────────────────────────

enum CountingGameState { playing, won }

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider for the Counting Game.
///
/// Structure:
/// - 5 rounds per game, each showing a new collection of circles.
/// - 3 questions per round (colour A → colour B → total).
/// - 3 BSL number buttons per question; wrong taps are greyed out/disabled.
/// - Correct answer awards 1 point and advances to the next question.
/// - After all 15 questions the game is won.
class CountingGameProvider extends ChangeNotifier {
  static const int totalRounds = 5;
  static const int questionsPerRound = 3;
  static const int totalQuestions = totalRounds * questionsPerRound;

  /// Maximum total circle count per level.
  static const List<int> _maxTotals = [5, 10, 20];

  int get _maxTotal => _maxTotals[_levelIndex];

  static const List<QuestionType> _questionOrder = [
    QuestionType.colourA,
    QuestionType.colourB,
    QuestionType.total,
  ];

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  // ── state ──────────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _levelIndex = 0;
  int get levelNumber => _levelIndex + 1;
  CircleColourPair get colours => countingColourPairs[_levelIndex];

  late List<CountingRound> _rounds;
  int _roundIndex = 0;
  int _questionIndexInRound = 0;

  CountingRound get currentRound => _rounds[_roundIndex];
  QuestionType get currentQuestionType =>
      _questionOrder[_questionIndexInRound];
  int get roundNumber => _roundIndex + 1;

  /// The correct answer for the current question.
  int get correctAnswer => currentRound.answerFor(currentQuestionType);

  /// The three answer options shown as BSL buttons (sorted ascending).
  late List<int> answerOptions;

  /// Answers the player has already tried and got wrong (greyed out).
  final Set<int> disabledAnswers = {};

  int _score = 0;
  int get score => _score;

  CountingGameState _state = CountingGameState.playing;
  CountingGameState get state => _state;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  CountingGameProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, countingColourPairs.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = CountingGameState.playing;
    _rounds = List.generate(totalRounds, (_) => _generateRound());
    _roundIndex = 0;
    _questionIndexInRound = 0;
    _buildOptions();
    notifyListeners();
  }

  // ── answer handling ────────────────────────────────────────────────────────

  void selectAnswer(int answer) {
    if (_state == CountingGameState.won) return;
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
    final nextQInRound = _questionIndexInRound + 1;

    if (nextQInRound < questionsPerRound) {
      // More questions in this round
      _questionIndexInRound = nextQInRound;
      _buildOptions();
      notifyListeners();
      return;
    }

    final nextRound = _roundIndex + 1;
    if (nextRound < totalRounds) {
      // Move to next round
      _roundIndex = nextRound;
      _questionIndexInRound = 0;
      _buildOptions();
      notifyListeners();
      return;
    }

    // All rounds complete — game won
    _state = CountingGameState.won;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.countingGame, _score, level: levelNumber)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    });
  }

  /// Builds the three answer option buttons for the current question.
  void _buildOptions() {
    disabledAnswers.clear();
    final correct = correctAnswer;
    final options = <int>{correct};

    // Distractors drawn from the same range as possible answers for this level.
    final range = _maxTotal;
    int attempts = 0;
    while (options.length < 3 && attempts < 100) {
      attempts++;
      final candidate = _random.nextInt(range) + 1;
      if (candidate != correct) {
        options.add(candidate);
      }
    }

    answerOptions = options.toList()..sort();
  }

  CountingRound _generateRound({CountingRound? previous}) {
    final maxTotal = _maxTotal;
    while (true) {
      // countA: at least 1, leaving room for at least 1 of colour B.
      final countA = _random.nextInt(maxTotal - 1) + 1;
      final maxB = (maxTotal - countA).clamp(1, maxTotal - 1);
      final countB = _random.nextInt(maxB) + 1;

      if (previous != null &&
          countA == previous.countA &&
          countB == previous.countB) {
        continue;
      }

      final positions = _generatePositions(countA + countB);
      return CountingRound(
        countA: countA,
        countB: countB,
        positions: positions,
      );
    }
  }

  /// Generates [count] non-overlapping normalised positions.
  /// Min-distance shrinks for higher counts so circles still fit.
  List<Offset> _generatePositions(int count) {
    final double minDist = count <= 5
        ? 0.22
        : count <= 10
            ? 0.17
            : 0.13;
    final positions = <Offset>[];
    int attempts = 0;

    while (positions.length < count && attempts < 600) {
      attempts++;
      final x = 0.12 + _random.nextDouble() * 0.76;
      final y = 0.12 + _random.nextDouble() * 0.76;
      final candidate = Offset(x, y);

      final tooClose = positions.any((p) {
        final dx = p.dx - x;
        final dy = p.dy - y;
        return sqrt(dx * dx + dy * dy) < minDist;
      });

      if (!tooClose) {
        positions.add(candidate);
      }
    }

    return positions;
  }
}
