import 'package:flutter/material.dart';

import 'bubble_patterns.dart';

export 'bubble_patterns.dart';

/// A bubble colour. [name] doubles as the BSL sign asset id
/// (`assets/images/colours_BSL/<name>.riv`) and the `colouring.colour.<name>`
/// translation key suffix — keep it in English.
enum BubbleColour {
  red(Color(0xFFFF3B3B)),
  blue(Color(0xFF2F7BFF)),
  green(Color(0xFF2ECC40)),
  purple(Color(0xFF9B4DFF)),
  orange(Color(0xFFFF8A00)),
  yellow(Color(0xFFFFD60A)),
  white(Color(0xFFF4F6FF)),
  black(Color(0xFF2A2A38)),
  pink(Color(0xFFFF5FB4)),
  brown(Color(0xFF9A5B2E));

  const BubbleColour(this.color);

  /// The bubble's base (mid-tone) colour.
  final Color color;
}

/// One level of the bubble shooter.
class BubbleShooterLevel {
  /// Level number (1-based).
  final int number;

  /// Colours used on this level.
  final List<BubbleColour> colours;

  /// Number of rows in the starting cluster. Rows beyond what fits on screen
  /// are revealed as the cluster lowers.
  final int rows;

  /// Chance (0–1) that a cell copies a neighbour's colour when the cluster
  /// is generated. Higher = bigger single-colour clumps = easier matches.
  final double clumpiness;

  /// When set, this level is a timed speed round of this many seconds: rows
  /// form a stack of shapes (see [speedRoundPattern]) and new rows keep
  /// appearing at the top so the bubbles never run out.
  final int? speedRoundSeconds;

  /// The shapes a speed round's rows are stacked from.
  final SpeedRoundPattern speedRoundPattern;

  /// When set, the starting cluster is regenerated (up to a limit) until no
  /// way of playing it can clear the board in fewer shots than this.
  final int? minShotsToClear;

  /// When set, the starting cluster is also regenerated until no single
  /// shot can clear more than this fraction (0–1) of it, popped and dropped
  /// bubbles together.
  final double? maxClearPerShot;

  /// When true, the ceiling row alternates colours in pairs, so no single
  /// colour holds up the whole cluster — popping one colour's ceiling
  /// bubbles leaves the other colour's still hanging.
  final bool ceilingInPairs;

  /// When set, the starting cluster is drawn in this geometric pattern
  /// instead of random clumps, mapping its four colour slots to [colours].
  final BubblePattern? pattern;

  /// Draws [pattern] with thinner bands, for smaller groups to pop.
  final bool finePattern;

  const BubbleShooterLevel({
    required this.number,
    required this.colours,
    required this.rows,
    required this.clumpiness,
    this.speedRoundSeconds,
    this.speedRoundPattern = SpeedRoundPattern.diamonds,
    this.minShotsToClear,
    this.maxClearPerShot,
    this.ceilingInPairs = false,
    this.pattern,
    this.finePattern = false,
  });

  bool get isSpeedRound => speedRoundSeconds != null;

  /// Whether the edge around the cannon's BSL sign (and the aim guide) is
  /// tinted with the loaded colour. From
  /// [BubbleShooterLevels.noColourHintLevel] on, the sign alone tells the
  /// player the colour.
  bool get showsColourHint => number < BubbleShooterLevels.noColourHintLevel;

  /// Translation key for the level name.
  String get nameKey => 'bubble_shooter.level$number.name';
}

/// The shapes a speed round's bubbles are stacked from.
enum SpeedRoundPattern {
  /// Diamonds split half-and-half into two colours, a different pair each
  /// time (see [SpeedRoundRows]).
  diamonds,

  /// Hexagons split half-and-half into two colours around a smaller
  /// hexagon of a third, a different trio each time (see
  /// [SpeedRoundHexagons]). Neighbouring hexagons are joined by a short
  /// white neck.
  hexagons,

  /// Full-width sections of diagonal stripes, each stripe two bubbles wide,
  /// in five colours per section (see [SpeedRoundStripes]). Each section's
  /// stripes lean the other way from the one below.
  stripes,
}

/// All bubble shooter levels, easiest first. Difficulty grows through the
/// number of colours, the cluster height (no level has fewer bubbles than
/// the one before), and smaller colour clumps. The two-colour levels form a
/// chain — each shares a colour with the one before — so every new sign is
/// met alongside a familiar one. Levels 11–20 use three colours, then
/// [speedRoundLevel], [hexagonRoundLevel] and [stripesRoundLevel] are
/// one-minute speed rounds. From [firstPatternLevel] to [lastLevel], levels
/// are generated (see [_patternLevels]): four colours in a geometric
/// pattern.
class BubbleShooterLevels {
  BubbleShooterLevels._();

  /// The one-minute speed round.
  static const int speedRoundLevel = 21;

  /// The one-minute speed round stacked from hexagons.
  static const int hexagonRoundLevel = 22;

  /// The one-minute speed round of diagonal stripes.
  static const int stripesRoundLevel = 23;

  /// First level without the colour hint around the cannon's sign.
  static const int noColourHintLevel = 11;

  /// First generated pattern level, and the last level of all.
  static const int firstPatternLevel = 24;
  static const int lastLevel = 40;

  static final List<BubbleShooterLevel> all = [
    ..._designedLevels,
    ..._patternLevels(),
  ];

  static const List<BubbleShooterLevel> _designedLevels = [
    BubbleShooterLevel(
      number: 1,
      colours: [BubbleColour.blue, BubbleColour.red],
      rows: 8,
      clumpiness: 0.75,
      minShotsToClear: 3,
      maxClearPerShot: 0.6,
      ceilingInPairs: true,
    ),
    BubbleShooterLevel(
      number: 2,
      colours: [BubbleColour.blue, BubbleColour.white],
      rows: 9,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 3,
      colours: [BubbleColour.white, BubbleColour.green],
      rows: 9,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 4,
      colours: [BubbleColour.green, BubbleColour.purple],
      rows: 10,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 5,
      colours: [BubbleColour.purple, BubbleColour.yellow],
      rows: 10,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 6,
      colours: [BubbleColour.yellow, BubbleColour.pink],
      rows: 11,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 7,
      colours: [BubbleColour.pink, BubbleColour.black],
      rows: 11,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 8,
      colours: [BubbleColour.black, BubbleColour.brown],
      rows: 12,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 9,
      colours: [BubbleColour.brown, BubbleColour.white],
      rows: 12,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 10,
      colours: [BubbleColour.white, BubbleColour.orange],
      rows: 13,
      clumpiness: 0.7,
    ),
    // Levels 11–20 use three colours each, every colour on exactly three
    // levels. The trios are picked to stay distinguishable with colour-vision
    // deficiency (protan, deutan and tritan simulations): red, green and
    // brown never share a level, nor do blue and purple, nor orange with
    // green, yellow, red or pink. Most distinct trios come first.
    BubbleShooterLevel(
      number: 11,
      colours: [BubbleColour.orange, BubbleColour.white, BubbleColour.black],
      rows: 14,
      clumpiness: 0.7,
    ),
    BubbleShooterLevel(
      number: 12,
      colours: [BubbleColour.green, BubbleColour.white, BubbleColour.black],
      rows: 14,
      clumpiness: 0.65,
    ),
    BubbleShooterLevel(
      number: 13,
      colours: [BubbleColour.green, BubbleColour.purple, BubbleColour.pink],
      rows: 15,
      clumpiness: 0.65,
    ),
    BubbleShooterLevel(
      number: 14,
      colours: [BubbleColour.red, BubbleColour.purple, BubbleColour.white],
      rows: 15,
      clumpiness: 0.6,
    ),
    BubbleShooterLevel(
      number: 15,
      colours: [BubbleColour.blue, BubbleColour.yellow, BubbleColour.brown],
      rows: 16,
      clumpiness: 0.6,
    ),
    BubbleShooterLevel(
      number: 16,
      colours: [BubbleColour.green, BubbleColour.black, BubbleColour.pink],
      rows: 16,
      clumpiness: 0.55,
    ),
    BubbleShooterLevel(
      number: 17,
      colours: [BubbleColour.red, BubbleColour.blue, BubbleColour.yellow],
      rows: 17,
      clumpiness: 0.55,
    ),
    BubbleShooterLevel(
      number: 18,
      colours: [BubbleColour.red, BubbleColour.yellow, BubbleColour.pink],
      rows: 17,
      clumpiness: 0.5,
    ),
    BubbleShooterLevel(
      number: 19,
      colours: [BubbleColour.blue, BubbleColour.orange, BubbleColour.brown],
      rows: 18,
      clumpiness: 0.5,
    ),
    BubbleShooterLevel(
      number: 20,
      colours: [BubbleColour.purple, BubbleColour.orange, BubbleColour.brown],
      rows: 18,
      clumpiness: 0.45,
    ),
    // Speed round: an endless stack of half-and-half diamonds, using every colour from the
    // levels before it. [colours] lists every colour the cannon might load.
    BubbleShooterLevel(
      number: 21,
      colours: [
        BubbleColour.blue,
        BubbleColour.red,
        BubbleColour.green,
        BubbleColour.purple,
        BubbleColour.orange,
        BubbleColour.yellow,
        BubbleColour.white,
        BubbleColour.black,
        BubbleColour.pink,
        BubbleColour.brown,
      ],
      rows: 14,
      clumpiness: 0,
      speedRoundSeconds: 60,
    ),
    // Speed round: an endless stack of half-and-half hexagons, each with a
    // smaller hexagon of a third colour in its middle. [colours] lists every
    // colour the cannon might load. 14 rows puts a hexagon's tip (which
    // sits on an odd row) at the bottom.
    BubbleShooterLevel(
      number: 22,
      colours: BubbleColour.values,
      rows: 14,
      clumpiness: 0,
      speedRoundSeconds: 60,
      speedRoundPattern: SpeedRoundPattern.hexagons,
    ),
    // Speed round: an endless stack of 7-row sections of diagonal stripes,
    // leaning alternate ways. [colours] lists every colour the cannon might
    // load.
    BubbleShooterLevel(
      number: 23,
      colours: BubbleColour.values,
      rows: 14,
      clumpiness: 0,
      speedRoundSeconds: 60,
      speedRoundPattern: SpeedRoundPattern.stripes,
    ),
  ];

  /// Patterns the generated levels use in their thinner ([finePattern])
  /// form, after one level of every pattern drawn wide.
  static const List<BubblePattern> _finePatterns = [
    BubblePattern.checks,
    BubblePattern.diagonals,
    BubblePattern.zigzags,
    BubblePattern.dots,
    BubblePattern.rings,
    BubblePattern.hexagons,
    BubblePattern.pinwheel,
  ];

  /// Generates levels [firstPatternLevel] to [lastLevel]: every
  /// [BubblePattern] drawn wide, easiest first, then the trickier ones
  /// drawn fine. Clusters start at the last designed level's height and
  /// grow a row every four levels, unless the pattern needs a set height
  /// ([BubblePattern.fixedRows]).
  ///
  /// Each level takes four colours with no colour-blind confusable pair
  /// (see [SpeedRoundStripes.confusable]): the unused set sharing fewest
  /// colours with the level before, then favouring colours used least so
  /// far. The set is rotated a step each level, so which colour fills
  /// which part of a pattern varies too.
  static List<BubbleShooterLevel> _patternLevels() {
    final patterns = [
      for (final p in BubblePattern.values) (p, false),
      for (final p in _finePatterns) (p, true),
    ];
    final sets = _patternColourSets();
    final used = <BubbleColour, int>{for (final c in BubbleColour.values) c: 0};
    var previous = <BubbleColour>{};
    final startRows = _designedLevels.where((l) => !l.isSpeedRound).last.rows;
    return [
      for (var i = 0; i <= lastLevel - firstPatternLevel; i++)
        () {
          int cost(List<BubbleColour> s) =>
              s.where(previous.contains).length * 100 +
              s.fold(0, (sum, c) => sum + used[c]!);
          final set = sets.reduce((a, b) => cost(b) < cost(a) ? b : a);
          sets.remove(set);
          for (final c in set) {
            used[c] = used[c]! + 1;
          }
          previous = set.toSet();
          final (pattern, fine) = patterns[i % patterns.length];
          return BubbleShooterLevel(
            number: firstPatternLevel + i,
            colours: [
              for (var k = 0; k < set.length; k++) set[(k + i) % set.length],
            ],
            rows: pattern.fixedRows ?? startRows + i ~/ 4,
            clumpiness: 0,
            pattern: pattern,
            finePattern: fine,
          );
        }(),
    ];
  }

  /// Every set of four colours with no [SpeedRoundStripes.confusable] pair.
  static List<List<BubbleColour>> _patternColourSets() {
    const c = BubbleColour.values;
    final sets = <List<BubbleColour>>[];
    void extend(List<BubbleColour> set, int from) {
      if (set.length == 4) {
        sets.add(List.of(set));
        return;
      }
      for (var i = from; i < c.length; i++) {
        if (set.any((s) => SpeedRoundStripes.areConfusable(s, c[i]))) continue;
        extend(set..add(c[i]), i + 1);
        set.removeLast();
      }
    }

    extend([], 0);
    return sets;
  }

  /// Level from which a level's newly introduced colours get solid rows.
  static const int firstIntroLevel = 4;

  /// Colours [level] uses that no earlier level used, in [colours] order —
  /// from [firstIntroLevel] on (speed rounds excluded). Each gets a solid
  /// row across the bottom of the cluster, and the cannon fires them first,
  /// so the player meets the new sign straight away.
  static List<BubbleColour> introducedColours(BubbleShooterLevel level) {
    if (level.number < firstIntroLevel || level.isSpeedRound) return const [];
    final seen = {
      for (final l in all.where((l) => l.number < level.number)) ...l.colours,
    };
    return level.colours.where((c) => !seen.contains(c)).toList();
  }

  /// Every [chestEvery]th level is a treasure chest on the level map.
  static const int chestEvery = 5;

  /// Whether [level] is a treasure chest on the level map — finishing it
  /// lets the player open the chest.
  static bool isChestLevel(int level) =>
      level % chestEvery == 0 && level <= all.length;

  /// Id of [level]'s chest, saved with the card it gives (see
  /// `SportsCollectionProvider`), so each chest opens once per player.
  static String chestSource(int level) => 'bubble_shooter_chest_$level';

  /// Gets a level by number, falling back to level 1 if out of range.
  static BubbleShooterLevel getLevel(int number) {
    if (number < 1 || number > all.length) return all.first;
    return all[number - 1];
  }
}

/// A grid cell in the hex layout. Odd rows are shifted right by one radius
/// and hold one fewer bubble than even rows.
@immutable
class GridCell {
  final int row;
  final int col;

  const GridCell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridCell($row, $col)';
}

/// A bubble currently in flight from the cannon.
class FlyingBubble {
  final BubbleColour colour;
  Offset position;
  Offset velocity;

  FlyingBubble({
    required this.colour,
    required this.position,
    required this.velocity,
  });
}

/// A bubble that's been cut loose from the cluster and is falling away.
class FallingBubble {
  final BubbleColour colour;
  Offset position;
  Offset velocity;

  /// Seconds before this bubble starts falling (staggers a big drop).
  double delay;

  FallingBubble({
    required this.colour,
    required this.position,
    required this.velocity,
    this.delay = 0,
  });
}

/// A bubble playing its pop animation.
class PoppingBubble {
  final BubbleColour colour;

  /// Moves with the cluster in a speed round, so the pop stays in place
  /// as the view scrolls.
  Offset position;

  /// Grid row the bubble popped from, while it still holds the speed
  /// round's view down (see `BubbleShooterProvider`).
  int? row;

  /// Seconds elapsed since the pop was queued; negative while waiting for
  /// its turn in a chain reaction.
  double age;

  PoppingBubble({
    required this.colour,
    required this.position,
    this.row,
    this.age = 0,
  });

  /// Total length of the pop animation, in seconds.
  static const double duration = 0.35;

  /// 0→1 progress through the animation, or null while still waiting.
  double? get progress => age < 0 ? null : (age / duration).clamp(0.0, 1.0);
}

/// Floating "+10" style score label shown where bubbles popped or fell.
class ScorePopup {
  final int points;
  Offset position;
  double age;

  ScorePopup({required this.points, required this.position, this.age = 0});

  static const double duration = 0.9;
}

/// Colour pairs for speed-round diamonds: each diamond is split into a left
/// and a right half, one colour each.
///
/// Most pairs stay distinguishable with colour-vision deficiency (they
/// differ in lightness and/or on the blue↔yellow axis). [hard] pairs are
/// the classic confusions, included on purpose but less often.
class SpeedRoundRows {
  SpeedRoundRows._();

  static const List<(BubbleColour, BubbleColour)> safe = [
    (BubbleColour.blue, BubbleColour.yellow),
    (BubbleColour.purple, BubbleColour.orange),
    (BubbleColour.black, BubbleColour.white),
    (BubbleColour.blue, BubbleColour.orange),
    (BubbleColour.pink, BubbleColour.black),
    (BubbleColour.purple, BubbleColour.yellow),
    (BubbleColour.blue, BubbleColour.white),
    (BubbleColour.orange, BubbleColour.black),
    (BubbleColour.yellow, BubbleColour.black),
    (BubbleColour.purple, BubbleColour.white),
    (BubbleColour.pink, BubbleColour.blue),
    (BubbleColour.red, BubbleColour.white),
    (BubbleColour.red, BubbleColour.blue),
    (BubbleColour.green, BubbleColour.purple),
    (BubbleColour.green, BubbleColour.white),
  ];

  static const List<(BubbleColour, BubbleColour)> hard = [
    (BubbleColour.green, BubbleColour.brown),
    (BubbleColour.red, BubbleColour.green),
    (BubbleColour.red, BubbleColour.brown),
    (BubbleColour.blue, BubbleColour.purple),
    (BubbleColour.green, BubbleColour.orange),
  ];

  /// Chance that a row uses a [hard] pair.
  static const double hardChance = 0.2;
}

/// Colours for hexagon speed-round hexagons.
class SpeedRoundHexagons {
  SpeedRoundHexagons._();

  /// Colour of the neck joining one hexagon to the next. No trio uses it,
  /// so the necks keep neighbouring hexagons' colours apart.
  static const BubbleColour neck = BubbleColour.white;

  /// Colour trios a hexagon is built from — the two halves and the middle
  /// hexagon, in any order. All three touch each other, so each trio is one
  /// already used together on a three-colour level (picked there to stay
  /// distinguishable with colour-vision deficiency), leaving out [neck].
  static const List<(BubbleColour, BubbleColour, BubbleColour)> trios = [
    (BubbleColour.purple, BubbleColour.green, BubbleColour.yellow),
    (BubbleColour.green, BubbleColour.purple, BubbleColour.pink),
    (BubbleColour.blue, BubbleColour.yellow, BubbleColour.brown),
    (BubbleColour.green, BubbleColour.black, BubbleColour.pink),
    (BubbleColour.red, BubbleColour.blue, BubbleColour.yellow),
    (BubbleColour.red, BubbleColour.yellow, BubbleColour.pink),
    (BubbleColour.blue, BubbleColour.orange, BubbleColour.brown),
    (BubbleColour.purple, BubbleColour.orange, BubbleColour.brown),
  ];
}

/// Colours for stripes speed-round sections.
class SpeedRoundStripes {
  SpeedRoundStripes._();

  /// Colours in each section. Every section uses the colours the one below
  /// didn't, so no stripe joins up with one in the next section.
  static const int coloursPerSection = 5;

  /// Pairs that are hard to tell apart with colour-vision deficiency,
  /// never used for neighbouring stripes.
  static const List<(BubbleColour, BubbleColour)> confusable = [
    (BubbleColour.red, BubbleColour.green),
    (BubbleColour.red, BubbleColour.brown),
    (BubbleColour.green, BubbleColour.brown),
    (BubbleColour.red, BubbleColour.black),
    (BubbleColour.green, BubbleColour.orange),
    (BubbleColour.blue, BubbleColour.purple),
    (BubbleColour.yellow, BubbleColour.orange),
    (BubbleColour.pink, BubbleColour.white),
  ];

  static bool areConfusable(BubbleColour a, BubbleColour b) => confusable
      .any((p) => (p.$1 == a && p.$2 == b) || (p.$1 == b && p.$2 == a));
}
