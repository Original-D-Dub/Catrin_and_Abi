import 'package:flutter/painting.dart';

import '../../features/vowel_hand/models/welsh_letters.dart';

/// Letter spacing applied to Welsh digraphs (ch, dd, ff, ng, ll, ph, rh, th)
/// in game lettering, as a fraction of the font size (-10%), so the two
/// characters read as the single letter they are in the Welsh alphabet.
const double digraphLetterSpacingFactor = -0.1;

/// Returns [style] with tightened letter spacing when [text] is a Welsh
/// digraph (case-insensitive); otherwise returns [style] unchanged.
///
/// [style] must set `fontSize`, since the spacing is relative to it.
TextStyle digraphAwareStyle(String text, TextStyle style) {
  if (!welshDigraphs.contains(text.toLowerCase())) return style;
  return style.copyWith(
    letterSpacing: (style.fontSize ?? 14) * digraphLetterSpacingFactor,
  );
}
