import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import 'bsl_key_tile.dart';

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
/// Each key is a [BslKeyTile] showing the BSL hand sign with the numeral
/// below (sign only, filling the key, in championship mode). Tapping a key
/// directly submits it as the answer.
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

  /// Side length of each (square) key for a keyboard laid out in
  /// [availableWidth] x [maxHeight].
  ///
  /// Keys are sized from the available width (3 columns) by default, so
  /// tiles are as large as the width allows rather than being shrunk to fit
  /// a pre-set keyboard height — but capped to [maxHeight] (when the parent
  /// bounds it, e.g. via a ConstrainedBox) so the keyboard never grows large
  /// enough to push other content off-screen. An infinite [maxHeight] has no
  /// effect.
  static double keySizeFor({
    required double availableWidth,
    required double maxHeight,
    required bool showTeenKeys,
    required double scale,
  }) {
    final rowCount = showTeenKeys ? 3 : 4;
    final horizontalPadding = AppSizes.paddingSmall * 2;
    final totalHSpacing = _BslKeyboardState._gridSpacing * 2;
    final keyWidth = (availableWidth - horizontalPadding - totalHSpacing) / 3;

    final verticalPadding = AppSizes.paddingSmall * 2;
    final totalVSpacing = _BslKeyboardState._gridSpacing * (rowCount - 1);
    final keyHeight = (maxHeight - verticalPadding - totalVSpacing) / rowCount;

    return (keyWidth < keyHeight ? keyWidth : keyHeight).clamp(
      50.0 * scale,
      120.0 * scale,
    );
  }

  /// Width from the outer edge of the left key to the outer edge of the
  /// right key in a 3-key row, for the same inputs as [keySizeFor].
  static double rowWidthFor({
    required double availableWidth,
    required double maxHeight,
    required bool showTeenKeys,
    required double scale,
  }) {
    final keySize = keySizeFor(
      availableWidth: availableWidth,
      maxHeight: maxHeight,
      showTeenKeys: showTeenKeys,
      scale: scale,
    );
    return keySize * 3 + _BslKeyboardState._gridSpacing * 2;
  }
}

class _BslKeyboardState extends State<BslKeyboard> {
  /// Font size for numeral labels below BSL signs
  static const double _numeralFontSize = 16.0;

  /// Grid spacing between keys
  static const double _gridSpacing = 8.0;

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
        final keySize = BslKeyboard.keySizeFor(
          availableWidth: availableWidth,
          maxHeight: constraints.maxHeight,
          showTeenKeys: widget.showTeenKeys,
          scale: scale,
        );
        final verticalPadding = AppSizes.paddingSmall * 2;
        final totalVSpacing = _gridSpacing * (rowCount - 1);
        final totalHeight =
            keySize * rowCount + verticalPadding + totalVSpacing;

        // The sign inside each key sizes itself from the key (see
        // BslKeyTile), so only the numeral needs a scale here.
        final numeralFontSize = _numeralFontSize * scale;

        final rows = widget.showTeenKeys
            ? [
                _buildNumberRow([11, 12, 13], keySize, numeralFontSize),
                _buildNumberRow([14, 15, 16], keySize, numeralFontSize),
                _buildNumberRow([17, 18, 19], keySize, numeralFontSize),
              ]
            : [
                // Row 1: 1, 2, 3
                _buildNumberRow([1, 2, 3], keySize, numeralFontSize),

                // Row 2: 4, 5, 6
                _buildNumberRow([4, 5, 6], keySize, numeralFontSize),

                // Row 3: 7, 8, 9
                _buildNumberRow([7, 8, 9], keySize, numeralFontSize),

                // Row 4: 10, centred
                _buildBottomRow(keySize, numeralFontSize),
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
            child: Column(
              children: _withGaps(rows, _gridSpacing, Axis.vertical),
            ),
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
    double numeralFontSize,
  ) {
    final keys = numbers
        .map((number) => _buildNumberKey(number, keySize, numeralFontSize))
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
  Widget _buildBottomRow(double keySize, double numeralFontSize) {
    return SizedBox(
      height: keySize,
      child: Center(child: _buildNumberKey(10, keySize, numeralFontSize)),
    );
  }

  /// Builds a [keySize] square [BslKeyTile]; the tile sizes its own sign.
  Widget _buildNumberKey(int number, double keySize, double numeralFontSize) {
    return SizedBox(
      width: keySize,
      height: keySize,
      child: BslKeyTile(
        number: number,
        onTap: widget.isDisabled ? null : () => widget.onKeyPressed(number),
        showNumber: widget.showNumbers,
        isDisabled: widget.isDisabled,
        hintCounter: _hintCounters[number],
        numeralFontSize: numeralFontSize,
      ),
    );
  }
}
