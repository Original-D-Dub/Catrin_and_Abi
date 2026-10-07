import 'dart:math';

import 'package:flutter/material.dart';

/// Pill showing a gold coin and the running coin total.
///
/// When [coins] goes up, the total counts up in ones. Each number fades and
/// slides up out of the way as the next fades in from below, overlapping it,
/// so a quick count reads as a blur of numbers. Any other change (e.g. a
/// reset to zero) snaps straight to the new value.
class CoinCounter extends StatefulWidget {
  final int coins;

  /// Attached to the pill's coin, so flying coins can aim at it.
  final Key? coinKey;

  const CoinCounter({super.key, required this.coins, this.coinKey});

  /// Time spent on each +1 while counting up.
  static const Duration stepDuration = Duration(milliseconds: 60);

  /// Longest a count-up may take; big jumps step faster to fit.
  static const Duration maxCountDuration = Duration(milliseconds: 900);

  @override
  State<CoinCounter> createState() => _CoinCounterState();
}

class _CoinCounterState extends State<CoinCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _count = AnimationController(
    vsync: this,
    value: 1,
  );
  late int _from = widget.coins;

  static const TextStyle _style = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.25,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// How far a number slides while giving way to the next; less than its
  /// height, so neighbouring numbers overlap.
  static const double _slide = 11;

  @override
  void didUpdateWidget(CoinCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coins == oldWidget.coins) return;
    if (widget.coins > oldWidget.coins &&
        !MediaQuery.disableAnimationsOf(context)) {
      // Carry on from whatever number is showing if a count was mid-way.
      _from = _countValue(oldWidget.coins).floor();
      final steps = widget.coins - _from;
      _count.duration = Duration(
        milliseconds: min(
          CoinCounter.stepDuration.inMilliseconds * steps,
          CoinCounter.maxCountDuration.inMilliseconds,
        ),
      );
      _count.forward(from: 0);
    } else {
      _from = widget.coins;
      _count.value = 1;
    }
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  /// The count's position between [_from] and [target]: whole numbers are
  /// settled totals, fractions are part-way to the next one.
  double _countValue(int target) => _from + (target - _from) * _count.value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Coins: ${widget.coins}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _count,
        builder: (context, _) {
          final counting = _count.isAnimating;
          return Transform.scale(
            scale: counting ? 1 + 0.08 * sin(pi * _count.value) : 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFFC73A), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GoldCoin(key: widget.coinKey, size: 34),
                  const SizedBox(width: 10),
                  counting
                      ? _rollingTotal()
                      : Text('${widget.coins}', style: _style),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The number being left behind, the current one and the next one,
  /// stacked with fades and offsets so they overlap like a fast count.
  Widget _rollingTotal() {
    final value = _countValue(widget.coins);
    final current = value.floor();
    final f = value - current;

    Widget number(int n, double opacity, double dy) => Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Text('$n', style: _style),
      ),
    );

    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        // Sizes the stack to the final total so the pill doesn't jitter.
        Opacity(opacity: 0, child: Text('${widget.coins}', style: _style)),
        if (current > _from)
          number(current - 1, (1 - f) * 0.3, -_slide * (1 + f)),
        number(current, 1 - f * 0.6, -_slide * f),
        if (current < widget.coins) number(current + 1, f, _slide * (1 - f)),
      ],
    );
  }
}

/// A shiny gold coin with a star, as shown in the [CoinCounter].
///
/// [outlineColor] adds a thin rim of that colour plus a drop shadow beneath
/// the coin in the same colour.
class GoldCoin extends StatelessWidget {
  final double size;
  final Color? outlineColor;

  const GoldCoin({super.key, required this.size, this.outlineColor});

  @override
  Widget build(BuildContext context) {
    final outline = outlineColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFE27A), Color(0xFFE0A21C)],
        ),
        border: outline == null
            ? null
            : Border.all(color: outline, width: size * 0.035),
        boxShadow: outline == null
            ? null
            : [
                BoxShadow(
                  color: outline,
                  offset: Offset(0, size * 0.07),
                  blurRadius: size * 0.04,
                ),
              ],
      ),
      child: const CustomPaint(painter: _StarPainter()),
    );
  }
}

/// A five-pointed star with rounded points, centred so its outline sits
/// evenly in the box (a star's top point reaches further from its centre
/// than its lower points, so its geometric centre is nudged down).
class _StarPainter extends CustomPainter {
  const _StarPainter();

  static const Color _color = Color(0xFFB57A0B);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = size.shortestSide * 0.3;
    final inner = outer * 0.45;
    // Top point is at -outer, lowest points at outer·cos 36°; shift so that
    // span is centred.
    final centre = size.center(Offset(0, outer * (1 - cos(pi / 5)) / 2));
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -pi / 2 + i * pi / 5;
      final p = centre + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = _color
        ..style = PaintingStyle.fill,
    );
    // Round off the points.
    canvas.drawPath(
      path,
      Paint()
        ..color = _color
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = outer * 0.18,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}
