import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// A multi-row colour palette for selecting colours.
///
/// Displays colours organised into rows of circular buttons
/// that the user can tap to select a colour for painting.
///
/// Usage:
/// ```dart
/// ColourPalette(
///   colourRows: [
///     [Colors.red, Colors.blue, Colors.green],
///     [Colors.brown, Colors.grey],
///   ],
///   selectedColour: Colors.red,
///   onColourSelected: (colour) => handleSelection(colour),
/// )
/// ```
class ColourPalette extends StatelessWidget {
  /// List of colour rows to display
  final List<List<Color>> colourRows;

  /// Currently selected colour (highlighted with border)
  final Color selectedColour;

  /// Callback when a colour is tapped
  final ValueChanged<Color> onColourSelected;

  const ColourPalette({
    super.key,
    required this.colourRows,
    required this.selectedColour,
    required this.onColourSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: colourRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((colour) {
                  final isSelected = _coloursEqual(colour, selectedColour);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ColourButton(
                      colour: colour,
                      isSelected: isSelected,
                      onTap: () => onColourSelected(colour),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Compares two colours for equality.
  bool _coloursEqual(Color a, Color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
  }
}

/// Individual colour button in the palette.
class _ColourButton extends StatelessWidget {
  /// The colour to display
  final Color colour;

  /// Whether this colour is currently selected
  final bool isSelected;

  /// Callback when button is tapped
  final VoidCallback onTap;

  /// Size of the colour button
  static const double _buttonSize = 36.0;

  const _ColourButton({
    required this.colour,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _buttonSize,
        height: _buttonSize,
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
                  size: const Size(_buttonSize - 2, _buttonSize - 2),
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
