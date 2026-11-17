import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/asset_paths.dart';
import 'hint_flash.dart';

/// Displays a Welsh-alphabet (IAC) sign as a plain tap target.
///
/// Used for the 'w' and 'y' vowel badges in the IAC vowel hand game, which
/// have no fingertip position on the open-hand image. The sign sits in a
/// white circle with a solid border matching the letter container's stroke.
class VowelBadge extends StatelessWidget {
  final String vowel;
  final VoidCallback onTap;

  /// When non-null, a red hint flashes over the badge. Changing the value
  /// restarts the flash (see [HintFlash]).
  final int? hintToken;

  const VowelBadge({
    super.key,
    required this.vowel,
    required this.onTap,
    this.hintToken,
  });

  /// Border width — same stroke as the letter container above the hand.
  static const double _borderWidth = 5;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final diameter = isMobile ? 140.0 : 300.0;
    final borderColor =
        AppColors.welshVowelPairColors[vowel] ?? AppColors.abiPink;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _buildBadge(diameter, borderColor),
          if (hintToken != null)
            Positioned.fill(
              child: HintFlash(
                key: ValueKey(hintToken),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentRed.withValues(alpha: 0.5),
                    border: Border.all(
                      color: AppColors.accentRed,
                      width: _borderWidth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(double diameter, Color borderColor) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: _borderWidth),
      ),
      child: ClipOval(
        // The 'y' sign sits left of centre in its image, so shift it right
        // by 15% and down by 5% of the container, and draw it at 95% size.
        child: FractionalTranslation(
          translation: vowel == 'y' ? const Offset(0.15, 0.03) : Offset.zero,
          child: Transform.scale(
            scale: vowel == 'y' ? 0.97 : 1.0,
            child: Image.asset(
              AssetPaths.vowelHandBadge(vowel),
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
