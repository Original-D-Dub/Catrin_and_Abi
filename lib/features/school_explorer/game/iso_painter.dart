import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../models/school_scene.dart';

/// Isometric projection and box painting shared by the School Explorer
/// scene components.
///
/// Grid `x` runs down-right on screen, grid `y` down-left and `z` straight
/// up, so the two visible side faces of any box are the ones at `x + w`
/// (right) and `y + d` (left).
class IsoPainter {
  IsoPainter._();

  static const double halfTileWidth = 32;
  static const double halfTileHeight = 16;
  static const double unitHeight = 36;

  static Offset project(double x, double y, double z) => Offset(
    (x - y) * halfTileWidth,
    (x + y) * halfTileHeight - z * unitHeight,
  );

  // ── Draw ordering ─────────────────────────────────────────────────────────

  /// Whether box A must be drawn before box B. Boxes separated along an
  /// axis are ordered by that axis (x, then y, then z — lower first);
  /// boxes separated in x one way and y the other never overlap on screen,
  /// so checking x first is safe. Intersecting boxes fall back to depth.
  static bool drawsBefore(IsoBox a, IsoBox b) {
    if (a.x1 <= b.x0) return true;
    if (b.x1 <= a.x0) return false;
    if (a.y1 <= b.y0) return true;
    if (b.y1 <= a.y0) return false;
    if (a.z1 <= b.z0) return true;
    if (b.z1 <= a.z0) return false;
    return a.depth < b.depth;
  }

  /// Sorts [items] into painter's-algorithm order using their bounding
  /// boxes. A plain comparator sort isn't enough (the "draws before"
  /// relation isn't transitive across non-overlapping boxes), so this does
  /// a stable topological sort, falling back to depth order.
  static List<T> sortForDrawing<T>(List<T> items, IsoBox Function(T) boxOf) {
    final boxes = items.map(boxOf).toList();
    final order = List<int>.generate(items.length, (i) => i)
      ..sort((a, b) => boxes[a].depth.compareTo(boxes[b].depth));
    final placed = <int>[];
    final remaining = order.toList();
    while (remaining.isNotEmpty) {
      // Take the first (shallowest) item that nothing remaining must
      // precede; if there's a cycle, just take the shallowest.
      var pick = remaining.first;
      for (final i in remaining) {
        final blocked = remaining.any(
          (j) => j != i && drawsBefore(boxes[j], boxes[i]),
        );
        if (!blocked) {
          pick = i;
          break;
        }
      }
      remaining.remove(pick);
      placed.add(pick);
    }
    return [for (final i in placed) items[i]];
  }

  static IsoBox boxOfPart(IsoPart p) =>
      IsoBox(p.x, p.y, p.z, p.x + p.w, p.y + p.d, p.z + p.h);

  static IsoBox boxOfObject(SchoolObject o) {
    var box = boxOfPart(o.parts.first);
    for (final p in o.parts.skip(1)) {
      box = box.union(boxOfPart(p));
    }
    return box;
  }

  // ── Geometry ──────────────────────────────────────────────────────────────

  /// The screen outline of [p] (a hexagon, or the top quad if flat).
  static Path hull(IsoPart p) {
    final x0 = p.x, y0 = p.y, z0 = p.z;
    final x1 = p.x + p.w, y1 = p.y + p.d, z1 = p.z + p.h;
    final pts = p.h == 0
        ? [
            project(x0, y0, z0),
            project(x1, y0, z0),
            project(x1, y1, z0),
            project(x0, y1, z0),
          ]
        : [
            project(x0, y0, z1),
            project(x1, y0, z1),
            project(x1, y0, z0),
            project(x1, y1, z0),
            project(x0, y1, z0),
            project(x0, y1, z1),
          ];
    return Path()..addPolygon(pts, true);
  }

  /// Screen-space bounding rectangle of a list of parts.
  static Rect bounds(Iterable<IsoPart> parts) {
    Rect? r;
    for (final p in parts) {
      final b = hull(p).getBounds();
      r = r == null ? b : r.expandToInclude(b);
    }
    return r ?? Rect.zero;
  }

  // ── Painting ──────────────────────────────────────────────────────────────

  static final Paint _fill = Paint()..isAntiAlias = true;
  static final Paint _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  static final Paint _shine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  static final Paint _shadow = Paint()
    ..color = const Color(0x22000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  static Color lighten(Color c, double amount) =>
      Color.lerp(c, const Color(0xFFFFFFFF), amount)!.withValues(alpha: c.a);

  static Color darken(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF000000), amount)!.withValues(alpha: c.a);

  /// Largest corner radius (screen px at zoom 1) — big enough to read as
  /// soft and toy-like for 4-6 year olds, small enough that thin parts
  /// (shelves, table legs) keep their shape. It's also capped per corner at
  /// a third of the shorter neighbouring edge.
  static const double cornerRadius = 7;

  /// A closed polygon with every corner rounded off by up to [radius].
  static Path roundedPolygon(List<Offset> pts, double radius) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final p = pts[i];
      final next = pts[(i + 1) % n];
      final toPrev = prev - p;
      final toNext = next - p;
      final r = math.min(
        radius,
        math.min(toPrev.distance, toNext.distance) / 3,
      );
      final a = toPrev.distance == 0 ? p : p + toPrev / toPrev.distance * r;
      final b = toNext.distance == 0 ? p : p + toNext / toNext.distance * r;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..close();
  }

  static void _face(Canvas canvas, List<Offset> pts, Color colour) {
    canvas.drawPath(roundedPolygon(pts, cornerRadius), _fill..color = colour);
  }

  /// A soft, blurred shadow on the floor under a part that stands on it.
  static void paintShadow(Canvas canvas, IsoPart p) {
    if (!p.visible || p.h == 0 || p.z > 0.05) return;
    const grow = 0.06, shift = 0.12;
    final x0 = p.x - grow + shift, y0 = p.y - grow + shift;
    final x1 = p.x + p.w + grow + shift, y1 = p.y + p.d + grow + shift;
    canvas.drawPath(
      roundedPolygon([
        project(x0, y0, 0),
        project(x1, y0, 0),
        project(x1, y1, 0),
        project(x0, y1, 0),
      ], cornerRadius * 2),
      _shadow,
    );
  }

  /// Paints one box as a soft, rounded, outlined toy block: the rounded
  /// silhouette is filled first (so the small gaps where rounded faces meet
  /// read as a bevel), then the two sides and the top, a highlight along
  /// the top's front edges, and a chunky outline around the whole shape.
  static void paintPart(Canvas canvas, IsoPart p) {
    if (!p.visible) return;
    final x0 = p.x, y0 = p.y, z0 = p.z;
    final x1 = p.x + p.w, y1 = p.y + p.d, z1 = p.z + p.h;
    final c = p.color;
    final outline = darken(c, 0.5).withValues(alpha: 0.8 * c.a);

    final topPts = [
      project(x0, y0, z1),
      project(x1, y0, z1),
      project(x1, y1, z1),
      project(x0, y1, z1),
    ];

    if (p.h > 0) {
      final silhouette = roundedPolygon([
        project(x0, y0, z1),
        project(x1, y0, z1),
        project(x1, y0, z0),
        project(x1, y1, z0),
        project(x0, y1, z0),
        project(x0, y1, z1),
      ], cornerRadius);
      canvas.drawPath(silhouette, _fill..color = darken(c, 0.1));
      // Left-facing side (y = y1).
      _face(canvas, [
        project(x0, y1, z0),
        project(x1, y1, z0),
        project(x1, y1, z1),
        project(x0, y1, z1),
      ], c);
      // Right-facing side (x = x1).
      _face(canvas, [
        project(x1, y0, z0),
        project(x1, y1, z0),
        project(x1, y1, z1),
        project(x1, y0, z1),
      ], darken(c, 0.16));
      _face(canvas, topPts, lighten(c, 0.18));
      // Shine along the top's two front edges.
      _shine.color = lighten(c, 0.6).withValues(alpha: 0.7 * c.a);
      // Nudged up so it sits just inside the top face, and skipped on
      // tops too thin to hold it.
      final topDepth = (topPts[2].dy - topPts[0].dy).abs();
      if (topDepth > 8) {
        final shine = Path()
          ..moveTo(
            Offset.lerp(topPts[3], topPts[2], 0.2)!.dx,
            Offset.lerp(topPts[3], topPts[2], 0.2)!.dy,
          )
          ..lineTo(topPts[2].dx, topPts[2].dy)
          ..lineTo(
            Offset.lerp(topPts[1], topPts[2], 0.2)!.dx,
            Offset.lerp(topPts[1], topPts[2], 0.2)!.dy,
          );
        canvas.drawPath(shine.shift(const Offset(0, -2.5)), _shine);
      }
      if (p.decal != IsoDecal.none) _paintDecal(canvas, p);
      canvas.drawPath(silhouette, _outline..color = outline);
    } else {
      final top = roundedPolygon(topPts, cornerRadius * 1.5);
      canvas.drawPath(top, _fill..color = c);
      if (p.decal != IsoDecal.none) _paintDecal(canvas, p);
      canvas.drawPath(
        top,
        _outline..color = outline.withValues(alpha: 0.35 * c.a),
      );
    }
  }

  // ── Decals ────────────────────────────────────────────────────────────────

  /// Maps face-local (u, v) in 0..1 to screen space. For side faces `u`
  /// runs along the face and `v` up it; for the top, `u` along x and `v`
  /// along y.
  static Offset Function(double u, double v) _faceMapper(IsoPart p, _Face f) {
    return switch (f) {
      _Face.top => (u, v) => project(p.x + u * p.w, p.y + v * p.d, p.z + p.h),
      _Face.left => (u, v) => project(p.x + u * p.w, p.y + p.d, p.z + v * p.h),
      _Face.right => (u, v) => project(p.x + p.w, p.y + u * p.d, p.z + v * p.h),
    };
  }

  /// The main vertical face — whichever visible side is wider.
  static _Face _mainSide(IsoPart p) => p.w >= p.d ? _Face.left : _Face.right;

  static double _faceLength(IsoPart p, _Face f) => f == _Face.left ? p.w : p.d;

  static void _poly(
    Canvas canvas,
    Offset Function(double, double) m,
    List<(double, double)> uv,
    Color colour,
  ) {
    final path = Path()..addPolygon([for (final (u, v) in uv) m(u, v)], true);
    canvas.drawPath(path, _fill..color = colour);
  }

  static void _rect(
    Canvas canvas,
    Offset Function(double, double) m,
    double u0,
    double v0,
    double u1,
    double v1,
    Color colour,
  ) {
    _poly(canvas, m, [(u0, v0), (u1, v0), (u1, v1), (u0, v1)], colour);
  }

  static void _line(
    Canvas canvas,
    Offset Function(double, double) m,
    double u0,
    double v0,
    double u1,
    double v1,
    Color colour,
    double width,
  ) {
    canvas.drawLine(
      m(u0, v0),
      m(u1, v1),
      Paint()
        ..color = colour
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _paintDecal(Canvas canvas, IsoPart p) {
    switch (p.decal) {
      case IsoDecal.none:
        return;
      case IsoDecal.clock:
        _paintClock(canvas, _faceMapper(p, _mainSide(p)));
      case IsoDecal.window:
        final face = _mainSide(p);
        final m = _faceMapper(p, face);
        final len = _faceLength(p, face);
        if (len > 4) {
          // A long wall (school building): a row of windows.
          final count = (len / 2).floor();
          for (var i = 0; i < count; i++) {
            final u0 = (i + 0.25) / count;
            final u1 = (i + 0.75) / count;
            _rect(canvas, m, u0, 0.45, u1, 0.85, const Color(0xFFFFFFFF));
            _rect(
              canvas,
              m,
              u0 + 0.01,
              0.47,
              u1 - 0.01,
              0.83,
              const Color(0xFFAEDCF2),
            );
            _line(
              canvas,
              m,
              (u0 + u1) / 2,
              0.47,
              (u0 + u1) / 2,
              0.83,
              const Color(0xFFFFFFFF),
              1.5,
            );
          }
        } else {
          const frame = Color(0xDDFFFFFF);
          for (var i = 1; i < 3; i++) {
            _line(canvas, m, i / 3, 0, i / 3, 1, frame, 2);
          }
          _line(canvas, m, 0, 0.5, 1, 0.5, frame, 2);
          // A glint of sky.
          _line(canvas, m, 0.08, 0.7, 0.2, 0.9, const Color(0x99FFFFFF), 2);
        }
      case IsoDecal.books:
        final m = _faceMapper(p, _mainSide(p));
        const colours = [
          Color(0xFFE0524B),
          Color(0xFF4A90D9),
          Color(0xFF5DB85C),
          Color(0xFFF2C94C),
          Color(0xFF9B6CC9),
          Color(0xFFF2994A),
        ];
        for (var shelf = 0; shelf < 3; shelf++) {
          final v0 = 0.06 + shelf * 0.32;
          _rect(canvas, m, 0.03, v0 - 0.03, 0.97, v0, darken(p.color, 0.3));
          var u = 0.05;
          var i = shelf * 2;
          while (u < 0.9) {
            final width = 0.06 + (i % 3) * 0.02;
            final height = 0.18 + (i % 2) * 0.06;
            _rect(
              canvas,
              m,
              u,
              v0,
              u + width,
              v0 + height,
              colours[i % colours.length],
            );
            u += width + 0.01;
            i++;
          }
        }
      case IsoDecal.screen:
        final m = _faceMapper(p, _mainSide(p));
        _rect(canvas, m, 0.08, 0.1, 0.92, 0.9, const Color(0xFF7EC8F0));
        _poly(canvas, m, [
          (0.12, 0.14),
          (0.45, 0.6),
          (0.7, 0.14),
        ], const Color(0xFF5DB85C));
        _poly(canvas, m, [
          (0.72, 0.62),
          (0.8, 0.62),
          (0.8, 0.78),
          (0.72, 0.78),
        ], const Color(0xFFF2C94C));
      case IsoDecal.writing:
        final m = _faceMapper(p, _mainSide(p));
        final ink = p.color.computeLuminance() < 0.3
            ? const Color(0xEEFFFFFF)
            : const Color(0xFF2F6BC4);
        const rows = [
          (0.1, 0.8, 0.55),
          (0.1, 0.62, 0.8),
          (0.1, 0.44, 0.4),
          (0.1, 0.26, 0.7),
        ];
        for (final (u0, v, u1) in rows) {
          _line(canvas, m, u0, v, u1, v, ink, 2);
        }
        _line(canvas, m, 0.75, 0.3, 0.88, 0.45, const Color(0xFFE0524B), 2);
      case IsoDecal.pictures:
        final m = _faceMapper(p, _mainSide(p));
        const colours = [
          Color(0xFFE0524B),
          Color(0xFF4A90D9),
          Color(0xFF5DB85C),
          Color(0xFFF2C94C),
        ];
        for (var i = 0; i < 4; i++) {
          final u0 = 0.06 + (i % 2) * 0.48;
          final v0 = 0.1 + (i ~/ 2) * 0.45;
          _rect(
            canvas,
            m,
            u0,
            v0,
            u0 + 0.4,
            v0 + 0.36,
            const Color(0xFFFFFFFF),
          );
          _rect(
            canvas,
            m,
            u0 + 0.04,
            v0 + 0.05,
            u0 + 0.36,
            v0 + 0.31,
            colours[i],
          );
        }
      case IsoDecal.keys:
        final m = _faceMapper(p, _mainSide(p));
        _rect(canvas, m, 0.02, 0.5, 0.98, 0.64, const Color(0xFFFFFFF0));
        for (var i = 1; i < 14; i++) {
          final u = 0.02 + i * 0.96 / 14;
          _line(canvas, m, u, 0.5, u, 0.64, const Color(0xFF444444), 0.8);
          if (i % 7 != 3 && i % 7 != 0) {
            _rect(
              canvas,
              m,
              u - 0.012,
              0.56,
              u + 0.012,
              0.64,
              const Color(0xFF111111),
            );
          }
        }
      case IsoDecal.pianoKeys:
        // A keyboard seen from above: black keys over the back 60% of the
        // white keys, in the 2-3 grouping of a real piano.
        final m = _faceMapper(p, _Face.top);
        const n = pianoWhiteKeys;
        for (var i = 0; i < n - 1; i++) {
          if (!pianoHasBlackKeyAfter(i)) continue;
          final u = (i + 1) / n;
          _rect(
            canvas,
            m,
            u - 0.3 / n,
            0,
            u + 0.3 / n,
            0.6,
            const Color(0xFF1A1A1A),
          );
        }
      case IsoDecal.hopscotch:
        _paintHopscotch(canvas, p);
      case IsoDecal.lines:
        final face = p.h == 0 ? _Face.top : _mainSide(p);
        final m = _faceMapper(p, face);
        if (face == _Face.top) {
          final stripe = lighten(p.color, 0.18);
          for (var i = 0; i < 8; i += 2) {
            _rect(canvas, m, i / 8, 0, (i + 1) / 8, 1, stripe);
          }
        } else {
          final rung = lighten(p.color, 0.35);
          for (var i = 1; i < 9; i++) {
            _line(canvas, m, 0.04, i / 9, 0.96, i / 9, rung, 2);
          }
        }
      case IsoDecal.leaves:
        final dot = darken(p.color, 0.2);
        final light = lighten(p.color, 0.2);
        for (final face in [_Face.left, _Face.right, _Face.top]) {
          final m = _faceMapper(p, face);
          for (var i = 0; i < 5; i++) {
            final u = 0.15 + (i * 0.37) % 0.75;
            final v = 0.2 + (i * 0.53) % 0.65;
            canvas.drawCircle(
              m(u, v),
              2.5,
              _fill..color = i.isEven ? dot : light,
            );
          }
        }
      case IsoDecal.food:
        final m = _faceMapper(p, _Face.top);
        const colours = [
          Color(0xFFE0524B),
          Color(0xFFF2C94C),
          Color(0xFF5DB85C),
          Color(0xFFF2994A),
          Color(0xFFFFFFFF),
        ];
        var k = 0;
        final cols = p.w > 1 ? 6 : 2;
        for (var i = 0; i < cols; i++) {
          for (var j = 0; j < 2; j++) {
            canvas.drawCircle(
              m((i + 0.5) / cols, 0.3 + j * 0.4),
              p.w > 1 ? 5 : 3,
              _fill..color = colours[k++ % colours.length],
            );
          }
        }
    }
  }

  /// White keys on the hall piano's keyboard — two octaves plus top C,
  /// shared with the close-up detail so the keys line up when it fades in.
  static const int pianoWhiteKeys = 15;

  /// Whether a black key sits between white key [i] and the next, starting
  /// the keyboard on C (C#, D#, F#, G#, A#; none after E or B).
  static bool pianoHasBlackKeyAfter(int i) =>
      const {0, 1, 3, 4, 5}.contains(i % 7);

  static void _paintClock(Canvas canvas, Offset Function(double, double) m) {
    final rim = <Offset>[];
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * math.pi * 2;
      rim.add(m(0.5 + 0.42 * math.cos(a), 0.5 + 0.42 * math.sin(a)));
    }
    canvas.drawPath(
      Path()..addPolygon(rim, true),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawPath(
      Path()..addPolygon(rim, true),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE0524B),
    );
    // The real time — a small nod to "what time is it?" in class.
    final now = DateTime.now();
    final minuteA = now.minute / 60 * math.pi * 2;
    final hourA = ((now.hour % 12) + now.minute / 60) / 12 * math.pi * 2;
    final hand = Paint()
      ..color = const Color(0xFF222222)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      m(0.5, 0.5),
      m(0.5 + 0.34 * math.sin(minuteA), 0.5 + 0.34 * math.cos(minuteA)),
      hand..strokeWidth = 1.5,
    );
    canvas.drawLine(
      m(0.5, 0.5),
      m(0.5 + 0.22 * math.sin(hourA), 0.5 + 0.22 * math.cos(hourA)),
      hand..strokeWidth = 2.5,
    );
  }

  static void _paintHopscotch(Canvas canvas, IsoPart p) {
    final m = _faceMapper(p, _Face.top);
    // Rows from the near end (v = 1) to the far end: 1, 2, 3|4, 5, 6|7, 8.
    const rows = [
      [1],
      [2],
      [3, 4],
      [5],
      [6, 7],
      [8],
    ];
    final chalk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFF4C2);
    for (var r = 0; r < rows.length; r++) {
      final v1 = 1 - r / rows.length;
      final v0 = 1 - (r + 1) / rows.length;
      final cells = rows[r];
      for (var c = 0; c < cells.length; c++) {
        final (u0, u1) = cells.length == 1
            ? (0.25, 0.75)
            : (c * 0.5, (c + 1) * 0.5);
        final path = Path()
          ..addPolygon([m(u0, v0), m(u1, v0), m(u1, v1), m(u0, v1)], true);
        canvas.drawPath(path, Paint()..color = const Color(0x33FFF4C2));
        canvas.drawPath(path, chalk);
        final tp = TextPainter(
          text: TextSpan(
            text: '${cells[c]}',
            style: const TextStyle(
              color: Color(0xFFFFF4C2),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final centre = m((u0 + u1) / 2, (v0 + v1) / 2);
        tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }
}

enum _Face { top, left, right }

/// Axis-aligned 3D bounding box in grid units, used for draw ordering.
class IsoBox {
  final double x0, y0, z0, x1, y1, z1;
  const IsoBox(this.x0, this.y0, this.z0, this.x1, this.y1, this.z1);

  double get depth => (x0 + x1) / 2 + (y0 + y1) / 2 + z0 * 0.01;

  IsoBox union(IsoBox o) => IsoBox(
    math.min(x0, o.x0),
    math.min(y0, o.y0),
    math.min(z0, o.z0),
    math.max(x1, o.x1),
    math.max(y1, o.y1),
    math.max(z1, o.z1),
  );
}
