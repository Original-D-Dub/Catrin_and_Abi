import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';

/// The app's standard back-arrow icon (`assets/icons/back_arrow.png`).
///
/// Drop-in replacement for `Icon(Icons.arrow_back)` wherever a back
/// button is drawn — IconButtons, GestureDetectors, AppBar leadings.
/// The PNG is pre-coloured artwork, so unlike [Icon] there is no color
/// parameter; [size] matches [Icon]'s sizing (default 24).
class BackArrowIcon extends StatelessWidget {
  final double size;

  const BackArrowIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.backArrowIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
