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
/// Teen Layout (3 columns x 4 rows, single-tap 11-19):
/// ```
///   [11] [12] [13]
///   [14] [15] [16]
///   [17] [18] [19]
///   [ ]  [C]  [=]
/// ```
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

  /// Whether to show teen number layout (11-19, single-tap)
  final bool showTeenKeys;

  /// Whether to show the numeral label below each BSL sign
  final bool showNumbers;

  const BslKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onClearPressed,
    required this.onSubmitPressed,
    this.isDisabled = false,
    this.enteredAnswer,
    this.isCorrect,
    this.showZeroKey = false,
    this.showTeenKeys = false,
    this.showNumbers = true,
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
        final scale = MediaQuery.of(context).size.width >= 600 ? 1.4 : 1.0;

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

        // Clamp key size — bounds double on wide screens
        final clampedWidth = keyWidth.clamp(50.0 * scale, 180.0 * scale);
        final clampedHeight = keyHeight.clamp(40.0 * scale, 120.0 * scale);

        // SVG and font sizes scale with device width
        final svgSize = (clampedHeight * 0.55).clamp(24.0 * scale, 72.0 * scale);
        final numeralFontSize = _numeralFontSize * scale;
        final operatorFontSize = _operatorFontSize * scale;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingSmall,
            vertical: AppSizes.paddingSmall,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: showTeenKeys
                ? [
                    Expanded(child: _buildNumberRow([11, 12, 13], clampedWidth, clampedHeight, svgSize, numeralFontSize)),
                    Expanded(child: _buildNumberRow([14, 15, 16], clampedWidth, clampedHeight, svgSize, numeralFontSize)),
                    Expanded(child: _buildNumberRow([17, 18, 19], clampedWidth, clampedHeight, svgSize, numeralFontSize)),
                    Expanded(child: _buildTeenBottomRow(clampedWidth, clampedHeight, operatorFontSize)),
                  ]
                : [
                    // Row 1: 1, 2, 3
                    Expanded(
                      child: _buildNumberRow(
                          [1, 2, 3], clampedWidth, clampedHeight, svgSize, numeralFontSize),
                    ),

                    // Row 2: 4, 5, 6
                    Expanded(
                      child: _buildNumberRow(
                          [4, 5, 6], clampedWidth, clampedHeight, svgSize, numeralFontSize),
                    ),

                    // Row 3: 7, 8, 9
                    Expanded(
                      child: _buildNumberRow(
                          [7, 8, 9], clampedWidth, clampedHeight, svgSize, numeralFontSize),
                    ),

                    // Row 4: bottom row with clear and submit
                    Expanded(
                      child: showZeroKey
                          // Level 2: 0, C, =
                          ? _buildLevel2BottomRow(clampedWidth, clampedHeight, svgSize, numeralFontSize, operatorFontSize)
                          // Level 1: 10, C, =
                          : _buildLevel1BottomRow(clampedWidth, clampedHeight, svgSize, numeralFontSize, operatorFontSize),
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
    double numeralFontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers
          .map((number) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
                  child: _buildNumberKey(number, keyWidth, keyHeight, svgSize, numeralFontSize),
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
    double numeralFontSize,
    double operatorFontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildNumberKey(10, keyWidth, keyHeight, svgSize, numeralFontSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildClearKey(keyWidth, keyHeight, operatorFontSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildOperatorKey('=', keyWidth, keyHeight, operatorFontSize),
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
    double numeralFontSize,
    double operatorFontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildNumberKey(0, keyWidth, keyHeight, svgSize, numeralFontSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildClearKey(keyWidth, keyHeight, operatorFontSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildSubmitKey(keyWidth, keyHeight, operatorFontSize),
          ),
        ),
      ],
    );
  }

  /// Builds the bottom row for teen layout: spacer, C, =
  Widget _buildTeenBottomRow(
    double keyWidth,
    double keyHeight,
    double operatorFontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Empty spacer in first column
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2), child: SizedBox(width: keyWidth, height: keyHeight))),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildClearKey(keyWidth, keyHeight, operatorFontSize),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gridSpacing / 2),
            child: _buildOperatorKey('=', keyWidth, keyHeight, operatorFontSize),
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
    double numeralFontSize,
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
                  if (showNumbers) ...[
                    const SizedBox(height: 2),
                    // Numeral label below the sign
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: numeralFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Clear (C) key.
  Widget _buildClearKey(double keyWidth, double keyHeight, double operatorFontSize) {
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
              child: Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    fontSize: operatorFontSize,
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
  Widget _buildSubmitKey(double keyWidth, double keyHeight, double operatorFontSize) {
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
                    fontSize: operatorFontSize,
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
  Widget _buildOperatorKey(String symbol, double keyWidth, double keyHeight, double operatorFontSize) {
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
              style: TextStyle(
                fontSize: operatorFontSize,
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