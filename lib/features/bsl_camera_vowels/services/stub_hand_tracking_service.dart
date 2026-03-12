import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hand_landmark_data.dart';
import 'hand_tracking_service.dart';

/// No-op implementation of [HandTrackingService] used on iOS.
///
/// The landmark stream never emits — the game UI loads normally but no
/// hand tracking occurs. Replace with a MediaPipe platform-channel
/// implementation to enable iOS support.

class StubHandTrackingService implements HandTrackingService {
  final _controller = StreamController<List<HandLandmarkData>>.broadcast();

  @override
  Stream<List<HandLandmarkData>> get landmarkStream => _controller.stream;

  @override
  Future<void> start() async {
    debugPrint(
      'StubHandTrackingService: hand tracking is not available on iOS. '
      'TODO: add iOS MediaPipe platform channel implementation.',
    );
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {
    _controller.close();
  }
}
