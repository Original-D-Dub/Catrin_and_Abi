/// Web stub — prevents [android_hand_tracking_service.dart] (and its
/// [hand_landmarker] dependency) from being compiled in web builds.
///
/// Dart's conditional import in [hand_tracking_service.dart] selects this
/// file on web instead of the real Android implementation, so
/// [AndroidHandTrackingService] resolves to [StubHandTrackingService] at
/// compile time and [hand_landmarker] is never linked into the web bundle.
library;

import 'stub_hand_tracking_service.dart';

typedef AndroidHandTrackingService = StubHandTrackingService;
