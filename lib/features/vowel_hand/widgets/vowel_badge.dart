import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';

/// Displays a Welsh-alphabet (IAC) sign as a plain tap target.
///
/// Used for the 'w' and 'y' vowel badges in the IAC vowel hand game, which
/// have no fingertip position on the open-hand SVG.
class VowelBadge extends StatelessWidget {
  final String vowel;
  final VoidCallback onTap;

  const VowelBadge({
    super.key,
    required this.vowel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final size = isMobile ? 160.0 : 300.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: BslAlphabetSvg(
          letter: vowel,
          signSystem: SignSystem.iac,
          fit: BoxFit.contain,
          fillColor: '#F3DECE',
          strokeColor: '#BF7171',
        ),
      ),
    );
  }
}
