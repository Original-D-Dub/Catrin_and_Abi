import 'package:flutter/foundation.dart';

//TODO import '../models/hand_landmark_data.dart';
// On web: resolves to the typedef stub (no hand_landmarker compilation).
// On mobile/desktop: resolves to the real Android implementation.
//T)DO import 'android_hand_tracking_service.dart'
//     if (dart.library.html) 'android_hand_tracking_service_web.dart';
// import 'stub_hand_tracking_service.dart';

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
  // TODO(handtracking) Stream<List<HandLandmarkData>> get landmarkStream;

  /// Begins camera capture and model inference.
  ///
  /// Must be called before [landmarkStream] emits any events.
  Future<void> start();

  /// Pauses camera capture and inference without releasing resources.
  Future<void> stop();

  /// Releases all resources. The service cannot be restarted after disposal.
  void dispose();

  /// Returns the correct implementation for the current platform.
  // TODO (handtracking)
    // TODO(ios): Replace with a MediaPipe platform-channel implementation
    // once the iOS native bridge is available.
  //TODO(handtracking)   return StubHandTrackingService();
  // }
}
