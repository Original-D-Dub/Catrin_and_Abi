import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/bubble_shooter_models.dart';

/// Game state and physics for the Bubble Shooter game.
///
/// Everything is measured in "bubble units": a bubble's radius is 1, so the
/// board is [columns] × 2 = 16 units wide. The screen scales units to pixels
/// and tells the provider how tall the board is via [setBoardHeight].
///
/// Layout is a hex grid hanging from a ceiling at [gridTop]: even rows hold
/// [columns] bubbles, odd rows are shifted right by one radius and hold one
/// fewer. As bubbles are cleared the whole cluster (ceiling included) slides
/// down so its lowest bubble stays near [_targetLineFraction] of the board,
/// revealing rows that started above the top of the screen.
///
/// Per-frame motion notifies [frame] (repaints the board only); game events
/// (score, colour change, level end) notify the provider's own listeners.
class BubbleShooterProvider extends ChangeNotifier {
  BubbleShooterProvider({this.locale = 'en', Random? random})
      : _random = random ?? Random();

  /// UI language ('en' or 'cy').
  final String locale;

  final Random _random;

  // ─────────────────────────────────────────
  // Geometry constants (bubble units)
  // ─────────────────────────────────────────

  /// Bubbles in an even row.
  static const int columns = 10;

  /// Board width in bubble units.
  static const double boardWidth = columns * 2.0;

  /// Vertical distance between row centres in a packed hex grid.
  static final double rowHeight = sqrt(3);

  /// Distance between centres at which a flying bubble sticks. A little under
  /// a full diameter so shots can slip through gaps that look open.
  static const double _stickDistance = 1.75;

  /// Shot speed, in bubble units per second.
  static const double _shotSpeed = 30;

  /// Largest single movement step, so fast shots can't tunnel through.
  static const double _maxStep = 0.25;

  /// Aim is clamped to this far either side of straight up (radians), so
  /// children can't fire flat along the floor.
  static const double maxAimAngle = 75 * pi / 180;

  /// Fraction of the board height the lowest bubble's bottom edge settles at.
  static const double _targetLineFraction = 0.5;

  /// Radius of the cannon's round body, which holds the BSL sign.
  static const double cannonRadius = 3.6;

  /// Size of the BSL sign shown, centred, in the cannon's round body.
  static const double cannonSignWidth = 5.0;
  static const double cannonSignHeight = 4.8;

  /// How far above the board's bottom edge the cannon's centre sits — set
  /// so the sign's bottom edge lines up with the board's bottom edge. The
  /// rest of the round body hangs below and is clipped by the board frame.
  static const double cannonOffsetFromBottom = cannonSignHeight / 2;

  /// Distance from the cannon's centre to the tip of the barrel, where a
  /// fired bubble first appears.
  static const double muzzleDistance = cannonRadius + 2.0;

  /// Minimum gap kept between the cluster and the top of the cannon's
  /// reach, so short (landscape) boards don't bury the barrel.
  static const double _cannonClearance = 2.0;

  /// Gravity for falling bubbles (units/s²).
  static const double _gravity = 60;

  /// Points per popped / dropped bubble.
  static const int popPoints = 10;
  static const int dropPoints = 20;

  /// Most clusters [_buildCluster] generates while looking for one that
  /// meets its level's shot limits. On level 1 about a third of clusters
  /// qualify, so missing in 40 tries is vanishingly rare.
  static const int _maxClusterAttempts = 40;

  /// Speed rounds keep at least this many rows hidden above the board top,
  /// topping up from the top as the cluster lowers.
  static const int _speedRowsAboveScreen = 3;

  /// Width, in bubbles, of a speed-round diamond's widest row. Odd, so it
  /// fits centred in the shorter (odd) rows.
  static const int diamondMaxWidth = 7;

  /// Widths, in bubbles, of a hexagon speed round's hexagons at their
  /// widest and narrowest rows. Odd, so the tips fit centred in the
  /// shorter (odd) rows, and the widest row has room for a centred middle
  /// hexagon three bubbles wide.
  static const int hexagonMaxWidth = 7;
  static const int hexagonMinWidth = 3;

  /// Width of the neck joining two hexagons — even, as it sits in an even
  /// row.
  static const int hexagonNeckWidth = 2;

  /// Height, in rows, of each section of a stripes speed round.
  static const int stripeSectionRows = 7;

  /// Width of each diagonal stripe along a row, in bubbles.
  static const int stripeWidth = 2;

  // ─────────────────────────────────────────
  // State
  // ─────────────────────────────────────────

  /// Notified every frame something moves, for the board painter.
  final _FrameNotifier _frame = _FrameNotifier();
  Listenable get frame => _frame;

  BubbleShooterLevel _level = BubbleShooterLevels.all.first;
  BubbleShooterLevel get currentLevel => _level;
  List<BubbleShooterLevel> get levels => BubbleShooterLevels.all;

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _gameOver = false;
  bool get gameOver => _gameOver;

  int _score = 0;
  int get score => _score;

  int _shotsFired = 0;
  int get shotsFired => _shotsFired;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  final Map<GridCell, BubbleColour> _grid = {};
  Map<GridCell, BubbleColour> get grid => UnmodifiableMapView(_grid);

  /// Bubble count when the level started, for the progress display.
  int _startingBubbleCount = 0;
  int get startingBubbleCount => _startingBubbleCount;

  double _boardHeight = 26;
  double get boardHeight => _boardHeight;

  /// Current (animated) y of the ceiling the cluster hangs from.
  double _gridTop = 0;
  double get gridTop => _gridTop;

  BubbleColour? _loaded;
  BubbleColour? get loadedColour => _loaded;

  BubbleColour? _next;
  BubbleColour? get nextColour => _next;

  /// Most times in a row the cannon serves the same colour, unless it's
  /// the only colour left that can be hit.
  static const int maxSameColourInARow = 3;

  /// Colour of the last bubble fired, and how many in a row it's been.
  BubbleColour? _lastFired;
  int _lastFiredRun = 0;

  FlyingBubble? _flying;
  FlyingBubble? get flying => _flying;

  final List<FallingBubble> _falling = [];
  List<FallingBubble> get falling => _falling;

  final List<PoppingBubble> _popping = [];
  List<PoppingBubble> get popping => _popping;

  final List<ScorePopup> _popups = [];
  List<ScorePopup> get popups => _popups;

  /// Current aim angle from vertical (radians, negative = left), or null
  /// while the player isn't aiming.
  double? _aimAngle;
  double? get aimAngle => _aimAngle;

  /// Angle the cannon barrel points at — keeps the last aim after firing.
  double _barrelAngle = 0;
  double get barrelAngle => _barrelAngle;

  /// Seconds since the last bubble attached, for the "landed" wobble.
  double _sinceLanding = 10;
  double get sinceLanding => _sinceLanding;
  GridCell? _lastLanded;
  GridCell? get lastLanded => _lastLanded;

  /// Seconds left in a speed round.
  double _timeRemaining = 0;
  int get timeRemainingSeconds => _timeRemaining.ceil();

  /// Whether a speed round's clock has run out.
  bool _timeUp = false;

  bool get isSpeedRound => _level.isSpeedRound;

  /// Called once with the final score when the level is cleared.
  void Function(int score)? onLevelComplete;

  // ─────────────────────────────────────────
  // Geometry helpers
  // ─────────────────────────────────────────

  /// Number of cells in [row].
  static int rowLength(int row) => row.isOdd ? columns - 1 : columns;

  /// Centre of [cell] given the ceiling at [top].
  static Offset cellCentre(GridCell cell, double top) => Offset(
        1.0 + cell.col * 2.0 + (cell.row.isOdd ? 1.0 : 0.0),
        top + 1.0 + cell.row * rowHeight,
      );

  /// Centre of [cell] at the current [gridTop].
  Offset centreOf(GridCell cell) => cellCentre(cell, _gridTop);

  /// Centre of the cannon's round body (the pivot the barrel turns on).
  Offset get cannonPosition =>
      Offset(boardWidth / 2, _boardHeight - cannonOffsetFromBottom);

  /// Where a fired bubble appears, at the tip of the barrel pointing at
  /// [angle] (defaults to the barrel's current angle).
  Offset muzzlePosition([double? angle]) {
    final a = angle ?? _barrelAngle;
    return cannonPosition + Offset(sin(a), -cos(a)) * muzzleDistance;
  }

  /// Hex neighbours of [cell] (may include out-of-range cells).
  static List<GridCell> neighbours(GridCell cell) {
    final r = cell.row;
    final c = cell.col;
    // Even rows' diagonal neighbours sit at c-1/c in the odd rows above and
    // below; odd rows' at c/c+1 in the even rows.
    final dl = r.isOdd ? c : c - 1;
    final dr = r.isOdd ? c + 1 : c;
    return [
      GridCell(r, c - 1),
      GridCell(r, c + 1),
      GridCell(r - 1, dl),
      GridCell(r - 1, dr),
      GridCell(r + 1, dl),
      GridCell(r + 1, dr),
    ];
  }

  int get _lowestRow =>
      _grid.isEmpty ? 0 : _grid.keys.map((c) => c.row).reduce(max);

  /// Ceiling position that puts the lowest bubble on the target line.
  double get _targetGridTop {
    final targetLine = min(
      _boardHeight * _targetLineFraction,
      _boardHeight - cannonOffsetFromBottom - muzzleDistance - 1 - _cannonClearance,
    );
    return targetLine - 2.0 - _lowestRow * rowHeight;
  }

  /// Ceiling position the cluster slides toward this frame. Normally
  /// [_targetGridTop], but in a speed round a popping bubble keeps holding
  /// the view down until its pop finishes — its row counts as the lowest,
  /// rising one row as the pop plays out. Matches pop from the bottom up, so
  /// the view scans up the column at the pace bubbles clear, and rows above
  /// never slide down behind pops still playing.
  double get _slideTargetGridTop {
    final target = _targetGridTop;
    if (!isSpeedRound) return target;
    var lowest = _lowestRow.toDouble();
    for (final p in _popping) {
      final row = p.row;
      if (row == null) continue;
      lowest = max(lowest, row - (p.progress ?? 0));
    }
    return target - (lowest - _lowestRow) * rowHeight;
  }

  // ─────────────────────────────────────────
  // Level flow
  // ─────────────────────────────────────────

  /// Tells the provider how tall the board is, in bubble units. Doesn't
  /// notify — called from layout.
  void setBoardHeight(double height) {
    if ((height - _boardHeight).abs() < 0.01) return;
    _boardHeight = height;
    // Mid-game, [tick] eases the cluster to its new target instead.
    if (!_isPlaying) _gridTop = _targetGridTop;
  }

  void setLevel(int levelNumber) {
    _level = BubbleShooterLevels.getLevel(levelNumber);
    notifyListeners();
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    _isPlaying = false;
    _gameOver = false;
    _flying = null;
    notifyListeners();
  }

  /// Builds the level's cluster so it's visible under the intro overlay.
  /// Follow with [startGame] when the intro finishes.
  void prepareForIntro() {
    _showLevelSelect = false;
    _isPlaying = false;
    _gameOver = false;
    _score = 0;
    _shotsFired = 0;
    _lastResult = null;
    _flying = null;
    _aimAngle = null;
    _barrelAngle = 0;
    _lastLanded = null;
    _falling.clear();
    _popping.clear();
    _popups.clear();
    _timeRemaining = (_level.speedRoundSeconds ?? 0).toDouble();
    _timeUp = false;
    _lastFired = null;
    _lastFiredRun = 0;
    _buildCluster();
    _topUpSpeedRows();
    _startingBubbleCount = _grid.length;
    _gridTop = _targetGridTop;
    // New colours are fired first, in order, one per solid row.
    final introduced = BubbleShooterLevels.introducedColours(_level);
    _loaded = introduced.isNotEmpty ? introduced[0] : _randomPresentColour();
    _next = introduced.length > 1 ? introduced[1] : _randomPresentColour();
    notifyListeners();
    _frame.ping();
  }

  /// Starts play on the current level (rebuilding the cluster if replaying).
  void startGame() {
    if (_gameOver || _grid.isEmpty) prepareForIntro();
    _isPlaying = true;
    notifyListeners();
  }

  /// Stops play without recording a result (e.g. leaving the screen).
  void stopGame() {
    _isPlaying = false;
    _flying = null;
    _aimAngle = null;
    notifyListeners();
  }

  /// Builds the starting cluster. When the level sets
  /// [BubbleShooterLevel.minShotsToClear] or
  /// [BubbleShooterLevel.maxClearPerShot], regenerates up to
  /// [_maxClusterAttempts] times until the board meets them (keeping the
  /// last attempt if none does).
  void _buildCluster() {
    _grid.clear();
    if (isSpeedRound) {
      _shapeRows = const [];
      _shapeRow = 0;
      _diamondColours = null;
      _hexagonTrios.clear();
      _hexagonColours = null;
      _stripeColours = null;
      _stripeSections = 0;
      // Built bottom-up, the same direction [_topUpSpeedRows] carries on
      // in, so the shapes continue seamlessly as rows are added.
      for (var r = _level.rows - 1; r >= 0; r--) {
        _fillSpeedRow(r);
      }
      return;
    }
    final minShots = _level.minShotsToClear;
    final maxClear = _level.maxClearPerShot;
    for (var attempt = 0; attempt < _maxClusterAttempts; attempt++) {
      _fillCluster();
      final tooFewShots =
          minShots != null && clearableWithin(_grid, minShots - 1);
      final shotTooBig =
          maxClear != null && bestSingleShotClear(_grid) > maxClear;
      if (!tooFewShots && !shotTooBig) return;
    }
  }

  /// Fills [currentLevel.rows] rows. Each cell copies a random already-filled
  /// neighbour (left or above) with probability [clumpiness], otherwise picks
  /// a random level colour — giving clumps that are easy to match.
  ///
  /// A level with a [BubbleShooterLevel.pattern] is drawn in it instead
  /// (leaving any cells the pattern skips empty).
  void _fillCluster() {
    _grid.clear();
    final colours = _level.colours;
    final pattern = _level.pattern;
    if (pattern != null) {
      for (var r = 0; r < _level.rows; r++) {
        for (var c = 0; c < rowLength(r); c++) {
          final cell = GridCell(r, c);
          final index = pattern.colourIndex(
            cell,
            rows: _level.rows,
            columns: columns,
            fine: _level.finePattern,
          );
          if (index != null) _grid[cell] = colours[index];
        }
      }
      return;
    }
    final ceilingStart = _random.nextInt(colours.length);
    for (var r = 0; r < _level.rows; r++) {
      for (var c = 0; c < rowLength(r); c++) {
        final cell = GridCell(r, c);
        if (r == 0 && _level.ceilingInPairs) {
          _grid[cell] = colours[(ceilingStart + c ~/ 2) % colours.length];
          continue;
        }
        final filled = neighbours(cell)
            .where((n) => n.row < r || (n.row == r && n.col < c))
            .where(_grid.containsKey)
            .toList();
        if (filled.isNotEmpty && _random.nextDouble() < _level.clumpiness) {
          _grid[cell] = _grid[filled[_random.nextInt(filled.length)]]!;
        } else {
          _grid[cell] = colours[_random.nextInt(colours.length)];
        }
      }
    }
    // Newly introduced colours each fill a whole row along the bottom: the
    // first new colour the very bottom row, the next one the row above.
    final introduced = BubbleShooterLevels.introducedColours(_level);
    final firstSolidRow = _level.rows - introduced.length;
    for (var i = 0; i < introduced.length; i++) {
      final row = _level.rows - 1 - i;
      for (var c = 0; c < rowLength(row); c++) {
        _grid[GridCell(row, c)] = introduced[i];
      }
    }

    // Make sure every level colour actually appears (outside the solid rows).
    for (final colour in colours) {
      if (!_grid.containsValue(colour)) {
        final keys =
            _grid.keys.where((k) => k.row < firstSolidRow).toList();
        _grid[keys[_random.nextInt(keys.length)]] = colour;
      }
    }
  }

  /// Whether [grid] can be cleared in at most [shots] shots, assuming the
  /// player always gets the colour they want. A shot that hits a group of
  /// two or more pops it (and drops anything left hanging); a lone bubble
  /// takes two shots — one to make a pair, one to pop it. Only groups with
  /// an open neighbouring cell can be hit.
  @visibleForTesting
  static bool clearableWithin(Map<GridCell, BubbleColour> grid, int shots) {
    if (grid.isEmpty) return true;
    if (shots <= 0) return false;
    final seen = <GridCell>{};
    for (final start in grid.keys) {
      if (seen.contains(start)) continue;
      final group = _groupIn(grid, start);
      seen.addAll(group);
      final cost = group.length >= 2 ? 1 : 2;
      if (cost > shots || !group.any((c) => _hasOpenNeighbour(grid, c))) {
        continue;
      }
      final rest = Map.of(grid)..removeWhere((c, _) => group.contains(c));
      if (clearableWithin(_anchoredIn(rest), shots - cost)) return true;
    }
    return false;
  }

  /// The largest fraction (0–1) of [grid] one shot can clear — a group of
  /// two or more popped plus whatever it leaves hanging.
  @visibleForTesting
  static double bestSingleShotClear(Map<GridCell, BubbleColour> grid) {
    if (grid.isEmpty) return 0;
    var best = 0;
    final seen = <GridCell>{};
    for (final start in grid.keys) {
      if (seen.contains(start)) continue;
      final group = _groupIn(grid, start);
      seen.addAll(group);
      if (group.length < 2 || !group.any((c) => _hasOpenNeighbour(grid, c))) {
        continue;
      }
      final rest = Map.of(grid)..removeWhere((c, _) => group.contains(c));
      best = max(best, grid.length - _anchoredIn(rest).length);
    }
    return best / grid.length;
  }

  /// Same-colour cells connected to [start] in [grid].
  static Set<GridCell> _groupIn(
      Map<GridCell, BubbleColour> grid, GridCell start) {
    final colour = grid[start];
    final group = {start};
    final queue = Queue.of([start]);
    while (queue.isNotEmpty) {
      for (final n in neighbours(queue.removeFirst())) {
        if (grid[n] == colour && group.add(n)) queue.add(n);
      }
    }
    return group;
  }

  /// The part of [grid] still connected to the ceiling row.
  static Map<GridCell, BubbleColour> _anchoredIn(
      Map<GridCell, BubbleColour> grid) {
    final anchored = {...grid.keys.where((c) => c.row == 0)};
    final queue = Queue.of(anchored);
    while (queue.isNotEmpty) {
      for (final n in neighbours(queue.removeFirst())) {
        if (grid.containsKey(n) && anchored.add(n)) queue.add(n);
      }
    }
    return {for (final c in anchored) c: grid[c]!};
  }

  static bool _hasOpenNeighbour(
          Map<GridCell, BubbleColour> grid, GridCell cell) =>
      neighbours(cell).any((n) =>
          n.row >= 0 &&
          n.col >= 0 &&
          n.col < rowLength(n.row) &&
          !grid.containsKey(n));

  /// Rows of the speed-round shape being built, in build order (bottom-up)
  /// and each left to right, and how many of them have been built so far.
  List<List<BubbleColour>> _shapeRows = const [];
  int _shapeRow = 0;

  /// The diamond's (left, right) colours.
  (BubbleColour, BubbleColour)? _diamondColours;

  /// Hexagon trios not yet used since the list was last shuffled, and the
  /// last hexagon's colours.
  final List<(BubbleColour, BubbleColour, BubbleColour)> _hexagonTrios = [];
  Set<BubbleColour>? _hexagonColours;

  /// The last stripes section's colours, and how many sections so far.
  Set<BubbleColour>? _stripeColours;
  int _stripeSections = 0;

  /// Fills the next row of the speed round's stack of shapes into [row],
  /// centred. Odd rows only fit odd widths centred (and even rows even
  /// widths), so each shape starts on a row that suits its first width.
  void _fillSpeedRow(int row) {
    if (_shapeRow >= _shapeRows.length) {
      switch (_level.speedRoundPattern) {
        case SpeedRoundPattern.diamonds:
          _startDiamond(tip: row.isOdd ? 1 : 2);
        case SpeedRoundPattern.hexagons:
          _startHexagon(row);
        case SpeedRoundPattern.stripes:
          _startStripes(row);
      }
    }
    final colours = _shapeRows[_shapeRow++];
    final start = (rowLength(row) - colours.length) ~/ 2;
    for (var i = 0; i < colours.length; i++) {
      _grid[GridCell(row, start + i)] = colours[i];
    }
  }

  /// Begins the next piece of a hexagon stack: a hexagon on an odd row,
  /// otherwise the neck joining it to the one below.
  ///
  /// Each hexagon widens one bubble per row from [hexagonMinWidth] to
  /// [hexagonMaxWidth] and narrows back — nine rows, so it ends on an odd
  /// row too and the next one needs a neck between. It's split into left
  /// and right halves around a small hexagon in its middle three rows (2,
  /// 3, then 2 wide), coloured
  /// from one of [SpeedRoundHexagons.trios] — each used once, in a random
  /// order, before any repeats, and never the same set twice in a row. The
  /// neck is [SpeedRoundHexagons.neck], which keeps one hexagon's colours
  /// from joining the next's.
  void _startHexagon(int row) {
    _shapeRow = 0;
    if (row.isEven) {
      _shapeRows = [List.filled(hexagonNeckWidth, SpeedRoundHexagons.neck)];
      return;
    }
    if (_hexagonTrios.isEmpty) {
      _hexagonTrios
        ..addAll(SpeedRoundHexagons.trios)
        ..shuffle(_random);
      Set<BubbleColour> set((BubbleColour, BubbleColour, BubbleColour) t) =>
          {t.$1, t.$2, t.$3};
      // A fresh shuffle mustn't start with the trio that ended the last one.
      if (_hexagonColours != null &&
          set(_hexagonTrios.last).containsAll(_hexagonColours!)) {
        _hexagonTrios.insert(0, _hexagonTrios.removeLast());
      }
    }
    final (a, b, c) = _hexagonTrios.removeLast();
    final [left, right, middle] = [a, b, c]..shuffle(_random);
    _hexagonColours = {left, right, middle};

    const steps = hexagonMaxWidth - hexagonMinWidth;
    List<BubbleColour> hexagonRow(int k) {
      final fromTip = min(k, 2 * steps - k);
      final width = hexagonMinWidth + fromTip;
      // The middle hexagon fills the three widest rows: 2, 3, 2.
      final inner = fromTip >= steps - 1 ? fromTip - 1 : 0;
      final side = (width - inner) ~/ 2;
      return [
        for (var i = 0; i < width; i++)
          i < side ? left : (i < side + inner ? middle : right),
      ];
    }

    _shapeRows = [for (var k = 0; k <= 2 * steps; k++) hexagonRow(k)];
  }

  /// Begins a [stripeSectionRows]-row section of a stripes speed round,
  /// whose bottom row is [row]: full-width rows crossed by diagonal stripes
  /// [stripeWidth] bubbles wide, leaning right (/) in the first section and
  /// alternating from there.
  ///
  /// A section's stripes repeat [SpeedRoundStripes.coloursPerSection]
  /// colours in an order that never puts a confusable pair side by side.
  /// The first section picks its colours at random (from those whose
  /// leftovers can be ordered too); every later one uses the colours the
  /// section below didn't, so stripes never join across sections.
  void _startStripes(int row) {
    final previous = _stripeColours;
    late Set<BubbleColour> colours;
    late List<List<BubbleColour>> orders;
    do {
      colours = previous != null
          ? BubbleColour.values.toSet().difference(previous)
          : (List.of(BubbleColour.values)..shuffle(_random))
              .take(SpeedRoundStripes.coloursPerSection)
              .toSet();
      orders = _stripeOrders(colours);
    } while (previous == null &&
        (orders.isEmpty ||
            _stripeOrders(BubbleColour.values.toSet().difference(colours))
                .isEmpty));
    final order = orders[_random.nextInt(orders.length)];
    final leansRight = _stripeSections.isEven;
    _stripeSections++;
    _stripeColours = colours;

    // With x a bubble's offset from the left wall in radii, less one, and k
    // its row within the section: going up a stripe moves one radius right
    // (/) or left (\) per row, and neighbours along a row are two apart —
    // so x ∓ k stays the same all the way along a stripe, and a stripe
    // [stripeWidth] bubbles wide covers 2 × [stripeWidth] values of it.
    _shapeRow = 0;
    _shapeRows = [
      for (var k = 0; k < stripeSectionRows; k++)
        [
          for (var c = 0; c < rowLength(row - k); c++)
            order[((2 * c + ((row - k).isOdd ? 1 : 0)) +
                        (leansRight ? -k : k) +
                        stripeSectionRows) ~/
                    (2 * stripeWidth) %
                order.length],
        ],
    ];
  }

  /// Every order of [colours] that, repeated, never puts a
  /// [SpeedRoundStripes.confusable] pair side by side.
  static List<List<BubbleColour>> _stripeOrders(Set<BubbleColour> colours) {
    final orders = <List<BubbleColour>>[];
    void extend(List<BubbleColour> order) {
      if (order.length == colours.length) {
        if (!SpeedRoundStripes.areConfusable(order.last, order.first)) {
          orders.add(List.of(order));
        }
        return;
      }
      for (final c in colours) {
        if (order.contains(c) ||
            (order.isNotEmpty &&
                SpeedRoundStripes.areConfusable(order.last, c))) {
          continue;
        }
        extend(order..add(c));
        order.removeLast();
      }
    }

    extend([]);
    return orders;
  }

  /// Begins a new speed-round diamond whose first and last rows are [tip]
  /// bubbles wide, picking its colours.
  ///
  /// Each diamond widens one bubble per row from its tip to
  /// [diamondMaxWidth], then narrows back to the tip, and is split down the
  /// middle — left half one colour, right half another — using a pair that
  /// shares no colour with the diamond before it, so only one half-diamond
  /// can be popped at a time.
  void _startDiamond({required int tip}) {
    _shapeRow = 0;

    final previous = _diamondColours;
    bool usable((BubbleColour, BubbleColour) p) =>
        previous == null ||
        !{previous.$1, previous.$2}.any((c) => c == p.$1 || c == p.$2);
    final hard = SpeedRoundRows.hard.where(usable).toList();
    final safe = SpeedRoundRows.safe.where(usable).toList();
    final pool = hard.isNotEmpty &&
            (safe.isEmpty || _random.nextDouble() < SpeedRoundRows.hardChance)
        ? hard
        : safe;
    var (left, right) = pool[_random.nextInt(pool.length)];
    if (_random.nextBool()) (left, right) = (right, left);
    _diamondColours = (left, right);
    _shapeRows = [
      for (final w in [
        for (var w = tip; w <= diamondMaxWidth; w++) w,
        for (var w = diamondMaxWidth - 1; w >= tip; w--) w,
      ])
        [for (var i = 0; i < w; i++) i * 2 < w ? left : right],
    ];
  }

  /// In a speed round, adds rows at the top so there are always more
  /// waiting above the board — the bubbles never run out. Rows are added
  /// two at a time so every row keeps its odd/even offset, and the view is
  /// shifted to match so nothing on screen jumps.
  void _topUpSpeedRows() {
    if (!isSpeedRound) return;
    while (_targetGridTop > -_speedRowsAboveScreen * rowHeight) {
      final shifted = {
        for (final e in _grid.entries)
          GridCell(e.key.row + 2, e.key.col): e.value,
      };
      _grid
        ..clear()
        ..addAll(shifted);
      _gridTop -= 2 * rowHeight;
      for (final p in _popping) {
        final row = p.row;
        if (row != null) p.row = row + 2;
      }
      final landed = _lastLanded;
      if (landed != null) _lastLanded = GridCell(landed.row + 2, landed.col);
      _fillSpeedRow(1);
      _fillSpeedRow(0);
    }
  }

  /// Replaces the board with [cells] and loads [loaded] — for tests that
  /// need a known layout. Call after [prepareForIntro]/[startGame].
  @visibleForTesting
  void debugSetBoard(Map<GridCell, BubbleColour> cells, BubbleColour loaded) {
    _grid
      ..clear()
      ..addAll(cells);
    _gridTop = _targetGridTop;
    _topUpSpeedRows();
    _loaded = loaded;
    _next = loaded;
  }

  /// A random colour still on the board (so every shot can make a match),
  /// or a random level colour if the board is empty.
  ///
  /// In a speed round the board holds many colours far out of reach, so
  /// only colours the cannon can actually hit (see [_reachableColours])
  /// are loaded.
  ///
  /// [avoid] is left out whenever another colour is available.
  BubbleColour _randomPresentColour({BubbleColour? avoid}) {
    final present = _level.colours.where(_isLoadable).toList();
    var pool = present.isEmpty ? _level.colours : present;
    if (pool.length > 1) pool = pool.where((c) => c != avoid).toList();
    return pool[_random.nextInt(pool.length)];
  }

  /// The colour that has already come out of the cannon
  /// [maxSameColourInARow] times in a row — counting the fired bubbles, plus
  /// the loaded one when [afterLoaded] — so the next pick should avoid it.
  /// Null when no colour has hit the limit.
  BubbleColour? _overusedColour({required bool afterLoaded}) {
    var colour = _lastFired;
    var run = _lastFiredRun;
    if (afterLoaded && _loaded != null) {
      run = _loaded == colour ? run + 1 : 1;
      colour = _loaded;
    }
    return run >= maxSameColourInARow ? colour : null;
  }

  bool _isLoadable(BubbleColour? colour) => isSpeedRound
      ? _reachableColours().contains(colour)
      : _grid.containsValue(colour);

  /// Colours of bubbles a shot can land next to: those beside an open cell
  /// joined, through other open cells, to the space below the cluster. An
  /// open cell walled off by a full row doesn't count, and neither does one
  /// above the top of the board — speed-round diamonds leave open channels
  /// down their sides that run up past the screen.
  Set<BubbleColour> _reachableColours() {
    bool onScreen(GridCell cell) => cellCentre(cell, _targetGridTop).dy >= 1;
    final belowRow = _lowestRow + 1;
    final open = {
      for (var c = 0; c < rowLength(belowRow); c++) GridCell(belowRow, c),
    };
    final queue = Queue.of(open);
    while (queue.isNotEmpty) {
      for (final n in neighbours(queue.removeFirst())) {
        if (n.row >= 0 &&
            n.row <= belowRow &&
            n.col >= 0 &&
            n.col < rowLength(n.row) &&
            !_grid.containsKey(n) &&
            onScreen(n) &&
            open.add(n)) {
          queue.add(n);
        }
      }
    }
    return {
      for (final e in _grid.entries)
        if (neighbours(e.key).any(open.contains)) e.value,
    };
  }

  // ─────────────────────────────────────────
  // Aiming & firing
  // ─────────────────────────────────────────

  /// Whether the cannon is ready to fire.
  bool get canFire =>
      _isPlaying &&
      !_gameOver &&
      !_timeUp &&
      _flying == null &&
      _grid.isNotEmpty;

  /// Aims at [target] (board units). Points below the cannon are ignored.
  void aimAt(Offset target) {
    if (!_isPlaying || _gameOver) return;
    final d = target - cannonPosition;
    if (d.dy > -0.5) {
      // Below/level with the cannon — aim straight sideways-ish instead.
      _aimAngle = d.dx >= 0 ? maxAimAngle : -maxAimAngle;
    } else {
      _aimAngle = atan2(d.dx, -d.dy).clamp(-maxAimAngle, maxAimAngle);
    }
    _barrelAngle = _aimAngle!;
    _frame.ping();
  }

  void cancelAim() {
    _aimAngle = null;
    _frame.ping();
  }

  /// Fires the loaded bubble along the current aim. Returns false if the
  /// cannon wasn't ready.
  bool fire() {
    final angle = _aimAngle;
    _aimAngle = null;
    if (angle == null || !canFire || _loaded == null) {
      _frame.ping();
      return false;
    }
    _flying = FlyingBubble(
      colour: _loaded!,
      position: muzzlePosition(angle),
      velocity: Offset(sin(angle), -cos(angle)) * _shotSpeed,
    );
    _shotsFired++;
    _lastFiredRun = _loaded == _lastFired ? _lastFiredRun + 1 : 1;
    _lastFired = _loaded;
    _loaded = _next;
    _next = _randomPresentColour(avoid: _overusedColour(afterLoaded: true));
    notifyListeners();
    _frame.ping();
    return true;
  }

  /// Simulates a shot along the current aim for the dotted guide line.
  /// Returns the path's corner points: cannon, each wall bounce, and where
  /// the shot would stop.
  List<Offset> aimGuide() {
    final angle = _aimAngle;
    if (angle == null) return const [];
    var pos = muzzlePosition(angle);
    var dir = Offset(sin(angle), -cos(angle));
    final points = [pos];
    const step = 0.2;
    for (var i = 0; i < 600; i++) {
      pos += dir * step;
      if (pos.dx < 1) {
        pos = Offset(2 - pos.dx, pos.dy);
        dir = Offset(-dir.dx, dir.dy);
        points.add(pos);
      } else if (pos.dx > boardWidth - 1) {
        pos = Offset(2 * (boardWidth - 1) - pos.dx, pos.dy);
        dir = Offset(-dir.dx, dir.dy);
        points.add(pos);
      }
      if (pos.dy - 1 <= _gridTop || _hitsCluster(pos) != null) break;
    }
    points.add(pos);
    return points;
  }

  /// The occupied cell [pos] is touching, if any.
  GridCell? _hitsCluster(Offset pos) {
    for (final cell in _grid.keys) {
      if ((centreOf(cell) - pos).distance < _stickDistance) return cell;
    }
    return null;
  }

  // ─────────────────────────────────────────
  // Frame update
  // ─────────────────────────────────────────

  /// Advances the simulation by [dt] seconds. Called every frame by the
  /// screen's ticker.
  void tick(double dt) {
    if (_showLevelSelect) return;
    dt = min(dt, 1 / 20); // Don't jump after a stall.
    var moved = false;

    // Slide the cluster toward its target height. A speed round follows
    // its pops closely, and the pops and score labels ride along with it.
    final target = _slideTargetGridTop;
    if ((target - _gridTop).abs() > 0.001) {
      final step =
          (target - _gridTop) * min(1.0, dt * (isSpeedRound ? 12 : 4));
      _gridTop += step;
      if (isSpeedRound) {
        for (final p in _popping) {
          p.position += Offset(0, step);
        }
        for (final p in _popups) {
          p.position += Offset(0, step);
        }
      }
      moved = true;
    }

    if (_flying != null) {
      _advanceShot(dt);
      moved = true;
    }

    for (final b in _falling) {
      if (b.delay > 0) {
        b.delay -= dt;
        continue;
      }
      b.velocity += Offset(0, _gravity * dt);
      b.position += b.velocity * dt;
    }
    _falling.removeWhere((b) => b.position.dy > _boardHeight + 3);

    for (final p in _popping) {
      p.age += dt;
    }
    _popping.removeWhere((p) => p.age >= PoppingBubble.duration);

    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= ScorePopup.duration);

    if (isSpeedRound && _isPlaying && !_timeUp) {
      final before = timeRemainingSeconds;
      _timeRemaining = max(0, _timeRemaining - dt);
      if (_timeRemaining == 0) {
        _timeUp = true;
        _aimAngle = null;
      }
      if (timeRemainingSeconds != before) notifyListeners();
    }

    _sinceLanding += dt;
    moved = moved ||
        _falling.isNotEmpty ||
        _popping.isNotEmpty ||
        _popups.isNotEmpty ||
        _sinceLanding < 0.5;

    final cleared = _grid.isEmpty && _falling.isEmpty && _popping.isEmpty;
    // A speed round ends when the clock runs out (once any shot in the air
    // has landed and been scored).
    if (_isPlaying && !_gameOver && _flying == null && (cleared || _timeUp)) {
      _completeLevel();
    }

    if (moved) _frame.ping();
  }

  void _advanceShot(double dt) {
    final shot = _flying!;
    var remaining = shot.velocity.distance * dt;
    while (remaining > 0 && _flying != null) {
      final step = min(remaining, _maxStep);
      remaining -= step;
      shot.position += shot.velocity / shot.velocity.distance * step;

      // Bounce off the side walls.
      if (shot.position.dx < 1) {
        shot.position = Offset(2 - shot.position.dx, shot.position.dy);
        shot.velocity = Offset(-shot.velocity.dx, shot.velocity.dy);
      } else if (shot.position.dx > boardWidth - 1) {
        shot.position = Offset(
            2 * (boardWidth - 1) - shot.position.dx, shot.position.dy);
        shot.velocity = Offset(-shot.velocity.dx, shot.velocity.dy);
      }

      if (shot.position.dy - 1 <= _gridTop ||
          _hitsCluster(shot.position) != null) {
        _attach(shot);
      }
    }
  }

  /// Snaps [shot] into the nearest free cell that's either on the ceiling
  /// row or touching the cluster, then resolves matches and drops.
  void _attach(FlyingBubble shot) {
    _flying = null;
    final cell = _nearestAttachableCell(shot.position);
    _grid[cell] = shot.colour;
    _lastLanded = cell;
    _sinceLanding = 0;

    final group = _sameColourGroup(cell);
    if (group.length >= 3) {
      _pop(group);
      _dropFloating();
      AudioService.playCorrect('bubble_shooter');
    }

    _topUpSpeedRows();

    // The loaded/next colours may have been cleared off the board entirely
    // (or, in a speed round, be out of reach).
    if (_grid.isNotEmpty) {
      if (!_isLoadable(_loaded)) {
        _loaded = _randomPresentColour(
            avoid: _overusedColour(afterLoaded: false));
      }
      // Re-checked even when still loadable: a replaced loaded colour can
      // turn the next one into one too many in a row.
      final overused = _overusedColour(afterLoaded: true);
      if (!_isLoadable(_next) || _next == overused) {
        _next = _randomPresentColour(avoid: overused);
      }
    }
    notifyListeners();
  }

  GridCell _nearestAttachableCell(Offset pos) {
    final maxRow = _lowestRow + 1;
    GridCell? best;
    var bestDist = double.infinity;
    for (var r = 0; r <= maxRow; r++) {
      for (var c = 0; c < rowLength(r); c++) {
        final cell = GridCell(r, c);
        if (_grid.containsKey(cell)) continue;
        final attachable =
            r == 0 || neighbours(cell).any(_grid.containsKey);
        if (!attachable) continue;
        final d = (centreOf(cell) - pos).distanceSquared;
        if (d < bestDist) {
          bestDist = d;
          best = cell;
        }
      }
    }
    return best ?? const GridCell(0, 0);
  }

  /// Connected same-colour cells including [start], in breadth-first order
  /// (so pops ripple outward from where the shot landed).
  List<GridCell> _sameColourGroup(GridCell start) {
    final colour = _grid[start];
    final result = <GridCell>[];
    final seen = {start};
    final queue = Queue.of([start]);
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      result.add(cell);
      for (final n in neighbours(cell)) {
        if (seen.add(n) && _grid[n] == colour) queue.add(n);
      }
    }
    return result;
  }

  void _pop(List<GridCell> group) {
    for (var i = 0; i < group.length; i++) {
      final cell = group[i];
      final pos = centreOf(cell);
      _popping.add(PoppingBubble(
        colour: _grid[cell]!,
        position: pos,
        row: isSpeedRound ? cell.row : null,
        age: -i * 0.04,
      ));
      _popups.add(
          ScorePopup(points: popPoints, position: pos, age: -i * 0.04));
      _grid.remove(cell);
    }
    _score += group.length * popPoints;
  }

  /// Drops every bubble no longer connected to the ceiling row.
  void _dropFloating() {
    final anchored = <GridCell>{};
    final queue = Queue.of(_grid.keys.where((c) => c.row == 0));
    anchored.addAll(queue);
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      for (final n in neighbours(cell)) {
        if (_grid.containsKey(n) && anchored.add(n)) queue.add(n);
      }
    }
    final loose = _grid.keys.where((c) => !anchored.contains(c)).toList();
    for (final cell in loose) {
      final pos = centreOf(cell);
      _falling.add(FallingBubble(
        colour: _grid[cell]!,
        position: pos,
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 6,
          -4 - _random.nextDouble() * 4,
        ),
        delay: _random.nextDouble() * 0.15,
      ));
      _popups.add(ScorePopup(points: dropPoints, position: pos));
      _grid.remove(cell);
    }
    _score += loose.length * dropPoints;
  }

  void _completeLevel() {
    _isPlaying = false;
    _gameOver = true;
    _lastResult = null;
    notifyListeners();
    onLevelComplete?.call(_score);
    _recordResult();
  }

  Future<void> _recordResult() async {
    try {
      final result = await GameStatsService().recordGameResult(
        GameIds.bubbleShooter,
        _score,
        level: _level.number,
      );
      _lastResult = result;
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('recordGameResult error (${GameIds.bubbleShooter}): $e');
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _frame.dispose();
    super.dispose();
  }
}

/// [ChangeNotifier] whose notify can be triggered by its owner.
class _FrameNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
