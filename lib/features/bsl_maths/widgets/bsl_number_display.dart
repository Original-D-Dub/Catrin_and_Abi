import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';

/// Displays a BSL number sign for a given number.
///
/// Single digits (0-10) use SVG hand-sign assets, 11-19 use Rive
/// animations, and two-digit numbers (20-99) are composed from the
/// tens and units digit signs shown side by side — BSL denotes place
/// value positionally, the same way written digits do.
///
/// Used in both the question display area (showing operands) and
/// on keyboard keys (showing available answers).
///
/// Each sign is rendered with [BoxFit.contain] to maintain aspect ratio
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

  /// When provided, the Rive animation retriggers each time the notifier's
  /// value increments. Used by the keyboard hint loop for teen numbers.
  final ValueNotifier<int>? hintCounter;

  /// Default display size matching child-friendly tap target dimensions
  static const double defaultSize = 64.0;

  const BslNumberDisplay({
    super.key,
    required this.number,
    this.size = defaultSize,
    this.hintCounter,
  });

  @override
  Widget build(BuildContext context) {
    if (number >= 13 && number <= 19) {
      return _RiveNumberDisplay(
        key: ValueKey(number),
        number: number,
        size: size,
        hintCounter: hintCounter,
      );
    }
    if (number == 11 || number == 12) {
      return _SimpleRiveDisplay(
        key: ValueKey(number),
        rivPath: number == 11 ? AssetPaths.bslNumber11Riv : AssetPaths.bslNumber12Riv,
        size: size,
        hintCounter: hintCounter,
      );
    }
    if (number >= 20 && number <= 99) {
      // BSL denotes place value positionally, just like written digits:
      // sign the tens digit followed by the units digit, left to right.
      final tens = number ~/ 10;
      final units = number % 10;
      return SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BslNumberDisplay(number: tens, size: size / 2),
            BslNumberDisplay(number: units, size: size / 2),
          ],
        ),
      );
    }
    // Numbers outside SVG range (0-10), 20-99, and not covered by a Rive file.
    if (number < 0 || number > 99) {
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

class _SimpleRiveDisplay extends StatefulWidget {
  final String rivPath;
  final double size;
  final ValueNotifier<int>? hintCounter;

  const _SimpleRiveDisplay({
    super.key,
    required this.rivPath,
    required this.size,
    this.hintCounter,
  });

  @override
  State<_SimpleRiveDisplay> createState() => _SimpleRiveDisplayState();
}

class _SimpleRiveDisplayState extends State<_SimpleRiveDisplay> {
  FileLoader? _fileLoader;
  int _key = 0;

  FileLoader _makeLoader() => FileLoader.fromAsset(
        widget.rivPath,
        riveFactory: Factory.flutter,
      );

  @override
  void initState() {
    super.initState();
    _fileLoader = _makeLoader();
    widget.hintCounter?.addListener(_onHintTick);
  }

  @override
  void didUpdateWidget(_SimpleRiveDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintCounter != oldWidget.hintCounter) {
      oldWidget.hintCounter?.removeListener(_onHintTick);
      widget.hintCounter?.addListener(_onHintTick);
    }
  }

  @override
  void dispose() {
    widget.hintCounter?.removeListener(_onHintTick);
    _fileLoader?.dispose();
    super.dispose();
  }

  void _onHintTick() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final old = _fileLoader;
      setState(() {
        _key++;
        _fileLoader = _makeLoader();
      });
      old?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveWidgetBuilder(
        key: ValueKey(_key),
        fileLoader: _fileLoader!,
        builder: (context, state) => switch (state) {
          RiveLoading() => const SizedBox.shrink(),
          RiveFailed() => const SizedBox.shrink(),
          RiveLoaded(:final controller) => RiveWidget(
              controller: controller,
              fit: Fit.contain,
            ),
        },
      ),
    );
  }
}

class _RiveNumberDisplay extends StatefulWidget {
  final int number;
  final double size;
  final ValueNotifier<int>? hintCounter;

  const _RiveNumberDisplay({
    super.key,
    required this.number,
    required this.size,
    this.hintCounter,
  });

  @override
  State<_RiveNumberDisplay> createState() => _RiveNumberDisplayState();
}

class _RiveNumberDisplayState extends State<_RiveNumberDisplay> {
  FileLoader? _fileLoader;
  int _key = 0;

  FileLoader _makeLoader() => FileLoader.fromAsset(
        AssetPaths.bslNumbers1319Riv,
        riveFactory: Factory.flutter,
      );

  @override
  void initState() {
    super.initState();
    _fileLoader = _makeLoader();
    widget.hintCounter?.addListener(_onHintTick);
  }

  @override
  void didUpdateWidget(_RiveNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintCounter != oldWidget.hintCounter) {
      oldWidget.hintCounter?.removeListener(_onHintTick);
      widget.hintCounter?.addListener(_onHintTick);
    }
  }

  @override
  void dispose() {
    widget.hintCounter?.removeListener(_onHintTick);
    _fileLoader?.dispose();
    super.dispose();
  }

  void _onHintTick() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final old = _fileLoader;
      setState(() {
        _key++;
        _fileLoader = _makeLoader();
      });
      old?.dispose();
    });
  }

  void _onLoaded(RiveLoaded state) {
    final vmi = state.viewModelInstance;
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
        key: ValueKey(_key),
        fileLoader: _fileLoader!,
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
