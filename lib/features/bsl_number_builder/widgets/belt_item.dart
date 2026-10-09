import 'dart:math';

import 'package:flutter/material.dart';

/// A grocery item (an [image]) with a [PriceTag] tied by a string
/// to its top right corner, trailing behind it as it rides the belt.
///
/// [boxSize] is the box's side length; the whole widget is
/// [widthFor]`(boxSize)` × [heightFor]`(boxSize)`, with the box's bottom
/// edge on the widget's bottom edge, so callers can position it.
class BeltItem extends StatelessWidget {
  final double boxSize;
  final String image;
  final int price;
  final bool tagShowsSign;

  const BeltItem({
    super.key,
    required this.boxSize,
    required this.image,
    required this.price,
    required this.tagShowsSign,
  });

  static double widthFor(double boxSize) =>
      _tagLeft(boxSize) + _tagExtent(boxSize).right;
  static double heightFor(double boxSize) => boxSize * 1.22;

  /// Tag tilt about its hole; negative swings the tag's foot away from the
  /// box, as if it's trailing behind on the moving belt.
  static const double _tagAngle = -0.18;

  /// How far the tilted tag's leftmost point overlaps the box's right edge.
  static const double _tagOverlap = 8;

  /// Width of the image canvas relative to [boxSize].
  static const double _imageScale = 4;

  static double _tagWidth(double s) => s * 0.72;
  static double _tagHeight(double s) => s * 0.92;

  /// Hole (and rotation pivot) within the tag, matching [_TagPainter].
  static Offset _tagHole(double s) =>
      Offset(_tagWidth(s) / 2, _tagHeight(s) * 0.13);

  /// Horizontal span of the tilted tag's outline, relative to the unrotated
  /// tag's left edge.
  static ({double left, double right}) _tagExtent(double s) {
    final w = _tagWidth(s);
    final h = _tagHeight(s);
    final cut = w * _TagPainter.cutFraction;
    final pivot = _tagHole(s);
    final xs =
        [
          Offset(cut, 0),
          Offset(w - cut, 0),
          Offset(w, cut),
          Offset(w, h),
          Offset(0, h),
          Offset(0, cut),
        ].map((p) {
          final d = p - pivot;
          return pivot.dx + d.dx * cos(_tagAngle) - d.dy * sin(_tagAngle);
        });
    return (left: xs.reduce(min), right: xs.reduce(max));
  }

  static double _tagLeft(double s) => s - _tagOverlap - _tagExtent(s).left;

  @override
  Widget build(BuildContext context) {
    final s = boxSize;
    final boxTop = heightFor(s) - s;
    final tagLeft = _tagLeft(s);
    final tagWidth = _tagWidth(s);
    final tagHeight = _tagHeight(s);
    final knot = Offset(s * 0.82, boxTop + s * 0.1);
    final hole = Offset(tagLeft, 0) + _tagHole(s);

    return SizedBox(
      width: widthFor(s),
      height: heightFor(s),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: boxTop,
            width: s,
            height: s,
            child: OverflowBox(
              // The artwork sits small in the middle of a 4:3 canvas, so
              // draw the canvas larger than the item, resting on its base.
              maxWidth: s * _imageScale,
              maxHeight: s * _imageScale * 0.75,
              alignment: const Alignment(0, 0.1),
              child: Image.asset(
                image,
                width: s * _imageScale,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: tagLeft,
            top: 0,
            width: tagWidth,
            height: tagHeight,
            child: Transform.rotate(
              angle: _tagAngle,
              // Pivot on the punched hole so the string stays threaded.
              alignment: const Alignment(0, -0.74),
              child: PriceTag(price: price, showSign: tagShowsSign),
            ),
          ),
          // Drawn over the tag so it visibly runs through the hole.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _StringPainter(knot, hole, s)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A cream swing tag with a punched hole, showing [price] as a digit or,
/// when [showSign] is true, as its BSL sign.
class PriceTag extends StatelessWidget {
  final int price;
  final bool showSign;

  const PriceTag({super.key, required this.price, required this.showSign});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _TagPainter(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Padding(
            padding: EdgeInsets.fromLTRB(w * 0.1, h * 0.26, w * 0.1, h * 0.08),
            child: Center(
              child: showSign
                  ? Image.asset(
                      'assets/games/till/signs/sign_$price.png',
                      fit: BoxFit.contain,
                    )
                  : FittedBox(
                      child: Text(
                        '$price',
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          fontSize: 64,
                          height: 1,
                          color: Color(0xFF3B2A12),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// The tag's string: knotted at the box's corner, sagging across the gap and
/// looping through the tag's hole.
class _StringPainter extends CustomPainter {
  final Offset from;
  final Offset to;

  /// Box side length, so the string scales with the item.
  final double scale;

  const _StringPainter(this.from, this.to, this.scale);

  static const Color _twine = Color(0xFFC8102E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final string = Paint()
      ..color = _twine
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.5, s * 0.022);

    final sag = Offset((from.dx + to.dx) / 2, max(from.dy, to.dy) + s * 0.1);
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(sag.dx, sag.dy, to.dx, to.dy),
      string,
    );

    // Loop over the top of the tag, back through the hole.
    canvas.drawArc(
      Rect.fromCircle(center: to.translate(0, -s * 0.03), radius: s * 0.05),
      pi * 0.5,
      pi * 1.5,
      false,
      string,
    );

    // Knot where it's tied round the box.
    canvas.drawCircle(from, s * 0.03, Paint()..color = _twine);
  }

  @override
  bool shouldRepaint(covariant _StringPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.scale != scale;
}

/// Swing-tag outline: top corners clipped, with a punched hole.
class _TagPainter extends CustomPainter {
  const _TagPainter();

  /// Size of the clipped top corners, as a fraction of the tag's width.
  static const double cutFraction = 0.26;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cut = w * cutFraction;
    final r = w * 0.06;
    final outline = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, cut)
      ..close();

    canvas.drawShadow(outline, Colors.black, 3, false);
    canvas.drawPath(outline, Paint()..color = const Color(0xFFFFF4D6));
    canvas.drawPath(
      outline,
      Paint()
        ..color = const Color(0xFFD4A94F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );

    final hole = Offset(w / 2, h * 0.13);
    canvas.drawCircle(
      hole,
      w * 0.075,
      Paint()
        ..color = const Color(0xFFD4A94F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );
    canvas.drawCircle(
      hole,
      w * 0.055,
      Paint()..color = const Color(0xFF2A2A2A),
    );
  }

  @override
  bool shouldRepaint(covariant _TagPainter oldDelegate) => false;
}
