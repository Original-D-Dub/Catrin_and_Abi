import '../../core/constants/app_colors.dart';

/// Replaces the CSS class attributes in the alphabet sign SVGs with inline
/// fill/stroke attributes.
///
/// flutter_svg does not reliably resolve CSS class rules, so every consumer of
/// the `bsl_alphabet_svg/` and `wyddor_iac_svg/` assets styles them through
/// this one place.
///
/// Classes handled: `cls-1` (skin fill + outline), `cls-2` (outline only),
/// `dash` (dashed movement line), `arrow` (solid arrowhead).
class SignSvgStyler {
  SignSvgStyler._();

  static String apply(String svg, {String? fillColor, String? strokeColor}) {
    final fill = fillColor ?? AppColors.svgSkin;
    final stroke = strokeColor ?? AppColors.svgStroke;

    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-1"'),
      'fill="$fill" stroke="$stroke" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-2"'),
      'fill="none" stroke="$stroke" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="dash"'),
      'fill="none" stroke="$stroke" stroke-dasharray="2 2"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="arrow"'),
      'fill="$stroke" stroke="$stroke" stroke-linejoin="round"',
    );
    return svg;
  }
}
