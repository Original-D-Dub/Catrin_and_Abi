import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/asset_paths.dart';
import '../models/hand_landmark_data.dart';

/// Displays the left-hand guide illustration.
///
/// When [rivFilePath] is provided the widget shows a Rive animation driven
/// by [activeFingertipIndex] and [wrongFingertipIndex] via Data Binding;
/// otherwise it falls back to the SVG asset.
///
/// ## Rive spec
/// - Artboard: `"LeftHand"`
/// - State machine: `"FingertipHighlight"`
/// - ViewModel booleans: `"thumb_active"`, `"index_active"`, `"middle_active"`,
///   `"ring_active"`, `"pinky_active"`
/// - ViewModel booleans: `"thumb_wrong"`, `"index_wrong"`, `"middle_wrong"`,
///   `"ring_wrong"`, `"pinky_wrong"`
class HandGuideDisplay extends StatefulWidget {
  const HandGuideDisplay({
    super.key,
    this.rivFilePath,
    this.activeFingertipIndex,
    this.wrongFingertipIndex,
  });

  /// Optional path to a .riv file, e.g. `'assets/hand_palm.riv'`
  final String? rivFilePath;

  /// Landmark index of the currently active (correctly touched) fingertip,
  /// or null when none. See [kFingertipIndices] for valid values.
  final int? activeFingertipIndex;

  /// Landmark index of the last incorrectly touched fingertip (Level 2 only),
  /// or null when no wrong touch is active.
  final int? wrongFingertipIndex;

  @override
  State<HandGuideDisplay> createState() => _HandGuideDisplayState();
}

/// Maps MediaPipe fingertip landmark index → ViewModel boolean name prefix.
const Map<int, String> _kInputPrefix = {
  kThumbTip:  'thumb',
  kIndexTip:  'index',
  kMiddleTip: 'middle',
  kRingTip:   'ring',
  kPinkyTip:  'pinky',
};

class _HandGuideDisplayState extends State<HandGuideDisplay> {
  FileLoader? _fileLoader;
  ViewModelInstance? _vmi;

  @override
  void initState() {
    super.initState();
    if (widget.rivFilePath != null) {
      _fileLoader = FileLoader.fromAsset(
        widget.rivFilePath!,
        riveFactory: Factory.flutter,
      );
    }
  }

  @override
  void didUpdateWidget(HandGuideDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeFingertipIndex != oldWidget.activeFingertipIndex ||
        widget.wrongFingertipIndex != oldWidget.wrongFingertipIndex) {
      _driveInputs();
    }
  }

  @override
  void dispose() {
    _fileLoader?.dispose();
    super.dispose();
  }

  void _onLoaded(RiveLoaded state) {
    _vmi = state.viewModelInstance;
    _driveInputs();
  }

  /// Pushes current active/wrong state into the ViewModel boolean properties.
  void _driveInputs() {
    final vmi = _vmi;
    if (vmi == null) return;
    for (final entry in _kInputPrefix.entries) {
      final prefix = entry.value;
      vmi.boolean('${prefix}_active')?.value =
          entry.key == widget.activeFingertipIndex;
      vmi.boolean('${prefix}_wrong')?.value =
          entry.key == widget.wrongFingertipIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileLoader = _fileLoader;
    if (fileLoader != null) {
      return RiveWidgetBuilder(
        fileLoader: fileLoader,
        artboardSelector: ArtboardSelector.byName('LeftHand'),
        stateMachineSelector: StateMachineSelector.byName('FingertipHighlight'),
        dataBind: const AutoBind(),
        onLoaded: _onLoaded,
        builder: (context, state) => switch (state) {
          RiveLoading() => const SizedBox.shrink(),
          RiveFailed() => _svgFallback(),
          RiveLoaded() => RiveWidget(
              controller: state.controller,
              fit: Fit.contain,
            ),
        },
      );
    }
    return _svgFallback();
  }

  Widget _svgFallback() => SvgPicture.asset(
        AssetPaths.vowelHandOpen,
        fit: BoxFit.contain,
      );
}
