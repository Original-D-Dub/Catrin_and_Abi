import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/hand_landmark_data.dart';
import 'hand_tracking_service.dart';

/// iOS implementation of [HandTrackingService].
///
/// Receives hand landmark data from [HandTrackingPlugin] (Swift) via a
/// Flutter [EventChannel]. The native side uses Apple's Vision framework
/// (VNDetectHumanHandPoseRequest) to detect up to 2 hands per camera frame
/// and emits 21 normalised landmarks per hand in MediaPipe index order.
///
/// Each channel event is a `List` of maps:
/// ```
/// [
///   {
///     "landmarks": [x0, y0, x1, y1, …, x20, y20],  // 42 doubles, 0–1
///     "isLeftHand": true | false
///   },
///   …
/// ]
/// ```
class IosHandTrackingService implements HandTrackingService {
  static const _channel = EventChannel('com.catrinabi.bsl/hand_tracking');

  final _controller = StreamController<List<HandLandmarkData>>.broadcast();
  StreamSubscription<dynamic>? _channelSub;

  @override
  Stream<List<HandLandmarkData>> get landmarkStream => _controller.stream;

  @override
  Future<void> start() async {
    _channelSub = _channel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object error) {
        debugPrint('IosHandTrackingService channel error: $error');
      },
    );
  }

  @override
  Future<void> stop() async {
    await _channelSub?.cancel();
    _channelSub = null;
  }

  @override
  void dispose() {
    _channelSub?.cancel();
    _controller.close();
  }

  void _onEvent(dynamic event) {
    if (event is! List) return;

    final hands = <HandLandmarkData>[];

    for (final raw in event) {
      if (raw is! Map) continue;

      final flatLandmarks = raw['landmarks'];
      final isLeftHand = raw['isLeftHand'] as bool? ?? false;

      if (flatLandmarks is! List || flatLandmarks.length != 42) continue;

      final landmarks = List<Offset>.generate(
        21,
        (i) => Offset(
          (flatLandmarks[i * 2] as num).toDouble(),
          (flatLandmarks[i * 2 + 1] as num).toDouble(),
        ),
        growable: false,
      );

      hands.add(HandLandmarkData(landmarks: landmarks, isLeftHand: isLeftHand));
    }

    _controller.add(hands);
  }
}
