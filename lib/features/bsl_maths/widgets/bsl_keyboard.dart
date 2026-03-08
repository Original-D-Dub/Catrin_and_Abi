import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'bsl_number_display.dart';

/// Calculator-style keyboard using BSL number hand sign SVGs.
///
/// Level 1 Layout (3 columns x 4 rows):
/// ```
///   [1]  [2]  [3]
///   [4]  [5]  [6]
///   [7]  [8]  [9]
///   [10] [C]  [=]
/// ```
///
/// Level 2 Layout (3 columns x 4 rows, 0-9 for two-digit input):
/// ```
///   [1]  [2]  [3]
///   [4]  [5]  [6]
///   [7]  [8]  [9]
///   [0]  [C]  [=]
/// ```
///
/// In Level 2, two-digit numbers are entered by tapping individual digits.
/// For example, to answer 10, tap [1] then [0].
///
/// Number keys are tappable and show the BSL hand sign SVG
/// with the numeral below. The C key clears the current answer.
/// The = key submits the answer.
class BslKeyboard extends StatelessWidget {
  /// Callback when a number key (0-10) is pressed
  final ValueChanged<int> onKeyPressed;

  /// Callback when the clear (C) key is pressed
  final VoidCallback onClearPressed;

  /// Callback when the submit (=) key is pressed
  final VoidCallback onSubmitPressed;

  /// Whether the keyboard is currently disabled (during feedback display)
  final bool isDisabled;

  /// The currently entered answer (for display purposes)
  final int? enteredAnswer;

  /// Whether the entered answer was correct, null if not yet submitted
  final bool? isCorrect;

  /// Whether to show Level 2 layout with 0 key
  final bool showZeroKey;

  const BslKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onClearPressed,
    required this.onSubmitPressed,
    this.isDisabled = false,
    this.enteredAnswer,
    this.isCorrect,
    this.showZeroKey = false,
  });

  /// Border width for unselected keys
  static const double _borderWidth = 2;

  /// Border width for selected key
  static const double _selectedBorderWidth = 3.0;

  /// Font size for numeral labels below BSL signs
  static const double _numeralFontSize = 16.0;

  /// Font size for operator symbols (C, =)
  static const double _operatorFontSize = 28.0;

  /// Grid spacing between keys
  static const double _gridSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Both levels use 4 rows
        const rowCount = 4;

        // Calculate key size based on available space (3 columns, 4 rows)
        final horizontalPadding = AppSizes.paddingSmall * 2;
        final totalHSpacing = _gridSpacing * 2; // 2 gaps for 3 columns
        final keyWidth =
            (availableWidth - horizontalPadding - totalHSpacing) / 3;

        final totalVSpacing = _gridSpacing * (rowCount - 1);
        final verticalPadding = AppSizes.paddingSmall * 2;
        final keyHeight =
            (availableHeight - verticalPadding - totalVSpacing) / rowCount;

        // Clamp key size to reasonable bounds
        final clampedWidth = keyWidth.clamp(50.0, 180.0);
        final clampedHeight = keyHeight.clamp(40.0, 120.0);

        // SVG size scales with key size
        final svgSize = (clampedHeight * 0.55).clamp(24.0, 72.0);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingSmall,
            vertical: AppSizes.paddingSmall,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Row 1: 1, 2, 3
              Expanded(
                child: _buildNumberRow(
                    [1, 2, 3], clampedWidth, clampedHeight, svgSize),
              ),

              // Row 2: 4, 5, 6
              Expanded(
                child: _buildNumberRow(
                    [4, 5, 6], clampedWidth, clampedHeight, svgSize),
              ),

              // Row 3: 7, 8, 9
              Expanded(
                child: _buildNumberRow(
                    [7, 8, 9], clampedWidth, clampedHeight, svgSize),
              ),

              // Row 4: bottom row with clear and submit
              Expanded(
                child: showZeroKey
                    // Level 2: 0, C, =
                    ? _buildLevel2BottomRow(clampedWidth, clampedHeight, svgSize)
                    // Level 1: 10, C, =
                    : _buildLevel1BottomRow(clampedWidth, clampedHeight, svgSize),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a row of number keys.
  Widget _buildNumberRow(
    List<int> numbers,
    double keyWidth,
    double keyHeight,
    double svgSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers
          .map((number) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
                  child: _buildNumberKey(number, keyWidth, keyHeight, svgSize),
                ),
              ))
          .toList(),
    );
  }

  /// Builds the bottom row for Level 1: 10, C, =
  Widget _buildLevel1BottomRow(
    double keyWidth,
    double keyHeight,
    double svgSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildNumberKey(10, keyWidth, keyHeight, svgSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildClearKey(keyWidth, keyHeight),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildOperatorKey('=', keyWidth, keyHeight),
          ),
        ),
      ],
    );
  }

  /// Builds the bottom row for Level 2: 0, C, =
  Widget _buildLevel2BottomRow(
    double keyWidth,
    double keyHeight,
    double svgSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildNumberKey(0, keyWidth, keyHeight, svgSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildClearKey(keyWidth, keyHeight),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildSubmitKey(keyWidth, keyHeight),
          ),
        ),
      ],
    );
  }

  /// Builds a tappable number key with BSL SVG and numeral label.
  Widget _buildNumberKey(
    int number,
    double keyWidth,
    double keyHeight,
    double svgSize,
  ) {
    // Background colour for glass effect
    const Color bgColor = Colors.white;

    return GestureDetector(
      onTap: isDisabled ? null : () => onKeyPressed(number),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: keyWidth,
            height: keyHeight,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: _borderWidth,
              ),
            ),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BSL hand sign SVG
                  BslNumberDisplay(
                    number: number,
                    size: svgSize,
                  ),
                  const SizedBox(height: 2),
                  // Numeral label below the sign
                  Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: _numeralFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Clear (C) key.
  Widget _buildClearKey(double keyWidth, double keyHeight) {
    return GestureDetector(
      onTap: isDisabled ? null : onClearPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: keyWidth,
            height: keyHeight,
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              border: Border.all(
                color: AppColors.accentOrange,
                width: _borderWidth,
              ),
            ),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    fontSize: _operatorFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Submit (=) key for Level 2.
  Widget _buildSubmitKey(double keyWidth, double keyHeight) {
    // Change colour based on whether answer is entered and correct/wrong
    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (isCorrect == true) {
      bgColor = AppColors.success.withValues(alpha: 0.2);
      textColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (isCorrect == false) {
      bgColor = AppColors.accentRed.withValues(alpha: 0.2);
      textColor = AppColors.accentRed;
      borderColor = AppColors.accentRed;
    } else {
      bgColor = AppColors.accentLimeGreen;
      textColor = AppColors.accentWhite;
      borderColor = AppColors.accentLimeGreen;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onSubmitPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: keyWidth,
            height: keyHeight,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.4),
                width: isCorrect != null ? _selectedBorderWidth : _borderWidth,
              ),
            ),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Center(
                child: Text(
                  '=',
                  style: TextStyle(
                    fontSize: _operatorFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a non-interactive operator key for display purposes.
  Widget _buildOperatorKey(String symbol, double keyWidth, double keyHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: keyWidth,
          height: keyHeight,
          decoration: BoxDecoration(
            color: AppColors.mathBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: _borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: _operatorFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.accentWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}