import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Displays a BSL colour sign from a Rive file and replays it every
/// [replayInterval] while [active].
///
/// When [active] flips from false to true the sign replays straight away, so
/// several instances can be kept mounted (e.g. in an [IndexedStack]) and
/// switched between without reloading the .riv file each time.
///
/// ## Rive spec
/// - File:          `assets/images/colours_BSL/{colourName}.riv`
/// - Artboard:      `{colourName}` (e.g. `green`, `blue`, `pink`, `purple`)
/// - State machine: `{colourName}_state_machine`
/// - Trigger input: `play_{colourName}` (view-model trigger, or the
///   deprecated state-machine input on older files)
class BslColourSign extends StatefulWidget {
  const BslColourSign({
    super.key,
    required this.colourName,
    this.active = true,
    this.replayInterval = const Duration(seconds: 6),
    this.fit = Fit.contain,
  });

  final String colourName;
  final bool active;
  final Duration replayInterval;

  /// How the artboard is sized within the widget's bounds. [Fit.cover]
  /// fills the bounds and crops whatever overflows.
  final Fit fit;

  @override
  State<BslColourSign> createState() => _BslColourSignState();
}

class _BslColourSignState extends State<BslColourSign> {
  late final FileLoader _fileLoader;
  ViewModelInstanceTrigger? _vmTrigger;
  TriggerInput? _playTrigger;
  Timer? _timer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/images/colours_BSL/${widget.colourName}.riv',
      riveFactory: Factory.flutter,
    );
  }

  @override
  void didUpdateWidget(BslColourSign oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active && _loaded) {
      if (widget.active) {
        _startReplaying();
      } else {
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fileLoader.dispose();
    super.dispose();
  }

  void _onLoaded(RiveLoaded state) {
    _loaded = true;
    // Updated .riv files (e.g. green) expose the trigger via a view model;
    // the rest still use the deprecated state machine input.
    _vmTrigger = state.viewModelInstance?.trigger('play_${widget.colourName}');
    if (_vmTrigger == null) {
      _playTrigger = state.controller.stateMachine
          // ignore: deprecated_member_use
          .trigger('play_${widget.colourName}');
    }
    if (widget.active) _startReplaying();
  }

  void _startReplaying() {
    _timer?.cancel();
    _triggerAnimation();
    _timer = Timer.periodic(widget.replayInterval, (_) => _triggerAnimation());
  }

  void _triggerAnimation() {
    if (_vmTrigger != null) {
      _vmTrigger!.trigger();
    } else {
      _playTrigger?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _fileLoader,
      artboardSelector: ArtboardSelector.byName(widget.colourName),
      stateMachineSelector: StateMachineSelector.byName(
        '${widget.colourName}_state_machine',
      ),
      dataBind: const AutoBind(),
      onLoaded: _onLoaded,
      builder: (context, state) => switch (state) {
        RiveLoading() => const SizedBox.shrink(),
        RiveFailed() => const SizedBox.shrink(),
        RiveLoaded() => RiveWidget(
          controller: state.controller,
          fit: widget.fit,
        ),
      },
    );
  }
}
