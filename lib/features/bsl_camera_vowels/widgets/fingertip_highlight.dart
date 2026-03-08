import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/vowel_hand/models/vowel_target.dart';
import '../models/hand_landmark_data.dart';

/// Overlays animated coloured rings on the five left-hand fingertip
/// positions of the hand guide SVG.
///
/// [activeFingertipIndex] — landmark index (4/8/12/16/20) currently lit
///   green after a correct touch.
/// [wrongFingertipIndex]  — landmark index lit red after an incorrect
///   touch (Level 2 only).
/// [handDisplaySize]      — rendered size of the hand SVG so fingertip
///   positions can be scaled correctly from normalised coordinates.
class FingertipHighlight extends StatelessWidget {
  const FingertipHighlight({
    super.key,
    required this.handDisplaySize,
    this.activeFingertipIndex,
    this.wrongFingertipIndex,
  });

  final Size handDisplaySize;
  final int? activeFingertipIndex;
  final int? wrongFingertipIndex;

  /// Maps each fingertip landmark index to its vowel colour.
  static const Map<int, Color> _fingertipColors = {
    kThumbTip: AppColors.accentRed,
    kIndexTip: AppColors.accentNavyBlue,
    kMiddleTip: AppColors.accentLimeGreen,
    kRingTip: AppColors.accentOrange,
    kPinkyTip: AppColors.accentPurple,
  };

  /// Ring diameter in logical pixels.
  static const double _ringSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: kFingertipIndices.map((index) {
        final normPos = _normalisedPosition(index);
        final cx = normPos.dx * handDisplaySize.width - _ringSize / 2;
        final cy = normPos.dy * handDisplaySize.height - _ringSize / 2;

        final isActive = index == activeFingertipIndex;
        final isWrong = index == wrongFingertipIndex;

        Color ringColor;
        if (isActive) {
          ringColor = AppColors.success;
        } else if (isWrong) {
          ringColor = AppColors.accentRed;
        } else {
          ringColor = (_fingertipColors[index] ?? Colors.white)
              .withValues(alpha: 0.55);
        }

        return Positioned(
          left: cx,
          top: cy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _ringSize,
            height: _ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isActive || isWrong)
                  ? ringColor.withValues(alpha: 0.35)
                  : Colors.transparent,
              border: Border.all(
                color: ringColor,
                width: isActive || isWrong ? 3.5 : 2.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Maps each fingertip landmark index to its position in
  /// [VowelHandConstants.targets] (thumb=0, index=1, middle=2, ring=3, pinky=4).
  static const Map<int, int> _landmarkToTargetIndex = {
    kThumbTip: 0,
    kIndexTip: 1,
    kMiddleTip: 2,
    kRingTip: 3,
    kPinkyTip: 4,
  };

  /// Returns the normalised (0–1) position for a fingertip landmark index
  /// using the same coordinates defined in [VowelHandConstants.targets].
  Offset _normalisedPosition(int landmarkIndex) {
    final i = _landmarkToTargetIndex[landmarkIndex];
    if (i == null) return Offset.zero;
    return VowelHandConstants.targets[i].normalizedPosition;
  }
}
