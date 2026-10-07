import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'coin_counter.dart';

/// A stream of gold coins arcing from [from] up to [to], one after another.
///
/// Fill a [Stack] with it; [from] and [to] are in that stack's coordinates.
/// [onFirstLanded] fires as the first coin reaches [to] (the moment to start
/// counting up the total) and [onDone] once the last coin has landed.
class CoinBurst extends StatefulWidget {
  final Offset from;
  final Offset to;
  final int count;
  final double coinSize;
  final VoidCallback? onFirstLanded;
  final VoidCallback? onDone;

  const CoinBurst({
    super.key,
    required this.from,
    required this.to,
    required this.count,
    this.coinSize = 30,
    this.onFirstLanded,
    this.onDone,
  });

  static const Duration flightDuration = Duration(milliseconds: 650);
  static const Duration stagger = Duration(milliseconds: 60);

  /// Most coins drawn for one burst, so big prices don't flood the screen.
  static const int maxCoins = 10;

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  late final int _count = widget.count.clamp(1, CoinBurst.maxCoins);
  late final AnimationController _controller;
  late final List<Offset> _scatter;
  bool _firstLanded = false;

  double get _flightMs => CoinBurst.flightDuration.inMilliseconds.toDouble();
  double get _staggerMs => CoinBurst.stagger.inMilliseconds.toDouble();

  @override
  void initState() {
    super.initState();
    // Fixed seed: each burst fans out the same way, which reads as tidy.
    final random = Random(_count);
    final spread = widget.coinSize * 1.2;
    _scatter = List.generate(
      _count,
      (_) => Offset(
        (random.nextDouble() - 0.5) * spread * 2,
        (random.nextDouble() - 0.5) * spread,
      ),
    );
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: (_flightMs + _staggerMs * (_count - 1)).round(),
            ),
          )
          ..addListener(_checkFirstLanded)
          ..forward().then((_) {
            if (mounted) widget.onDone?.call();
          });
  }

  void _checkFirstLanded() {
    if (_firstLanded) return;
    if (_elapsedMs >= _flightMs) {
      _firstLanded = true;
      widget.onFirstLanded?.call();
    }
  }

  double get _elapsedMs =>
      _controller.value * _controller.duration!.inMilliseconds;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final size = widget.coinSize;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _count; i++)
                if (_progress(i) case final t when t > 0 && t < 1)
                  _coin(i, t, size),
            ],
          );
        },
      ),
    );
  }

  double _progress(int i) => (_elapsedMs - i * _staggerMs) / _flightMs;

  Widget _coin(int i, double t, double size) {
    final start = widget.from + _scatter[i];
    final end = widget.to;
    // Quadratic arc: pops out sideways and up, then homes in on the total.
    final control = Offset(
      lerpDouble(start.dx, end.dx, 0.25)! + _scatter[i].dx,
      min(start.dy, end.dy) - size * 1.5,
    );
    final e = Curves.easeInOutCubic.transform(t);
    final u = 1 - e;
    final pos = start * (u * u) + control * (2 * u * e) + end * (e * e);
    // Pop in, then shrink to the counter's coin size as it lands.
    final scale = t < 0.15 ? t / 0.15 * 1.2 : lerpDouble(1.2, 0.9, t)!;

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: Transform.rotate(
        angle: t * pi * 2 * (i.isEven ? 1 : -1),
        child: Transform.scale(
          scale: scale,
          child: GoldCoin(size: size),
        ),
      ),
    );
  }
}
