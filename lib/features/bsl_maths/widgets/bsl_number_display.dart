import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';

/// Displays a BSL number sign SVG for a given number (0-10).
///
/// Used in both the question display area (showing operands) and
/// on keyboard keys (showing available answers).
///
/// The SVG is rendered with [BoxFit.contain] to maintain aspect ratio
/// within the given [size] constraints.
///
/// Example:
/// ```dart
/// BslNumberDisplay(number: 5, size: 80.0)
/// ```
class BslNumberDisplay extends StatelessWidget {
  /// The number to display (0-10), corresponding to a BSL hand sign SVG
  final int number;

  /// The width and height of the display area in logical pixels
  final double size;

  /// Default display size matching child-friendly tap target dimensions
  static const double defaultSize = 64.0;

  const BslNumberDisplay({
    super.key,
    required this.number,
    this.size = defaultSize,
  });

  @override
  Widget build(BuildContext context) {
    if (number >= 13 && number <= 19) {
      return _RiveNumberDisplay(
        key: ValueKey(number),
        number: number,
        size: size,
      );
    }
    // Numbers outside SVG range (0-10) — e.g. 11, 12 — shown as numeral.
    if (number < 0 || number > 10) {
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
      child: SvgPicture.asset(
        AssetPaths.bslNumber(number),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RiveNumberDisplay extends StatefulWidget {
  final int number;
  final double size;

  const _RiveNumberDisplay({super.key, required this.number, required this.size});

  @override
  State<_RiveNumberDisplay> createState() => _RiveNumberDisplayState();
}

class _RiveNumberDisplayState extends State<_RiveNumberDisplay> {
  late final FileLoader _fileLoader;
  ViewModelInstance? _vmi;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      AssetPaths.bslNumbers1319Riv,
      riveFactory: Factory.flutter,
    );
  }

  @override
  void didUpdateWidget(_RiveNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != oldWidget.number) _driveInputs();
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  void _onLoaded(RiveLoaded state) {
    _vmi = state.viewModelInstance;
    _driveInputs();
  }

  void _driveInputs() {
    final vmi = _vmi;
    if (vmi == null) return;
    vmi.number('v_style_data')?.value = widget.number.toDouble();
    vmi.trigger('t_play_data')?.trigger();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader,
        dataBind: const AutoBind(),
        onLoaded: _onLoaded,
        builder: (context, state) => switch (state) {
          RiveLoading() => const SizedBox.shrink(),
          RiveFailed() => const SizedBox.shrink(),
          RiveLoaded() => RiveWidget(
              controller: state.controller,
              fit: Fit.contain,
            ),
        },
      ),
    );
  }
}
