import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'bsl_number_display.dart';

/// Calculator-style keyboard using BSL number hand sign SVGs.
///
/// Standard Layout (3 columns x 4 rows):
/// ```
///   [1]  [2]  [3]
///   [4]  [5]  [6]
///   [7]  [8]  [9]
///      [10]
/// ```
///
/// Teen Layout (3 columns x 3 rows, single-tap 11-19, auto-submits):
/// ```
///   [11] [12] [13]
///   [14] [15] [16]
///   [17] [18] [19]
/// ```
///
/// Number keys are tappable and show the BSL hand sign SVG with the
/// numeral below. Tapping a key directly submits it as the answer.
class BslKeyboard extends StatefulWidget {
  /// Callback when a number key (0-10) is pressed
  final ValueChanged<int> onKeyPressed;

  /// Whether the keyboard is currently disabled (during feedback display)
  final bool isDisabled;

  /// The currently entered answer (for display purposes)
  final int? enteredAnswer;

  /// Whether to show teen number layout (11-19, single-tap)
  final bool showTeenKeys;

  /// Whether to show the numeral label below each BSL sign
  final bool showNumbers;

  const BslKeyboard({
    super.key,
    required this.onKeyPressed,
    this.isDisabled = false,
    this.enteredAnswer,
    this.showTeenKeys = false,
    this.showNumbers = true,
  });

  @override
  State<BslKeyboard> createState() => _BslKeyboardState();
}

class _BslKeyboardState extends State<BslKeyboard> {
  /// Border width for unselected keys
  static const double _borderWidth = 2;

  /// Font size for numeral labels below BSL signs
  static const double _numeralFontSize = 16.0;

  /// Grid spacing between keys
  static const double _gridSpacing = 8.0;

  /// Gap from the key's top edge to the SVG, and from the numeral to the
  /// key's bottom edge — kept equal so the content looks centred.
  static const double _keyEdgePadding = _gridSpacing / 2;

  static const List<int> _hintNumbers = [11, 12, 13, 14, 15, 16, 17, 18, 19];
  static const Duration _betweenSigns = Duration(milliseconds: 1200);
  static const Duration _pauseAfterSequence = Duration(seconds: 3);
  static const Duration _initialDelay = Duration(seconds: 3);

  final Map<int, ValueNotifier<int>> _hintCounters = {};
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    for (final n in _hintNumbers) {
      _hintCounters[n] = ValueNotifier(0);
    }
    if (widget.showTeenKeys) _scheduleHintStart();
  }

  @override
  void didUpdateWidget(BslKeyboard old) {
    super.didUpdateWidget(old);
    if (widget.showTeenKeys && !old.showTeenKeys) {
      _scheduleHintStart();
    } else if (!widget.showTeenKeys && old.showTeenKeys) {
      _hintTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    for (final c in _hintCounters.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleHintStart() {
    _hintTimer?.cancel();
    _hintTimer = Timer(_initialDelay, () => _runSequence(0));
  }

  void _runSequence(int index) {
    if (!mounted) return;
    if (index >= _hintNumbers.length) {
      _hintTimer = Timer(_pauseAfterSequence, () => _runSequence(0));
      return;
    }
    // Increment the counter — _RiveNumberDisplay listens and retriggers its animation.
    _hintCounters[_hintNumbers[index]]?.value++;
    _hintTimer = Timer(_betweenSigns, () => _runSequence(index + 1));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final scale = MediaQuery.of(context).size.width >= 600 ? 1.4 : 1.0;

        // Teen layout has no bottom row, so it only needs 3 rows.
        final rowCount = widget.showTeenKeys ? 3 : 4;

        // Keys are always square (1:1). Size from the available width (3
        // columns) by default, so tiles are as large as the width allows
        // rather than being shrunk to fit a pre-set keyboard height — but
        // cap to the available height (when the parent bounds it, e.g.
        // via a ConstrainedBox) so the keyboard never grows large enough
        // to push other content off-screen. When height is unconstrained,
        // constraints.maxHeight is infinite and has no effect.
        final horizontalPadding = AppSizes.paddingSmall * 2;
        final totalHSpacing = _gridSpacing * 2; // 2 gaps for 3 columns
        final keyWidth =
            (availableWidth - horizontalPadding - totalHSpacing) / 3;

        final verticalPadding = AppSizes.paddingSmall * 2;
        final totalVSpacing = _gridSpacing * (rowCount - 1);
        final keyHeight =
            (constraints.maxHeight - verticalPadding - totalVSpacing) / rowCount;

        final keySize = (keyWidth < keyHeight ? keyWidth : keyHeight)
            .clamp(50.0 * scale, 120.0 * scale);
        final totalHeight = keySize * rowCount + verticalPadding + totalVSpacing;

        // SVG/Rive sign size scales with device width, plus an extra 50%
        // on tablets (>=600px) so the hand-sign animations read clearly
        // at that size.
        final iconScale = MediaQuery.of(context).size.width >= 600 ? 1.5 : 1.0;
        final svgSize = (keySize * 0.5 * iconScale)
            .clamp(24.0 * scale * iconScale, 72.0 * scale * iconScale);
        final numeralFontSize = _numeralFontSize * scale;

        final rows = widget.showTeenKeys
            ? [
                _buildNumberRow([11, 12, 13], keySize, svgSize, numeralFontSize),
                _buildNumberRow([14, 15, 16], keySize, svgSize, numeralFontSize),
                _buildNumberRow([17, 18, 19], keySize, svgSize, numeralFontSize),
              ]
            : [
                // Row 1: 1, 2, 3
                _buildNumberRow([1, 2, 3], keySize, svgSize, numeralFontSize),

                // Row 2: 4, 5, 6
                _buildNumberRow([4, 5, 6], keySize, svgSize, numeralFontSize),

                // Row 3: 7, 8, 9
                _buildNumberRow([7, 8, 9], keySize, svgSize, numeralFontSize),

                // Row 4: 10, centred
                _buildBottomRow(keySize, svgSize, numeralFontSize),
              ];

        return SizedBox(
          height: totalHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
              vertical: AppSizes.paddingSmall,
            ),
            // Explicit gaps (rather than mainAxisAlignment.spaceEvenly) so
            // the vertical gap between rows exactly matches the
            // horizontal gap between keys in a row (both _gridSpacing).
            child: Column(children: _withGaps(rows, _gridSpacing, Axis.vertical)),
          ),
        );
      },
    );
  }

  /// Interleaves [gap]-sized [SizedBox]es between [items] along [axis].
  List<Widget> _withGaps(List<Widget> items, double gap, Axis axis) {
    final spacer = axis == Axis.vertical
        ? SizedBox(height: gap)
        : SizedBox(width: gap);
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(spacer);
      result.add(items[i]);
    }
    return result;
  }

  /// Builds a row of number keys.
  Widget _buildNumberRow(
    List<int> numbers,
    double keySize,
    double svgSize,
    double numeralFontSize,
  ) {
    final keys = numbers
        .map((number) => _buildNumberKey(number, keySize, svgSize, numeralFontSize))
        .toList();
    return SizedBox(
      height: keySize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _withGaps(keys, _gridSpacing, Axis.horizontal),
      ),
    );
  }

  /// Builds the bottom row: 10, centred
  Widget _buildBottomRow(
    double keySize,
    double svgSize,
    double numeralFontSize,
  ) {
    return SizedBox(
      height: keySize,
      child: Center(
        child: _buildNumberKey(10, keySize, svgSize, numeralFontSize),
      ),
    );
  }

  /// Builds a tappable number key with BSL SVG and numeral label.
  Widget _buildNumberKey(
    int number,
    double keySize,
    double svgSize,
    double numeralFontSize,
  ) {
    // Background colour for glass effect
    const Color bgColor = Colors.white;

    return GestureDetector(
      onTap: widget.isDisabled ? null : () => widget.onKeyPressed(number),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: keySize,
            height: keySize,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: _borderWidth,
              ),
            ),
            child: Opacity(
              opacity: widget.isDisabled ? 0.5 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Equal to the gap below the numeral, so the SVG isn't
                  // closer to the top edge than the numeral is to the
                  // bottom edge.
                  const SizedBox(height: _keyEdgePadding),
                  // BSL hand sign SVG
                  BslNumberDisplay(
                    number: number,
                    size: svgSize,
                    hintCounter: _hintCounters[number],
                  ),
                  if (widget.showNumbers) ...[
                    const SizedBox(height: 2),
                    // Numeral label below the sign. A tight line height
                    // avoids the font's descender space (unused by pure
                    // digits) making this look further from the bottom
                    // edge than the SVG is from the top.
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: numeralFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: _keyEdgePadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}