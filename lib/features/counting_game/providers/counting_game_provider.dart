import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/game_stats_service.dart';

// ── Colour pairs ─────────────────────────────────────────────────────────────

/// Canonical colour for each number 1-10, matching the standard Cuisenaire
/// rod colours. Used by levels that colour-code dots by their count
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

/// Level 5 ("Add to 10") rounds that split 10 into 5 + 5 would show two
/// identical yellow groups ([numberColours] 5), so those rounds colour the
/// first group light yellow and the second dark yellow instead — see
/// [DotColourPair.isSplitFives]. Names are `counting_game.colour.<name>`
/// suffixes.
const Color splitFivesColourA = Color(0xFFFFF176); // light yellow
const Color splitFivesColourB = Color(0xFFF9A825); // dark yellow
const String splitFivesNameA = 'light_yellow';
const String splitFivesNameB = 'dark_yellow';

/// The two dot colours used in one game session.
class DotColourPair {
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

  /// When true, dots are laid out in fixed dice-pip patterns (see
  /// [dicePipPositions]) instead of [CountingGameProvider]'s random scatter.
  final bool useDicePattern;

  /// When set (with [useDicePattern] also true), every round's countA +
  /// countB always equals this value — e.g. "Add to 10" always splits 10
  /// dots across two groups instead of picking a random total. Rendered
  /// as two side-by-side panels, each group coloured by its own count via
  /// [numberColours] (see [usesNumberColours]) rather than by [colorA]
  /// /[colorB].
  final int? fixedTotal;

  /// When true, this level always shows a fixed group of 10 dots (laid
  /// out as two rows of 5 with a divider) beside a second group of 1-10
  /// dots (in the usual dice pattern) — used by the "Ten and More"
  /// teen-number level. Each group is coloured by its own count via
  /// [numberColours] (see [usesNumberColours]) rather than by [colorA]
  /// /[colorB].
  final bool isTeenGrid;

  /// When true, this level is a 60-second timed challenge instead of the
  /// usual fixed 5 rounds: rounds keep generating until the clock runs out,
  /// and the score is simply "how many right in 1 minute".
  final bool isTimed;

  /// When false, the answer buttons show only the BSL hand sign — no
  /// digit label underneath — for levels that drill sign recognition
  /// without the numeral as a crutch.
  final bool showAnswerNumerals;

  /// When true, each round shows pictures of a [CountingObject] (balloons,
  /// candles, hats, strawberries, oranges or sandwiches) instead of dots — the Random tab's
  /// levels. See [CountingRound.objectA].
  final bool usePictures;

  const DotColourPair({
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
    this.showAnswerNumerals = true,
    this.usePictures = false,
  });

  /// True when this level shows dots in a single colour only.
  bool get singleColour => colorA == colorB;

  /// True when this level colours each group by its own count value (via
  /// [numberColours]) instead of using the fixed [colorA]/[colorB] pair —
  /// so the same number always looks the same, reinforcing that each
  /// number is a distinct value.
  bool get usesNumberColours => fixedTotal != null || isTeenGrid;

  /// True for a [fixedTotal] round whose two groups are the same size
  /// (5 + 5 on "Add to 10"), which [numberColours] would draw in the same
  /// colour — those rounds use [splitFivesColourA]/[splitFivesColourB].
  bool isSplitFives(CountingRound round) =>
      fixedTotal != null && round.countA == round.countB;
}

const List<DotColourPair> countingColourPairs = [
  // Patterns levels 1-3: dice-pip patterns instead of a random scatter.
  DotColourPair(
    colorA: Color(0xFFE53935),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level1.name',
    nameA: 'red',
    nameB: 'red',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  DotColourPair(
    colorA: Color.fromARGB(255, 112, 67, 160),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level2.name',
    nameA: 'purple',
    nameB: 'purple',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level3.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
  ),
  // Level 4: timed duplicate of level 3 — how many right in 1 minute.
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level4.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    isTimed: true,
  ),
  // Level 5: two groups that always add up to 10, in the same grid
  // pattern as levels 1-3. colorA/colorB/nameA/nameB are unused — each
  // group is coloured by its own count via numberColours (usesNumberColours).
  DotColourPair(
    colorA: Color(0xFFE53935),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level5.name',
    nameA: 'red',
    nameB: 'green',
    useDicePattern: true,
    fixedTotal: 10,
  ),
  // Level 6: a fixed group of 10 beside a second group of 1-10 — teen
  // numbers as "10 and some more". colorA/colorB/nameA/nameB are unused —
  // each group is coloured by its own count via numberColours
  // (usesNumberColours).
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFFFF6F00),
    name: 'counting_game.level6.name',
    nameA: 'blue',
    nameB: 'orange',
    questionOrder: [QuestionType.total],
    isTeenGrid: true,
  ),
  // Levels 7-13: the Random tab's picture levels (shown as Random 1-7).
  DotColourPair(
    colorA: Color(0xFFFF6F00),
    colorB: Color(0xFFFF6F00),
    name: 'counting_game.level7.name',
    usePictures: true,
    nameA: 'orange',
    nameB: 'orange',
    questionOrder: [QuestionType.total],
  ),
  DotColourPair(
    colorA: Color(0xFFFDD835),
    colorB: Color(0xFFFDD835),
    name: 'counting_game.level8.name',
    usePictures: true,
    nameA: 'yellow',
    nameB: 'yellow',
    questionOrder: [QuestionType.total],
  ),
  DotColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level9.name',
    usePictures: true,
    nameA: 'green',
    nameB: 'green',
    questionOrder: [QuestionType.total],
  ),
  // Level 10: timed duplicate of level 9 — how many right in 1 minute.
  DotColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color(0xFF43A047),
    name: 'counting_game.level10.name',
    usePictures: true,
    nameA: 'green',
    nameB: 'green',
    questionOrder: [QuestionType.total],
    isTimed: true,
  ),
  DotColourPair(
    colorA: Color(0xFFEE009B),
    colorB: Color(0xFFcca815),
    name: 'counting_game.level11.name',
    usePictures: true,
    nameA: 'pink',
    nameB: 'yellow',
  ),
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level12.name',
    usePictures: true,
    nameA: 'blue',
    nameB: 'red',
  ),
  DotColourPair(
    colorA: Color(0xFF43A047),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level13.name',
    usePictures: true,
    nameA: 'green',
    nameB: 'purple',
  ),
  // Levels 14-17: duplicates of levels 1-4 with the answer buttons' digit
  // labels hidden, so the sign itself has to be read instead of the numeral.
  // Not listed on either tab.
  DotColourPair(
    colorA: Color(0xFFE53935),
    colorB: Color(0xFFE53935),
    name: 'counting_game.level14.name',
    nameA: 'red',
    nameB: 'red',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    showAnswerNumerals: false,
  ),
  DotColourPair(
    colorA: Color.fromARGB(255, 112, 67, 160),
    colorB: Color.fromARGB(255, 112, 67, 160),
    name: 'counting_game.level15.name',
    nameA: 'purple',
    nameB: 'purple',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    showAnswerNumerals: false,
  ),
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level16.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    showAnswerNumerals: false,
  ),
  // Level 17: timed duplicate of level 16 — how many right in 1 minute.
  DotColourPair(
    colorA: Color(0xFF1E88E5),
    colorB: Color(0xFF1E88E5),
    name: 'counting_game.level17.name',
    nameA: 'blue',
    nameB: 'blue',
    questionOrder: [QuestionType.total],
    useDicePattern: true,
    isTimed: true,
    showAnswerNumerals: false,
  ),
];

// ── Picture objects ───────────────────────────────────────────────────────────

/// The things the Random levels count instead of dots. Each has a
/// folder of pictures under `assets/images/counting_game/`; balloons and
/// hats also come in named colours, for the two-colour levels' "How many
/// pink hats?" questions.
enum CountingObject {
  balloons(
    images: ['balloon-blue.png', 'balloon-pale.png', 'balloon-red.png'],
    byColour: {'blue': 'balloon-blue.png', 'red': 'balloon-red.png'},
  ),
  candles(
    images: [
      'candle-blue-light-dark.png',
      'candle-green-light-dark.png',
      'candle-pink-purple.png',
      'candle-pink-red.png',
      'candle-yellow-gold.png',
    ],
    strip: 'ten-candles.jpg',
    // ten-candles.jpg is 1264px wide; the gaps between its candles are at
    // 171, 296, 413, 534, 657, 771, 878, 998 and 1117px from the left.
    stripCuts: [
      171 / 1264,
      296 / 1264,
      413 / 1264,
      534 / 1264,
      657 / 1264,
      771 / 1264,
      878 / 1264,
      998 / 1264,
      1117 / 1264,
    ],
  ),
  hats(
    images: [
      'hat-yellow.png',
      'hat-blue.png',
      'hat-green.png',
      'hat-orange.png',
      'hat-pink.png',
      'hat-purple.png',
      'hat-red.png',
      'hat-silver.png',
    ],
    byColour: {
      'pink': 'hat-pink.png',
      'yellow': 'hat-yellow.png',
      'blue': 'hat-blue.png',
      'red': 'hat-red.png',
      'green': 'hat-green.png',
      'purple': 'hat-purple.png',
    },
  ),
  strawberries(images: ['strawberry-1.png', 'strawberry-2.png']),
  oranges(images: ['orange.png']),
  sandwiches(images: ['sandwich.png']);

  /// File names in this object's folder.
  final List<String> images;

  /// Colour name (as in [DotColourPair.nameA]) → the picture in that
  /// colour, for the colours this object comes in.
  final Map<String, String> byColour;

  /// A picture of 10 of this object standing evenly spaced in a row. When
  /// set, a round shows this one picture cropped to the round's count
  /// instead of scattering separate pictures — see [stripImage].
  final String? strip;

  /// Where the gaps between the items in [strip] fall, as fractions (0-1)
  /// of its width from the left — 9 cuts for its 10 items, which aren't
  /// evenly spaced. See [stripFraction].
  final List<double> stripCuts;

  const CountingObject({
    required this.images,
    this.byColour = const {},
    this.strip,
    this.stripCuts = const [],
  });

  String _path(String file) => 'assets/images/counting_game/$name/$file';

  /// Asset path of a random picture of this object.
  String randomImage(Random random) =>
      _path(images[random.nextInt(images.length)]);

  /// Asset path of this object's picture in [colour].
  String imageInColour(String colour) => _path(byColour[colour]!);

  /// Asset path of this object's [strip] picture, if it has one.
  String? get stripImage => strip == null ? null : _path(strip!);

  /// How much of [strip]'s width, from the left, shows exactly [count]
  /// items (1-10).
  double stripFraction(int count) =>
      count >= 10 ? 1.0 : stripCuts[count.clamp(1, 9) - 1];
}

// ── Dice-pip layout ───────────────────────────────────────────────────────────

/// Fractional (0-1) pip positions for a single die face, values 1-6.
const Map<int, List<Offset>> _diePipPattern = {
  1: [Offset(0.5, 0.5)],
  2: [Offset(0.3, 0.3), Offset(0.7, 0.7)],
  3: [Offset(0.3, 0.3), Offset(0.5, 0.5), Offset(0.7, 0.7)],
  4: [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.3, 0.7), Offset(0.7, 0.7)],
  5: [
    Offset(0.3, 0.3),
    Offset(0.7, 0.3),
    Offset(0.5, 0.5),
    Offset(0.3, 0.7),
    Offset(0.7, 0.7),
  ],
  6: [
    Offset(0.3, 0.22),
    Offset(0.7, 0.22),
    Offset(0.3, 0.5),
    Offset(0.7, 0.5),
    Offset(0.3, 0.78),
    Offset(0.7, 0.78),
  ],
};

/// Maps a die [pattern] (1-6) into normalised positions within [rect].
List<Offset> _pipsInRect(int pattern, Rect rect) {
  return _diePipPattern[pattern]!
      .map(
        (p) => Offset(
          rect.left + p.dx * rect.width,
          rect.top + p.dy * rect.height,
        ),
      )
      .toList();
}

/// Dice-style pip layout for [count] (1-5), used by dice-pattern levels
/// instead of a random scatter: the standard die face for that number.
///
/// 6-9 stack two sub-patterns vertically, and 10 places two side by
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
      return _pipsInRect(count, const Rect.fromLTWH(0, 0, 1, 1));
    case 6:
    case 7:
    case 8:
    case 9:
      throw ArgumentError(
        'count=$count is a stacked pattern; use stackedDicePipPixelPositions',
      );
    case 10:
      throw ArgumentError(
        'count=10 is a side-by-side pattern; use sideBySideDicePipPixelPositions',
      );
    default:
      throw ArgumentError('No dice pattern for count=$count');
  }
}

/// The two sub-patterns (top, bottom) stacked to form counts 6-9.
const Map<int, List<int>> _diceStackPatterns = {
  6: [3, 3],
  7: [3, 4],
  8: [4, 4],
  9: [4, 5],
};

/// Pixel-space pip positions for a stacked dice count (6-9), sized so
/// each row's sub-pattern is inscribed in a true square — independent of
/// the play area's [width]/[height] aspect ratio — so the pattern stays
/// recognisable rather than being stretched into a wide, flat rectangle.
List<Offset> stackedDicePipPixelPositions(
  int count,
  double width,
  double height,
) {
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
  List<int> rows,
  double width,
  double height,
) {
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
/// Used by level 6's ("10+") constant "always 10" group.
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
/// box, picking whichever dice pattern fits: a direct die face (1-5), a
/// stacked pair (6-9), or side-by-side fives (10). The 1-5 die face is
/// confined to a square sub-region centred within the box (rather than
/// stretched to fill a non-square box) so it stays proportionally correct,
/// matching how the 6-9/10 patterns are already square-cell sized. Used to
/// render a single colour's group within its own panel — see
/// [DotColourPair.fixedTotal].
List<Offset> dicePatternPipPixelPositions(
  int count,
  double width,
  double height,
) {
  if (count == 10) return sideBySideDicePipPixelPositions(width, height);
  if (count >= 6) return stackedDicePipPixelPositions(count, width, height);
  final double side = min(width, height);
  final Rect square = Rect.fromLTWH(
    (width - side) / 2,
    (height - side) / 2,
    side,
    side,
  );
  return _pipsInRect(count, square);
}

// ── Question types ────────────────────────────────────────────────────────────

enum QuestionType { colourA, colourB, total }

// ── Round ─────────────────────────────────────────────────────────────────────

/// One round = one collection of dots + the questions about it
/// (see [DotColourPair.questionOrder]).
class CountingRound {
  final int countA;
  final int countB;

  /// Pre-computed normalised positions (0–1) within the play area.
  final List<Offset> positions;

  /// True when a horizontal divider line should be drawn across the middle
  /// of the play area (dice patterns for 6, 8 and 9).
  final bool showDivider;

  /// Set for dice counts 6-10: the widget computes pip positions itself via
  /// [stackedDicePipPixelPositions] (6-9) or
  /// [sideBySideDicePipPixelPositions] (10) — both need the play area's
  /// actual pixel size to keep each sub-pattern square — ignoring
  /// [positions].
  final int? diceCompositeCount;

  /// For [DotColourPair.usePictures] levels, what group A's and group
  /// B's items are pictures of (the same object unless the level shows two
  /// separate groups, as "Add to 10" does); null for dot levels.
  final CountingObject? objectA;
  final CountingObject? objectB;

  /// For picture levels, the asset path of each item's picture — group A's
  /// [countA] items first, then group B's. Empty for dot levels.
  final List<String> images;

  const CountingRound({
    required this.countA,
    required this.countB,
    required this.positions,
    this.showDivider = false,
    this.diceCompositeCount,
    this.objectA,
    this.objectB,
    this.images = const [],
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
/// - 5 rounds per game, each showing a new collection of dots — except
///   [DotColourPair.isTimed] levels, which keep generating rounds for
///   [timedLevelDurationSeconds] instead of stopping at a fixed count.
/// - Each round asks the questions in [DotColourPair.questionOrder]:
///   single-colour levels ask just "total"; two-colour levels ask
///   colour A → colour B → total.
/// - 3 BSL number buttons per question; wrong taps are greyed out/disabled.
/// - Correct answer awards 1 point and advances to the next question.
/// - The game is won once every round's questions have been answered, or
///   (for timed levels) once the clock runs out.
class CountingGameProvider extends ChangeNotifier {
  static const int totalRounds = 5;

  /// Canonical levels listed on the Patterns tab, in on-screen order —
  /// numbered the same on screen: the dice-pattern levels 1-4, then
  /// "Add to 10" (5) and "10+" (6).
  static const List<int> patternTabLevels = [1, 2, 3, 4, 5, 6];

  /// Canonical levels listed on the Random tab, in on-screen order: the
  /// random-scatter picture levels 7-13, shown as Random 1-7.
  ///
  /// Canonical 14-17 (levels 1-4 with the answer digits hidden) aren't
  /// listed on any tab; they live on as Champion Mode's rendition of
  /// levels 1-4.
  static const List<int> randomTabLevels = [7, 8, 9, 10, 11, 12, 13];

  /// The level number shown on screen for canonical level [canonicalLevel]
  /// (1-17): its position within its tab ([patternTabLevels] or
  /// [randomTabLevels]). Canonical 14-17, listed on neither, pass through
  /// unchanged.
  static int displayLevelNumber(int canonicalLevel) {
    final patternIndex = patternTabLevels.indexOf(canonicalLevel);
    if (patternIndex >= 0) return patternIndex + 1;
    final randomIndex = randomTabLevels.indexOf(canonicalLevel);
    if (randomIndex >= 0) return randomIndex + 1;
    return canonicalLevel;
  }

  /// The canonical level number "Next Level" moves to from
  /// [canonicalLevel], or null at the end of the game. Play runs through
  /// [patternTabLevels] then [randomTabLevels]. Canonical 14-17 aren't
  /// listed on any tab, so they continue from where level 4 would.
  static int? nextLevelNumber(int canonicalLevel) {
    const order = [...patternTabLevels, ...randomTabLevels];
    final from = canonicalLevel >= 14 ? 4 : canonicalLevel;
    final index = order.indexOf(from);
    if (index < 0 || index + 1 >= order.length) return null;
    return order[index + 1];
  }

  // ── Champion Mode ──────────────────────────────────────────────────────────
  // Mirrors BSL Maths' Champion Mode: unlocked by a personal-best score and,
  // while on, hides the digit labels beneath the BSL number signs in the
  // answer boxes (levels 1-4 then play exactly like levels 14-17).

  /// Score required in a single "level 4" game (a 60-second timed level)
  /// to unlock Champion Mode.
  static const int championModeUnlockScore = 10;

  /// The canonical levels whose personal bests gate Champion Mode — the
  /// level 4 game of each tab: Patterns 4 (canonical 4) and Random 4
  /// (canonical 10).
  static const List<int> championModeUnlockLevels = [4, 10];

  /// Whether Champion Mode is enabled — hides the digits beneath the BSL
  /// number signs in the answer boxes (see [showAnswerNumerals]).
  bool _championMode = false;
  bool get championMode => _championMode;

  /// Whether the player has unlocked Champion Mode by scoring at least
  /// [championModeUnlockScore] in either level 4 game
  /// ([championModeUnlockLevels]).
  bool _isChampionModeUnlocked = false;
  bool get isChampionModeUnlocked => _isChampionModeUnlocked;

  /// True for one session only: the player just crossed the Champion Mode
  /// unlock threshold for the first time. The screen shows a celebratory
  /// banner while this is true, then calls
  /// [dismissChampionModeUnlockedBanner] to clear it.
  bool _justUnlockedChampionMode = false;
  bool get justUnlockedChampionMode => _justUnlockedChampionMode;

  /// Whether the current level's answer buttons show their digit labels —
  /// each level's own [DotColourPair.showAnswerNumerals], overridden to
  /// hidden while Champion Mode is on.
  bool get showAnswerNumerals => !_championMode && colours.showAnswerNumerals;

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

  /// Clears [justUnlockedChampionMode] once the unlock banner has been
  /// shown and dismissed.
  void dismissChampionModeUnlockedBanner() {
    _justUnlockedChampionMode = false;
    notifyListeners();
  }

  /// Unlocks Champion Mode from the player's personal bests on the two
  /// level-4 games ([championModeUnlockLevels]), if it isn't already
  /// unlocked.
  ///
  /// Only ever raises [isChampionModeUnlocked], never lowers it: guest play
  /// isn't persisted by [GameStatsService], so this lookup always comes
  /// back empty for guests — if it could clear the flag, a guest who just
  /// unlocked Champion Mode this session would see it re-locked on
  /// returning to level select.
  Future<void> _refreshChampionModeUnlock() async {
    if (_isChampionModeUnlocked) return;
    for (final level in championModeUnlockLevels) {
      final best = await _statsService.getPersonalBest(
        '${GameIds.countingGame}_$level',
      );
      if ((best ?? 0) >= championModeUnlockScore) {
        _isChampionModeUnlocked = true;
        _championMode = !_championModeOffThisSession;
        notifyListeners();
        return;
      }
    }
  }

  /// Marks Champion Mode as just-unlocked when the game that just finished
  /// was a level-4 game and the score crossed [championModeUnlockScore] —
  /// runs right after the result is recorded so the banner shows once.
  /// Only ever raises the flags, so a guest whose score isn't persisted
  /// still gets their one unlock celebration this session.
  void _maybeJustUnlockedChampionMode() {
    if (_isChampionModeUnlocked) return;
    if (championModeUnlockLevels.contains(levelNumber) &&
        _score >= championModeUnlockScore) {
      _isChampionModeUnlocked = true;
      _championMode = !_championModeOffThisSession;
      _justUnlockedChampionMode = true;
    }
  }

  /// Countdown duration for [DotColourPair.isTimed] levels.
  static const int timedLevelDurationSeconds = 60;

  /// Maximum total dot count per level.
  static const List<int> _maxTotals = [
    5,
    7,
    10,
    10,
    10,
    19,
    5,
    7,
    10,
    10,
    5,
    10,
    19,
    5,
    7,
    10,
    10,
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
  DotColourPair get colours => countingColourPairs[_levelIndex];

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

  /// Called with the final score whenever a level ends (won or, for timed
  /// levels, timeUp) — set by the trail flow to gate node completion on
  /// [TrailNode.minScore]. Unused outside the trail.
  Function(int score)? onLevelComplete;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  /// [initialLevelNumber], when set, skips level-select and starts directly
  /// on that level — used when launched from the "Learn BSL trail". Timed
  /// levels are the exception: they stay unstarted so the screen can show
  /// the intro countdown first (same as normal timed-level play) instead
  /// of the clock silently already running underneath it.
  CountingGameProvider({int? initialLevelNumber}) {
    if (initialLevelNumber != null &&
        !countingColourPairs[initialLevelNumber - 1].isTimed) {
      startGame(initialLevelNumber - 1);
    } else {
      showLevelSelection();
    }
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    _timedLevelTimer?.cancel();
    _refreshChampionModeUnlock();
    notifyListeners();
  }

  void startGame(int levelIndex) {
    _levelIndex = levelIndex.clamp(0, countingColourPairs.length - 1);
    _showLevelSelect = false;
    _score = 0;
    _lastResult = null;
    _justUnlockedChampionMode = false;
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
          onLevelComplete?.call(_score);
          _statsService
              .recordGameResult(
                GameIds.countingGame,
                _score,
                level: levelNumber,
              )
              .then((result) {
                _lastResult = result;
                _maybeJustUnlockedChampionMode();
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
    onLevelComplete?.call(_score);
    _statsService
        .recordGameResult(GameIds.countingGame, _score, level: levelNumber)
        .then((result) {
          _lastResult = result;
          _maybeJustUnlockedChampionMode();
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
    final round = _generateCounts(previous: previous);
    return colours.usePictures
        ? _withPictures(round, previous: previous)
        : round;
  }

  /// Gives [round] a new [CountingObject] (a different one from
  /// [previous]'s where there's a choice) and a picture for every item:
  /// - two-colour levels: an object that comes in both colours, each group
  ///   pictured in its own colour;
  /// - "Add to 10" ([DotColourPair.fixedTotal]): two different objects,
  ///   one per group, since its number colours are gone;
  /// - otherwise: one object, each item a random picture of it.
  CountingRound _withPictures(CountingRound round, {CountingRound? previous}) {
    CountingObject pick(Iterable<CountingObject> options) {
      final all = options.toList();
      final fresh = all.where((o) => o != previous?.objectA).toList();
      final from = fresh.isNotEmpty ? fresh : all;
      return from[_random.nextInt(from.length)];
    }

    final CountingObject objectA;
    final CountingObject objectB;
    final List<String> images;
    if (!colours.singleColour && !colours.usesNumberColours) {
      objectA = objectB = pick(
        CountingObject.values.where(
          (o) =>
              o.byColour.containsKey(colours.nameA) &&
              o.byColour.containsKey(colours.nameB),
        ),
      );
      images = [
        for (var i = 0; i < round.countA; i++)
          objectA.imageInColour(colours.nameA),
        for (var i = 0; i < round.countB; i++)
          objectA.imageInColour(colours.nameB),
      ];
    } else {
      objectA = pick(CountingObject.values);
      objectB = colours.fixedTotal != null
          ? (CountingObject.values.where((o) => o != objectA).toList()
                  ..shuffle(_random))
                .first
          : objectA;
      images = [
        for (var i = 0; i < round.countA; i++) objectA.randomImage(_random),
        for (var i = 0; i < round.countB; i++) objectB.randomImage(_random),
      ];
    }
    return CountingRound(
      countA: round.countA,
      countB: round.countB,
      positions: round.positions,
      showDivider: round.showDivider,
      diceCompositeCount: round.diceCompositeCount,
      objectA: objectA,
      objectB: objectB,
      images: images,
    );
  }

  CountingRound _generateCounts({CountingRound? previous}) {
    final maxTotal = _maxTotal;

    if (colours.isTeenGrid) {
      while (true) {
        // countB is 1-9 (not 1-10) so the total (10 + countB) never reaches
        // 20 — the highest total across all levels is capped at 19.
        final countB = _random.nextInt(9) + 1;

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
          // merged composite pattern is needed here — see _DotPlayArea.
          return CountingRound(
            countA: countA,
            countB: countB,
            positions: const [],
          );
        }
      }

      while (true) {
        final count = _random.nextInt(maxTotal) + 1;

        if (previous != null && count == previous.countA) {
          continue;
        }

        final bool isComposite = count >= 6;
        return CountingRound(
          countA: count,
          countB: 0,
          positions: isComposite ? const [] : dicePipPositions(count),
          showDivider: count == 6 || count == 8 || count == 9,
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
  /// Min-distance shrinks for higher counts so dots still fit.
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
