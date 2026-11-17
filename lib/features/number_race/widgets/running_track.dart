import 'dart:math';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// A strip of athletics track: BSL Sprint's track red, speckled with noise
/// for a rubbery texture, with a white line along the bottom edge.
///
/// Fills whatever size it's given.
class RunningTrack extends StatelessWidget {
  const RunningTrack({super.key});

  @override
  Widget build(BuildContext context) {
    // Static, so keep it out of the grandstand's per-frame repaints.
    return const RepaintBoundary(
      child: CustomPaint(painter: _RunningTrackPainter()),
    );
  }
}

class _RunningTrackPainter extends CustomPainter {
  const _RunningTrackPainter();

  /// BSL Sprint's track gradient, top to bottom.
  static const _trackTop = Color(0xFFD94A44);
  static const _trackBottom = Color(0xFFF85A54);

  static const double _borderWidth = 6;

  /// Noise specks per square logical pixel.
  static const double _noiseDensity = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final trackRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      max(0, size.height - _borderWidth),
    );

    // Track surface.
    canvas.drawRect(
      trackRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_trackTop, _trackBottom],
        ).createShader(trackRect),
    );

    // Noise: light and dark specks scattered from a fixed seed, so the
    // grain stays put between repaints.
    final random = Random(7);
    final count = (trackRect.width * trackRect.height * _noiseDensity).round();
    final light = <Offset>[];
    final dark = <Offset>[];
    for (var i = 0; i < count; i++) {
      final point = Offset(
        random.nextDouble() * trackRect.width,
        random.nextDouble() * trackRect.height,
      );
      (random.nextBool() ? light : dark).add(point);
    }
    canvas.drawPoints(
      PointMode.points,
      light,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPoints(
      PointMode.points,
      dark,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // White line along the bottom edge.
    canvas.drawRect(
      Rect.fromLTRB(0, rect.bottom - _borderWidth, size.width, rect.bottom),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RunningTrackPainter oldDelegate) => false;
}
