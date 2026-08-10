import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Colour pairs ─────────────────────────────────────────────────────────────

/// Canonical colour for each number 1-10, matching the standard Cuisenaire
/// rod colours. Used by levels that colour-code circles by their count
/// value rather than by a fixed per-level "colour A/B" role, so the same
/// number always looks the same everywhere it appears — reinforcing that
/// each number is a distinct, consistent value.
const Map<int, Color> numberColours = {
  1: Color(0xFFFFFFFF), // white
  2: Color(0xFFE53935), // red
  3: Color(0xFF8BC34A), // light green
  4: Color.fromARGB(255, 112, 67, 160), // purple
  5: Color(0xFFFDD835), // yellow
  6: Color(0xFF2E7D32), // dark green
  7: Color(0xFF212121), // black
  8: Color(0xFF6D4C41), // brown
  9: Color(0xFF1E88E5), // blue
  10: Color(0xFFFF6F00), // orange
};

/// Colour-name suffixes matching [numberColours], for building
/// `counting_game.colour.<name>` translation keys.
const Map<int, String> numberColourNames = {
  1: 'white',
  2: 'red',
  3: 'light_green',
  4: 'purple',
  5: 'yellow',
  6: 'dark_green',
  7: 'black',
  8: 'brown',
  9: 'blue',
  10: 'orange',
};

/// The two circle colours used in one game session.
class CircleColourPair {
  final Color colorA;
  final Color colorB;
  /// Translation key for the level select display name.
  final String name;

  /// Colour name suffixes used to build `counting_game.colour.<name>`
  /// translation keys (e.g. 'orange', 'pink').
  final String nameA;
  final String nameB;

  /// The questions asked for each round, in order. Levels with a single
  /// colour only ask [QuestionType.total]; two-colour levels ask all three.
  final List<QuestionType> questionOrder;

  /// When true, circles are laid out in fixed dice-pip patterns (see
  /// [dicePipPositions]) instead of [CountingGameProvider]'s random scatter.
  final bool useDicePattern;

  /// When set (with [useDicePattern] also true), every round's countA +
  /// countB always equals this value — e.g. "Add to 10" always splits 10
  /// circles across two groups instead of picking a random total. Rendered
  /// as two side-by-side panels, each group coloured by its own count via
  /// [numberColours] (see [usesNumberColours]) rather than by [colorA]
  /// /[colorB].
  final int? fixedTotal;

  /// When true, this level always shows a fixed group of 10 circles (laid
  /// out as two rows of 5 with a divider) beside a second group of 1-10
  /// circles (in the usual dice pattern) — used by the "Ten and More"
  /// teen-number level. Each group is coloured by its own count via
  /// [numberColours] (see [usesNumberColours]) rather than by [colorA]
  /// /[colorB].
  final bool isTeenGrid;

  /// When true, this level is a 60-second timed challenge instead of the
  /// usual fixed 5 rounds: rounds keep generating until the clock runs out,
  /// and the score is simply "how many right in 1 minute".
  final bool isTimed;

  const CircleColourPair({
    required this.colorA,
    required this.colorB,
    required this.name,
    required this.nameA,
    required this.nameB,
    this.questionOrder = const [
      QuestionType.colourA,
      QuestionType.colourB,
      QuestionType.total,
    ],
    this.useDicePattern = false,
    this.fixedTotal,
    this.isTeenGrid = false,
    this.isTimed = false,
  });

  /// True when this level shows circles in a single colour only.
  bool get singleColour => colorA == colorB;

  /// True when this level colours each group by its own count value (via
  /// [numberColours]) instead of using the fixed [colorA]/[colorB] pair —
  /// so the same number always looks the same, reinforcing that each
  /// number is a distinct value.
  bool get usesNumberColours => fixedTotal != null || isTeenGrid;
}

const List<CircleColourPair> countingColourPairs = [
  // Levels 1-3: dice-pip patterns instead of a random scatter.
  CircleColourPair(
    colorA: Color(0xFFE53935),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level1.name',
    nameA: 'red',
    nameB: 'red',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  CircleColourPair(
    colorA: Color.fromARGB(255, 112, 67, 160),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level2.name',
    nameA: 'purple',
    nameB: 'purple',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  CircleColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level3.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  // Level 4: timed duplicate of level 3 — how many right in 1 minute.
  CircleColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level4.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    isTimed: true,
  ),
  CircleColourPair(
    colorA: Color(0xFFFF6F00),
    colorB: Color(0xFFFF6F00),
    name: 'counting_game.level5.name',
    nameA: 'orange',
    nameB: 'orange',
    questionOrder: [QuestionType.total],
  ),
  CircleColourPair(
    colorA: Color(0xFFFDD835),
    colorB: Color(0xFFFDD835),
    name: 'counting_game.level6.name',
    nameA: 'yellow',
    nameB: 'yellow',
    questionOrder: [QuestionType.total],
  ),
  CircleColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level7.name',
    nameA: 'green',
    nameB: 'green',
    questionOrder: [QuestionType.total],
  ),
  // Level 8: timed duplicate of level 7 — how many right in 1 minute.
  CircleColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level8.name',
    nameA: 'green',
    nameB: 'green',
    questionOrder: [QuestionType.total],
    isTimed: true,
  ),
  CircleColourPair(
    colorA: Color(0xFFEE009B),
    colorB: Color(0xFFcca815),
    name: 'counting_game.level9.name',
    nameA: 'pink',
    nameB: 'yellow',
  ),
  CircleColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level10.name',
    nameA: 'blue',
    nameB: 'red',
  ),
  CircleColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level11.name',
    nameA: 'green',
    nameB: 'purple',
  ),
  // Level 12: two groups that always add up to 10, in the same grid
  // pattern as levels 1-3. colorA/colorB/nameA/nameB are unused — each
  // group is coloured by its own count via numberColours (usesNumberColours).
  CircleColourPair(
    colorA: Color(0xFFE53935),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level12.name',
    nameA: 'red',
    nameB: 'green',
    useDicePattern: true,
    fixedTotal: 10,
  ),
  // Level 13: a fixed group of 10 beside a second group of 1-10 — teen
  // numbers as "10 and some more". colorA/colorB/nameA/nameB are unused —
  // each group is coloured by its own count via numberColours
  // (usesNumberColours).
  CircleColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFFFF6F00),
    name: 'counting_game.level13.name',
    nameA: 'blue',
    nameB: 'orange',
    questionOrder: [QuestionType.total],
    isTeenGrid: true,
  ),
];

// ── Dice-pip layout ───────────────────────────────────────────────────────────

/// Fractional (0-1) pip positions for a single die face, values 1-6.
const Map<int, List<Offset>> _diePipPattern = {
  1: [Offset(0.5, 0.5)],
  2: [Offset(0.3, 0.3), Offset(0.7, 0.7)],
  3: [Offset(0.3, 0.3), Offset(0.5, 0.5), Offset(0.7, 0.7)],
  4: [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.3, 0.7), Offset(0.7, 0.7)],
  5: [
    Offset(0.3, 0.3), Offset(0.7, 0.3),
    Offset(0.5, 0.5),
    Offset(0.3, 0.7), Offset(0.7, 0.7),
  ],
  6: [
    Offset(0.3, 0.22), Offset(0.7, 0.22),
    Offset(0.3, 0.5), Offset(0.7, 0.5),
    Offset(0.3, 0.78), Offset(0.7, 0.78),
  ],
};

/// Maps a die [pattern] (1-6) into normalised positions within [rect].
List<Offset> _pipsInRect(int pattern, Rect rect) {
  return _diePipPattern[pattern]!
      .map((p) => Offset(
            rect.left + p.dx * rect.width,
            rect.top + p.dy * rect.height,
          ))
      .toList();
}

/// Dice-style pip layout for [count] (1-6), used by dice-pattern levels
/// instead of a random scatter: the standard die face for that number.
///
/// 7, 8 and 9 stack two sub-patterns vertically, and 10 places two side by
/// side — all need to know the play area's actual pixel size to keep each
/// sub-pattern square, so use [stackedDicePipPixelPositions] /
/// [sideBySideDicePipPixelPositions] for those instead.
List<Offset> dicePipPositions(int count) {
  switch (count) {
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
      return _pipsInRect(count, const Rect.fromLTWH(0, 0, 1, 1));
    case 7:
    case 8:
    case 9:
      throw ArgumentError(
          'count=$count is a stacked pattern; use stackedDicePipPixelPositions');
    case 10:
      throw ArgumentError(
          'count=10 is a side-by-side pattern; use sideBySideDicePipPixelPositions');
    default:
      throw ArgumentError('No dice pattern for count=$count');
  }
}

/// The two sub-patterns (top, bottom) stacked to form counts 7-9.
const Map<int, List<int>> _diceStackPatterns = {
  7: [3, 4],
  8: [4, 4],
  9: [4, 5],
};

/// Pixel-space pip positions for a stacked dice count (7, 8 or 9), sized so
/// each row's sub-pattern is inscribed in a true square — independent of
/// the play area's [width]/[height] aspect ratio — so the pattern stays
/// recognisable rather than being stretched into a wide, flat rectangle.
List<Offset> stackedDicePipPixelPositions(
    int count, double width, double height) {
  final rows = _diceStackPatterns[count];
  if (rows == null) {
    throw ArgumentError('count=$count is not a stacked dice pattern');
  }
  return _stackedRowsPipPositions(rows, width, height);
}

/// Shared layout math for two die-face sub-patterns [rows] stacked
/// vertically with a gap between them, each sized so its bounding box is a
/// true square regardless of the play area's aspect ratio.
List<Offset> _stackedRowsPipPositions(
    List<int> rows, double width, double height) {
  final double gap = height * 0.08;
  final double cell = min(width, (height - gap) / 2);
  final double left = (width - cell) / 2;
  final double topRowTop = (height - (cell * 2 + gap)) / 2;
  final double bottomRowTop = topRowTop + cell + gap;

  Offset toPixel(Offset frac, double cellTop) =>
      Offset(left + frac.dx * cell, cellTop + frac.dy * cell);

  return [
    ..._diePipPattern[rows[0]]!.map((p) => toPixel(p, topRowTop)),
    ..._diePipPattern[rows[1]]!.map((p) => toPixel(p, bottomRowTop)),
  ];
}

/// Pixel-space pip positions for a fixed group of 10: two rows of 5 with a
/// horizontal divider, the same stacked style as the 8/9 dice patterns.
/// Used by level 11's constant "always 10" group.
List<Offset> tenBlockStackedPipPositions(double width, double height) =>
    _stackedRowsPipPositions(const [5, 5], width, height);

/// Pixel-space pip positions for count 10: two "5" sub-patterns side by
/// side, each sized so its bounding box is a true square — independent of
/// the play area's [width]/[height] aspect ratio — rather than being
/// squeezed into a narrow, tall rectangle.
List<Offset> sideBySideDicePipPixelPositions(double width, double height) {
  final double gap = width * 0.08;
  final double cell = min(height, (width - gap) / 2);
  final double top = (height - cell) / 2;
  final double leftColLeft = (width - (cell * 2 + gap)) / 2;
  final double rightColLeft = leftColLeft + cell + gap;

  Offset toPixel(Offset frac, double cellLeft) =>
      Offset(cellLeft + frac.dx * cell, top + frac.dy * cell);

  return [
    ..._diePipPattern[5]!.map((p) => toPixel(p, leftColLeft)),
    ..._diePipPattern[5]!.map((p) => toPixel(p, rightColLeft)),
  ];
}

/// Pixel-space pip positions for [count] (1-10) within a [width]x[height]
/// box, picking whichever dice pattern fits: a direct die face (1-6), a
/// stacked pair (7-9), or side-by-side fives (10). The 1-6 die face is
/// confined to a square sub-region centred within the box (rather than
/// stretched to fill a non-square box) so it stays proportionally correct,
/// matching how the 7-9/10 patterns are already square-cell sized. Used to
/// render a single colour's group within its own panel — see
/// [CircleColourPair.fixedTotal].
List<Offset> dicePatternPipPixelPositions(int count, double width, double height) {
  if (count == 10) return sideBySideDicePipPixelPositions(width, height);
  if (count >= 7) return stackedDicePipPixelPositions(count, width, height);
  final double side = min(width, height);
  final Rect square =
      Rect.fromLTWH((width - side) / 2, (height - side) / 2, side, side);
  return _pipsInRect(count, square);
}

// ── Question types ────────────────────────────────────────────────────────────

enum QuestionType { colourA, colourB, total }

// ── Round ─────────────────────────────────────────────────────────────────────

/// One round = one collection of circles + the questions about it
/// (see [CircleColourPair.questionOrder]).
class CountingRound {
  final int countA;
  final int countB;

  /// Pre-computed normalised positions (0–1) within the play area.
  final List<Offset> positions;

  /// True when a horizontal divider line should be drawn across the middle
  /// of the play area (dice patterns for 8 and 9).
  final bool showDivider;

  /// Set for dice counts 7-10: the widget computes pip positions itself via
  /// [stackedDicePipPixelPositions] (7-9) or
  /// [sideBySideDicePipPixelPositions] (10) — both need the play area's
  /// actual pixel size to keep each sub-pattern square — ignoring
  /// [positions].
  final int? diceCompositeCount;

  const CountingRound({
    required this.countA,
    required this.countB,
    required this.positions,
    this.showDivider = false,
    this.diceCompositeCount,
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

enum CountingGameState { playing, won, timeUp }

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider for the Counting Game.
///
/// Structure:
/// - 5 rounds per game, each showing a new collection of circles — except
///   [CircleColourPair.isTimed] levels, which keep generating rounds for
///   [timedLevelDurationSeconds] instead of stopping at a fixed count.
/// - Each round asks the questions in [CircleColourPair.questionOrder]:
///   single-colour levels ask just "total"; two-colour levels ask
///   colour A → colour B → total.
/// - 3 BSL number buttons per question; wrong taps are greyed out/disabled.
/// - Correct answer awards 1 point and advances to the next question.
/// - The game is won once every round's questions have been answered, or
///   (for timed levels) once the clock runs out.
class CountingGameProvider extends ChangeNotifier {
  static const int totalRounds = 5;

  /// Countdown duration for [CircleColourPair.isTimed] levels.
  static const int timedLevelDurationSeconds = 60;

  /// Maximum total circle count per level.
  static const List<int> _maxTotals = [
    5, 7, 10, 10, 5, 7, 10, 10, 5, 10, 20, 10, 20,
  ];

  int get _maxTotal => _maxTotals[_levelIndex];

  /// Number of questions asked per round for the current level.
  int get _questionsPerRound => colours.questionOrder.length;

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
      colours.questionOrder[_questionIndexInRound];
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

  /// True when the current level is a 60-second timed challenge.
  bool get isTimedLevel => colours.isTimed;

  Timer? _timedLevelTimer;
  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  CountingGameProvider() {
    showLevelSelection();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    _timedLevelTimer?.cancel();
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, countingColourPairs.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _state = CountingGameState.playing;
    _timedLevelTimer?.cancel();

    if (colours.isTimed) {
      _rounds = [_generateRound()];
      _secondsRemaining = timedLevelDurationSeconds;
      _timedLevelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _timedLevelTimer?.cancel();
          _state = CountingGameState.timeUp;
          _lastResult = null;
          notifyListeners();
          _statsService
              .recordGameResult(GameIds.countingGame, _score, level: levelNumber)
              .then((result) {
            _lastResult = result;
            notifyListeners();
          });
          return;
        }
        notifyListeners();
      });
    } else {
      _rounds = [];
      for (int i = 0; i < totalRounds; i++) {
        _rounds.add(_generateRound(previous: i == 0 ? null : _rounds[i - 1]));
      }
    }

    _roundIndex = 0;
    _questionIndexInRound = 0;
    _buildOptions();
    notifyListeners();
  }

  @override
  void dispose() {
    _timedLevelTimer?.cancel();
    super.dispose();
  }

  // ── answer handling ────────────────────────────────────────────────────────

  void selectAnswer(int answer) {
    if (_state != CountingGameState.playing) return;
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

    if (nextQInRound < _questionsPerRound) {
      // More questions in this round
      _questionIndexInRound = nextQInRound;
      _buildOptions();
      notifyListeners();
      return;
    }

    if (colours.isTimed) {
      // Timed levels keep generating rounds until the clock runs out.
      _roundIndex++;
      _questionIndexInRound = 0;
      _rounds.add(_generateRound(previous: _rounds[_roundIndex - 1]));
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

    if (colours.isTeenGrid) {
      while (true) {
        final countB = _random.nextInt(10) + 1;

        if (previous != null && countB == previous.countB) {
          continue;
        }

        return CountingRound(countA: 10, countB: countB, positions: const []);
      }
    }

    if (colours.useDicePattern) {
      final fixedTotal = colours.fixedTotal;

      if (fixedTotal != null) {
        while (true) {
          final countA = _random.nextInt(fixedTotal - 1) + 1;
          final countB = fixedTotal - countA;

          if (previous != null &&
              countA == previous.countA &&
              countB == previous.countB) {
            continue;
          }

          // Rendered as two side-by-side panels (one colour each), so no
          // merged composite pattern is needed here — see _CirclePlayArea.
          return CountingRound(
              countA: countA, countB: countB, positions: const []);
        }
      }

      while (true) {
        final count = _random.nextInt(maxTotal) + 1;

        if (previous != null && count == previous.countA) {
          continue;
        }

        final bool isComposite = count >= 7;
        return CountingRound(
          countA: count,
          countB: 0,
          positions: isComposite ? const [] : dicePipPositions(count),
          showDivider: count == 8 || count == 9,
          diceCompositeCount: isComposite ? count : null,
        );
      }
    }

    if (colours.singleColour) {
      while (true) {
        final count = _random.nextInt(maxTotal) + 1;

        if (previous != null && count == previous.countA) {
          continue;
        }

        final positions = _generatePositions(count);
        return CountingRound(countA: count, countB: 0, positions: positions);
      }
    }

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
