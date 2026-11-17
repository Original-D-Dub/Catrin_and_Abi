import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';

/// Renders the alphabet sign PNG for [letter].
///
/// BSL and IAC share one set of sign images (`assets/bsl_alphabet_png`),
/// which covers the single letters a–z plus the Welsh digraphs
/// ch, dd, ff, ll, ng, ph, rh, th.
class SignLetterImage extends StatelessWidget {
  final String letter;
  final BoxFit fit;

  const SignLetterImage({
    super.key,
    required this.letter,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.signLetterPng(letter),
      fit: fit,
      // A missing sign image leaves the slot blank rather than showing
      // Flutter's red error box to a child.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
