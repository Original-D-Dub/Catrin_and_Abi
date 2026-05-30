// Web build: always returns the no-op stub — no jni, no camera, no native code.
import 'hand_tracking_service.dart';
import 'stub_hand_tracking_service.dart';

HandTrackingService createPlatformHandTrackingService() =>
    StubHandTrackingService();
