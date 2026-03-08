// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/painting.dart';
// import 'package:hand_landmarker/hand_landmarker.dart';

// import '../models/hand_landmark_data.dart';
// import 'hand_tracking_service.dart';

// /// Android implementation of [HandTrackingService] using the
// /// [hand_landmarker] package (MediaPipe Hand Landmarker task).
// ///
// /// Detects up to 2 hands per frame and emits [HandLandmarkData] objects
// /// with 21 normalised landmarks each.
// ///
// /// The front camera is used so the player can hold their hands in front
// /// of the device. MediaPipe reports handedness from the image perspective
// /// (mirrored), so we flip the [isLeftHand] flag to match the player's
// /// actual left/right hands.
// class AndroidHandTrackingService implements HandTrackingService {
//   HandLandmarker? _landmarker;
//   final _controller = StreamController<List<HandLandmarkData>>.broadcast();

//   @override
//   Stream<List<HandLandmarkData>> get landmarkStream => _controller.stream;

//   @override
//   Future<void> start() async {
//     try {
//       _landmarker = await HandLandmarker.create(
//         numHands: 2,
//         minHandDetectionConfidence: 0.5,
//         minHandPresenceConfidence: 0.5,
//         minTrackingConfidence: 0.5,
//       );

//       _landmarker!.resultStream.listen(_onResult);
//       await _landmarker!.startCamera(cameraFacing: CameraFacing.front);
//     } catch (e) {
//       debugPrint('AndroidHandTrackingService.start failed: $e');
//     }
//   }

//   void _onResult(HandLandmarkerResult result) {
//     if (_controller.isClosed) return;

//     final hands = <HandLandmarkData>[];

//     for (int i = 0; i < result.landmarks.length; i++) {
//       final rawLandmarks = result.landmarks[i];
//       if (rawLandmarks.length != 21) continue;

//       // MediaPipe reports handedness from the image perspective.
//       // When using the front camera the image is mirrored, so we invert
//       // the label to get the player's actual hand side.
//       final label = result.handedness.length > i
//           ? result.handedness[i].first.categoryName
//           : 'Left';
//       final isPlayerLeftHand = label == 'Right'; // inverted for front camera

//       final landmarks = rawLandmarks
//           .map((lm) => Offset(lm.x, lm.y))
//           .toList(growable: false);

//       hands.add(HandLandmarkData(
//         landmarks: landmarks,
//         isLeftHand: isPlayerLeftHand,
//       ));
//     }

//     _controller.add(hands);
//   }

//   @override
//   Future<void> stop() async {
//     await _landmarker?.stopCamera();
//   }

//   @override
//   void dispose() {
//     _landmarker?.dispose();
//     _controller.close();
//   }
// }
