import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../bsl_camera_vowels/models/hand_landmark_data.dart';
import '../../bsl_camera_vowels/services/hand_tracking_service.dart';

/// Game states for the Wave Hello game.
enum WaveHelloGameState { idle, playing, permissionDenied }

/// State manager for the Wave Hello game.
///
/// Uses [HandTrackingService] to stream hand landmarks from the front camera.
/// Detects a waving gesture by tracking horizontal wrist oscillation:
/// a wave is registered when the wrist changes direction 3+ times
/// within a 1.2-second sliding window.
///
/// Each detected wave increments [waveCount], which the screen watches to
/// fire the Rive "wave" trigger on the Catrin character.
class WaveHelloProvider extends ChangeNotifier {
  // ── Services ──────────────────────────────────────────────────────────────

  late final HandTrackingService _trackingService = HandTrackingService.create();
  StreamSubscription<List<HandLandmarkData>>? _landmarkSub;

  // ── Game state ────────────────────────────────────────────────────────────

  WaveHelloGameState _gameState = WaveHelloGameState.idle;
  WaveHelloGameState get gameState => _gameState;

  /// Incremented each time a wave is detected. The screen watches this value
  /// to know when to fire the Rive trigger.
  int _waveCount = 0;
  int get waveCount => _waveCount;

  // ── Wave detection state ──────────────────────────────────────────────────

  /// Rolling history of (timestamp, wrist-x) pairs used to count direction
  /// reversals within the sliding window.
  final _wristHistory = <(DateTime, double)>[];

  /// How long the detection window extends back in time.
  static const _windowDuration = Duration(milliseconds: 1200);

  /// Minimum number of direction reversals to register a wave.
  static const _minDirectionChanges = 3;

  /// Minimum normalised x-movement between samples to count as intentional
  /// (filters out sensor jitter).
  static const _minMovement = 0.015;

  /// Prevents rapid re-triggering: true while in cooldown.
  bool _waveCooldown = false;

  /// How long to wait before the next wave can be detected.
  static const _cooldownDuration = Duration(seconds: 2);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Requests camera permission and starts hand tracking.
  Future<void> start() async {
    if (kIsWeb) {
      _gameState = WaveHelloGameState.permissionDenied;
      notifyListeners();
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _gameState = WaveHelloGameState.permissionDenied;
      notifyListeners();
      return;
    }

    await _trackingService.start();
    _landmarkSub = _trackingService.landmarkStream.listen(_onLandmarks);
    _gameState = WaveHelloGameState.playing;
    notifyListeners();
  }

  void _stop() {
    _landmarkSub?.cancel();
    _landmarkSub = null;
    _trackingService.stop();
  }

  @override
  void dispose() {
    _stop();
    _trackingService.dispose();
    super.dispose();
  }

  // ── Landmark processing ───────────────────────────────────────────────────

  void _onLandmarks(List<HandLandmarkData> hands) {
    if (_gameState != WaveHelloGameState.playing) return;
    if (hands.isEmpty) return;

    // Use whichever hand is most visible (first in list).
    final wristX = hands.first.landmark(0).dx;
    _processWristX(wristX);
  }

  void _processWristX(double x) {
    if (_waveCooldown) return;

    final now = DateTime.now();
    _wristHistory.add((now, x));

    // Prune samples older than the window.
    _wristHistory.removeWhere(
      (e) => now.difference(e.$1) > _windowDuration,
    );

    if (_wristHistory.length < 4) return;

    // Count horizontal direction reversals in the window.
    int reversals = 0;
    double? lastDirection;
    for (int i = 1; i < _wristHistory.length; i++) {
      final dx = _wristHistory[i].$2 - _wristHistory[i - 1].$2;
      if (dx.abs() < _minMovement) continue;
      final dir = dx.sign;
      if (lastDirection != null && dir != lastDirection) reversals++;
      lastDirection = dir;
    }

    if (reversals >= _minDirectionChanges) {
      _onWaveDetected();
    }
  }

  void _onWaveDetected() {
    _waveCount++;
    _waveCooldown = true;
    _wristHistory.clear();
    notifyListeners();

    Timer(_cooldownDuration, () {
      _waveCooldown = false;
    });
  }
}
