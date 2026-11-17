import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Firework bursts over the multiplayer checking view, set off by the
/// Winner button. Same look as the Bubble Shooter level-complete screen
/// (`LevelCompleteModal`): round sparks bursting from random launch points,
/// one every 0.45s — here for [showDuration] after each change of
/// [trigger], plus one burst from every point at once to start.
///
/// Fill the screen with it (e.g. in a [Positioned.fill]); it ignores taps.
/// Does nothing under the OS "reduce motion" setting.
class WinnerFireworks extends StatefulWidget {
  /// Change this (e.g. increment it) to set the fireworks off. 0 = never.
  final int trigger;

  static const Duration showDuration = Duration(seconds: 5);

  const WinnerFireworks({super.key, required this.trigger});

  @override
  State<WinnerFireworks> createState() => _WinnerFireworksState();
}

class _WinnerFireworksState extends State<WinnerFireworks> {
  /// Launch points, as fractions of the screen.
  static const _bursts = [
    Alignment(-0.6, -0.65),
    Alignment(0.55, -0.75),
    Alignment(0.0, -0.9),
    Alignment(-0.65, -0.15),
    Alignment(0.6, 0.25),
  ];
  static const _colours = [
    Color(0xFFFFD54A),
    Color(0xFFFF7AB8),
    Color(0xFF8E44EC),
    Color(0xFF5FBBE1),
    Colors.white,
  ];

  final _random = Random();
  late final List<ConfettiController> _fireworks = [
    for (var i = 0; i < _bursts.length; i++)
      ConfettiController(duration: const Duration(milliseconds: 500)),
  ];
  Timer? _timer;
  Timer? _stopTimer;
  int _next = 0;

  @override
  void didUpdateWidget(WinnerFireworks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger != 0) _start();
  }

  void _start() {
    if (MediaQuery.of(context).disableAnimations) return;
    for (final f in _fireworks) {
      f.play();
    }
    _timer?.cancel();
    _stopTimer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      _fireworks[_next].play();
      _next =
          (_next + 1 + _random.nextInt(_fireworks.length - 1)) %
          _fireworks.length;
    });
    _stopTimer = Timer(WinnerFireworks.showDuration, () => _timer?.cancel());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopTimer?.cancel();
    for (final f in _fireworks) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < _bursts.length; i++)
            Align(
              alignment: _bursts[i],
              child: ConfettiWidget(
                confettiController: _fireworks[i],
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 22,
                maxBlastForce: 16,
                minBlastForce: 6,
                gravity: 0.18,
                emissionFrequency: 0.5,
                colors: _colours,
                minimumSize: const Size(6, 6),
                maximumSize: const Size(9, 9),
                // Round sparks rather than confetti strips.
                createParticlePath: (size) =>
                    Path()..addOval(Offset.zero & size),
              ),
            ),
        ],
      ),
    );
  }
}
