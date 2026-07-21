import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Double-border purple frame matching the [GameHeaderBar] design:
/// a light outer rectangle and darker inner rectangle, both edged with
/// [AppColors.headerBorderDark]. Used to frame character images on the
/// zoo pick-a-player screen.
class ZooFramedBox extends StatelessWidget {
  final Widget child;

  const ZooFramedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.headerBorderDark, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.headerBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );
  }
}
