import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Brief pill banner telling the player they tapped too far from an
/// animal/enclosure to take a picture — shown for a moment, bottom-centre,
/// over the map.
class ZooTooFarMessage extends StatelessWidget {
  final String message;

  const ZooTooFarMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentOrange, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accentOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
