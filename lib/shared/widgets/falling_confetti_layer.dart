import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Decorative, non-interactive falling confetti — a looping ambient layer
/// for full-screen celebration overlays (originally built for the Letter
/// Bingo celebration, now shared with [GameSuccessOverlay]).
///
/// Must be a direct [Stack] child — it renders itself as a
/// [Positioned.fill], and wrapping it in another widget with its own
/// [RenderObject] (e.g. a [Container]) before it reaches the [Stack] would
/// break the parent-data handoff that lets it fill the screen.
///
/// Hidden entirely under the OS "reduce motion" accessibility setting.
class FallingConfettiLayer extends StatefulWidget {
  const FallingConfettiLayer({super.key});

  @override
  State<FallingConfettiLayer> createState() => _FallingConfettiLayerState();
}

class _FallingConfettiLayerState extends State<FallingConfettiLayer>
    with SingleTickerProviderStateMixin {
  static const Duration _loopDuration = Duration(seconds: 5);
  static const int _pieceCount = 40;

  late final AnimationController _controller;
  final List<_ConfettiPiece> _pieces = _buildPieces();

  static List<_ConfettiPiece> _buildPieces() {
    final rng = Random();
    const palette = [
      AppColors.accentRed,
      AppColors.accentYellow,
      AppColors.accentLimeGreen,
      AppColors.accentOrange,
      AppColors.accentPurple,
      AppColors.abiPink,
      AppColors.connectorGold,
    ];
    return List.generate(
      _pieceCount,
      (_) => _ConfettiPiece(
        x: rng.nextDouble(),
        phase: rng.nextDouble(),
        speed: 0.45 + rng.nextDouble() * 0.55,
        size: 6 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 4,
        color: palette[rng.nextInt(palette.length)],
        isCircle: rng.nextBool(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _loopDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(t: _controller.value, pieces: _pieces),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double x; // horizontal start, 0..1 of width
  final double phase; // loop offset, 0..1
  final double speed; // fall-speed multiplier
  final double size;
  final double spin; // rotations per loop (can be negative)
  final Color color;
  final bool isCircle;

  const _ConfettiPiece({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.pieces});

  final double t;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final progress = (t * p.speed + p.phase) % 1.1;
      final dy = (progress / 1.1) * (size.height + 40) - 40;
      final dx = p.x * size.width + sin(2 * pi * (t + p.phase)) * 24;
      paint.color = p.color.withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(2 * pi * p.spin * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
