import 'dart:math';

import 'bubble_shooter_models.dart';

/// Geometric patterns a generated level's starting cluster is drawn in,
/// easiest first. Each colours cells with one of a level's four colours
/// (see [colourIndex]); only [hollowHexagons] leaves some cells empty.
enum BubblePattern {
  /// Two columns of hollow hexagons with an open channel between them, so
  /// a skilful shot up the middle lands high in the cluster.
  hollowHexagons,

  /// Vertical stripes hanging from the ceiling.
  stripes,

  /// A four-colour checkerboard of blocks.
  checks,

  /// Stripes running diagonally along the hex grid.
  diagonals,

  /// Stacked V shapes pointing down the middle.
  chevrons,

  /// Horizontal bands bent into a row of Vs.
  zigzags,

  /// Little hexagonal dots on vertical stripes of two background colours.
  dots,

  /// Concentric circles.
  rings,

  /// Concentric hexagons.
  hexagons,

  /// Wedges fanning out from a centre, like a pinwheel.
  pinwheel;

  /// Height, in rows, of the repeating tile [rings], [hexagons] and
  /// [pinwheel] are drawn in, one motif per tile.
  static const int tileRows = 10;

  /// Whether this pattern leaves cells empty, so its cluster isn't full.
  bool get hasGaps => this == hollowHexagons;

  /// Rows this pattern's cluster must have, or null to fit any height.
  /// [hollowHexagons] needs its bottom and top rows to be hexagon edges,
  /// on even rows: 21 rows hold five hexagons per column.
  int? get fixedRows => this == hollowHexagons ? 21 : null;

  /// Which of a level's four colours (0–3) [cell] gets, in a cluster [rows]
  /// tall and [columns] bubbles wide, or null to leave it empty. [fine]
  /// draws the pattern with thinner bands (or more wedges), making smaller
  /// groups to pop.
  ///
  /// Everything is measured from the bottom row up, so whatever the
  /// cluster's height, the rows the player sees first start on a whole
  /// motif.
  int? colourIndex(
    GridCell cell, {
    required int rows,
    required int columns,
    required bool fine,
  }) {
    final r = cell.row;
    // Bubble centre's offset from the left wall, in radii, less one. Going
    // up or down a row while moving one radius sideways follows the grid's
    // diagonals, so lines where x ± row stays the same are clean.
    final x = 2 * cell.col + (r.isOdd ? 1 : 0);
    final up = rows - 1 - r;
    // x of the board's centre line — an odd-row bubble sits on it.
    final mid = columns - 1;
    final w = fine ? 2 : 3;
    // Width of a vertical stripe or block, in radii: 2 or 2½ bubbles, so
    // the right wall never ends in a column of lone bubbles.
    final columnWidth = fine ? 4 : 5;

    // Odd row (so a bubble sits on [mid]) at the centre of the tile [r] is
    // in. The bottom tile's centre is about half a tile above the bottom.
    int tileCentre() {
      var bottom = rows - 1 - tileRows ~/ 2;
      if (bottom.isEven) bottom--;
      return bottom - tileRows * ((bottom - r) / tileRows).round();
    }

    switch (this) {
      case hollowHexagons:
        return _hollowHexagonsColourIndex(x, up, columns);
      case stripes:
        return x ~/ columnWidth % 4;
      case checks:
        return x ~/ columnWidth % 2 + 2 * (up ~/ w % 2);
      case diagonals:
        return (x + up) ~/ (2 * w) % 4;
      case chevrons:
        return ((x - mid).abs() + up) ~/ (2 * w) % 4;
      case zigzags:
        // Mirrored about the centre line, so both walls end the same way.
        final t = (x - mid).abs() % (4 * w);
        return (up + (t - 2 * w).abs()) ~/ (2 * w) % 4;
      case dots:
        return _dotsColourIndex(x, r, up, fine);
      case rings:
        final dx = (x - mid).toDouble();
        final dy = (r - tileCentre()) * sqrt(3);
        // Wide bands are a touch over 1½ bubbles, so the side walls stay in
        // one ring rather than leaving lone bubbles just over the edge of
        // the next.
        final band = fine ? 2.0 : 3.25;
        final ring = (sqrt(dx * dx + dy * dy) / band).floor();
        // Wide rings fit three whole rings in a tile; the tile's far corners
        // join the outermost colour rather than starting a fifth ring.
        return (fine ? ring : min(ring, 3)) % 4;
      case hexagons:
        final dx = (x - mid).abs();
        final dr = (r - tileCentre()).abs();
        final distance = dr + max(0, (dx - dr) ~/ 2);
        return distance ~/ (fine ? 1 : 2) % 4;
      case pinwheel:
        final angle = atan2((r - tileCentre()) * sqrt(3), (x - mid).toDouble());
        final wedges = fine ? 12 : 8;
        // Turned half a wedge, so the centre row runs through the middle of
        // a wedge rather than along an edge.
        final wedge =
            ((angle + pi) / (2 * pi) * wedges + 0.5).floor() % wedges;
        return fine ? wedge % 4 : _eightWedgeColours[wedge];
    }
  }

  /// Rows from one hexagon edge to the next in [hollowHexagons].
  static const int _hexagonRows = 4;

  /// Cells of a [hollowHexagons] left-column hexagon, as x offsets, for
  /// each row counted up from its bottom edge: an edge two bubbles wide,
  /// then sides around a hollow 1, 2 and 1 bubbles wide. The top edge is
  /// the bottom edge of the hexagon above.
  static const List<Set<int>> _hexagonOutline = [
    {2, 4},
    {1, 5},
    {0, 6},
    {1, 5},
  ];

  /// [hollowHexagons]: a column of hexagons down each side, the right one
  /// mirroring the left, with a channel down the middle wide enough for a
  /// shot to pass. Every second hexagon edge, a bridge crosses the channel,
  /// so a shot up it lands just under the bridge — high up, but still on
  /// screen — rather than flying on to the ceiling.
  ///
  /// Each hexagon is one colour and owns its top edge, so popping one high
  /// up drops the hexagon hanging below it. Colours step down each column,
  /// the right column one ahead of the left; a bridge takes the one colour
  /// none of the four hexagons it touches has.
  static int? _hollowHexagonsColourIndex(int x, int up, int columns) {
    final right = x > columns - 1;
    final mirrored = right ? 2 * (columns - 1) - x : x;
    final k = up % _hexagonRows;
    final hexagon = up == 0 ? 0 : (up - 1) ~/ _hexagonRows;
    if (_hexagonOutline[k].contains(mirrored)) {
      return (hexagon + (right ? 1 : 0)) % 4;
    }
    final bridge = up > 0 && up % (2 * _hexagonRows) == 0;
    if (bridge && mirrored > _hexagonOutline[0].reduce(max)) {
      return (hexagon + 3) % 4;
    }
    return null;
  }

  /// Colours for [pinwheel]'s eight wedges. Opposite wedges meet at the
  /// centre, so unlike neighbours they mustn't match either — which simply
  /// repeating four colours would do.
  static const List<int> _eightWedgeColours = [0, 1, 2, 3, 1, 0, 3, 2];

  /// [dots]: hexagons of seven bubbles on a staggered lattice, in colours 2
  /// and 3, over vertical stripes four bubbles wide in colours 0 and 1 — so
  /// popping one stripe drops only the dots hanging from it. [fine] gives
  /// each dot a centre in the other dot colour.
  static int _dotsColourIndex(int x, int r, int up, bool fine) {
    for (var d = -1; d <= 1; d++) {
      final dotUp = up + d;
      if (dotUp % 4 != 2) continue;
      final dotRow = r - d;
      final lattice = dotUp ~/ 4;
      final centres = lattice.isEven ? const [3, 11] : const [7, 15];
      for (var i = 0; i < centres.length; i++) {
        // Even rows' bubbles sit on even x.
        final centreX = centres[i] - (dotRow.isEven ? 1 : 0);
        final dx = (x - centreX).abs();
        final dr = d.abs();
        if (dr + max(0, (dx - dr) ~/ 2) > 1) continue;
        final colour = 2 + (lattice + i) % 2;
        return fine && dx == 0 && dr == 0 ? 5 - colour : colour;
      }
    }
    return x ~/ 8 % 2;
  }
}
