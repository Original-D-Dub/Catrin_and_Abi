import 'dart:math' as math;
import 'dart:ui';

import '../models/school_scene.dart';
import 'iso_painter.dart';

/// Close-up detail painted over an object's blocks once the child zooms in
/// far enough for small features to be seen — the "level of detail" layer.
///
/// [opacity] fades the detail in (0 → 1) as the zoom crosses the detail
/// threshold, so it never pops. [time] (seconds) drives small animations.
typedef DetailPainter =
    void Function(
      Canvas canvas,
      SchoolObject object,
      double opacity,
      double time,
    );

/// Registry of detail painters, keyed by the last segment of
/// [SchoolObject.nameKey] (e.g. `water_fountain`), so every object of the
/// same kind gets the same detail in any area.
///
/// Only the drinking fountain has close-up detail so far — it's the trial
/// for the approach. To add another object, write a painter here and
/// register it in [_painters]; nothing else needs to change.
class ObjectDetails {
  ObjectDetails._();

  static final Map<String, DetailPainter> _painters = {
    'water_fountain': _waterFountain,
    'piano': _piano,
  };

  static DetailPainter? painterFor(SchoolObject object) =>
      _painters[object.nameKey.split('.').last];

  /// Hand-drawn art painted at every zoom, for shapes plain blocks can't
  /// make recognisable (leaves). Called after the object's blocks with the
  /// current detail opacity — which may be 0 — so an art painter can fold
  /// its own close-up detail in, correctly layered leaf by leaf, rather
  /// than having it painted over the top afterwards.
  static final Map<String, DetailPainter> _art = {
    'plant': _plant,
    'tree': _tree,
    'garden': _garden,
    'fruit_bowl': _fruitBowl,
    'slide': _slide,
  };

  static DetailPainter? artPainterFor(SchoolObject object) =>
      _art[object.nameKey.split('.').last];

  static Offset _p(double x, double y, double z) => IsoPainter.project(x, y, z);

  static Color _o(Color c, double opacity) =>
      c.withValues(alpha: c.a * opacity);

  // ── Drinking fountain ─────────────────────────────────────────────────────
  //
  // Matches the parts in SchoolLayouts.canteen: a tiled splash-back on the
  // x == 0 wall, a steel pedestal, a basin on top, a chrome spout at the
  // back of the basin and a blue push button on the basin's front.

  static void _waterFountain(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    // Origin of the fountain footprint, so the detail follows the parts
    // if the fountain is moved in the layout.
    final basin = object.parts.firstWhere((p) => p.id == 'basin');
    final pedestal = object.parts.firstWhere((p) => p.id == 'pedestal');
    final splash = object.parts.firstWhere((p) => p.id == 'splashback');
    final spout = object.parts.firstWhere((p) => p.id == 'spout');
    final button = object.parts.firstWhere((p) => p.id == 'button');

    final fill = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Splash-back tiles: grout lines across the visible (x = +w) face.
    final sx = splash.x + splash.w;
    stroke
      ..strokeWidth = 0.8
      ..color = _o(const Color(0xAAFFFFFF), opacity);
    for (var i = 1; i < 4; i++) {
      final y = splash.y + splash.d * i / 4;
      canvas.drawLine(
        _p(sx, y, splash.z + 0.02),
        _p(sx, y, splash.z + splash.h - 0.02),
        stroke,
      );
    }
    for (var i = 1; i < 3; i++) {
      final z = splash.z + splash.h * i / 3;
      canvas.drawLine(
        _p(sx, splash.y + 0.02, z),
        _p(sx, splash.y + splash.d - 0.02, z),
        stroke,
      );
    }

    // "Drinking water" sign: white disc with a blue drop, high on the tiles.
    final signCentre = _p(
      sx,
      splash.y + splash.d / 2,
      splash.z + splash.h * 0.8,
    );
    canvas.drawOval(
      Rect.fromCenter(center: signCentre, width: 14, height: 14),
      fill..color = _o(const Color(0xFFFFFFFF), opacity),
    );
    _drop(
      canvas,
      signCentre + const Offset(0, 0.5),
      4.2,
      _o(const Color(0xFF2F80ED), opacity),
    );

    // Pedestal: chrome streak down the front face and a darker kick plate.
    final px = pedestal.x + pedestal.w;
    final kick = [
      _p(px, pedestal.y, 0),
      _p(px, pedestal.y + pedestal.d, 0),
      _p(px, pedestal.y + pedestal.d, 0.08),
      _p(px, pedestal.y, 0.08),
    ];
    canvas.drawPath(
      IsoPainter.roundedPolygon(kick, 2),
      fill..color = _o(const Color(0xFF7D8A94), opacity),
    );
    stroke
      ..strokeWidth = 2
      ..color = _o(const Color(0xCCFFFFFF), opacity);
    final streakY = pedestal.y + pedestal.d * 0.25;
    canvas.drawLine(
      _p(px, streakY, 0.14),
      _p(px, streakY, pedestal.h - 0.08),
      stroke,
    );
    stroke.strokeWidth = 1;
    canvas.drawLine(
      _p(px, streakY + 0.06, 0.2),
      _p(px, streakY + 0.06, pedestal.h - 0.2),
      stroke,
    );
    // Two screws on the front panel.
    for (final z in [0.18, pedestal.h - 0.12]) {
      final c = _p(px, pedestal.y + pedestal.d * 0.75, z);
      canvas.drawCircle(
        c,
        1.4,
        fill..color = _o(const Color(0xFF5F6B73), opacity),
      );
    }

    // Basin bowl: a recessed, rounded dip in the basin top.
    final bz = basin.z + basin.h;
    const rim = 0.08;
    final bowl = IsoPainter.roundedPolygon([
      _p(basin.x + rim, basin.y + rim, bz),
      _p(basin.x + basin.w - rim, basin.y + rim, bz),
      _p(basin.x + basin.w - rim, basin.y + basin.d - rim, bz),
      _p(basin.x + rim, basin.y + basin.d - rim, bz),
    ], 14);
    canvas.drawPath(bowl, fill..color = _o(const Color(0xFF9FB0BC), opacity));
    // Inner shadow along the back of the bowl gives it depth.
    canvas.save();
    canvas.clipPath(bowl);
    canvas.drawPath(
      bowl.shift(const Offset(0, 3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = _o(const Color(0x33000000), opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();

    // Drain: a small grille where the water lands.
    final landX = basin.x + basin.w * 0.68;
    final landY = spout.y + spout.d / 2;
    final drain = _p(landX, landY, bz);
    canvas.drawOval(
      Rect.fromCenter(center: drain, width: 9, height: 5),
      fill..color = _o(const Color(0xFF55636D), opacity),
    );
    stroke
      ..strokeWidth = 0.8
      ..color = _o(const Color(0xFFC9D3DA), opacity);
    canvas.drawLine(
      drain - const Offset(3.5, 0),
      drain + const Offset(3.5, 0),
      stroke,
    );
    canvas.drawLine(
      drain - const Offset(0, 2),
      drain + const Offset(0, 2),
      stroke,
    );

    // Spout nozzle: a chrome tip with a highlight.
    final tip = (
      spout.x + spout.w,
      spout.y + spout.d / 2,
      spout.z + spout.h * 0.75,
    );
    final tipPt = _p(tip.$1, tip.$2, tip.$3);
    canvas.drawOval(
      Rect.fromCenter(center: tipPt, width: 5, height: 4),
      fill..color = _o(const Color(0xFF6F7C86), opacity),
    );
    canvas.drawCircle(
      _p(spout.x + spout.w * 0.4, spout.y + spout.d * 0.3, spout.z + spout.h),
      1.5,
      fill..color = _o(const Color(0xFFFFFFFF), opacity),
    );

    // Water arc: from the nozzle, up a little and down into the drain.
    Offset arc(double t) {
      final x = tip.$1 + (landX - tip.$1) * t;
      final z = tip.$3 + 0.16 * 4 * t * (1 - t) - (tip.$3 - bz) * t;
      return _p(x, landY, z);
    }

    final arcPath = Path()..moveTo(tipPt.dx, tipPt.dy);
    for (var i = 1; i <= 16; i++) {
      final pt = arc(i / 16);
      arcPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      arcPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2
        ..color = _o(const Color(0xAA7FD3FF), opacity),
    );
    canvas.drawPath(
      arcPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1
        ..color = _o(const Color(0xDDFFFFFF), opacity),
    );
    // Droplets running along the arc.
    for (var i = 0; i < 3; i++) {
      final t = (time * 0.9 + i / 3) % 1.0;
      canvas.drawCircle(
        arc(t),
        1.6,
        fill..color = _o(const Color(0xFFFFFFFF), opacity),
      );
    }
    // Ripples where the water lands, growing and fading.
    for (var i = 0; i < 2; i++) {
      final k = (time * 0.8 + i / 2) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: drain, width: 6 + 12 * k, height: 3 + 6 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _o(const Color(0xFFFFFFFF), opacity * (1 - k)),
      );
    }

    // Push button: a round blue button with a drop on it, and a soft glow
    // ring that pulses to say "press me".
    final bx = button.x + button.w;
    final bc = _p(bx, button.y + button.d / 2, button.z + button.h / 2);
    final pulse = 0.5 + 0.5 * math.sin(time * 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: bc,
        width: 12 + 3 * pulse,
        height: 10 + 3 * pulse,
      ),
      Paint()..color = _o(const Color(0x552F80ED), opacity * pulse),
    );
    canvas.drawOval(
      Rect.fromCenter(center: bc, width: 9, height: 8),
      fill..color = _o(const Color(0xFF2F80ED), opacity),
    );
    _drop(
      canvas,
      bc + const Offset(0, 0.3),
      2.6,
      _o(const Color(0xFFFFFFFF), opacity),
    );
  }

  // ── Piano ─────────────────────────────────────────────────────────────────
  //
  // Matches the parts in SchoolLayouts.hall: an upright case, a keybed with
  // the keys on top, a music stand holding sheet music, three gold pedals
  // and a red stool. The keyboard's front faces +y (the left-facing side).

  static void _piano(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    IsoPart part(String id) => object.parts.firstWhere((p) => p.id == id);
    final pianoCase = part('case');
    final keybed = part('keybed');
    final keys = part('keys');
    final music = part('music');
    final stool = part('stool');
    final pedals = object.parts
        .where((p) => p.id?.startsWith('pedal') ?? false)
        .toList();

    final fill = Paint()..isAntiAlias = true;
    Paint line(Color c, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = _o(c, opacity);

    // Face mappers: `front` is the +y face, `top` the upper face;
    // u runs along x, v up (front) or towards the player (top).
    Offset front(IsoPart p, double u, double v) =>
        _p(p.x + u * p.w, p.y + p.d, p.z + v * p.h);
    Offset top(IsoPart p, double u, double v) =>
        _p(p.x + u * p.w, p.y + v * p.d, p.z + p.h);
    Path frontRect(
      IsoPart p,
      double u0,
      double v0,
      double u1,
      double v1,
      double r,
    ) => IsoPainter.roundedPolygon([
      front(p, u0, v0),
      front(p, u1, v0),
      front(p, u1, v1),
      front(p, u0, v1),
    ], r);

    // Case: a carved panel on the lower front, and a glossy sheen on the
    // lid and the side so it reads as polished black wood.
    canvas.drawPath(
      frontRect(pianoCase, 0.12, 0.08, 0.88, 0.4, 4),
      line(const Color(0xFF6A6A6A), 1.2),
    );
    canvas.drawPath(
      frontRect(pianoCase, 0.16, 0.12, 0.84, 0.36, 3),
      line(const Color(0xFF4A4A4A), 0.8),
    );
    canvas.drawLine(
      top(pianoCase, 0.15, 0.2),
      top(pianoCase, 0.55, 0.85),
      line(const Color(0x66FFFFFF), 3),
    );
    canvas.drawLine(
      top(pianoCase, 0.62, 0.2),
      top(pianoCase, 0.72, 0.5),
      line(const Color(0x44FFFFFF), 2),
    );
    final sideX = pianoCase.x + pianoCase.w;
    canvas.drawLine(
      _p(sideX, pianoCase.y + pianoCase.d * 0.3, 0.15),
      _p(sideX, pianoCase.y + pianoCase.d * 0.3, pianoCase.h - 0.1),
      line(const Color(0x33FFFFFF), 2.5),
    );
    // Lid hinge.
    canvas.drawLine(
      top(pianoCase, 0.05, 0.72),
      top(pianoCase, 0.95, 0.72),
      line(const Color(0xFF8C8C8C), 0.8),
    );

    // Gold nameplate on the keybed's front rail.
    canvas.drawPath(
      frontRect(keybed, 0.43, 0.25, 0.57, 0.75, 2),
      fill..color = _o(const Color(0xFFE0B040), opacity),
    );
    canvas.drawLine(
      front(keybed, 0.46, 0.5),
      front(keybed, 0.54, 0.5),
      line(const Color(0xFF8A6A1E), 0.7),
    );

    // Keys: a line between every white key, a lip along the front edge,
    // and a glint on each black key.
    const n = IsoPainter.pianoWhiteKeys;
    final keyLine = line(const Color(0xFFB9B2A0), 0.6);
    for (var i = 1; i < n; i++) {
      canvas.drawLine(top(keys, i / n, 0.02), top(keys, i / n, 0.98), keyLine);
    }
    canvas.drawLine(
      top(keys, 0, 0.97),
      top(keys, 1, 0.97),
      line(const Color(0xFFE6DFCB), 1),
    );
    final glint = line(const Color(0x88FFFFFF), 0.8);
    for (var i = 0; i < n - 1; i++) {
      if (!IsoPainter.pianoHasBlackKeyAfter(i)) continue;
      final u = (i + 1) / n;
      canvas.drawLine(
        top(keys, u - 0.1 / n, 0.08),
        top(keys, u - 0.1 / n, 0.5),
        glint,
      );
    }

    // Sheet music: two staves, a bar line, and a little tune.
    final staff = line(const Color(0xFF7A7A7A), 0.5);
    for (final base in [0.58, 0.18]) {
      for (var l = 0; l < 5; l++) {
        final v = base + l * 0.055;
        canvas.drawLine(front(music, 0.08, v), front(music, 0.92, v), staff);
      }
      canvas.drawLine(
        front(music, 0.5, base),
        front(music, 0.5, base + 0.22),
        staff,
      );
      // Notes: (u, line position 0-4) — a rising and falling tune.
      const tune = [
        (0.18, 0.5),
        (0.3, 1.5),
        (0.42, 2.5),
        (0.6, 3.0),
        (0.72, 2.0),
        (0.84, 1.0),
      ];
      for (final (u, pos) in tune) {
        final head = front(music, u, base + pos * 0.055);
        canvas.drawOval(
          Rect.fromCenter(center: head, width: 3.2, height: 2.4),
          fill..color = _o(const Color(0xFF222222), opacity),
        );
        canvas.drawLine(
          head + const Offset(1.4, 0),
          head + const Offset(1.4, -6),
          line(const Color(0xFF222222), 0.6),
        );
      }
    }
    // Title bar across the top of the sheet.
    canvas.drawLine(
      front(music, 0.3, 0.92),
      front(music, 0.7, 0.92),
      line(const Color(0xFFB0B0B0), 1.2),
    );

    // Pedals: shiny gold tops.
    for (final pedal in pedals) {
      canvas.drawCircle(
        top(pedal, 0.5, 0.6),
        1.3,
        fill..color = _o(const Color(0xFFFFF1B8), opacity),
      );
    }

    // Stool: piping round the cushion and three buttons tufted into it.
    canvas.drawPath(
      IsoPainter.roundedPolygon([
        top(stool, 0.04, 0.08),
        top(stool, 0.96, 0.08),
        top(stool, 0.96, 0.92),
        top(stool, 0.04, 0.92),
      ], 6),
      line(const Color(0xFFE88A95), 1),
    );
    for (final u in [0.25, 0.5, 0.75]) {
      final c = top(stool, u, 0.5);
      canvas.drawCircle(
        c,
        1.8,
        fill..color = _o(const Color(0xFF7E2230), opacity),
      );
      canvas.drawCircle(
        c - const Offset(0.5, 0.5),
        0.6,
        fill..color = _o(const Color(0x88FFFFFF), opacity),
      );
    }

    // Music notes floating up from the piano, swaying and fading — a
    // playful cue that this makes music.
    const noteColours = [
      Color(0xFFE91E63),
      Color(0xFF2F80ED),
      Color(0xFFF2994A),
    ];
    for (var i = 0; i < 3; i++) {
      final phase = (time * 0.3 + i / 3) % 1.0;
      final alpha = math.sin(phase * math.pi) * opacity;
      if (alpha <= 0.01) continue;
      final base = _p(
        pianoCase.x + pianoCase.w * (0.3 + 0.2 * i),
        pianoCase.y + pianoCase.d / 2,
        pianoCase.z + pianoCase.h + 0.15 + phase * 0.9,
      );
      final c = base + Offset(math.sin(phase * math.pi * 2 + i) * 6, 0);
      _musicNote(
        canvas,
        c,
        noteColours[i].withValues(alpha: alpha),
        beamed: i == 1,
      );
    }
  }

  /// A cartoon quaver (or a pair of beamed quavers when [beamed]) with its
  /// note head centred on [c].
  static void _musicNote(
    Canvas canvas,
    Offset c,
    Color colour, {
    bool beamed = false,
  }) {
    final fill = Paint()..color = colour;
    final stem = Paint()
      ..color = colour
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    void head(Offset h) {
      canvas.save();
      canvas.translate(h.dx, h.dy);
      canvas.rotate(-0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 5),
        fill,
      );
      canvas.restore();
    }

    head(c);
    final stemTop = c + const Offset(3, -12);
    canvas.drawLine(c + const Offset(3, -1), stemTop, stem);
    if (beamed) {
      final c2 = c + const Offset(9, -2);
      head(c2);
      final stemTop2 = c2 + const Offset(3, -12);
      canvas.drawLine(c2 + const Offset(3, -1), stemTop2, stem);
      canvas.drawLine(stemTop, stemTop2, stem..strokeWidth = 3);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(stemTop.dx, stemTop.dy)
          ..quadraticBezierTo(
            stemTop.dx + 6,
            stemTop.dy + 3,
            stemTop.dx + 4,
            stemTop.dy + 8,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = colour,
      );
    }
  }

  // ── Plant ─────────────────────────────────────────────────────────────────
  //
  // A leafy house plant, drawn at every zoom: big two-tone leaves with a
  // clear outline and centre vein on green stems, springing from the soil
  // in the terracotta pot (SchoolLayouts.classroom). Close up it gains side
  // veins, shine, soil crumbs, a spotty pot band and a ladybird.

  /// Leaves as (direction in degrees around the stem, angle up from
  /// horizontal in degrees, length in grid units, width as a fraction of
  /// length). Directions avoid pointing into the wall behind (−x).
  static const List<(double, double, double, double)> _plantLeaves = [
    (225, 62, 0.55, 0.3),
    (275, 58, 0.6, 0.3),
    (320, 42, 0.55, 0.32),
    (180, 55, 0.45, 0.3),
    (5, 38, 0.55, 0.32),
    (40, 48, 0.6, 0.3),
    (85, 42, 0.58, 0.32),
    (130, 38, 0.52, 0.3),
    (60, 72, 0.66, 0.28),
    (150, 70, 0.6, 0.28),
    (250, 80, 0.62, 0.26),
  ];

  static void _plant(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    final soil = object.parts.firstWhere((p) => p.id == 'soil');
    final pot = object.parts.firstWhere((p) => p.id == 'pot');
    final rim = object.parts.firstWhere((p) => p.id == 'rim');
    final cx = soil.x + soil.w / 2;
    final cy = soil.y + soil.d / 2;
    final cz = soil.z;

    // ── Close-up: pot band and soil, under the leaves ──
    if (opacity > 0) {
      // A row of cream spots round the pot, like a painted pot.
      final spot = Paint()..color = _o(const Color(0xFFFFF1D6), opacity);
      for (var i = 0; i < 4; i++) {
        final u = (i + 0.5) / 4;
        canvas.drawCircle(
          _p(pot.x + u * pot.w, pot.y + pot.d, pot.h * 0.45),
          2,
          spot,
        );
        canvas.drawCircle(
          _p(pot.x + pot.w, pot.y + u * pot.d, pot.h * 0.45),
          2,
          spot,
        );
      }
      // Shine on the rim.
      canvas.drawLine(
        _p(rim.x + rim.w * 0.1, rim.y + rim.d, rim.z + rim.h * 0.6),
        _p(rim.x + rim.w * 0.6, rim.y + rim.d, rim.z + rim.h * 0.6),
        Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = _o(const Color(0x88FFFFFF), opacity),
      );
      // Soil crumbs and a pebble.
      final crumb = Paint()..color = _o(const Color(0xFF4A3220), opacity);
      const crumbs = [
        (0.2, 0.3),
        (0.7, 0.25),
        (0.35, 0.75),
        (0.8, 0.7),
        (0.55, 0.5),
        (0.15, 0.6),
      ];
      for (final (u, v) in crumbs) {
        canvas.drawCircle(
          _p(soil.x + u * soil.w, soil.y + v * soil.d, cz),
          1.1,
          crumb,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: _p(soil.x + 0.75 * soil.w, soil.y + 0.45 * soil.d, cz),
          width: 5,
          height: 3,
        ),
        Paint()..color = _o(const Color(0xFFB8B0A4), opacity),
      );
    }

    // ── Leaves, back to front ──
    final stemBase = _p(cx, cy, cz);
    final leaves =
        <
          ({
            Offset base,
            Offset control,
            Offset tip,
            double width,
            bool facing,
            double depth,
          })
        >[];
    for (var i = 0; i < _plantLeaves.length; i++) {
      final (az, el, len, widthK) = _plantLeaves[i];
      // A gentle sway, each leaf out of step with the others.
      final a = (az + math.sin(time * 1.1 + i * 1.7) * 3) * math.pi / 180;
      final e = el * math.pi / 180;
      final dx = math.cos(a), dy = math.sin(a);
      final reach = len * math.cos(e);
      final rise = len * math.sin(e);
      // Leaf base a little way up its stem; the midrib bows upward then
      // the tip droops slightly, like a real leaf.
      final base = _p(cx + dx * 0.06, cy + dy * 0.06, cz + 0.12);
      final control = _p(
        cx + dx * reach * 0.55,
        cy + dy * reach * 0.55,
        cz + 0.12 + rise * 1.05,
      );
      final tipX = cx + dx * reach, tipY = cy + dy * reach;
      final tip = _p(tipX, tipY, cz + 0.12 + rise * 0.8);
      leaves.add((
        base: base,
        control: control,
        tip: tip,
        width: widthK,
        // Leaves turned towards the viewer (+x/+y) catch more light.
        facing: dx + dy > -0.2,
        depth: tipX + tipY,
      ));
    }
    leaves.sort((a, b) => a.depth.compareTo(b.depth));

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = const Color(0xFF3F7F32);

    var ladybirdDone = false;
    for (var i = 0; i < leaves.length; i++) {
      final leaf = leaves[i];
      // Stem from the soil to the leaf.
      canvas.drawLine(stemBase, leaf.base, stemPaint);
      final bulge = _drawLeaf(
        canvas,
        leaf.base,
        leaf.control,
        leaf.tip,
        leaf.width,
        facing: leaf.facing,
        detailOpacity: opacity,
      );
      // A ladybird on the frontmost forward-facing leaf, close up.
      if (opacity > 0 &&
          bulge != null &&
          !ladybirdDone &&
          leaf.facing &&
          i >= leaves.length - 3) {
        ladybirdDone = true;
        final at = _bez(leaf.base, leaf.control, leaf.tip, 0.55) + bulge * 0.25;
        _ladybird(canvas, at, _o, opacity);
      }
    }
  }

  // ── Shared drawing helpers ────────────────────────────────────────────────

  static Paint _stroke(Color c, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = c;

  /// A cartoon ball (fruit, canopy clump): a base colour with a lighter
  /// upper-left, a dark outline and a small shine.
  static void _ball(
    Canvas canvas,
    Offset c,
    double r,
    Color colour, {
    double outline = 1.3,
    bool shine = true,
  }) {
    canvas.drawCircle(c, r, Paint()..color = IsoPainter.darken(colour, 0.12));
    canvas.drawCircle(
      c + Offset(-r * 0.14, -r * 0.16),
      r * 0.8,
      Paint()..color = colour,
    );
    canvas.drawCircle(c, r, _stroke(IsoPainter.darken(colour, 0.5), outline));
    if (shine) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(-r * 0.38, -r * 0.42),
          width: r * 0.55,
          height: r * 0.32,
        ),
        Paint()..color = const Color(0x99FFFFFF),
      );
    }
  }

  /// Points round a horizontal circle of radius [r] (grid units) centred
  /// on ([cx], [cy], [z]), from angle [from] to [to] (radians, 0 = +x).
  static List<Offset> _isoArc(
    double cx,
    double cy,
    double z,
    double r,
    double from,
    double to, {
    int steps = 24,
  }) => [
    for (var i = 0; i <= steps; i++)
      _p(
        cx + r * math.cos(from + (to - from) * i / steps),
        cy + r * math.sin(from + (to - from) * i / steps),
        z,
      ),
  ];

  // ── Tree ──────────────────────────────────────────────────────────────────
  //
  // A classic picture-book tree: a brown trunk block topped by a big round
  // crown of leafy clumps, with separate leaves peeping out round its edge.
  // Close up: bark lines and a knot hole, leaves across the clumps, red
  // apples, and a little bird.

  /// Crown clumps as (dx, dy, dz, radius), grid units from the crown centre.
  static const List<(double, double, double, double)> _treeClumps = [
    (0.0, 0.0, -0.25, 0.42),
    (-0.38, 0.05, 0.05, 0.4),
    (0.05, -0.38, 0.1, 0.4),
    (-0.2, -0.22, 0.45, 0.38),
    (0.0, 0.0, 0.6, 0.42),
    (0.38, 0.05, 0.0, 0.4),
    (0.05, 0.38, -0.05, 0.4),
    (0.25, 0.25, 0.35, 0.4),
  ];

  static void _tree(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    final trunk = object.parts.firstWhere((p) => p.id == 'trunk');
    final cx = trunk.x + trunk.w / 2;
    final cy = trunk.y + trunk.d / 2;
    final cz = trunk.z + trunk.h + 0.55;
    // A slow sway of the whole crown.
    final sway = Offset(math.sin(time * 0.8 + cx) * 1.2, 0);
    const unitPx = IsoPainter.unitHeight;

    // Close up: bark on the trunk's two visible faces, and a knot hole.
    if (opacity > 0) {
      final bark = _stroke(_o(const Color(0xFF5E3E22), opacity), 0.8);
      final fx = trunk.x + trunk.w, fy = trunk.y + trunk.d;
      for (var i = 0; i < 3; i++) {
        final u = (i + 0.5) / 3;
        final wave = i.isEven ? 0.04 : -0.04;
        canvas.drawPath(
          Path()
            ..moveTo(
              _p(trunk.x + u * trunk.w, fy, 0.1).dx,
              _p(trunk.x + u * trunk.w, fy, 0.1).dy,
            )
            ..quadraticBezierTo(
              _p(trunk.x + (u + wave) * trunk.w, fy, trunk.h * 0.5).dx,
              _p(trunk.x + (u + wave) * trunk.w, fy, trunk.h * 0.5).dy,
              _p(trunk.x + u * trunk.w, fy, trunk.h * 0.9).dx,
              _p(trunk.x + u * trunk.w, fy, trunk.h * 0.9).dy,
            ),
          bark,
        );
        canvas.drawLine(
          _p(fx, trunk.y + u * trunk.d, 0.1),
          _p(fx, trunk.y + u * trunk.d, trunk.h * 0.85),
          bark,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: _p(trunk.x + trunk.w * 0.5, fy, trunk.h * 0.55),
          width: 5,
          height: 6,
        ),
        Paint()..color = _o(const Color(0xFF3B2614), opacity),
      );
    }

    // Leaves peeping out round the crown's edge (drawn first, so the
    // clumps cover their bases).
    final centre = _p(cx, cy, cz) + sway;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2 + 0.2;
      final out = Offset(math.cos(a), math.sin(a) * 0.8);
      final base = centre + out * (unitPx * 0.62);
      final tip = centre + out * (unitPx * 0.98);
      final control =
          Offset.lerp(base, tip, 0.5)! + Offset(-out.dy, out.dx) * 3;
      _drawLeaf(
        canvas,
        base,
        control,
        tip,
        0.32,
        facing: out.dy > -0.2,
        detailOpacity: opacity,
        outlineWidth: 1.2,
      );
    }

    // Crown clumps, back to front.
    final clumps = [..._treeClumps]
      ..sort(
        (a, b) =>
            (a.$1 + a.$2 + a.$3 * 0.6).compareTo(b.$1 + b.$2 + b.$3 * 0.6),
      );
    for (final (dx, dy, dz, r) in clumps) {
      final c = _p(cx + dx, cy + dy, cz + dz) + sway;
      // Lower clumps sit in shade; higher ones catch the sun.
      final colour = Color.lerp(
        const Color(0xFF3F9A3E),
        const Color(0xFF6CC85A),
        ((dz + 0.25) / 0.85).clamp(0.0, 1.0),
      )!;
      _ball(canvas, c, r * unitPx, colour, outline: 1.6, shine: false);
    }

    if (opacity <= 0) return;

    // Close up: little leaves across the front of the crown.
    for (final (dx, dy, dz, r) in clumps.where((c) => c.$1 + c.$2 >= 0)) {
      final c = _p(cx + dx, cy + dy, cz + dz) + sway;
      for (var k = 0; k < 3; k++) {
        final a = k * 2.1 + dx * 5;
        final at = c + Offset(math.cos(a), math.sin(a)) * (r * unitPx * 0.45);
        final dir = Offset(math.cos(a + 0.8), math.sin(a + 0.8)) * 5.5;
        _drawLeaf(
          canvas,
          at - dir,
          at + Offset(-dir.dy, dir.dx) * 0.2,
          at + dir,
          0.3,
          detailOpacity: opacity,
          outlineWidth: 0.7,
        );
      }
    }
    // Apples.
    const apples = [
      (-0.3, 0.3, 0.1),
      (0.35, 0.2, 0.3),
      (0.1, 0.45, -0.1),
      (0.4, -0.1, -0.05),
    ];
    for (final (dx, dy, dz) in apples) {
      final c = _p(cx + dx, cy + dy, cz + dz) + sway;
      canvas.drawLine(
        c + const Offset(0, -3.5),
        c + const Offset(0.8, -6),
        _stroke(_o(const Color(0xFF5E3E22), opacity), 0.9),
      );
      _ball(canvas, c, 3.6, _o(const Color(0xFFE53935), opacity), outline: 0.9);
    }
    // A little bird on top, bobbing.
    final bird =
        _p(cx + 0.1, cy + 0.1, cz + 1.02) +
        sway +
        Offset(0, math.sin(time * 4) * 0.8);
    _bird(canvas, bird, opacity);
  }

  static void _bird(Canvas canvas, Offset c, double opacity) {
    final body = Paint()..color = _o(const Color(0xFF4A90D9), opacity);
    canvas.drawOval(Rect.fromCenter(center: c, width: 10, height: 7), body);
    canvas.drawCircle(c + const Offset(4, -3), 3, body);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(-1, 1), width: 6, height: 3.5),
      Paint()..color = _o(const Color(0xFFBFE3F7), opacity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + 6.5, c.dy - 3.5)
        ..lineTo(c.dx + 9, c.dy - 2.6)
        ..lineTo(c.dx + 6.5, c.dy - 1.8)
        ..close(),
      Paint()..color = _o(const Color(0xFFF2994A), opacity),
    );
    canvas.drawCircle(
      c + const Offset(5, -3.6),
      0.8,
      Paint()..color = _o(const Color(0xFF1A1A1A), opacity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 4.5, c.dy)
        ..lineTo(c.dx - 8.5, c.dy - 2.5)
        ..lineTo(c.dx - 8, c.dy + 1)
        ..close(),
      body,
    );
  }

  // ── Garden bed ────────────────────────────────────────────────────────────
  //
  // A back row of flowers (sunflowers, tulips, a daisy) and a front row of
  // vegetables (carrots, lettuces) growing in the raised bed's soil.
  // Close up: plank seams, seeds in the sunflowers, carrot ridges, plant
  // labels, and a buzzing bee.

  static void _garden(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    final bed = object.parts.firstWhere((p) => p.id == 'bed');
    final soil = object.parts.firstWhere((p) => p.id == 'soil');
    Offset at(double u, double v, [double dz = 0]) =>
        _p(soil.x + u * soil.w, soil.y + v * soil.d, soil.z + dz);

    if (opacity > 0) {
      // Plank seams on the bed's two visible sides.
      final seam = _stroke(_o(const Color(0xFF8D6038), opacity), 1);
      canvas.drawLine(
        _p(bed.x + 0.05, bed.y + bed.d, bed.h / 2),
        _p(bed.x + bed.w - 0.05, bed.y + bed.d, bed.h / 2),
        seam,
      );
      canvas.drawLine(
        _p(bed.x + bed.w, bed.y + 0.05, bed.h / 2),
        _p(bed.x + bed.w, bed.y + bed.d - 0.05, bed.h / 2),
        seam,
      );
      final nail = Paint()..color = _o(const Color(0xFF6B6B6B), opacity);
      for (final u in [0.03, 0.5, 0.97]) {
        for (final v in [0.25, 0.75]) {
          canvas.drawCircle(
            _p(bed.x + u * bed.w, bed.y + bed.d, bed.h * v),
            0.9,
            nail,
          );
        }
      }
    }

    // Plants in draw order: back row first, left to right.
    final sway = math.sin(time * 1.3) * 1.2;
    _flower(canvas, at(0.12, 0.3), 0.75, _FlowerKind.sunflower, opacity, sway);
    _flower(canvas, at(0.34, 0.3), 0.42, _FlowerKind.tulipRed, opacity, -sway);
    _flower(canvas, at(0.56, 0.3), 0.36, _FlowerKind.daisy, opacity, sway);
    _flower(
      canvas,
      at(0.78, 0.3),
      0.44,
      _FlowerKind.tulipYellow,
      opacity,
      -sway,
    );
    _flower(canvas, at(0.94, 0.28), 0.68, _FlowerKind.sunflower, opacity, sway);
    _carrot(canvas, at(0.1, 0.72), opacity, sway);
    _lettuce(canvas, at(0.28, 0.72), opacity);
    _carrot(canvas, at(0.46, 0.72), opacity, -sway);
    _carrot(canvas, at(0.62, 0.72), opacity, sway);
    _lettuce(canvas, at(0.82, 0.72), opacity);

    if (opacity <= 0) return;

    // Plant labels on sticks at the front edge.
    for (final (u, colour) in [
      (0.18, const Color(0xFFF2994A)),
      (0.72, const Color(0xFF5DB85C)),
    ]) {
      final foot = at(u, 0.97);
      final top = foot + const Offset(0, -9);
      canvas.drawLine(
        foot,
        top,
        _stroke(_o(const Color(0xFFC8955C), opacity), 1.2),
      );
      final label = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: top + const Offset(0, -2.5),
          width: 9,
          height: 6,
        ),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        label,
        Paint()..color = _o(const Color(0xFFFFFFFF), opacity),
      );
      canvas.drawRRect(label, _stroke(_o(colour, opacity), 1));
    }

    // A bee buzzing in a loop over the flowers.
    final t = time * 0.9;
    final bee =
        at(0.5 + 0.4 * math.sin(t), 0.3, 0.9) + Offset(0, 6 * math.sin(t * 2));
    _bee(canvas, bee, opacity, time, facingRight: math.cos(t) > 0);
  }

  static void _flower(
    Canvas canvas,
    Offset soilPt,
    double height,
    _FlowerKind kind,
    double opacity,
    double sway,
  ) {
    final head = soilPt + Offset(sway, -height * IsoPainter.unitHeight);
    // Stem, curving slightly.
    canvas.drawPath(
      Path()
        ..moveTo(soilPt.dx, soilPt.dy)
        ..quadraticBezierTo(
          soilPt.dx - 2,
          (soilPt.dy + head.dy) / 2,
          head.dx,
          head.dy,
        ),
      _stroke(const Color(0xFF3F7F32), 1.8),
    );
    // Two leaves on the stem.
    final leafAt = Offset.lerp(soilPt, head, 0.35)!;
    final size = kind == _FlowerKind.sunflower ? 10.0 : 7.0;
    _drawLeaf(
      canvas,
      leafAt,
      leafAt + Offset(size * 0.5, -size * 0.6),
      leafAt + Offset(size, -size * 0.3),
      0.32,
      detailOpacity: opacity,
      outlineWidth: 0.9,
    );
    _drawLeaf(
      canvas,
      leafAt + const Offset(0, 3),
      leafAt + Offset(-size * 0.5, -size * 0.4),
      leafAt + Offset(-size, -size * 0.1),
      0.32,
      facing: false,
      detailOpacity: opacity,
      outlineWidth: 0.9,
    );

    switch (kind) {
      case _FlowerKind.sunflower:
        _petalRing(
          canvas,
          head,
          12,
          8.5,
          4.2,
          const Color(0xFFFFC928),
          const Color(0xFFB8860B),
          opacity,
        );
        _ball(
          canvas,
          head,
          4.4,
          const Color(0xFF7A4A1E),
          outline: 1,
          shine: false,
        );
        if (opacity > 0) {
          final seed = Paint()..color = _o(const Color(0xFF4A2A0E), opacity);
          for (var i = 0; i < 7; i++) {
            final a = i * 2.4;
            final r = 1.2 + (i % 3) * 0.9;
            canvas.drawCircle(
              head + Offset(math.cos(a), math.sin(a)) * r,
              0.55,
              seed,
            );
          }
        }
      case _FlowerKind.daisy:
        _petalRing(
          canvas,
          head,
          9,
          5.5,
          2.6,
          const Color(0xFFFFFFFF),
          const Color(0xFFB0B0B0),
          opacity,
        );
        _ball(
          canvas,
          head,
          2.4,
          const Color(0xFFFFC928),
          outline: 0.8,
          shine: false,
        );
      case _FlowerKind.tulipRed:
      case _FlowerKind.tulipYellow:
        final colour = kind == _FlowerKind.tulipRed
            ? const Color(0xFFE53935)
            : const Color(0xFFFFD54F);
        final cup = Path()
          ..moveTo(head.dx - 4.5, head.dy - 5)
          ..lineTo(head.dx - 2.2, head.dy - 2.5)
          ..lineTo(head.dx, head.dy - 6)
          ..lineTo(head.dx + 2.2, head.dy - 2.5)
          ..lineTo(head.dx + 4.5, head.dy - 5)
          ..quadraticBezierTo(head.dx + 5, head.dy + 3, head.dx, head.dy + 2)
          ..quadraticBezierTo(
            head.dx - 5,
            head.dy + 3,
            head.dx - 4.5,
            head.dy - 5,
          )
          ..close();
        canvas.drawPath(cup, Paint()..color = colour);
        canvas.drawPath(cup, _stroke(IsoPainter.darken(colour, 0.45), 1));
        if (opacity > 0) {
          canvas.drawLine(
            head + const Offset(0, -2),
            head + const Offset(0, 1.5),
            _stroke(_o(IsoPainter.darken(colour, 0.25), opacity), 0.6),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: head + const Offset(-2.2, -1),
              width: 1.6,
              height: 3.5,
            ),
            Paint()..color = _o(const Color(0x88FFFFFF), opacity),
          );
        }
    }
  }

  /// A ring of [count] petals of length [len] and width [width] round
  /// [c], each outlined, with a centre line when close up.
  static void _petalRing(
    Canvas canvas,
    Offset c,
    int count,
    double len,
    double width,
    Color colour,
    Color edge,
    double opacity,
  ) {
    for (var i = 0; i < count; i++) {
      final a = i / count * math.pi * 2;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      final petal = Rect.fromCenter(
        center: Offset(len * 0.55, 0),
        width: len,
        height: width,
      );
      canvas.drawOval(petal, Paint()..color = colour);
      canvas.drawOval(petal, _stroke(edge, 0.7));
      if (opacity > 0) {
        canvas.drawLine(
          Offset(len * 0.25, 0),
          Offset(len * 0.85, 0),
          _stroke(_o(edge, opacity * 0.6), 0.4),
        );
      }
      canvas.restore();
    }
  }

  static void _carrot(
    Canvas canvas,
    Offset soilPt,
    double opacity,
    double sway,
  ) {
    // Feathery tops fanning up out of the soil.
    for (final (dx, h) in const [(-5.0, 14.0), (0.0, 17.0), (5.0, 14.0)]) {
      final tip = soilPt + Offset(dx + sway, -h);
      _drawLeaf(
        canvas,
        soilPt + const Offset(0, -2),
        Offset.lerp(soilPt, tip, 0.5)! + Offset(dx * 0.2, 0),
        tip,
        0.2,
        detailOpacity: opacity,
        outlineWidth: 0.8,
      );
    }
    // Orange shoulder poking out of the ground.
    final shoulder = Path()
      ..moveTo(soilPt.dx - 4, soilPt.dy - 1)
      ..quadraticBezierTo(
        soilPt.dx,
        soilPt.dy - 5,
        soilPt.dx + 4,
        soilPt.dy - 1,
      )
      ..quadraticBezierTo(
        soilPt.dx,
        soilPt.dy + 3,
        soilPt.dx - 4,
        soilPt.dy - 1,
      )
      ..close();
    canvas.drawPath(shoulder, Paint()..color = const Color(0xFFF57C00));
    canvas.drawPath(shoulder, _stroke(const Color(0xFF9A4A00), 0.9));
    if (opacity > 0) {
      final ridge = _stroke(_o(const Color(0xFFB85C00), opacity), 0.5);
      canvas.drawLine(
        soilPt + const Offset(-2, -1),
        soilPt + const Offset(-1, 0.6),
        ridge,
      );
      canvas.drawLine(
        soilPt + const Offset(1.5, -1.5),
        soilPt + const Offset(2.2, 0.2),
        ridge,
      );
    }
  }

  static void _lettuce(Canvas canvas, Offset soilPt, double opacity) {
    // Overlapping round leaves, outer (darker) first, heart (lighter) last.
    const leaves = [
      (-5.5, -3.0, 5.0, Color(0xFF4FAE45)),
      (5.5, -3.0, 5.0, Color(0xFF4FAE45)),
      (0.0, -6.5, 5.0, Color(0xFF5DBE50)),
      (-3.0, -2.0, 4.5, Color(0xFF7FD06A)),
      (3.0, -2.0, 4.5, Color(0xFF7FD06A)),
      (0.0, -3.5, 3.5, Color(0xFFA8E08F)),
    ];
    for (final (dx, dy, r, colour) in leaves) {
      final c = soilPt + Offset(dx, dy);
      canvas.drawCircle(c, r, Paint()..color = colour);
      canvas.drawCircle(c, r, _stroke(const Color(0xFF2E6B2F), 1));
      if (opacity > 0) {
        canvas.drawLine(
          c + Offset(0, r * 0.7),
          c - Offset(0, r * 0.5),
          _stroke(_o(const Color(0xFFD4F2C4), opacity), 0.6),
        );
      }
    }
  }

  static void _bee(
    Canvas canvas,
    Offset c,
    double opacity,
    double time, {
    required bool facingRight,
  }) {
    final flip = facingRight ? 1.0 : -1.0;
    // Wings, flickering.
    final flap = 0.6 + 0.4 * math.sin(time * 40).abs();
    final wing = Paint()..color = _o(const Color(0xCCFFFFFF), opacity);
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-1.5 * flip, -3.5),
        width: 4,
        height: 5 * flap,
      ),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(1 * flip, -3.8),
        width: 4,
        height: 5 * flap,
      ),
      wing,
    );
    // Striped body.
    final body = Rect.fromCenter(center: c, width: 8, height: 5.5);
    canvas.drawOval(
      body,
      Paint()..color = _o(const Color(0xFFFFC928), opacity),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)));
    final stripe = Paint()..color = _o(const Color(0xFF1A1A1A), opacity);
    for (final dx in [-1.5, 1.2]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: c + Offset(dx * flip, 0),
          width: 1.3,
          height: 6,
        ),
        stripe,
      );
    }
    canvas.restore();
    canvas.drawOval(body, _stroke(_o(const Color(0xFF1A1A1A), opacity), 0.7));
    canvas.drawCircle(c + Offset(3 * flip, -0.6), 0.6, stripe);
  }

  // ── Slide ─────────────────────────────────────────────────────────────────
  //
  // A playground slide: a yellow chute sloping straight down from the
  // climbing frame's platform, with red side rails, a short flat run-out
  // at the bottom and blue legs. Close up: a shine down the chute, bolts
  // along the rails and grab handles at the top.

  static void _slide(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    final box = object.parts.firstWhere((p) => p.id == 'chute');
    const rail = 0.16; // Rail height above the bed.
    const thick = 0.1; // Chute thickness below the bed.
    const runOut = 0.45; // Flat section at the bottom.
    final x0 = box.x, x2 = box.x + box.w, x1 = x2 - runOut;
    final ya = box.y, yb = box.y + box.d;
    final zTop = box.z + box.h - rail; // Bed height at the top.
    const zEnd = 0.22; // Bed height along the run-out.

    // Bed height at x, along the slope then flat.
    double bedZ(double x) =>
        x >= x1 ? zEnd : zTop + (zEnd - zTop) * (x - x0) / (x1 - x0);

    const yellow = Color(0xFFF2C94C);
    const red = Color(0xFFE0524B);
    const blue = Color(0xFF4A90D9);
    const r = 5.0;

    void shape(List<Offset> pts, Color fill, {Color? edge}) {
      final path = IsoPainter.roundedPolygon(pts, r);
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, _stroke(edge ?? IsoPainter.darken(fill, 0.5), 1.4));
    }

    // Legs under the chute: one mid-slope, one under the run-out.
    for (final lx in [x0 + (x1 - x0) * 0.45, x1 + runOut * 0.4]) {
      final top = bedZ(lx) - thick;
      for (final ly in [ya + 0.06, yb - 0.14]) {
        shape([
          _p(lx, ly + 0.08, 0),
          _p(lx + 0.08, ly + 0.08, 0),
          _p(lx + 0.08, ly + 0.08, top),
          _p(lx, ly + 0.08, top),
        ], blue);
      }
    }

    // Underside thickness: the far end face.
    shape([
      _p(x2, ya, zEnd),
      _p(x2, yb, zEnd),
      _p(x2, yb, zEnd - thick),
      _p(x2, ya, zEnd - thick),
    ], IsoPainter.darken(yellow, 0.3));

    // Bed: the slope and run-out as one smooth surface.
    final bed = [
      _p(x0, ya, zTop),
      _p(x1, ya, zEnd),
      _p(x2, ya, zEnd),
      _p(x2, yb, zEnd),
      _p(x1, yb, zEnd),
      _p(x0, yb, zTop),
    ];
    shape(bed, IsoPainter.lighten(yellow, 0.15));

    // Back rail's inside face, standing on the bed's far edge.
    const railIn = 0.06;
    shape([
      _p(x0, ya + railIn, zTop),
      _p(x1, ya + railIn, zEnd),
      _p(x2, ya + railIn, zEnd),
      _p(x2, ya + railIn, zEnd + rail),
      _p(x1, ya + railIn, zEnd + rail),
      _p(x0, ya + railIn, zTop + rail),
    ], IsoPainter.lighten(red, 0.1));

    if (opacity > 0) {
      // Close up: a shine running down the middle of the chute.
      final mid = (ya + yb) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(
            _p(x0 + 0.1, mid - 0.05, zTop).dx,
            _p(x0 + 0.1, mid - 0.05, zTop).dy,
          )
          ..lineTo(_p(x1, mid - 0.05, zEnd).dx, _p(x1, mid - 0.05, zEnd).dy)
          ..lineTo(
            _p(x2 - 0.08, mid - 0.05, zEnd).dx,
            _p(x2 - 0.08, mid - 0.05, zEnd).dy,
          ),
        _stroke(_o(const Color(0xAAFFFFFF), opacity), 2.2),
      );
    }

    // Front side: chute edge below the bed and the front rail above it,
    // one continuous face along y = yb.
    shape([
      _p(x0, yb, zTop - thick),
      _p(x1, yb, zEnd - thick),
      _p(x2, yb, zEnd - thick),
      _p(x2, yb, zEnd + rail),
      _p(x1, yb, zEnd + rail),
      _p(x0, yb, zTop + rail),
    ], red);
    // Yellow chute edge showing beneath the red rail.
    canvas.drawPath(
      Path()
        ..moveTo(
          _p(x0, yb, zTop - thick * 0.5).dx,
          _p(x0, yb, zTop - thick * 0.5).dy,
        )
        ..lineTo(
          _p(x1, yb, zEnd - thick * 0.5).dx,
          _p(x1, yb, zEnd - thick * 0.5).dy,
        )
        ..lineTo(
          _p(x2, yb, zEnd - thick * 0.5).dx,
          _p(x2, yb, zEnd - thick * 0.5).dy,
        ),
      _stroke(IsoPainter.darken(yellow, 0.1), 2.6),
    );
    // Rail top edge highlight.
    canvas.drawPath(
      Path()
        ..moveTo(_p(x0, yb, zTop + rail).dx, _p(x0, yb, zTop + rail).dy)
        ..lineTo(_p(x1, yb, zEnd + rail).dx, _p(x1, yb, zEnd + rail).dy)
        ..lineTo(_p(x2, yb, zEnd + rail).dx, _p(x2, yb, zEnd + rail).dy),
      _stroke(IsoPainter.lighten(red, 0.45), 1.2),
    );

    if (opacity <= 0) return;

    // Close up: bolts along the front rail.
    final bolt = Paint()..color = _o(const Color(0xFF8C8C8C), opacity);
    for (var i = 0; i <= 6; i++) {
      final x = x0 + 0.12 + (x2 - x0 - 0.24) * i / 6;
      canvas.drawCircle(_p(x, yb, bedZ(x) + rail * 0.5), 1.1, bolt);
    }
    // Grab handles at the top of the slide.
    for (final hy in [ya + railIn, yb]) {
      final base = _p(x0 + 0.02, hy, zTop + rail);
      final top = _p(x0 + 0.02, hy, zTop + rail + 0.32);
      final out = _p(x0 + 0.18, hy, zTop + rail + 0.32);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..lineTo(top.dx, top.dy)
          ..quadraticBezierTo((top.dx + out.dx) / 2, top.dy - 3, out.dx, out.dy)
          ..lineTo(
            _p(x0 + 0.22, hy, zTop + rail * 0.8).dx,
            _p(x0 + 0.22, hy, zTop + rail * 0.8).dy,
          ),
        _stroke(_o(blue, opacity), 2.4),
      );
    }
  }

  // ── Fruit bowl ────────────────────────────────────────────────────────────
  //
  // A round white bowl with a blue band on the canteen's fruit table,
  // heaped with fruit a young child knows by sight: red and green apples,
  // oranges, a bunch of bananas and grapes. Close up: peel dimples, apple
  // speckles, banana ridges, shine on the grapes, and a pattern on the
  // bowl.

  static void _fruitBowl(
    Canvas canvas,
    SchoolObject object,
    double opacity,
    double time,
  ) {
    final table = object.parts.firstWhere((p) => p.id == 'table');
    final cx = table.x + table.w / 2;
    final cy = table.y + table.d / 2;
    final tz = table.z + table.h;
    const rimR = 0.36, footR = 0.18, rimZ = 0.22, footZ = 0.02;

    // Bowl body: the front half of the rim joined to the front half of the
    // foot. "Front" faces the viewer (+x/+y), i.e. angles −45°…135°.
    const front0 = -math.pi / 4, front1 = 3 * math.pi / 4;
    final rimFront = _isoArc(cx, cy, tz + rimZ, rimR, front0, front1);
    final footFront = _isoArc(cx, cy, tz + footZ, footR, front0, front1);
    final body = Path()..addPolygon([...rimFront, ...footFront.reversed], true);
    const ceramic = Color(0xFFF4F6F8);
    canvas.drawPath(body, Paint()..color = ceramic);
    // Shade the right-hand side of the bowl.
    canvas.save();
    canvas.clipPath(body);
    final mid = _p(cx, cy, tz);
    canvas.drawRect(
      Rect.fromLTRB(mid.dx + 6, mid.dy - 60, mid.dx + 60, mid.dy + 30),
      Paint()..color = const Color(0x1A000000),
    );
    // Blue band round the bowl.
    final bandTop = _isoArc(
      cx,
      cy,
      tz + rimZ * 0.62,
      rimR * 0.88,
      front0,
      front1,
    );
    final bandBottom = _isoArc(
      cx,
      cy,
      tz + rimZ * 0.42,
      rimR * 0.78,
      front0,
      front1,
    );
    canvas.drawPath(
      Path()..addPolygon([...bandTop, ...bandBottom.reversed], true),
      Paint()..color = const Color(0xFF4A90D9),
    );
    if (opacity > 0) {
      // Close up: white dots along the band.
      final dot = Paint()..color = _o(const Color(0xFFFFFFFF), opacity);
      for (var i = 2; i < bandTop.length - 2; i += 3) {
        canvas.drawCircle(
          Offset.lerp(bandTop[i], bandBottom[i], 0.5)!,
          0.9,
          dot,
        );
      }
    }
    canvas.restore();
    // Foot ring.
    canvas.drawPath(
      Path()
        ..addPolygon(_isoArc(cx, cy, tz + footZ, footR, 0, math.pi * 2), true),
      _stroke(const Color(0xFFB8C2CA), 1),
    );
    canvas.drawPath(body, _stroke(const Color(0xFF7F8B94), 1.3));

    // Inside of the bowl: the rim's full ellipse, a little darker.
    final rimAll = _isoArc(cx, cy, tz + rimZ, rimR, 0, math.pi * 2);
    final inside = Path()..addPolygon(rimAll, true);
    canvas.drawPath(inside, Paint()..color = const Color(0xFFDCE3E8));

    // The rim is drawn as two arcs so the fruit sits between them: the
    // back (upper-on-screen) arc goes behind the fruit, the front (lower)
    // arc in front of it. Back = angles 135°…315°, the complement of
    // [front0]…[front1].
    const rimGrey = Color(0xFF7F8B94);
    final rimBack = _isoArc(
      cx,
      cy,
      tz + rimZ,
      rimR,
      front1,
      front0 + math.pi * 2,
    );
    canvas.drawPath(Path()..addPolygon(rimBack, false), _stroke(ceramic, 3.2));
    canvas.drawPath(Path()..addPolygon(rimBack, false), _stroke(rimGrey, 1.2));

    // Fruit, back to front: (dx, dy, height above the bowl floor).
    final fz = tz + rimZ * 0.7;
    Offset f(double dx, double dy, double dz) => _p(cx + dx, cy + dy, fz + dz);

    _bananas(canvas, f(-0.12, -0.14, 0.08), opacity);
    _grapes(canvas, f(0.12, -0.16, 0.06), opacity);
    _orange(canvas, f(-0.2, 0.06, 0.04), 6.8, opacity);
    _apple(canvas, f(0.05, 0.0, 0.18), 6.2, const Color(0xFF7CC242), opacity);
    _orange(canvas, f(0.2, 0.02, 0.05), 6.8, opacity);
    _apple(canvas, f(-0.02, 0.18, 0.06), 6.4, const Color(0xFFE53935), opacity);

    // Front arc of the rim over the fruit, so it sits *in* the bowl.
    canvas.drawPath(Path()..addPolygon(rimFront, false), _stroke(ceramic, 3.2));
    canvas.drawPath(Path()..addPolygon(rimFront, false), _stroke(rimGrey, 1.2));
  }

  static void _apple(
    Canvas canvas,
    Offset c,
    double r,
    Color colour,
    double opacity,
  ) {
    _ball(canvas, c, r, colour, outline: 1.1);
    // Stalk and leaf.
    final top = c + Offset(0, -r * 0.8);
    canvas.drawLine(
      top,
      top + Offset(r * 0.15, -r * 0.55),
      _stroke(const Color(0xFF5E3E22), 1.2),
    );
    _drawLeaf(
      canvas,
      top + Offset(r * 0.1, -r * 0.3),
      top + Offset(r * 0.45, -r * 0.75),
      top + Offset(r * 0.9, -r * 0.5),
      0.35,
      detailOpacity: opacity,
      outlineWidth: 0.7,
    );
    if (opacity > 0) {
      final speck = Paint()
        ..color = _o(IsoPainter.lighten(colour, 0.45), opacity * 0.8);
      for (final d in const [
        Offset(0.3, 0.2),
        Offset(-0.1, 0.45),
        Offset(0.45, -0.15),
        Offset(-0.35, 0.1),
      ]) {
        canvas.drawCircle(c + d * r, 0.45, speck);
      }
    }
  }

  static void _orange(Canvas canvas, Offset c, double r, double opacity) {
    _ball(canvas, c, r, const Color(0xFFFF9800), outline: 1.1);
    // A little green star where the stalk was.
    final star = c + Offset(r * 0.1, -r * 0.7);
    canvas.drawCircle(star, 1.1, Paint()..color = const Color(0xFF3F7F32));
    if (opacity > 0) {
      final dimple = Paint()
        ..color = _o(const Color(0xFFD46F00), opacity * 0.7);
      for (var i = 0; i < 8; i++) {
        final a = i * 2.2;
        final rr = r * (0.25 + (i % 3) * 0.2);
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * rr,
          0.45,
          dimple,
        );
      }
    }
  }

  static void _bananas(Canvas canvas, Offset c, double opacity) {
    const yellow = Color(0xFFFFD84D);
    const edge = Color(0xFF9C7A00);
    // Three bananas fanned from a shared stem end on the left.
    for (final tilt in const [-0.35, 0.0, 0.32]) {
      canvas.save();
      canvas.translate(c.dx - 7, c.dy);
      canvas.rotate(tilt);
      final banana = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(9, 8, 18, -2)
        ..quadraticBezierTo(9, 3, 0, -3.5)
        ..close();
      canvas.drawPath(banana, Paint()..color = yellow);
      canvas.drawPath(banana, _stroke(edge, 1));
      // Brown tip.
      canvas.drawCircle(
        const Offset(17.5, -2),
        1.2,
        Paint()..color = const Color(0xFF5E3E22),
      );
      if (opacity > 0) {
        canvas.drawPath(
          Path()
            ..moveTo(2, -1.5)
            ..quadraticBezierTo(9, 4.5, 16, -1.5),
          _stroke(_o(const Color(0xFFD9B21C), opacity), 0.6),
        );
      }
      canvas.restore();
    }
    // Stem end.
    canvas.drawRect(
      Rect.fromCenter(
        center: c + const Offset(-7.5, -1.5),
        width: 3,
        height: 3,
      ),
      Paint()..color = const Color(0xFF6B8E23),
    );
  }

  static void _grapes(Canvas canvas, Offset c, double opacity) {
    const grape = Color(0xFF8E44AD);
    // A downward-pointing cluster, back rows first.
    const positions = [
      Offset(-4, -4),
      Offset(0, -4.5),
      Offset(4, -4),
      Offset(-2, -0.5),
      Offset(2, -0.5),
      Offset(-3.8, 3),
      Offset(0, 3.2),
      Offset(3.8, 3),
      Offset(-1.8, 6.4),
      Offset(1.8, 6.4),
      Offset(0, 9.2),
    ];
    canvas.drawLine(
      c + const Offset(0, -6),
      c + const Offset(1.5, -10),
      _stroke(const Color(0xFF5E3E22), 1.2),
    );
    for (final d in positions) {
      final p = c + d;
      canvas.drawCircle(p, 2.6, Paint()..color = grape);
      canvas.drawCircle(p, 2.6, _stroke(const Color(0xFF4A1F5E), 0.8));
      if (opacity > 0) {
        canvas.drawCircle(
          p + const Offset(-0.9, -0.9),
          0.7,
          Paint()..color = _o(const Color(0xBBFFFFFF), opacity),
        );
      }
    }
  }

  static Offset _bez(Offset p0, Offset c, Offset p1, double t) =>
      p0 * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + p1 * (t * t);

  /// Draws one cartoon leaf — shared by the plant, trees and garden so they
  /// all read the same way to a young child: a pointed blade with a dark
  /// outline, a lighter half on one side of a pale centre vein, and (as
  /// [detailOpacity] rises) side veins and a shine.
  ///
  /// The midrib runs from [base] to [tip], bowed through [control]; [width]
  /// is the blade's half-width as a fraction of its length. [facing] leaves
  /// (turned towards the viewer) are brighter. Returns the blade's
  /// sideways bulge vector (for placing things on the leaf), or null if the
  /// leaf is too small to draw.
  static Offset? _drawLeaf(
    Canvas canvas,
    Offset base,
    Offset control,
    Offset tip,
    double width, {
    bool facing = true,
    double detailOpacity = 0,
    double outlineWidth = 1.4,
  }) {
    final axis = tip - base;
    final length = axis.distance;
    if (length < 1) return null;
    final perp = Offset(-axis.dy, axis.dx) / length;
    final bulge = perp * (length * width);
    final blade = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        control.dx + bulge.dx,
        control.dy + bulge.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        control.dx - bulge.dx,
        control.dy - bulge.dy,
        base.dx,
        base.dy,
      )
      ..close();
    final light = facing ? const Color(0xFF6FCB5E) : const Color(0xFF4FA546);
    final dark = facing ? const Color(0xFF4FAE45) : const Color(0xFF3B8A38);
    canvas.drawPath(blade, Paint()..color = dark);
    // Lighter half of the blade (one side of the midrib) for a folded,
    // two-tone look that reads clearly as a leaf.
    final half = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        control.dx + bulge.dx,
        control.dy + bulge.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(control.dx, control.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(half, Paint()..color = light);
    canvas.drawPath(
      blade,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = outlineWidth
        ..color = const Color(0xFF245C27),
    );
    // Centre vein.
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = outlineWidth * 0.9
        ..color = const Color(0xFFB8EBA8),
    );

    if (detailOpacity <= 0) return bulge;

    // Close up: side veins angling towards the tip, and a soft shine.
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = outlineWidth * 0.5
      ..color = _o(const Color(0xFFB8EBA8), detailOpacity * 0.9);
    for (var k = 1; k <= 4; k++) {
      final s = k / 5;
      final on = _bez(base, control, tip, s);
      final ahead = _bez(base, control, tip, math.min(1, s + 0.12));
      final reachOut = math.sin(s * math.pi) * 0.75;
      for (final side in [1.0, -1.0]) {
        final end = ahead + bulge * (side * reachOut);
        canvas.drawLine(on, Offset.lerp(on, end, 0.85)!, vein);
      }
    }
    final glintAt = _bez(base, control, tip, 0.35) + bulge * 0.35;
    canvas.drawOval(
      Rect.fromCenter(
        center: glintAt,
        width: length * 0.18,
        height: length * 0.09,
      ),
      Paint()..color = _o(const Color(0x66FFFFFF), detailOpacity),
    );
    return bulge;
  }

  static void _ladybird(
    Canvas canvas,
    Offset c,
    Color Function(Color, double) o,
    double opacity,
  ) {
    final black = Paint()..color = o(const Color(0xFF1A1A1A), opacity);
    canvas.drawCircle(c + const Offset(-3.4, -0.6), 1.7, black);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 7, height: 6),
      Paint()..color = o(const Color(0xFFE53935), opacity),
    );
    canvas.drawLine(
      c + const Offset(-1.2, -3),
      c + const Offset(1.2, 3),
      black..strokeWidth = 0.6,
    );
    for (final d in const [
      Offset(-1.6, 0.6),
      Offset(1.4, -1.2),
      Offset(1.8, 1.2),
    ]) {
      canvas.drawCircle(c + d, 0.8, black);
    }
    canvas.drawCircle(
      c + const Offset(-0.6, -1.6),
      0.7,
      Paint()..color = o(const Color(0xAAFFFFFF), opacity),
    );
  }

  /// A water-drop icon centred on [c], [r] ≈ half its height.
  static void _drop(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 1.3)
      ..quadraticBezierTo(
        c.dx + r * 1.1,
        c.dy - r * 0.1,
        c.dx + r * 0.75,
        c.dy + r * 0.45,
      )
      ..arcToPoint(
        Offset(c.dx - r * 0.75, c.dy + r * 0.45),
        radius: Radius.circular(r * 0.8),
      )
      ..quadraticBezierTo(c.dx - r * 1.1, c.dy - r * 0.1, c.dx, c.dy - r * 1.3)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }
}

enum _FlowerKind { sunflower, daisy, tulipRed, tulipYellow }
