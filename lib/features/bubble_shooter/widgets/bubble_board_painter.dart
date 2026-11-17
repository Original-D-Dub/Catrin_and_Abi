import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bubble_shooter_models.dart';
import '../providers/bubble_shooter_provider.dart';

/// Light, base and dark tones for a glossy bubble of [colour]. White and
/// black get hand-tuned shading so they still read as shiny 3D spheres.
({Color light, Color base, Color dark}) bubbleTones(BubbleColour colour) {
  switch (colour) {
    case BubbleColour.white:
      return (
        light: Colors.white,
        base: colour.color,
        dark: const Color(0xFFAFBBD9),
      );
    case BubbleColour.black:
      return (
        light: const Color(0xFF75758F),
        base: colour.color,
        dark: const Color(0xFF07070C),
      );
    default:
      final hsl = HSLColor.fromColor(colour.color);
      return (
        light: Color.lerp(colour.color, Colors.white, 0.55)!,
        base: colour.color,
        dark: hsl
            .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
            .toColor(),
      );
  }
}

/// Paints a bright, glossy, three-dimensional bubble: soft drop shadow,
/// off-centre radial body gradient, dark rim, a reflected glow along the
/// bottom, and a white specular highlight + sparkle top-left.
void paintShinyBubble(
  Canvas canvas,
  Offset c,
  double r,
  BubbleColour colour, {
  double opacity = 1,
  bool shadow = true,
}) {
  if (r <= 0 || opacity <= 0) return;
  final tones = bubbleTones(colour);
  final a = opacity.clamp(0.0, 1.0);
  // The body fill is slightly see-through; the rim stroke stays solid.
  const fillOpacity = 0.9;
  Color fade(Color col, [double alpha = 1]) =>
      col.withValues(alpha: col.a * alpha * a);

  if (shadow) {
    canvas.drawCircle(
      c + Offset(r * 0.06, r * 0.14),
      r * 0.98,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.14),
    );
  }

  final rect = Rect.fromCircle(center: c, radius: r);

  // Body
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.05,
        colors: [
          fade(tones.light, fillOpacity),
          fade(tones.base, fillOpacity),
          fade(tones.dark, fillOpacity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect),
  );

  // Reflected glow along the bottom edge
  final glowRect = Rect.fromCenter(
    center: c + Offset(0, r * 0.52),
    width: r * 1.3,
    height: r * 0.7,
  );
  canvas.drawOval(
    glowRect,
    Paint()
      ..shader = RadialGradient(
        colors: [fade(tones.light, 0.55), fade(tones.light, 0)],
      ).createShader(glowRect),
  );

  // Rim
  canvas.drawCircle(
    c,
    r * 0.97,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..color = fade(tones.dark, 0.55),
  );

  // Specular highlight
  canvas.save();
  canvas.translate(c.dx - r * 0.3, c.dy - r * 0.42);
  canvas.rotate(-0.5);
  final hl = Rect.fromCenter(
    center: Offset.zero,
    width: r * 0.82,
    height: r * 0.44,
  );
  canvas.drawOval(
    hl,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95 * a),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(hl),
  );
  canvas.restore();

  // Sparkle
  canvas.drawCircle(
    c + Offset(-r * 0.56, -r * 0.08),
    r * 0.09,
    Paint()..color = Colors.white.withValues(alpha: 0.85 * a),
  );
}

/// Paints the whole board: the ceiling the cluster hangs from, the cluster,
/// pop sparkles, falling bubbles, the aim guide, the flying shot and the
/// floating score labels. The loaded bubble isn't drawn — its colour is
/// only shown by the BSL sign in the cannon, and it appears when fired.
///
/// Works in bubble units scaled by [scale] (pixels per unit), and repaints
/// whenever [BubbleShooterProvider.frame] fires.
class BubbleBoardPainter extends CustomPainter {
  BubbleBoardPainter({required this.provider, required this.scale})
    : super(repaint: provider.frame);

  final BubbleShooterProvider provider;
  final double scale;

  static const List<Color> rainbow = [
    Color(0xFFFF3B3B),
    Color(0xFFFF8A00),
    Color(0xFFFFD60A),
    Color(0xFF2ECC40),
    Color(0xFF2F7BFF),
    Color(0xFF9B4DFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    _paintCeiling(canvas);
    _paintCluster(canvas);
    _paintFalling(canvas);
    _paintPops(canvas);
    _paintAimGuide(canvas);

    final shot = provider.flying;
    if (shot != null) paintShinyBubble(canvas, shot.position, 1, shot.colour);

    canvas.restore();

    // Text is laid out at real pixel sizes so it stays crisp.
    _paintPopups(canvas);
  }

  /// A rope of rainbow bunting along the top of the cluster — visible once
  /// the cluster has lowered far enough to show its top.
  void _paintCeiling(Canvas canvas) {
    final top = provider.gridTop;
    if (top < -1.5) return;
    const w = BubbleShooterProvider.boardWidth;
    final rope = Paint()
      ..color = const Color(0xFF8F0693)
      ..strokeWidth = 0.18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, top - 0.1), Offset(w, top - 0.1), rope);
    const flags = 12;
    const flagW = w / flags;
    for (var i = 0; i < flags; i++) {
      final x = i * flagW;
      final path = Path()
        ..moveTo(x + 0.1, top - 0.1)
        ..lineTo(x + flagW - 0.1, top - 0.1)
        ..lineTo(x + flagW / 2, top + 0.8)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = rainbow[i % rainbow.length].withValues(alpha: 0.9),
      );
    }
  }

  void _paintCluster(Canvas canvas) {
    final landed = provider.lastLanded;
    final t = provider.sinceLanding;
    // Brief squash-and-settle wobble on the bubble that just landed.
    final wobble = t < 0.4 ? 1 + 0.12 * sin(t * 30) * (1 - t / 0.4) : 1.0;
    provider.grid.forEach((cell, colour) {
      final r = cell == landed ? wobble : 1.0;
      paintShinyBubble(canvas, provider.centreOf(cell), 0.98 * r, colour);
    });
  }

  void _paintFalling(Canvas canvas) {
    for (final b in provider.falling) {
      paintShinyBubble(canvas, b.position, 0.98, b.colour);
    }
  }

  void _paintPops(Canvas canvas) {
    for (final p in provider.popping) {
      final progress = p.progress;
      if (progress == null) {
        // Still waiting for its turn in the chain — keep showing it.
        paintShinyBubble(canvas, p.position, 0.98, p.colour);
        continue;
      }
      final eased = Curves.easeOut.transform(progress);
      paintShinyBubble(
        canvas,
        p.position,
        0.98 * (1 + 0.45 * eased),
        p.colour,
        opacity: 1 - progress,
        shadow: false,
      );
      // Sparkles bursting outward
      final tones = bubbleTones(p.colour);
      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4 + p.position.dx;
        final dist = 0.8 + 1.6 * eased;
        final pos = p.position + Offset(cos(angle), sin(angle)) * dist;
        final paint = Paint()
          ..color = (i.isEven ? Colors.white : tones.light).withValues(
            alpha: 1 - progress,
          );
        _drawStar(canvas, pos, 0.28 * (1 - progress * 0.5), paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.4;
      final a = i * pi / 4 - pi / 2;
      final pt = c + Offset(cos(a), sin(a)) * rad;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  /// Dotted line from the cannon along the shot's path, including bounces.
  /// Dots are the loaded colour on levels that show a colour hint, purple
  /// otherwise.
  void _paintAimGuide(Canvas canvas) {
    final points = provider.aimGuide();
    final colour = provider.loadedColour;
    if (points.length < 2 || colour == null) return;
    // From level 11 the guide is plain purple so it doesn't give away the
    // colour — the BSL sign is the only clue.
    final hint = provider.currentLevel.showsColourHint;
    final fill = Paint()
      ..color = hint ? bubbleTones(colour).base : const Color(0xFF8F0693);
    final outline = Paint()
      ..color = hint && colour == BubbleColour.white
          ? const Color(0xFF8F0693)
          : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;
    const spacing = 0.9;
    var carried = 1.4; // Start beyond the loaded bubble.
    var drawn = 0;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final segment = (b - a).distance;
      if (segment == 0) continue;
      final dir = (b - a) / segment;
      var d = carried;
      while (d < segment) {
        final p = a + dir * d;
        final radius = max(0.12, 0.24 - drawn * 0.004);
        canvas.drawCircle(p, radius, fill);
        canvas.drawCircle(p, radius, outline);
        drawn++;
        d += spacing;
      }
      carried = d - segment;
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in provider.popups) {
      if (p.age < 0) continue;
      final t = p.age / ScorePopup.duration;
      final tp = TextPainter(
        text: TextSpan(
          text: '+${p.points}',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 0.9 * scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFC73A).withValues(alpha: 1 - t),
            shadows: [
              Shadow(
                color: const Color(0xFF8F0693).withValues(alpha: 1 - t),
                blurRadius: 0.15 * scale,
                offset: Offset(0.05 * scale, 0.05 * scale),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        p.position * scale -
            Offset(tp.width / 2, tp.height / 2 + t * 2 * scale),
      );
    }
  }

  @override
  bool shouldRepaint(BubbleBoardPainter oldDelegate) =>
      oldDelegate.provider != provider || oldDelegate.scale != scale;
}

/// Paints the cannon's barrel, turning on the centre of the cannon's round
/// body. Sits underneath the round BSL sign widget, so only the part of the
/// barrel sticking out past the body shows.
class CannonBarrelPainter extends CustomPainter {
  CannonBarrelPainter({required this.provider, required this.scale})
    : super(repaint: provider.frame);

  final BubbleShooterProvider provider;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    const tip = BubbleShooterProvider.muzzleDistance - 0.6;
    final pivot = provider.cannonPosition;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(provider.barrelAngle);

    final barrel = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-1.25, -tip, 1.25, 0),
      const Radius.circular(0.5),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8F0693), Color(0xFFFB7DFF), Color(0xFF8F0693)],
        ).createShader(barrel.outerRect),
    );

    // Gold muzzle ring
    final muzzle = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-1.5, -tip - 0.2, 1.5, -tip + 0.5),
      const Radius.circular(0.35),
    );
    canvas.drawRRect(muzzle, Paint()..color = const Color(0xFFFFC73A));
    canvas.drawRRect(
      muzzle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1
        ..color = const Color(0xFFB37A00),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CannonBarrelPainter oldDelegate) =>
      oldDelegate.provider != provider || oldDelegate.scale != scale;
}
