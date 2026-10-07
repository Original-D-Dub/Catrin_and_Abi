import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/audio_service.dart';

/// Artwork and geometry for the till: the body SVG plus where its keys,
/// LCD and tick sit, all in the SVG's coordinate space.
class BslTillLayout {
  final String bodyAsset;
  final Size canvas;
  final List<BslTillKeySpec> keys;

  /// Digit area: the right-hand part of the green LCD panel, leaving room
  /// for the tick.
  final Rect lcdRect;

  /// Left end of the LCD panel, vertically centred.
  final Rect tickRect;

  /// Canvas x where the dark background starts (hides what's behind it).
  final double opaqueFromX;

  /// Canvas x of the till body's right edge (the dark background reaches
  /// further).
  final double bodyRight;

  /// Canvas y of the drawer keyhole's centre.
  final double keyholeY;

  const BslTillLayout({
    required this.bodyAsset,
    required this.canvas,
    required this.keys,
    required this.lcdRect,
    required this.tickRect,
    required this.opaqueFromX,
    required this.bodyRight,
    required this.keyholeY,
  });

  double get aspectRatio => canvas.width / canvas.height;

  /// The keys' values, in keypad order.
  List<int> get values => [for (final key in keys) key.value];

  /// Centre of the whole LCD panel, as fractions of the till's size.
  Offset get lcdCentreFraction {
    final panel = tickRect.expandToInclude(lcdRect);
    return Offset(
      panel.center.dx / canvas.width,
      panel.center.dy / canvas.height,
    );
  }

  /// Three rows of keys: 1–4, 5–8, 9–12.
  static const standard = BslTillLayout(
    bodyAsset: 'assets/games/till/till_body_wide.svg',
    canvas: Size(2108, 1908),
    keys: [
      BslTillKeySpec(1, Rect.fromLTWH(450, 668, 270, 230)),
      BslTillKeySpec(2, Rect.fromLTWH(742, 668, 270, 230)),
      BslTillKeySpec(3, Rect.fromLTWH(1034, 668, 270, 230)),
      BslTillKeySpec(4, Rect.fromLTWH(1326, 668, 270, 230)),
      BslTillKeySpec(5, Rect.fromLTWH(450, 913, 270, 230)),
      BslTillKeySpec(6, Rect.fromLTWH(742, 913, 270, 230)),
      BslTillKeySpec(7, Rect.fromLTWH(1034, 913, 270, 230)),
      BslTillKeySpec(8, Rect.fromLTWH(1326, 913, 270, 230)),
      BslTillKeySpec(9, Rect.fromLTWH(450, 1158, 270, 230)),
      BslTillKeySpec(10, Rect.fromLTWH(742, 1158, 270, 230)),
      BslTillKeySpec(11, Rect.fromLTWH(1034, 1158, 270, 230)),
      BslTillKeySpec(12, Rect.fromLTWH(1326, 1158, 270, 230)),
    ],
    lcdRect: Rect.fromLTRB(1194, 272, 1578, 404),
    tickRect: Rect.fromLTWH(1061, 280, 116, 116),
    opaqueFromX: 47,
    bodyRight: 1770,
    keyholeY: 1644,
  );
}

class BslTillKeySpec {
  final int value;
  final Rect rect;
  const BslTillKeySpec(this.value, this.rect);
}

/// A cash till whose keypad shows BSL number signs. Tapping a key presses
/// it down and reports its value through [onKeyPressed].
///
/// [display] is shown right-aligned as LCD digits in the till's screen;
/// null leaves the screen blank. [showNumbers] swaps the keys' BSL signs for
/// numerals, and [showTick] pops a green tick in at the left of the LCD.
///
/// All geometry is in [BslTillLayout.standard]'s SVG coordinate space and scaled to the
/// widget's width.
class BslTill extends StatelessWidget {
  final ValueChanged<int>? onKeyPressed;

  /// Digits to show on the LCD, e.g. `'12'`. Only 0–9 are drawn.
  final String? display;

  /// When true, keys show numerals instead of BSL signs.
  final bool showNumbers;

  /// When true, a green tick is shown at the left end of the LCD.
  final bool showTick;

  /// When false, keys don't respond to taps.
  final bool enabled;

  const BslTill({
    super.key,
    this.onKeyPressed,
    this.display,
    this.showNumbers = false,
    this.showTick = false,
    this.enabled = true,
  });

  /// How far a key top drops when pressed; matches the key-side depth
  /// drawn in the till SVGs, so a pressed key hides its side entirely.
  static const double _keyDepth = 14;

  @override
  Widget build(BuildContext context) {
    const layout = BslTillLayout.standard;
    return AspectRatio(
      aspectRatio: layout.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / layout.canvas.width;
          Rect scaled(Rect r) => Rect.fromLTRB(
            r.left * scale,
            r.top * scale,
            r.right * scale,
            r.bottom * scale,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(layout.bodyAsset, fit: BoxFit.fill),
              ),
              Positioned.fromRect(
                rect: scaled(layout.lcdRect),
                child: CustomPaint(painter: _LcdPainter(display ?? '')),
              ),
              Positioned.fromRect(
                rect: scaled(layout.tickRect),
                child: AnimatedScale(
                  scale: showTick ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: showTick ? Curves.easeOutBack : Curves.easeIn,
                  child: const _Tick(),
                ),
              ),
              for (final key in layout.keys)
                Positioned.fromRect(
                  rect: scaled(key.rect),
                  child: _TillKey(
                    value: key.value,
                    showNumber: showNumbers,
                    scale: scale,
                    depth: _keyDepth,
                    onPressed: enabled
                        ? () => onKeyPressed?.call(key.value)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TillKey extends StatefulWidget {
  final int value;
  final bool showNumber;
  final double scale;
  final double depth;
  final VoidCallback? onPressed;

  const _TillKey({
    required this.value,
    required this.showNumber,
    required this.scale,
    required this.depth,
    required this.onPressed,
  });

  @override
  State<_TillKey> createState() => _TillKeyState();
}

class _TillKeyState extends State<_TillKey> {
  // Keeps a quick tap visibly "down" instead of flashing for one frame.
  static const Duration _minPressDuration = Duration(milliseconds: 110);

  static const Color _glowColor = Color(0xFFDDEEFF);

  // The glow snaps on and fades out slowly, so even a quick tap is seen.
  static const Duration _glowOn = Duration(milliseconds: 60);
  static const Duration _glowOff = Duration(milliseconds: 350);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final depth = widget.depth * s;
    final signInset = 10 * s;
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(18 * s);
    final glowDuration = _pressed ? _glowOn : _glowOff;

    final key = LayoutBuilder(
      builder: (context, constraints) {
        final faceHeight = constraints.maxHeight - depth;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Halo spilling out around the key while it's pressed.
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: faceHeight,
                child: AnimatedOpacity(
                  duration: glowDuration,
                  opacity: _pressed ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: _glowColor.withValues(alpha: 0.9),
                          blurRadius: 30 * s,
                          spreadRadius: 6 * s,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: faceHeight,
                child: SvgPicture.asset(
                  'assets/games/till/key_top.svg',
                  fit: BoxFit.fill,
                ),
              ),
              if (widget.showNumber)
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: faceHeight,
                  child: Center(
                    child: Text(
                      '${widget.value}',
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w700,
                        fontSize: faceHeight * 0.55,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  left: signInset,
                  top: signInset,
                  right: signInset,
                  bottom: signInset,
                  child: Image.asset(
                    'assets/games/till/signs/sign_${widget.value}.png',
                    fit: BoxFit.fill,
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: faceHeight,
                // Lit-up face: a warm wash and a bright rim.
                child: AnimatedOpacity(
                  duration: glowDuration,
                  opacity: _pressed ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: _glowColor, width: 5 * s),
                      gradient: RadialGradient(
                        radius: 0.9,
                        colors: [
                          _glowColor.withValues(alpha: 0.45),
                          _glowColor.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!enabled) return key;

    return Semantics(
      button: true,
      label: 'BSL ${widget.value}',
      // The numeral shown on number keys would otherwise be read twice.
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          AudioService.playTillBeep();
          _setPressed(true);
        },
        onTapUp: (_) {
          widget.onPressed!();
          Future.delayed(_minPressDuration, () => _setPressed(false));
        },
        onTapCancel: () => _setPressed(false),
        child: key,
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2EB160),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: constraints.maxWidth * 0.06,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: constraints.maxWidth * 0.7,
        ),
      ),
    );
  }
}

/// Draws [text] as right-aligned seven-segment LCD digits, with faint
/// unlit "8"s in every cell like a real till display.
class _LcdPainter extends CustomPainter {
  final String text;

  const _LcdPainter(this.text);

  static const Color _litColor = Color(0xFF1C2620);

  // Segments per digit, in order a (top), b (top right), c (bottom right),
  // d (bottom), e (bottom left), f (top left), g (middle).
  static const Map<String, String> _segments = {
    '0': 'abcdef',
    '1': 'bc',
    '2': 'abged',
    '3': 'abgcd',
    '4': 'fgbc',
    '5': 'afgcd',
    '6': 'afgedc',
    '7': 'abc',
    '8': 'abcdefg',
    '9': 'abcdfg',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final digitHeight = size.height * 0.86;
    final digitWidth = digitHeight * 0.52;
    final gap = digitWidth * 0.34;
    final top = (size.height - digitHeight) / 2;
    final cells = ((size.width + gap) / (digitWidth + gap)).floor();

    final digits = text.split('').where(_segments.containsKey).toList();
    final shown = digits.length > cells
        ? digits.sublist(digits.length - cells)
        : digits;

    final ghost = Paint()..color = _litColor.withValues(alpha: 0.08);
    final lit = Paint()..color = _litColor;

    for (var i = 0; i < cells; i++) {
      // Cell 0 is the rightmost, so digits right-align.
      final left = size.width - digitWidth - i * (digitWidth + gap);
      final digitIndex = shown.length - 1 - i;
      canvas.save();
      canvas.translate(left, top);
      canvas.transform(Matrix4.skewX(-0.1).storage);
      _paintDigit(canvas, digitWidth, digitHeight, 'abcdefg', ghost);
      if (digitIndex >= 0) {
        _paintDigit(
          canvas,
          digitWidth,
          digitHeight,
          _segments[shown[digitIndex]]!,
          lit,
        );
      }
      canvas.restore();
    }
  }

  void _paintDigit(Canvas canvas, double w, double h, String on, Paint paint) {
    final t = w * 0.2;
    final ht = t / 2;
    final g = t * 0.14;

    Path horizontal(double cy) => Path()
      ..moveTo(g, cy)
      ..lineTo(g + ht, cy - ht)
      ..lineTo(w - g - ht, cy - ht)
      ..lineTo(w - g, cy)
      ..lineTo(w - g - ht, cy + ht)
      ..lineTo(g + ht, cy + ht)
      ..close();

    Path vertical(double cx, double y0, double y1) => Path()
      ..moveTo(cx, y0 + g)
      ..lineTo(cx + ht, y0 + g + ht)
      ..lineTo(cx + ht, y1 - g - ht)
      ..lineTo(cx, y1 - g)
      ..lineTo(cx - ht, y1 - g - ht)
      ..lineTo(cx - ht, y0 + g + ht)
      ..close();

    final mid = h / 2;
    final paths = <String, Path>{
      'a': horizontal(ht),
      'b': vertical(w - ht, ht, mid),
      'c': vertical(w - ht, mid, h - ht),
      'd': horizontal(h - ht),
      'e': vertical(ht, mid, h - ht),
      'f': vertical(ht, ht, mid),
      'g': horizontal(mid),
    };
    for (final s in on.split('')) {
      canvas.drawPath(paths[s]!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LcdPainter oldDelegate) =>
      oldDelegate.text != text;
}
