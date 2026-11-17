import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import 'bsl_number_display.dart';

/// A square key on the [BslKeyboard] showing a BSL number sign, styled like
/// a 2000s computer keyboard keycap (in white for legibility).
///
/// The key is built from two layers:
/// - a **skirt** (the sloped sides of the keycap): a diagonal light→dark
///   gradient gives the bevel, with a dark hairline outline and a short
///   hard drop shadow so it sits up off the background;
/// - a **dished top face**, inset more at the bottom than the top (the
///   front of a keycap slopes further), with inner shadows — dark along the
///   top, a light highlight along the bottom — so it reads as concave.
///
/// While a finger is down the key "travels": it shifts down and the front
/// skirt shrinks, then pops back up on release.
///
/// The tile is an [AspectRatio] 1:1 box that fills whatever the parent gives
/// it, and the sign is sized from the face's own constraints (via
/// [LayoutBuilder]) so it scales with the key on every screen size.
/// - **[showNumber] true**: the sign fills the space above the numeral.
/// - **[showNumber] false** (championship mode): no numeral; the sign
///   fills the whole face.
class BslKeyTile extends StatefulWidget {
  /// The number this key enters.
  final int number;

  /// Called when the key is tapped; null while the keyboard is disabled.
  final VoidCallback? onTap;

  /// Whether to show the numeral label under the sign.
  final bool showNumber;

  /// Dims the key while input is locked (feedback display).
  final bool isDisabled;

  /// Retriggers the teen-number Rive animation (keyboard hint loop).
  final ValueNotifier<int>? hintCounter;

  /// Font size of the numeral label.
  final double numeralFontSize;

  const BslKeyTile({
    super.key,
    required this.number,
    required this.onTap,
    this.showNumber = true,
    this.isDisabled = false,
    this.hintCounter,
    this.numeralFontSize = 16,
  });

  // Outer bevel ("skirt") styling, public so other parts of the game (e.g.
  // the question card) can share the keycap edge. White plastic: less
  // period-accurate than beige, but the signs read more clearly.
  static const Color skirtLight = Color(0xFFFFFFFF);
  static const Color skirtDark = Color(0xFFBDBDBD);
  static const Color skirtOutline = Color(0xFF8A8A8A);

  /// Skirt widths around the face: (left/right, top, bottom). The bottom is
  /// deeper because the front of a keycap slopes further.
  static const double skirtSide = 4;
  static const double skirtTop = 2;
  static const double skirtBottom = 7;

  /// The skirt decoration (bevel gradient, hairline outline, hard drop
  /// shadow). [pressed] flattens the shadow for the key's travel.
  static BoxDecoration skirtDecoration({
    required double radius,
    bool pressed = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [skirtLight, skirtDark],
      ),
      border: Border.all(color: skirtOutline, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: pressed ? 0.25 : 0.4),
          offset: Offset(0, pressed ? 1 : 2.5),
          blurRadius: pressed ? 1 : 2,
        ),
      ],
    );
  }

  /// Inset shadows that make the top face read as dished — public so the
  /// question card can share the same look (via [BslInnerShadowPainter]).
  static final List<BoxShadow> faceInnerShadows = [
    // Shadow cast into the dish along the top edge.
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 2),
      blurRadius: 3,
    ),
    // Highlight catching the lower lip of the dish.
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      offset: const Offset(0, -1.5),
      blurRadius: 2,
    ),
  ];

  @override
  State<BslKeyTile> createState() => _BslKeyTileState();
}

class _BslKeyTileState extends State<BslKeyTile> {
  // Top-face palette (the skirt's lives on BslKeyTile).
  static const Color _faceTop = Color(0xFFF4F4F4);
  static const Color _faceBottom = Color(0xFFFFFFFF);
  static const Color _legend = Color(0xFF2B2B2B);

  /// Padding between the face's edge and its content.
  static const double _contentPadding = 3;

  /// Gap between the sign and the numeral.
  static const double _numeralGap = 2;

  static const double _skirtSide = BslKeyTile.skirtSide;
  static const double _skirtTop = BslKeyTile.skirtTop;
  static const double _skirtBottom = BslKeyTile.skirtBottom;

  /// How far the key travels down when pressed.
  static const double _travel = 2;

  static const Duration _pressDuration = Duration(milliseconds: 60);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final outerRadius = AppSizes.borderRadiusMedium;
    final faceRadius = (outerRadius - 2).clamp(2.0, outerRadius);
    final interactive = widget.onTap != null;
    final pressed = _pressed && interactive;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: AnimatedContainer(
          duration: _pressDuration,
          transform: Matrix4.translationValues(0, pressed ? _travel : 0, 0),
          // Skirt / bevel.
          decoration: BslKeyTile.skirtDecoration(
            radius: outerRadius,
            pressed: pressed,
          ),
          child: AnimatedPadding(
            duration: _pressDuration,
            padding: EdgeInsets.fromLTRB(
              _skirtSide,
              pressed ? _skirtTop + 1 : _skirtTop,
              _skirtSide,
              pressed ? _skirtBottom - _travel - 1 : _skirtBottom,
            ),
            // Dished top face.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(faceRadius),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_faceTop, _faceBottom],
                ),
              ),
              child: CustomPaint(
                painter: BslInnerShadowPainter(
                  radius: faceRadius,
                  shadows: BslKeyTile.faceInnerShadows,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_contentPadding),
                  child: Opacity(
                    opacity: widget.isDisabled ? 0.5 : 1.0,
                    child: widget.showNumber
                        ? Column(
                            children: [
                              Expanded(child: _buildSign()),
                              const SizedBox(height: _numeralGap),
                              // Tight line height so the numeral's unused
                              // descender space doesn't add a bottom gap.
                              Text(
                                '${widget.number}',
                                style: TextStyle(
                                  fontSize: widget.numeralFontSize,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                  color: _legend,
                                ),
                              ),
                            ],
                          )
                        : _buildSign(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The BSL sign, sized to the largest square that fits the space given.
  Widget _buildSign() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        return Center(
          child: BslNumberDisplay(
            number: widget.number,
            size: size,
            hintCounter: widget.hintCounter,
          ),
        );
      },
    );
  }
}

/// Paints inset (inner) shadows inside a rounded rectangle — Flutter's
/// [BoxShadow] only draws outside a box.
///
/// For each shadow, it fills everything *outside* the rounded rect (shifted
/// by the shadow's offset) with a blurred paint, clipped to the rect itself,
/// so only the soft edge bleeds inwards.
class BslInnerShadowPainter extends CustomPainter {
  final double radius;
  final List<BoxShadow> shadows;

  const BslInnerShadowPainter({required this.radius, required this.shadows});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outer = Rect.fromLTWH(
      -size.width,
      -size.height,
      size.width * 3,
      size.height * 3,
    );

    canvas.save();
    canvas.clipRRect(rrect);
    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(shadow.blurRadius),
        );
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer)
        ..addRRect(rrect.shift(shadow.offset));
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BslInnerShadowPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.shadows != shadows;
}
