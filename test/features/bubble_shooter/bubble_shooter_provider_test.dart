import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bubble_shooter/models/bubble_shooter_models.dart';
import 'package:catrin_abi_bsl/features/bubble_shooter/providers/bubble_shooter_provider.dart';
import 'package:catrin_abi_bsl/features/bubble_shooter/widgets/bubble_board_painter.dart';
import 'package:catrin_abi_bsl/shared/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioService.sfxEnabled = false;
    AudioService.instructionsEnabled = false;
  });

  BubbleShooterProvider playing({int level = 1}) {
    final p = BubbleShooterProvider(random: Random(1))
      ..setBoardHeight(26)
      ..setLevel(level)
      ..prepareForIntro()
      ..startGame();
    return p;
  }

  /// Fires straight up from the cannon and runs frames until it lands.
  void fireStraightUp(BubbleShooterProvider p) {
    p.aimAt(p.cannonPosition - const Offset(0, 10));
    expect(p.fire(), isTrue);
    for (var i = 0; i < 300 && p.flying != null; i++) {
      p.tick(1 / 60);
    }
    expect(p.flying, isNull);
  }

  void settle(BubbleShooterProvider p) {
    for (var i = 0; i < 240; i++) {
      p.tick(1 / 60);
    }
  }

  test('levels use the requested colour combinations', () {
    const c = BubbleColour.values;
    final expected = [
      [c.byName('blue'), c.byName('red')],
      [c.byName('blue'), c.byName('white')],
      [c.byName('white'), c.byName('green')],
      [c.byName('green'), c.byName('purple')],
      [c.byName('purple'), c.byName('yellow')],
      [c.byName('yellow'), c.byName('pink')],
      [c.byName('pink'), c.byName('black')],
      [c.byName('black'), c.byName('brown')],
      [c.byName('brown'), c.byName('white')],
      [c.byName('white'), c.byName('orange')],
      [c.byName('orange'), c.byName('white'), c.byName('black')],
      [c.byName('green'), c.byName('white'), c.byName('black')],
      [c.byName('green'), c.byName('purple'), c.byName('pink')],
      [c.byName('red'), c.byName('purple'), c.byName('white')],
      [c.byName('blue'), c.byName('yellow'), c.byName('brown')],
      [c.byName('green'), c.byName('black'), c.byName('pink')],
      [c.byName('red'), c.byName('blue'), c.byName('yellow')],
      [c.byName('red'), c.byName('yellow'), c.byName('pink')],
      [c.byName('blue'), c.byName('orange'), c.byName('brown')],
      [c.byName('purple'), c.byName('orange'), c.byName('brown')],
      null, // Speed round
      null, // Hexagon speed round
      null, // Stripes speed round
    ];
    expect(
      BubbleShooterLevels.all
          .take(expected.length)
          .map((l) => l.isSpeedRound ? null : l.colours)
          .toList(),
      expected,
    );
    const speed = BubbleShooterLevels.speedRoundLevel;
    expect(speed, 21);
    expect(BubbleShooterLevels.getLevel(speed).isSpeedRound, isTrue);
    expect(BubbleShooterLevels.getLevel(speed).speedRoundSeconds, 60);
    const hexagons = BubbleShooterLevels.hexagonRoundLevel;
    expect(hexagons, 22);
    expect(BubbleShooterLevels.getLevel(hexagons).speedRoundSeconds, 60);
    expect(BubbleShooterLevels.getLevel(hexagons).speedRoundPattern,
        SpeedRoundPattern.hexagons);
  });

  test('levels 24 to 40 are generated four-colour patterns', () {
    final generated = BubbleShooterLevels.all
        .skip(BubbleShooterLevels.firstPatternLevel - 1)
        .toList();
    expect(BubbleShooterLevels.all.length, 40);
    expect(generated.map((l) => l.number),
        [for (var n = 24; n <= 40; n++) n]);
    // Every pattern appears, wide before fine.
    expect(generated.map((l) => l.pattern).toSet(),
        BubblePattern.values.toSet());
    final firstFine = generated.indexWhere((l) => l.finePattern);
    expect(generated.take(firstFine).every((l) => !l.finePattern), isTrue);
    expect(generated.skip(firstFine).every((l) => l.finePattern), isTrue);
    for (var i = 0; i < generated.length; i++) {
      final level = generated[i];
      expect(level.isSpeedRound, isFalse);
      expect(level.colours.toSet(), hasLength(4));
      if (i > 0) {
        expect(level.colours.toSet(), isNot(generated[i - 1].colours.toSet()),
            reason: 'level ${level.number} repeats the colours before it');
      }
    }
  });

  test('pattern clusters follow their pattern and leave no lone bubbles',
      () {
    for (final level
        in BubbleShooterLevels.all.where((l) => l.pattern != null)) {
      final p = playing(level: level.number);
      for (var r = 0; r < level.rows; r++) {
        for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++) {
          final cell = GridCell(r, c);
          final index = level.pattern!.colourIndex(cell,
              rows: level.rows,
              columns: BubbleShooterProvider.columns,
              fine: level.finePattern);
          expect(p.grid[cell], index == null ? null : level.colours[index],
              reason: 'level ${level.number} $cell');
        }
      }
      // Lone bubbles take two shots each — fine at the ceiling, where a
      // pattern gets cut off, but not lower down.
      final lone = p.grid.entries.where((e) =>
          e.key.row > 0 &&
          BubbleShooterProvider.neighbours(e.key)
              .every((n) => p.grid[n] != e.value));
      // Fine rings, hexagons and dots have a single bubble at each centre.
      final centred = {
        BubblePattern.rings,
        BubblePattern.hexagons,
        BubblePattern.dots,
      };
      if (!centred.contains(level.pattern) || !level.finePattern) {
        expect(lone.map((e) => e.key), isEmpty,
            reason: 'level ${level.number} ${level.pattern}');
      }
    }
  });

  group('hollow hexagons', () {
    final level = BubbleShooterLevels.getLevel(24);

    test('is level 24, with every bubble hanging from the ceiling', () {
      expect(level.pattern, BubblePattern.hollowHexagons);
      final p = playing(level: 24);
      expect(p.grid.values.toSet(), level.colours.toSet());
      final anchored = {...p.grid.keys.where((c) => c.row == 0)};
      final queue = [...anchored];
      while (queue.isNotEmpty) {
        for (final n in BubbleShooterProvider.neighbours(queue.removeLast())) {
          if (p.grid.containsKey(n) && anchored.add(n)) queue.add(n);
        }
      }
      expect(anchored, hasLength(p.grid.length));
    });

    test('a shot up the middle channel lands high, under a bridge', () {
      final p = playing(level: 24);
      final bottom = p.grid.keys.map((c) => c.row).reduce(max);
      fireStraightUp(p);
      // The first bridge is eight rows up; the shot stops just below it.
      expect(p.lastLanded!.row, bottom - 7);
    });

    test('a straight shot pops the bridge, dropping nothing', () {
      final p = playing(level: 24);
      final bottom = p.grid.keys.map((c) => c.row).reduce(max);
      final bridge = p.grid[GridCell(bottom - 8, 4)]!;
      p.debugSetBoard(Map.of(p.grid), bridge);
      final before = p.grid.length;
      fireStraightUp(p);
      settle(p);
      expect(before + 1 - p.grid.length, 4 + 1);
    });

    test('an angled shot up the channel pops a hexagon high up, dropping '
        'the one below it', () {
      final p = playing(level: 24);
      final bottom = p.grid.keys.map((c) => c.row).reduce(max);
      // The inner side of the left column's second hexagon, at its widest.
      final side = GridCell(bottom - 6, 3);
      p.debugSetBoard(Map.of(p.grid), p.grid[side]!);
      final before = p.grid.length;
      // Just clipping the side's channel edge: aiming any further left
      // hits the lower hexagon's side on the way up.
      p.aimAt(p.centreOf(side) + const Offset(1.6, 0));
      expect(p.fire(), isTrue);
      settle(p);
      // Popped: the second hexagon (8) plus the shot. Dropped: the bottom
      // hexagon below it (10).
      expect(before + 1 - p.grid.length, 8 + 1 + 10);
    });
  });

  test('every level builds a full cluster using all its colours', () {
    for (final level in BubbleShooterLevels.all
        .where((l) => !l.isSpeedRound && l.pattern?.hasGaps != true)) {
      final p = playing(level: level.number);
      final expectedCount = List.generate(
        level.rows,
        BubbleShooterProvider.rowLength,
      ).reduce((a, b) => a + b);
      expect(p.grid.length, expectedCount, reason: 'level ${level.number}');
      expect(p.grid.values.toSet(), level.colours.toSet());
      expect(level.colours, contains(p.loadedColour));
      expect(level.colours, contains(p.nextColour));
    }
  });

  test('level 1 boards need three shots and no shot clears too much', () {
    final level = BubbleShooterLevels.getLevel(1);
    for (var seed = 0; seed < 30; seed++) {
      final p = BubbleShooterProvider(random: Random(seed))
        ..setBoardHeight(26)
        ..setLevel(1)
        ..prepareForIntro();
      expect(
        BubbleShooterProvider.clearableWithin(
          p.grid,
          level.minShotsToClear! - 1,
        ),
        isFalse,
        reason: 'seed $seed',
      );
      expect(
        BubbleShooterProvider.bestSingleShotClear(p.grid),
        lessThanOrEqualTo(level.maxClearPerShot!),
        reason: 'seed $seed',
      );
      // Ceiling alternates colours in pairs.
      final ceiling = [
        for (var c = 0; c < BubbleShooterProvider.columns; c++)
          p.grid[GridCell(0, c)],
      ];
      for (var c = 0; c < ceiling.length; c++) {
        expect(ceiling[c] == ceiling[c ^ 1], isTrue, reason: '$ceiling');
        if (c + 2 < ceiling.length) {
          expect(ceiling[c] == ceiling[c + 2], isFalse, reason: '$ceiling');
        }
      }
    }
  });

  testWidgets('cannon never serves one colour more than three times in a row', (
    tester,
  ) async {
    // A two-, three- and four-colour level.
    for (final level in [1, 12, 18]) {
      final p = playing(level: level);
      final fired = <BubbleColour>[];
      for (var shot = 0; shot < 40 && p.canFire; shot++) {
        // Only meaningful while another colour could have been served.
        final choices = p.currentLevel.colours
            .where(p.grid.containsValue)
            .length;
        if (choices < 2) break;
        fired.add(p.loadedColour!);
        fireStraightUp(p);
        settle(p);
      }
      var run = 0;
      for (var i = 0; i < fired.length; i++) {
        run = i > 0 && fired[i] == fired[i - 1] ? run + 1 : 1;
        expect(
          run,
          lessThanOrEqualTo(BubbleShooterProvider.maxSameColourInARow),
          reason: 'level $level: $fired',
        );
      }
      expect(fired.length, greaterThan(5), reason: 'level $level');
    }
  });

  test('clearableWithin counts drops and lone bubbles', () {
    const b = BubbleColour.blue, r = BubbleColour.red;
    // A blue ceiling pair holding a red bubble below: one shot pops the
    // blues and drops the red.
    final hanging = {
      const GridCell(0, 0): b,
      const GridCell(0, 1): b,
      const GridCell(1, 0): r,
    };
    expect(BubbleShooterProvider.clearableWithin(hanging, 1), isTrue);
    // Two lone ceiling bubbles: two shots each.
    final lone = {const GridCell(0, 0): b, const GridCell(0, 2): r};
    expect(BubbleShooterProvider.clearableWithin(lone, 3), isFalse);
    expect(BubbleShooterProvider.clearableWithin(lone, 4), isTrue);
  });

  test('no level has fewer bubbles than the level before', () {
    int bubbles(BubbleShooterLevel l) => List.generate(
      l.rows,
      BubbleShooterProvider.rowLength,
    ).reduce((a, b) => a + b);
    // The speed round has no fixed size, so it's left out.
    // Patterns with gaps are left out too: they're thinner on purpose.
    final counts = BubbleShooterLevels.all
        .where((l) => !l.isSpeedRound && l.pattern?.hasGaps != true)
        .map(bubbles)
        .toList();
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThanOrEqualTo(counts[i - 1]), reason: '$counts');
    }
  });

  test('four-colour levels avoid colour-blind confusable pairs', () {
    const confusable = [
      {BubbleColour.red, BubbleColour.green},
      {BubbleColour.red, BubbleColour.brown},
      {BubbleColour.green, BubbleColour.brown},
      {BubbleColour.red, BubbleColour.black},
      {BubbleColour.green, BubbleColour.orange},
      {BubbleColour.blue, BubbleColour.purple},
      {BubbleColour.yellow, BubbleColour.orange},
      {BubbleColour.pink, BubbleColour.white},
    ];
    for (final level in BubbleShooterLevels.all
        .skip(BubbleShooterLevels.speedRoundLevel)
        .where((l) => !l.isSpeedRound)) {
      expect(level.colours.length, 4);
      for (final pair in confusable) {
        expect(
          level.colours.toSet().containsAll(pair),
          isFalse,
          reason: 'level ${level.number} uses $pair',
        );
      }
    }
  });

  group('speed round', () {
    /// Checks the board is a stack of diamonds: every row is a centred,
    /// unbroken run one bubble wider or narrower than the row below, widest
    /// at [BubbleShooterProvider.diamondMaxWidth] and narrowest at a 1- or
    /// 2-bubble tip. Each
    /// row splits into single-colour left/right halves, and neighbouring
    /// rows either share a diamond's colours or share none at all.
    void expectDiamonds(BubbleShooterProvider p) {
      final byRow = <int, Map<int, BubbleColour>>{};
      p.grid.forEach((cell, colour) => (byRow[cell.row] ??= {})[cell.col] = colour);
      final rows = byRow.keys.toList()..sort();
      expect(rows.last - rows.first + 1, rows.length, reason: 'no gaps');

      int? previousWidth;
      Set<BubbleColour>? previous;
      var sawWidest = false;
      for (final r in rows) {
        final cols = byRow[r]!.keys.toList()..sort();
        final width = cols.length;
        expect(cols.last - cols.first + 1, width, reason: 'row $r unbroken');
        expect(cols.first, (BubbleShooterProvider.rowLength(r) - width) ~/ 2,
            reason: 'row $r centred');
        expect(width,
            lessThanOrEqualTo(BubbleShooterProvider.diamondMaxWidth));
        if (width == BubbleShooterProvider.diamondMaxWidth) sawWidest = true;

        final left = {
          for (var i = 0; i < width; i++)
            if (i * 2 < width) byRow[r]![cols.first + i]!,
        };
        final right = {
          for (var i = 0; i < width; i++)
            if (i * 2 >= width) byRow[r]![cols.first + i]!,
        };
        expect(left, hasLength(1), reason: 'row $r left half');
        if (width > 1) {
          expect(right, hasLength(1), reason: 'row $r right half');
          expect(left.first, isNot(right.first), reason: 'row $r');
        }
        final colours = {...left, ...right};

        if (previousWidth != null) {
          expect((width - previousWidth).abs(), 1, reason: 'row $r width');
          final sameDiamond = colours.containsAll(previous!) ||
              previous.containsAll(colours);
          expect(
            sameDiamond || colours.intersection(previous).isEmpty,
            isTrue,
            reason: 'row $r shares only some colours with the row above',
          );
          if (!sameDiamond) {
            expect(max(width, previousWidth), 2, reason: 'row $r meets at a tip');
          }
        }
        previousWidth = width;
        previous = colours;
      }
      expect(sawWidest, isTrue);
    }

    /// The bottom diamond's widest row.
    int lowestWidestRow(BubbleShooterProvider p) => p.grid.keys
        .map((c) => c.row)
        .toSet()
        .where((r) =>
            p.grid.keys.where((c) => c.row == r).length ==
            BubbleShooterProvider.diamondMaxWidth)
        .reduce(max);

    test('builds a stack of half-and-half diamonds', () {
      for (var seed = 0; seed < 20; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.speedRoundLevel)
          ..prepareForIntro();
        expectDiamonds(p);
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        expect(p.grid.keys.where((c) => c.row == bottom).length,
            lessThanOrEqualTo(2),
            reason: 'starts at a diamond tip');
      }
    });

    test('uses hard colour pairs sometimes, but mostly safe ones', () {
      final hard = SpeedRoundRows.hard.map((p) => {p.$1, p.$2}).toList();
      var hardRows = 0, rows = 0;
      for (var seed = 0; seed < 20; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.speedRoundLevel)
          ..prepareForIntro();
        final byRow = <int, Set<BubbleColour>>{};
        p.grid.forEach((cell, colour) => (byRow[cell.row] ??= {}).add(colour));
        // Single-bubble tips show only one colour of their pair.
        for (final colours in byRow.values.where((c) => c.length == 2)) {
          rows++;
          if (hard.any((h) => h.containsAll(colours))) hardRows++;
        }
      }
      expect(hardRows, greaterThan(0));
      expect(hardRows, lessThan(rows / 2));
    });

    test('popping half a diamond clears nothing beyond that diamond', () {
      for (var seed = 0; seed < 10; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.speedRoundLevel)
          ..prepareForIntro()
          ..startGame();
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final tip = p.grid.keys.where((c) => c.row == bottom).reduce(
            (a, b) => a.col < b.col ? a : b);
        final pair = {p.grid[tip]!};
        // The bottom diamond: bubbles joined to its tip through its colours
        // (the diamond above shares none of them).
        final widest = lowestWidestRow(p);
        pair.addAll(p.grid.entries
            .where((e) => e.key.row == widest)
            .map((e) => e.value));
        final diamond = <GridCell>{tip};
        final queue = [tip];
        while (queue.isNotEmpty) {
          for (final n in BubbleShooterProvider.neighbours(queue.removeLast())) {
            if (pair.contains(p.grid[n]) && diamond.add(n)) queue.add(n);
          }
        }
        final leftHalf =
            diamond.where((c) => p.grid[c] == p.grid[tip]).length;

        p.debugSetBoard(Map.of(p.grid), p.grid[tip]!);
        fireStraightUp(p);

        expect(p.score,
            greaterThanOrEqualTo(
                (leftHalf + 1) * BubbleShooterProvider.popPoints),
            reason: 'seed $seed: the half-diamond + the shot pop');
        expect(
            p.score,
            lessThanOrEqualTo(
                (diamond.length + 1) * BubbleShooterProvider.dropPoints),
            reason: 'seed $seed: nothing above the diamond');
      }
    });

    test('rows never run out', () {
      final p = playing(level: BubbleShooterLevels.speedRoundLevel);
      for (var round = 0; round < 30; round++) {
        // Clear the bottom two rows, as if the player popped them.
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final kept = Map.of(p.grid)
          ..removeWhere((cell, _) => cell.row >= bottom - 1);
        p.debugSetBoard(kept, kept.values.first);
        expect(p.grid.length, greaterThan(30));
        expect(p.gridTop, lessThan(-2 * BubbleShooterProvider.rowHeight));
      }
      expectDiamonds(p);
    });

    test('only loads colours the cannon can reach', () {
      for (var seed = 0; seed < 10; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.speedRoundLevel)
          ..prepareForIntro();
        // Only bubbles on screen count — the diamonds' side channels run
        // up past the top of the board.
        final reachable = {
          for (final e in p.grid.entries)
            if (p.centreOf(e.key).dy >= 0) e.value,
        };
        expect(reachable, contains(p.loadedColour));
        expect(reachable, contains(p.nextColour));
      }
    });

    test('ends after 60 seconds and stops firing', () {
      final p = playing(level: BubbleShooterLevels.speedRoundLevel);
      expect(p.timeRemainingSeconds, 60);
      for (var i = 0; i < 59 * 60; i++) {
        p.tick(1 / 60);
      }
      expect(p.gameOver, isFalse);
      expect(p.canFire, isTrue);
      for (var i = 0; i < 2 * 60; i++) {
        p.tick(1 / 60);
      }
      expect(p.timeRemainingSeconds, 0);
      expect(p.gameOver, isTrue);
      expect(p.canFire, isFalse);
    });
  });

  group('hexagon speed round', () {
    /// Rows bottom-up, each its colours left to right, after checking every
    /// row is a centred, unbroken run.
    List<List<BubbleColour>> rowsBottomUp(BubbleShooterProvider p) {
      final byRow = <int, Map<int, BubbleColour>>{};
      p.grid.forEach(
          (cell, colour) => (byRow[cell.row] ??= {})[cell.col] = colour);
      final rows = byRow.keys.toList()..sort((a, b) => b.compareTo(a));
      expect(rows.first - rows.last + 1, rows.length, reason: 'no gaps');
      return [
        for (final r in rows)
          () {
            final cols = byRow[r]!.keys.toList()..sort();
            expect(cols.last - cols.first + 1, cols.length,
                reason: 'row $r unbroken');
            expect(cols.first,
                (BubbleShooterProvider.rowLength(r) - cols.length) ~/ 2,
                reason: 'row $r centred');
            return [for (final c in cols) byRow[r]![c]!];
          }(),
      ];
    }

    /// One hexagon, bottom-up, then the neck above it, as (left, middle,
    /// right) bubble counts.
    const hexagonAndNeck = [
      (1, 0, 2),
      (2, 0, 2),
      (2, 0, 3),
      (2, 2, 2),
      (2, 3, 2),
      (2, 2, 2),
      (2, 0, 3),
      (2, 0, 2),
      (1, 0, 2),
      (0, 2, 0),
    ];

    /// Checks [rows] (bottom-up, starting at a hexagon's tip) are a stack of
    /// hexagons, each coloured from a trio and different from the one
    /// below, joined by white necks. Returns each hexagon's colours.
    List<Set<BubbleColour>> expectHexagons(List<List<BubbleColour>> rows) {
      final trios = SpeedRoundHexagons.trios
          .map((t) => {t.$1, t.$2, t.$3})
          .toList();
      final hexagons = <Set<BubbleColour>>[];
      for (var top = 0; top < rows.length; top += hexagonAndNeck.length) {
        // Colours from the widest row, which has all three.
        final widest = rows.length > top + 4 ? rows[top + 4] : null;
        if (widest == null) break;
        final left = widest.first, middle = widest[3], right = widest.last;
        final colours = {left, middle, right};
        expect(colours, hasLength(3), reason: 'hexagon at row $top');
        expect(trios.any((t) => t.containsAll(colours)), isTrue,
            reason: 'hexagon at row $top uses a trio: $colours');
        if (hexagons.isNotEmpty) {
          expect(colours, isNot(hexagons.last),
              reason: 'hexagon at row $top repeats the one below');
        }
        hexagons.add(colours);
        for (var i = top;
            i < min(rows.length, top + hexagonAndNeck.length);
            i++) {
          final (l, m, r) = hexagonAndNeck[i - top];
          final expected = i - top == hexagonAndNeck.length - 1
              ? List.filled(m, SpeedRoundHexagons.neck)
              : [
                  ...List.filled(l, left),
                  ...List.filled(m, middle),
                  ...List.filled(r, right),
                ];
          expect(rows[i], expected, reason: 'row $i from the bottom');
        }
      }
      return hexagons;
    }

    test('builds a stack of hexagons joined by white necks', () {
      for (var seed = 0; seed < 10; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.hexagonRoundLevel)
          ..prepareForIntro();
        expect(expectHexagons(rowsBottomUp(p)), isNotEmpty);
      }
    });

    test('rows never run out, and every trio comes round', () {
      final p = playing(level: BubbleShooterLevels.hexagonRoundLevel);
      final seen = [expectHexagons(rowsBottomUp(p)).first];
      for (var round = 0; round < 60; round++) {
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final kept = Map.of(p.grid)
          ..removeWhere((cell, _) => cell.row >= bottom - 1);
        p.debugSetBoard(kept, kept.values.first);
        expect(p.grid.length, greaterThan(30));
        // Every 10 rows cleared the bottom is a hexagon's tip again.
        if (round % 5 == 4) {
          final hexagons = expectHexagons(rowsBottomUp(p));
          seen.add(hexagons.first);
        }
      }
      // 13 hexagons seen — more than one shuffle of the trios.
      for (final t in SpeedRoundHexagons.trios) {
        expect(seen.any((s) => s.containsAll({t.$1, t.$2, t.$3})), isTrue,
            reason: '$t never used');
      }
    });

    test('popping half a hexagon clears nothing beyond that hexagon', () {
      for (var seed = 0; seed < 10; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.hexagonRoundLevel)
          ..prepareForIntro()
          ..startGame();
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final tip = p.grid.keys
            .where((c) => c.row == bottom)
            .reduce((a, b) => a.col < b.col ? a : b);
        final left = p.grid[tip]!;
        final halfHexagon = p.grid.entries
            .where((e) => e.value == left && e.key.row > bottom - 9)
            .length;
        p.debugSetBoard(Map.of(p.grid), left);
        fireStraightUp(p);
        // Popped only — no drops, which score more.
        expect(p.score, (halfHexagon + 1) * BubbleShooterProvider.popPoints,
            reason: 'seed $seed');
      }
    });
  });

  group('stripes speed round', () {
    const sectionRows = BubbleShooterProvider.stripeSectionRows;

    /// Checks the board, from its bottom row up, is made of full sections
    /// of diagonal stripes as described on [SpeedRoundPattern.stripes].
    /// Returns how many whole sections it checked.
    int expectStripes(BubbleShooterProvider p) {
      final grid = p.grid;
      final bottom = grid.keys.map((c) => c.row).reduce(max);
      final top = grid.keys.map((c) => c.row).reduce(min);
      for (var r = top; r <= bottom; r++) {
        for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++) {
          expect(grid.containsKey(GridCell(r, c)), isTrue,
              reason: 'row $r full');
        }
      }

      int sectionOf(GridCell cell) => (bottom - cell.row) ~/ sectionRows;
      final sections = (bottom - top + 1) ~/ sectionRows;
      Set<BubbleColour>? previousColours;
      bool? previousLeansRight;
      for (var s = 0; s < sections; s++) {
        final rows = [
          for (var k = 0; k < sectionRows; k++) bottom - s * sectionRows - k,
        ];
        final colours = {
          for (final r in rows)
            for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++)
              grid[GridCell(r, c)]!,
        };
        expect(colours, hasLength(SpeedRoundStripes.coloursPerSection),
            reason: 'section $s');
        if (previousColours != null) {
          expect(colours.intersection(previousColours), isEmpty,
              reason: 'section $s shares colours with the one below');
        }
        previousColours = colours;

        // Stripes 2 wide along each row, neighbours never confusable.
        for (final r in rows) {
          final row = [
            for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++)
              grid[GridCell(r, c)]!,
          ];
          final runs = <(BubbleColour, int)>[];
          for (final colour in row) {
            if (runs.isNotEmpty && runs.last.$1 == colour) {
              runs.last = (colour, runs.last.$2 + 1);
            } else {
              runs.add((colour, 1));
            }
          }
          for (var i = 0; i < runs.length; i++) {
            final edge = i == 0 || i == runs.length - 1;
            expect(runs[i].$2, edge ? lessThanOrEqualTo(2) : 2,
                reason: 'row $r stripe $i width: $row');
            if (i > 0) {
              expect(
                  SpeedRoundStripes.areConfusable(
                      runs[i - 1].$1, runs[i].$1),
                  isFalse,
                  reason: 'row $r stripes $i-1/$i: $row');
            }
          }
        }

        // Every bubble below the section's top row continues its stripe up
        // one diagonal — the same one for the whole section.
        bool continuesUp(GridCell cell, bool right) {
          final up = BubbleShooterProvider.neighbours(cell)[right ? 3 : 2];
          return !grid.containsKey(up) || grid[up] == grid[cell];
        }

        final lower = [
          for (final r in rows.take(sectionRows - 1))
            for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++)
              GridCell(r, c),
        ];
        final leansRight = lower.every((cell) => continuesUp(cell, true));
        expect(leansRight || lower.every((cell) => continuesUp(cell, false)),
            isTrue,
            reason: 'section $s stripes lean one way');
        if (previousLeansRight != null) {
          expect(leansRight, isNot(previousLeansRight),
              reason: 'section $s leans the same way as the one below');
        }
        previousLeansRight = leansRight;
      }

      // No same-colour group reaches into another section.
      for (final start in grid.keys) {
        for (final n in BubbleShooterProvider.neighbours(start)) {
          if (grid[n] == grid[start]) {
            expect(sectionOf(n), sectionOf(start),
                reason: '$start and $n join across sections');
          }
        }
      }
      return sections;
    }

    test('builds alternating sections of diagonal stripes', () {
      for (var seed = 0; seed < 10; seed++) {
        final p = BubbleShooterProvider(random: Random(seed))
          ..setBoardHeight(26)
          ..setLevel(BubbleShooterLevels.stripesRoundLevel)
          ..prepareForIntro();
        expect(expectStripes(p), greaterThanOrEqualTo(2),
            reason: 'seed $seed');
        // The first section leans right.
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final cell = GridCell(bottom, 4);
        expect(p.grid[BubbleShooterProvider.neighbours(cell)[3]],
            p.grid[cell]);
      }
    });

    test('rows never run out', () {
      final p = playing(level: BubbleShooterLevels.stripesRoundLevel);
      for (var round = 0; round < 3 * sectionRows; round++) {
        // Clear the bottom row, as if the player popped it.
        final bottom = p.grid.keys.map((c) => c.row).reduce(max);
        final kept = Map.of(p.grid)
          ..removeWhere((cell, _) => cell.row == bottom);
        p.debugSetBoard(kept, kept.values.first);
        expect(p.grid.length, greaterThan(30));
      }
      // 21 rows cleared — whole sections, so the bottom starts one again.
      expectStripes(p);
    });
  });

  test('sign edge colour hint only before level 11', () {
    expect(BubbleShooterLevels.noColourHintLevel, 11);
    for (final level in BubbleShooterLevels.all) {
      expect(
        level.showsColourHint,
        level.number < BubbleShooterLevels.noColourHintLevel,
        reason: 'level ${level.number}',
      );
    }
  });

  group('new colours', () {
    test('are introduced from level 4, once each', () {
      const c = BubbleColour.values;
      final introduced = {
        for (final l in BubbleShooterLevels.all)
          l.number: BubbleShooterLevels.introducedColours(l),
      };
      expect(introduced, {
        1: <BubbleColour>[],
        2: <BubbleColour>[],
        3: <BubbleColour>[],
        4: [c.byName('purple')],
        5: [c.byName('yellow')],
        6: [c.byName('pink')],
        7: [c.byName('black')],
        8: [c.byName('brown')],
        9: <BubbleColour>[],
        10: [c.byName('orange')],
        11: <BubbleColour>[],
        12: <BubbleColour>[],
        13: <BubbleColour>[],
        14: <BubbleColour>[],
        15: <BubbleColour>[],
        16: <BubbleColour>[],
        17: <BubbleColour>[],
        18: <BubbleColour>[],
        19: <BubbleColour>[],
        20: <BubbleColour>[],
        21: <BubbleColour>[],
        22: <BubbleColour>[],
        23: <BubbleColour>[],
        for (var n = 24; n <= 40; n++) n: <BubbleColour>[],
      });
    });

    test('fill solid bottom rows and are loaded first', () {
      for (final level in BubbleShooterLevels.all) {
        final introduced = BubbleShooterLevels.introducedColours(level);
        if (introduced.isEmpty) continue;
        for (var seed = 0; seed < 5; seed++) {
          final p = BubbleShooterProvider(random: Random(seed))
            ..setBoardHeight(26)
            ..setLevel(level.number)
            ..prepareForIntro();
          for (var i = 0; i < introduced.length; i++) {
            final row = level.rows - 1 - i;
            final colours = {
              for (
                var col = 0;
                col < BubbleShooterProvider.rowLength(row);
                col++
              )
                p.grid[GridCell(row, col)],
            };
            expect(colours, {
              introduced[i],
            }, reason: 'level ${level.number} row $row');
          }
          expect(p.loadedColour, introduced.first);
          if (introduced.length > 1) {
            expect(p.nextColour, introduced[1]);
          }
        }
      }
    });

    test('the first shot pops the whole new-colour row', () {
      final p = playing(level: 5);
      final level = p.currentLevel;
      final bottom = level.rows - 1;
      final rowSize = BubbleShooterProvider.rowLength(bottom);
      fireStraightUp(p);
      expect(p.grid.keys.where((c) => c.row == bottom), isEmpty);
      expect(
        p.score,
        greaterThanOrEqualTo((rowSize + 1) * BubbleShooterProvider.popPoints),
      );
    });
  });

  test('hex neighbours are symmetric', () {
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < BubbleShooterProvider.rowLength(r); c++) {
        final cell = GridCell(r, c);
        for (final n in BubbleShooterProvider.neighbours(cell)) {
          expect(BubbleShooterProvider.neighbours(n), contains(cell));
        }
      }
    }
  });

  test('three matching bubbles pop and clearing the board ends the level', () {
    final p = playing();
    p.debugSetBoard({
      const GridCell(0, 3): BubbleColour.red,
      const GridCell(0, 4): BubbleColour.red,
    }, BubbleColour.red);

    fireStraightUp(p);

    expect(p.grid, isEmpty);
    expect(p.score, 3 * BubbleShooterProvider.popPoints);
    settle(p);
    expect(p.gameOver, isTrue);
  });

  test('bubbles cut off from the ceiling fall', () {
    final p = playing();
    p.debugSetBoard({
      const GridCell(0, 4): BubbleColour.red,
      const GridCell(0, 5): BubbleColour.red,
      // Hangs only from (0, 5)...
      const GridCell(1, 5): BubbleColour.blue,
      // ...and this only from (1, 5).
      const GridCell(2, 6): BubbleColour.blue,
      // Anchored to the ceiling on its own — must stay.
      const GridCell(0, 0): BubbleColour.blue,
    }, BubbleColour.red);

    fireStraightUp(p);

    expect(p.grid.keys, [const GridCell(0, 0)]);
    expect(
      p.score,
      3 * BubbleShooterProvider.popPoints +
          2 * BubbleShooterProvider.dropPoints,
    );
    expect(p.falling.length, 2);
    // Only blue is left, so only blue gets loaded.
    expect(p.loadedColour, BubbleColour.blue);
    expect(p.nextColour, BubbleColour.blue);
  });

  test('a non-matching shot sticks without popping', () {
    final p = playing();
    p.debugSetBoard({
      const GridCell(0, 4): BubbleColour.red,
      const GridCell(0, 5): BubbleColour.red,
    }, BubbleColour.blue);

    fireStraightUp(p);

    expect(p.grid[const GridCell(1, 4)], BubbleColour.blue);
    expect(p.grid.length, 3);
    expect(p.score, 0);
  });

  test('shots bounce off the side walls', () {
    final p = playing();
    p.debugSetBoard({
      for (var c = 0; c < BubbleShooterProvider.columns; c++)
        GridCell(0, c): BubbleColour.red,
    }, BubbleColour.blue);

    // Aim hard left so the shot must bounce before reaching the cluster.
    p.aimAt(p.cannonPosition + const Offset(-20, -4));
    p.fire();
    var minX = double.infinity;
    var bounced = false;
    double? lastDx;
    for (var i = 0; i < 300 && p.flying != null; i++) {
      p.tick(1 / 60);
      final shot = p.flying;
      if (shot == null) break;
      minX = min(minX, shot.position.dx);
      if (lastDx != null && lastDx < 0 && shot.velocity.dx > 0) {
        bounced = true;
      }
      lastDx = shot.velocity.dx;
    }
    expect(bounced, isTrue);
    expect(minX, greaterThanOrEqualTo(1));
    expect(p.grid.length, BubbleShooterProvider.columns + 1);
  });

  test('cluster lowers as it shrinks', () {
    final p = playing(level: 7);
    final startTop = p.gridTop;
    // Remove everything below row 2.
    final kept = Map.of(p.grid)..removeWhere((cell, _) => cell.row > 2);
    p.debugSetBoard(kept, kept.values.first);
    expect(p.gridTop, greaterThan(startTop));
  });

  test('shots leave from the barrel tip and the cluster clears the cannon', () {
    for (final height in [18.4, 26.0, 34.0]) {
      final p = playing(level: 7)..setBoardHeight(height);
      settle(p); // Mid-game height changes ease the cluster into place.
      p.aimAt(p.cannonPosition + const Offset(-10, -3));
      final muzzle = p.muzzlePosition(p.aimAngle);
      p.fire();
      expect(p.flying!.position, muzzle);
      final lowest = p.grid.keys.map((c) => c.row).reduce(max);
      final lowestBottom =
          p.gridTop + 2 + lowest * BubbleShooterProvider.rowHeight;
      final cannonTop =
          p.cannonPosition.dy - BubbleShooterProvider.muzzleDistance - 1;
      expect(lowestBottom, lessThan(cannonTop), reason: 'board height $height');
    }
  });

  test('cannot fire below the horizontal clamp', () {
    final p = playing();
    p.aimAt(p.cannonPosition + const Offset(-10, 5));
    expect(p.aimAngle, -BubbleShooterProvider.maxAimAngle);
  });

  testWidgets('board painter draws every level mid-shot without errors', (
    tester,
  ) async {
    for (final level in BubbleShooterLevels.all) {
      final p = playing(level: level.number);
      p.aimAt(p.cannonPosition + const Offset(-6, -10));
      await tester.pumpWidget(
        SizedBox(
          width: 360,
          height: 585,
          child: CustomPaint(
            painter: BubbleBoardPainter(provider: p, scale: 360 / 16),
            foregroundPainter: CannonBarrelPainter(
              provider: p,
              scale: 360 / 16,
            ),
          ),
        ),
      );
      p.fire();
      for (var i = 0; i < 20; i++) {
        p.tick(1 / 60);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    }
  });
}
