import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// MediaPipe hand landmark indices for fingertips.
///
/// These follow the standard MediaPipe Hand Landmarker convention where
/// each hand is represented by 21 landmarks (0–20).
const int kThumbTip = 4;
const int kIndexTip = 8;
const int kMiddleTip = 12;
const int kRingTip = 16;
const int kPinkyTip = 20;

/// Maps each left-hand fingertip landmark index to its BSL vowel.
///
/// BSL vowel hand: thumb=a, index=e, middle=i, ring=o, pinky=u
const Map<int, String> kFingertipVowels = {
  kThumbTip: 'a',
  kIndexTip: 'e',
  kMiddleTip: 'i',
  kRingTip: 'o',
  kPinkyTip: 'u',
};

/// Ordered list of left-hand fingertip indices for iteration.
const List<int> kFingertipIndices = [
  kThumbTip,
  kIndexTip,
  kMiddleTip,
  kRingTip,
  kPinkyTip,
];

/// 21 normalised landmark positions for a single detected hand.
///
/// Each [Offset] uses normalised image coordinates: x and y are both
/// in the range [0.0, 1.0], where (0, 0) is the top-left of the camera
/// frame and (1, 1) is the bottom-right.
@immutable
class HandLandmarkData {
  const HandLandmarkData({
    required this.landmarks,
    required this.isLeftHand,
  }) : assert(landmarks.length == 21,
            'MediaPipe always returns exactly 21 landmarks per hand');

  /// All 21 hand landmarks in normalised image coordinates.
  final List<Offset> landmarks;

  /// True when MediaPipe classifies this hand as the left hand.
  ///
  /// Note: MediaPipe reports handedness from the perspective of the image
  /// (i.e. mirrored relative to the user when using the front camera).
  /// The service implementations account for this mirror flip.
  final bool isLeftHand;

  /// Convenience accessor for a single landmark by its index (0–20).
  Offset landmark(int index) => landmarks[index];

  /// The fingertip position for the right-hand index finger (landmark 8).
  Offset get indexTip => landmarks[kIndexTip];

  @override
  String toString() =>
      'HandLandmarkData(${isLeftHand ? "left" : "right"}, '
      'indexTip=${landmarks[kIndexTip].dx.toStringAsFixed(2)},'
      '${landmarks[kIndexTip].dy.toStringAsFixed(2)})';
}
