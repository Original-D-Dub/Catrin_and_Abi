import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adds a running elapsed-time stopwatch to a [ChangeNotifier], ticking
/// once a second so a timer display stays current without the screen
/// needing its own [Timer].
///
/// Call [startTimer] when play begins (resets and starts the stopwatch —
/// safe to call again for a fresh Play Again run) and [stopTimer] once
/// the level is complete.
mixin ElapsedTimerMixin on ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTimer;

  /// Time elapsed since the most recent [startTimer] call — frozen once
  /// [stopTimer] is called.
  Duration get elapsedTime => _stopwatch.elapsed;

  void startTimer() {
    _stopwatch
      ..reset()
      ..start();
    _displayTimer?.cancel();
    _displayTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  void stopTimer() {
    _stopwatch.stop();
    _displayTimer?.cancel();
    _displayTimer = null;
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }
}
