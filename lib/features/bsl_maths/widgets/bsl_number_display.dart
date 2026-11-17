import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';

/// Displays a BSL number sign for a given number.
///
/// Single digits (0-10) use PNG hand-sign assets, 11 and 12 animate
/// through three PNG frames each, 13-19 bounce the 3-9 PNG sign once per syllable, and two-digit numbers (20-99) are composed from the
/// tens and units digit signs shown side by side — BSL denotes place
/// value positionally, the same way written digits do.
///
/// Used in both the question display area (showing operands) and
/// on keyboard keys (showing available answers).
///
/// Each sign is rendered with [BoxFit.contain] to maintain aspect ratio
/// within the given [size] constraints.
///
/// Example:
/// ```dart
/// BslNumberDisplay(number: 5, size: 80.0)
/// ```
class BslNumberDisplay extends StatelessWidget {
  /// The number to display (0-99); 0-10 use the BSL hand sign PNGs
  final int number;

  /// The width and height of the display area in logical pixels
  final double size;

  /// When provided, the 11-19 animations retrigger each time the notifier's
  /// value increments. Used by the keyboard hint loop for teen numbers.
  final ValueNotifier<int>? hintCounter;

  /// Default display size matching child-friendly tap target dimensions
  static const double defaultSize = 64.0;

  const BslNumberDisplay({
    super.key,
    required this.number,
    this.size = defaultSize,
    this.hintCounter,
  });

  @override
  Widget build(BuildContext context) {
    if (number >= 13 && number <= 19) {
      return _TeenBounceDisplay(
        key: ValueKey(number),
        number: number,
        size: size,
        hintCounter: hintCounter,
      );
    }
    if (number == 11 || number == 12) {
      return _FrameSequenceDisplay(
        key: ValueKey(number),
        framePaths: [
          for (var part = 1; part <= 3; part++)
            AssetPaths.bslNumberPartPng(number, part),
        ],
        size: size,
        hintCounter: hintCounter,
      );
    }
    if (number >= 20 && number <= 99) {
      // BSL denotes place value positionally, just like written digits:
      // sign the tens digit followed by the units digit, left to right.
      final tens = number ~/ 10;
      final units = number % 10;
      return SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BslNumberDisplay(number: tens, size: size / 2),
            BslNumberDisplay(number: units, size: size / 2),
          ],
        ),
      );
    }
    // Numbers outside the 0-99 range covered by the sign art.
    if (number < 0 || number > 99) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.catrinBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w900,
                color: AppColors.catrinBlue,
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      // 0-10 come from the PNG sign art; the two-handed 10 is composed
      // from its left and right hand images, swapped so the thumbs sit on
      // the outside.
      child: number == 10
          ? Row(
              children: [
                Expanded(
                  child: Image.asset(
                    AssetPaths.bslNumber10RightPng,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    AssetPaths.bslNumber10LeftPng,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          : Image.asset(AssetPaths.bslNumberPng(number), fit: BoxFit.contain),
    );
  }
}

/// Animates a moving sign by stepping through [framePaths] (PNG frames that
/// share the same framing), with short crossfades between frames.
///
/// For 11 and 12 the frames are: 0 = open (part 1), 1 = in-between
/// (part 2), 2 = fingers closed (part 3). The timeline plays them as a
/// double tap — open → quick close → partly reopen → slower close → hold —
/// over a 2-second cycle (matching the 120-frame @ 60fps Rive timelines
/// this replaced), and loops. Each tick of [hintCounter] restarts it from
/// the start, so the keyboard hint loop stays in step with the teen keys.
class _FrameSequenceDisplay extends StatefulWidget {
  final List<String> framePaths;
  final double size;
  final ValueNotifier<int>? hintCounter;

  const _FrameSequenceDisplay({
    super.key,
    required this.framePaths,
    required this.size,
    this.hintCounter,
  });

  @override
  State<_FrameSequenceDisplay> createState() => _FrameSequenceDisplayState();
}

class _FrameSequenceDisplayState extends State<_FrameSequenceDisplay>
    with SingleTickerProviderStateMixin {
  /// Length of one pass through the timeline.
  static const int _cycleMs = 2000;
  static const Duration cycle = Duration(milliseconds: _cycleMs);

  /// The timeline: each step shows [_Step.frame] from [_Step.startMs],
  /// crossfading in over the [_Step.fadeMs] just before that. The last step
  /// holds until the cycle ends, then fades back into the first step.
  static const List<_Step> _steps = [
    _Step(frame: 0, startMs: 0, fadeMs: 100), // open (gentle loop-back)
    _Step(frame: 1, startMs: 800, fadeMs: 25), // in-between, ~60ms
    _Step(frame: 2, startMs: 860, fadeMs: 25), // 1st close — fast
    _Step(frame: 1, startMs: 1000, fadeMs: 40), // partly reopen
    _Step(frame: 2, startMs: 1220, fadeMs: 140), // 2nd close — slower
  ];

  /// Motion blur, one window per movement. The fast first close gets the
  /// strongest blur; the reopen and the slower second close get less.
  static const List<_BlurWindow> _blurWindows = [
    _BlurWindow(startMs: 775, peakMs: 830, endMs: 860, strength: 1.0),
    _BlurWindow(startMs: 960, peakMs: 985, endMs: 1000, strength: 0.5),
    _BlurWindow(startMs: 1080, peakMs: 1160, endMs: 1220, strength: 0.6),
  ];

  /// Peak blur sigma per 100 logical px of display size, so the smear looks
  /// the same on small keys and the large question signs. Stronger
  /// vertically, since the fingers mostly curl downwards.
  static const double _blurSigmaX = 1.0;
  static const double _blurSigmaY = 2.5;

  /// Blur strength (0 = none) at [ms] into the cycle.
  static double _blurAmount(double ms) {
    for (final w in _blurWindows) {
      if (ms <= w.startMs || ms >= w.endMs) continue;
      final ramp = ms < w.peakMs
          ? (ms - w.startMs) / (w.peakMs - w.startMs)
          : (w.endMs - ms) / (w.endMs - w.peakMs);
      return ramp * w.strength;
    }
    return 0;
  }

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: cycle)..repeat();
    widget.hintCounter?.addListener(_restart);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every frame up front so the first swap doesn't flash blank.
    for (final path in widget.framePaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void didUpdateWidget(_FrameSequenceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintCounter != oldWidget.hintCounter) {
      oldWidget.hintCounter?.removeListener(_restart);
      widget.hintCounter?.addListener(_restart);
    }
  }

  @override
  void dispose() {
    widget.hintCounter?.removeListener(_restart);
    _controller.dispose();
    super.dispose();
  }

  void _restart() {
    if (!mounted) return;
    _controller
      ..reset()
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final ms = _controller.value * _cycleMs;
          // Current step: the last one whose start time has passed.
          var currentStep = 0;
          for (var i = 0; i < _steps.length; i++) {
            if (ms >= _steps[i].startMs) currentStep = i;
          }
          final nextStep = (currentStep + 1) % _steps.length;
          final nextStartMs = nextStep == 0
              ? _cycleMs
              : _steps[nextStep].startMs;
          // Fade the next step's frame in over the end of this one.
          final fade = _steps[nextStep].fadeMs;
          final fadeIn = ((ms - (nextStartMs - fade)) / fade).clamp(0.0, 1.0);
          final current = _steps[currentStep].frame;
          final next = _steps[nextStep].frame;

          final frames = Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.framePaths[current],
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
              if (fadeIn > 0)
                Opacity(
                  opacity: fadeIn,
                  child: Image.asset(
                    widget.framePaths[next],
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
            ],
          );

          // Approximate motion blur: Flutter has no directional/per-pixel
          // motion blur, so blur the whole sign briefly (more vertically)
          // while the hand is moving. Skipped entirely when still.
          final blur = _blurAmount(ms);
          if (blur <= 0) return frames;
          final scale = widget.size / 100;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blurSigmaX * scale * blur,
              sigmaY: _blurSigmaY * scale * blur,
              tileMode: TileMode.decal,
            ),
            child: frames,
          );
        },
      ),
    );
  }
}

/// One step of a [_FrameSequenceDisplay] timeline.
class _Step {
  /// Index into the display's frame paths.
  final int frame;

  /// When this step's frame is fully showing, in ms into the cycle.
  final int startMs;

  /// How long it crossfades in over the previous step, ending at [startMs].
  final int fadeMs;

  const _Step({
    required this.frame,
    required this.startMs,
    required this.fadeMs,
  });
}

/// A 0 → [strength] → 0 motion-blur ramp, in ms into the cycle.
class _BlurWindow {
  final int startMs;
  final int peakMs;
  final int endMs;
  final double strength;

  const _BlurWindow({
    required this.startMs,
    required this.peakMs,
    required this.endMs,
    required this.strength,
  });
}

/// BSL teen numbers 13-19: the sign for the units digit (3-9) "bounced"
/// once per syllable of the spoken number (thir-teen = 2, se-ven-teen = 3).
///
/// Recreates the numbers13-19.riv `Action` timeline it replaced: each beat
/// tilts the sign 15° about the wrist over ~167ms (10 frames @ 60fps) and
/// eases back upright over ~250ms (15 frames), in a 2-second timeline that
/// plays once on load and again on each tick of [hintCounter], then rests
/// upright.
class _TeenBounceDisplay extends StatefulWidget {
  final int number;
  final double size;
  final ValueNotifier<int>? hintCounter;

  const _TeenBounceDisplay({
    super.key,
    required this.number,
    required this.size,
    this.hintCounter,
  });

  @override
  State<_TeenBounceDisplay> createState() => _TeenBounceDisplayState();
}

class _TeenBounceDisplayState extends State<_TeenBounceDisplay>
    with SingleTickerProviderStateMixin {
  static const int _cycleMs = 2000;
  static const int _downMs = 167;
  static const int _upMs = 250;
  static const int _beatMs = _downMs + _upMs;

  /// Tilt at the bottom of each beat (15°, as in the Rive file). Positive is
  /// clockwise: upright hands lean forward to the right, sideways hands dip
  /// their fingers down.
  static const double _tilt = 0.26;

  /// Syllables in the spoken English number, i.e. how many beats to bounce.
  static const Map<int, int> _syllables = {
    13: 2, // thir-teen
    14: 2, // four-teen
    15: 2, // fif-teen
    16: 2, // six-teen
    17: 3, // se-ven-teen
    18: 2, // eigh-teen
    19: 2, // nine-teen
  };

  /// Pivot for each 3-9 PNG, placed down the forearm near the image edge so
  /// the whole arm swings rather than just the hand. 3-5 are upright (pivot
  /// near the bottom); 6-9 point sideways (pivot near the left edge).
  static const Map<int, Alignment> _wristPivots = {
    3: Alignment(0.07, 0.9),
    4: Alignment(0.16, 0.9),
    5: Alignment(0.16, 0.9),
    6: Alignment(-0.9, 0.16),
    7: Alignment(-0.9, 0.16),
    8: Alignment(-0.9, 0.09),
    9: Alignment(-0.9, 0.16),
  };

  late final AnimationController _controller;

  int get _digit => widget.number - 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _cycleMs),
    )..forward();
    widget.hintCounter?.addListener(_restart);
  }

  @override
  void didUpdateWidget(_TeenBounceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintCounter != oldWidget.hintCounter) {
      oldWidget.hintCounter?.removeListener(_restart);
      widget.hintCounter?.addListener(_restart);
    }
  }

  @override
  void dispose() {
    widget.hintCounter?.removeListener(_restart);
    _controller.dispose();
    super.dispose();
  }

  void _restart() {
    if (!mounted) return;
    _controller.forward(from: 0);
  }

  /// Rotation (radians) at [ms] into the timeline.
  double _angleAt(double ms) {
    final beats = _syllables[widget.number] ?? 2;
    if (ms >= beats * _beatMs) return 0;
    final inBeat = ms % _beatMs;
    if (inBeat < _downMs) {
      return _tilt * Curves.easeOut.transform(inBeat / _downMs);
    }
    return _tilt * (1 - Curves.easeInOut.transform((inBeat - _downMs) / _upMs));
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AssetPaths.bslNumberPng(_digit),
      fit: BoxFit.contain,
    );
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        child: image,
        builder: (context, child) => Transform.rotate(
          angle: _angleAt(_controller.value * _cycleMs),
          alignment: _wristPivots[_digit] ?? Alignment.bottomCenter,
          child: child,
        ),
      ),
    );
  }
}
