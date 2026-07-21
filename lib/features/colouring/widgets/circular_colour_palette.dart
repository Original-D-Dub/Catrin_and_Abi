import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A colour palette arranged in two concentric rings around a centre widget
/// (the BSL video circle), rather than the usual linear rows.
///
/// The rings sweep an arc that avoids the direction the centre widget is
/// anchored towards (bottom-right), so every swatch stays on screen.
class CircularColourPalette extends StatelessWidget {
  /// Colours to place around the ring, split evenly between the inner and
  /// outer ring (outer ring gets the extra colour when the count is odd).
  final List<Color> colours;

  /// Currently selected colour (highlighted with border).
  final Color selectedColour;

  /// Callback when a colour is tapped.
  final ValueChanged<Color> onColourSelected;

  /// The widget placed at the centre of the rings (the video circle).
  final Widget centerChild;

  /// Diameter of [centerChild].
  final double centerSize;

  /// Diameter of each colour swatch.
  final double buttonSize;

  /// Gap between the centre circle and the inner ring, and between the
  /// inner and outer ring.
  final double ringGap;

  /// Padding between the outermost swatch edge and the edge of the
  /// background disc.
  final double backgroundPadding;

  /// Start angle of the sweep, in degrees (0 = right/east, 90 = down/south,
  /// 180 = left/west, 270 = up/north).
  final double startAngle;

  /// Angular width of the sweep, in degrees.
  final double sweepAngle;

  const CircularColourPalette({
    super.key,
    required this.colours,
    required this.selectedColour,
    required this.onColourSelected,
    required this.centerChild,
    required this.centerSize,
    this.buttonSize = 36.0,
    this.ringGap = 8.0,
    this.backgroundPadding = 8.0,
    this.startAngle = 160.0,
    this.sweepAngle = 135.0,
  });

  /// Diameter of the full palette (rings + centre), given the same
  /// parameters used at build time. Callers use this to position the
  /// palette so it stays concentric with [centerChild].
  static double diameterFor({
    required double centerSize,
    required double buttonSize,
    double ringGap = 8.0,
    double backgroundPadding = 8.0,
  }) {
    final innerRadius = centerSize / 2 + ringGap + buttonSize / 2;
    final outerRadius = innerRadius + buttonSize + ringGap;
    return outerRadius * 2 + buttonSize + backgroundPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final diameter = diameterFor(
      centerSize: centerSize,
      buttonSize: buttonSize,
      ringGap: ringGap,
      backgroundPadding: backgroundPadding,
    );
    final innerRadius = centerSize / 2 + ringGap + buttonSize / 2;
    final outerRadius = innerRadius + buttonSize + ringGap;

    final outerCount = (colours.length / 2).ceil();
    final innerColours = colours.sublist(0, colours.length - outerCount);
    final outerColours = colours.sublist(colours.length - outerCount);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.headerBorderDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          ..._ring(innerColours, innerRadius, diameter),
          ..._ring(outerColours, outerRadius, diameter),
          Positioned(
            left: diameter / 2 - centerSize / 2,
            top: diameter / 2 - centerSize / 2,
            width: centerSize,
            height: centerSize,
            child: centerChild,
          ),
        ],
      ),
    );
  }

  List<Widget> _ring(List<Color> ringColours, double radius, double diameter) {
    if (ringColours.isEmpty) return [];
    final count = ringColours.length;
    return List.generate(count, (i) {
      final angleDeg = startAngle + sweepAngle * (i + 0.5) / count;
      final angleRad = angleDeg * math.pi / 180;
      final dx = radius * math.cos(angleRad);
      final dy = radius * math.sin(angleRad);
      final colour = ringColours[i];
      return Positioned(
        left: diameter / 2 + dx - buttonSize / 2,
        top: diameter / 2 + dy - buttonSize / 2,
        child: ColourSwatchButton(
          colour: colour,
          isSelected: _coloursEqual(colour, selectedColour),
          onTap: () => onColourSelected(colour),
          buttonSize: buttonSize,
        ),
      );
    });
  }

  bool _coloursEqual(Color a, Color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
  }
}

/// A single circular colour swatch button, shared by every colour palette.
class ColourSwatchButton extends StatelessWidget {
  final Color colour;
  final bool isSelected;
  final VoidCallback onTap;
  final double buttonSize;

  const ColourSwatchButton({
    super.key,
    required this.colour,
    required this.isSelected,
    required this.onTap,
    this.buttonSize = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: colour,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colour.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        // Add checkered pattern for white colour to make it visible
        child: colour == Colors.white
            ? ClipOval(
                child: CustomPaint(
                  size: Size(buttonSize - 2, buttonSize - 2),
                  painter: _CheckerPainter(),
                ),
              )
            : null,
      ),
    );
  }
}

/// Paints a checkered pattern (used for white colour visibility).
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade200;
    const squareSize = 6.0;

    for (double x = 0; x < size.width; x += squareSize * 2) {
      for (double y = 0; y < size.height; y += squareSize * 2) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x + squareSize, y + squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
