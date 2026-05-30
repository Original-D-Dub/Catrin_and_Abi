import '../models/hand_landmark_data.dart';
// dart.library.html is only available on web, so the web stub factory is
// selected there; the native factory (which imports jni-dependent packages)
// is selected on Android/iOS/desktop.
import '_platform_hand_tracking.dart'
    if (dart.library.html) '_platform_hand_tracking_web.dart';

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
  /// Dispatched at compile time via the conditional import:
  /// - Android/iOS/desktop → native factory (MediaPipe / Apple Vision)
  /// - web → stub factory (no-op, no jni dependency)
  factory HandTrackingService.create() => createPlatformHandTrackingService();
}
