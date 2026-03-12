import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../models/hand_landmark_data.dart';
import 'hand_tracking_service.dart';

/// Android implementation of [HandTrackingService] using the
/// [hand_landmarker] package (MediaPipe Hand Landmarker task via JNI).
///
/// Opens the front camera invisibly (no preview), streams YUV frames into
/// [HandLandmarkerPlugin.detect], and emits [HandLandmarkData] objects with
/// 21 normalised landmarks each.
///
/// Handedness is estimated geometrically from the cross-product of
/// wrist→index-MCP and wrist→pinky-MCP vectors, since [hand_landmarker]
/// 2.1.x does not expose a handedness classifier. The estimate is reliable
/// when the palm faces the camera; it may need tuning if edge cases arise.
class AndroidHandTrackingService implements HandTrackingService {
  HandLandmarkerPlugin? _plugin;
  CameraController? _cameraController;
  final _controller = StreamController<List<HandLandmarkData>>.broadcast();
  bool _isProcessing = false;

  @override
  Stream<List<HandLandmarkData>> get landmarkStream => _controller.stream;

  @override
  Future<void> start() async {
    try {
      // Initialise the MediaPipe hand-landmarker (synchronous JNI call).
      _plugin = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5
      );

      // Locate the front-facing camera.
       final cameras = await availableCameras();
       final frontCamera = cameras.firstWhere(
         (c) => c.lensDirection == CameraLensDirection.front,
         orElse: () => cameras.first,
       );
  
       // YUV 4:2:0 is required by hand_landmarker's detect() method.
        _cameraController = CameraController(
         frontCamera,
         ResolutionPreset.medium,
         enableAudio: false,
         imageFormatGroup: ImageFormatGroup.yuv420,
       );
       await _cameraController!.initialize();
       await _cameraController!.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('AndroidHandTrackingService.start failed: $e');
    }
  }

  void _processFrame(CameraImage image) {
     if (_isProcessing || _plugin == null || _controller.isClosed) return;
     _isProcessing = true;

    try {
       final sensorOrientation =
           _cameraController?.description.sensorOrientation ?? 270;
       final rawHands = _plugin!.detect(image, sensorOrientation);
 
      final hands = rawHands
          .where((h) => h.landmarks.length == 21)
          .map((h) {
            final landmarks = h.landmarks
                .map((lm) => Offset(lm.x, lm.y))
                .toList(growable: false);
            return HandLandmarkData(
              landmarks: landmarks,
              isLeftHand: _isPlayerLeftHand(landmarks),
            );
          })
          .toList();
 
      _controller.add(hands);
    } catch (e) {
      debugPrint('AndroidHandTrackingService._processFrame error: $e');
    } finally {
      _isProcessing = false;
}
    }

  /// Estimates whether [lm] belongs to the player's left hand.
  ///
  /// Uses the 2-D cross product of the wrist→index-MCP (lm[5]) and
  /// wrist→pinky-MCP (lm[17]) vectors. In image coordinates (y increases
  /// downward) with a mirrored front camera, a positive cross product
  /// corresponds to the player's left hand when the palm faces the camera.
  bool _isPlayerLeftHand(List<Offset> lm) {
    final wrist = lm[0];
    final indexMcp = lm[5];
    final pinkyMcp = lm[17];
    final cross =
        (indexMcp.dx - wrist.dx) * (pinkyMcp.dy - wrist.dy) -
        (indexMcp.dy - wrist.dy) * (pinkyMcp.dx - wrist.dx);
    return cross > 0;
  }

  @override
  Future<void> stop() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      debugPrint('AndroidHandTrackingService.stop error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _plugin?.dispose();
    _plugin = null;
    _controller.close();
  }
}
