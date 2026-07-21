import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;

import '../models/enclosure_level_config.dart';
import '../providers/enclosure_walk_provider.dart';

/// One enclosure viewing window: a chunky rock frame set into the wall,
/// a name plaque above it, and — until real pictures/video exist — a flat
/// placeholder fill ([EnclosureLevelConfig.windowColor]) behind the glass.
///
/// When the enclosure has been photographed a green tick badge appears on
/// the frame's top-right corner (read live from the provider each frame,
/// so no listener wiring is needed).
class EnclosureWindowComponent extends PositionComponent {
  final EnclosureSpec spec;

  /// Already-localized plaque text — the game resolves translations so
  /// this component stays locale-agnostic.
  final String label;

  final EnclosureLevelConfig config;
  final EnclosureWalkProvider provider;

  final double _frame;
  final double _plaqueHeight;
  late final TextPainter _labelPainter;

  /// Frame speckles as (rect, shade) pairs, generated once per layout.
  late final List<(Rect, Color)> _speckles;

  static const double _plaqueGap = 10;

  /// [windowCenter] / [windowTop] / window size come from
  /// [EnclosureWalkLayout]; the component's box also includes the frame
  /// border and the plaque above it.
  EnclosureWindowComponent({
    required this.spec,
    required this.label,
    required this.config,
    required this.provider,
    required double windowCenterX,
    required double windowTop,
    required double windowWidth,
    required double windowHeight,
  })  : _frame = (windowWidth * 0.06).clamp(14.0, 30.0),
        _plaqueHeight = (windowHeight * 0.12).clamp(34.0, 56.0),
        super(anchor: Anchor.topCenter, priority: 1) {
    final frame = _frame;
    size = Vector2(
      windowWidth + frame * 2,
      _plaqueHeight + _plaqueGap + windowHeight + frame * 2,
    );
    position = Vector2(
      windowCenterX,
      windowTop - frame - _plaqueGap - _plaqueHeight,
    );
  }

  /// Outer edge of the rock frame, in local coordinates.
  Rect get _frameRect =>
      Rect.fromLTWH(0, _plaqueHeight + _plaqueGap, size.x,
          size.y - _plaqueHeight - _plaqueGap);

  /// The glass itself.
  Rect get _windowRect => _frameRect.deflate(_frame);

  @override
  Future<void> onLoad() async {
    _labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: _plaqueHeight * 0.48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Seeded per enclosure so the rocks don't shimmer between rebuilds.
    final rnd = Random(spec.id.hashCode);
    final frameRect = _frameRect;
    final windowRect = _windowRect;
    _speckles = [];
    final count = (frameRect.width * frameRect.height / 4500).round();
    while (_speckles.length < count) {
      final r = Rect.fromCenter(
        center: Offset(
          frameRect.left + rnd.nextDouble() * frameRect.width,
          frameRect.top + rnd.nextDouble() * frameRect.height,
        ),
        width: 6 + rnd.nextDouble() * _frame * 0.9,
        height: 4 + rnd.nextDouble() * _frame * 0.5,
      );
      if (windowRect.overlaps(r)) continue;
      final light = rnd.nextBool();
      _speckles.add((
        r,
        light ? const Color(0x22FFFFFF) : const Color(0x33000000),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint();
    final frameRect = _frameRect;
    final windowRect = _windowRect;

    // Rock frame with its speckle texture.
    paint.color = config.frameColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      paint,
    );
    for (final (rect, shade) in _speckles) {
      paint.color = shade;
      canvas.drawOval(rect, paint);
    }

    // Placeholder "water": flat colour with a slightly darker lower half,
    // to be replaced by enclosure pictures/video. The colour must be reset
    // to opaque first — its alpha modulates the shader.
    paint.color = const Color(0xFFFFFFFF);
    paint.shader = Gradient.linear(
      windowRect.topCenter,
      windowRect.bottomCenter,
      [config.windowColor, _darken(config.windowColor, 0.35)],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
      paint,
    );
    paint.shader = null;

    // Glass shine: two translucent diagonal streaks.
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
    );
    paint.color = const Color(0x1AFFFFFF);
    for (final offset in [0.15, 0.35]) {
      final x = windowRect.left + windowRect.width * offset;
      final path = Path()
        ..moveTo(x, windowRect.top)
        ..lineTo(x + windowRect.width * 0.08, windowRect.top)
        ..lineTo(x - windowRect.height * 0.3 + windowRect.width * 0.08,
            windowRect.bottom)
        ..lineTo(x - windowRect.height * 0.3, windowRect.bottom)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();

    // Inner bevel so the glass sits "into" the rock.
    paint
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
      paint,
    );
    paint.style = PaintingStyle.fill;

    _renderPlaque(canvas, paint);

    if (provider.isPhotographed(spec.id)) {
      _renderPhotoBadge(canvas, paint, frameRect);
    }
  }

  void _renderPlaque(Canvas canvas, Paint paint) {
    final plaqueWidth = _labelPainter.width + _plaqueHeight * 1.2;
    final plaque = Rect.fromCenter(
      center: Offset(size.x / 2, _plaqueHeight / 2),
      width: plaqueWidth,
      height: _plaqueHeight,
    );
    paint.color = const Color(0xFF263238);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaque, const Radius.circular(10)),
      paint,
    );
    _labelPainter.paint(
      canvas,
      Offset(
        plaque.center.dx - _labelPainter.width / 2,
        plaque.center.dy - _labelPainter.height / 2,
      ),
    );
  }

  void _renderPhotoBadge(Canvas canvas, Paint paint, Rect frameRect) {
    final radius = _frame * 0.9;
    final centre = Offset(frameRect.right - _frame, frameRect.top + _frame);
    paint.color = const Color(0xFF4CAF50);
    canvas.drawCircle(centre, radius, paint);
    paint
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.28
      ..strokeCap = StrokeCap.round;
    final tick = Path()
      ..moveTo(centre.dx - radius * 0.45, centre.dy + radius * 0.05)
      ..lineTo(centre.dx - radius * 0.1, centre.dy + radius * 0.4)
      ..lineTo(centre.dx + radius * 0.5, centre.dy - radius * 0.35);
    canvas.drawPath(tick, paint);
    paint
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
  }

  static Color _darken(Color color, double amount) => Color.lerp(
        color,
        const Color(0xFF000000),
        amount,
      )!;
}
