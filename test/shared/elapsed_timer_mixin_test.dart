import 'package:catrin_abi_bsl/shared/mixins/elapsed_timer_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _TimedNotifier extends ChangeNotifier with ElapsedTimerMixin {}

void main() {
  test('elapsed time runs after startTimer and freezes after stopTimer', () {
    final notifier = _TimedNotifier();

    notifier.startTimer();
    expect(notifier.elapsedTime, lessThan(const Duration(milliseconds: 5)));

    // Real elapsed time (Stopwatch reads the wall clock, not fake async).
    final busyUntil = DateTime.now().add(const Duration(milliseconds: 20));
    while (DateTime.now().isBefore(busyUntil)) {}
    expect(notifier.elapsedTime, greaterThan(Duration.zero));

    notifier.stopTimer();
    final frozen = notifier.elapsedTime;
    final busyUntil2 = DateTime.now().add(const Duration(milliseconds: 20));
    while (DateTime.now().isBefore(busyUntil2)) {}
    expect(notifier.elapsedTime, frozen);

    notifier.dispose();
  });

  test('startTimer again resets elapsed time from zero', () {
    final notifier = _TimedNotifier();

    notifier.startTimer();
    final busyUntil = DateTime.now().add(const Duration(milliseconds: 20));
    while (DateTime.now().isBefore(busyUntil)) {}
    notifier.stopTimer();
    expect(notifier.elapsedTime, greaterThan(Duration.zero));

    notifier.startTimer();
    expect(notifier.elapsedTime, lessThan(const Duration(milliseconds: 5)));

    notifier.dispose();
  });
}
