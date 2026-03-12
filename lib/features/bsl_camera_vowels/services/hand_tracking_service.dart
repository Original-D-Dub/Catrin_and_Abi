import 'package:flutter/foundation.dart';

import '../models/hand_landmark_data.dart';
import 'android_hand_tracking_service.dart';
import 'ios_hand_tracking_service.dart';
import 'stub_hand_tracking_service.dart';

/// Abstract interface for real-time hand landmark detection.
///
/// Implementations stream [HandLandmarkData] for up to 2 hands detected
/// per camera frame. Consumers subscribe to [landmarkStream] and call
/// [start] / [stop] to control capture.
///
/// Use [HandTrackingService.create()] to get the correct implementation
/// for the current platform:
/// - Android → [AndroidHandTrackingService] (MediaPipe hand_landmarker)
/// - iOS/web → [StubHandTrackingService] (no-op; iOS support pending)
abstract class HandTrackingService {
  /// Stream of detected hands emitted once per processed camera frame.
  ///
  /// Each event is a list of 0–2 [HandLandmarkData] objects.
  /// An empty list means no hands were detected in that frame.
  Stream<List<HandLandmarkData>> get landmarkStream;

  /// Begins camera capture and model inference.
  ///
  /// Must be called before [landmarkStream] emits any events.
  Future<void> start();

  /// Pauses camera capture and inference without releasing resources.
  Future<void> stop();

  /// Releases all resources. The service cannot be restarted after disposal.
  void dispose();

  /// Returns the correct implementation for the current platform.
  ///
  /// - Android → [AndroidHandTrackingService] (MediaPipe via JNI)
  /// - iOS     → [IosHandTrackingService] (Apple Vision framework)
  /// - web/desktop → [StubHandTrackingService] (no-op)
  factory HandTrackingService.create() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return AndroidHandTrackingService();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return IosHandTrackingService();
      }
    }
    return StubHandTrackingService();
  }
}
