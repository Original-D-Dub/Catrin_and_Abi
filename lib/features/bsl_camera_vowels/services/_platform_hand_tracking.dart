// Native build: dispatches to the correct platform implementation.
// This file is NOT compiled on web — the conditional import in
// hand_tracking_service.dart selects _platform_hand_tracking_web.dart instead.
import 'package:flutter/foundation.dart';

import 'android_hand_tracking_service.dart';
import 'hand_tracking_service.dart';
import 'ios_hand_tracking_service.dart';
import 'stub_hand_tracking_service.dart';

HandTrackingService createPlatformHandTrackingService() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidHandTrackingService();
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return IosHandTrackingService();
  }
  return StubHandTrackingService();
}
