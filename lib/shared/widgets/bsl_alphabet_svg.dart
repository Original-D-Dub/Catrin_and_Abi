import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/constants/game_filters.dart';

/// Renders an alphabet sign SVG with styles applied as inline attributes.
///
/// flutter_svg does not reliably resolve CSS class rules on Android — elements
/// with class="cls-1" render as solid black when the <style> block is ignored.
/// This widget replaces class attributes with equivalent inline fill/stroke
/// attributes at load time, matching the same pattern used by ClothingSvgWidget.
///
/// [signSystem] selects which sign family the SVG is loaded from: BSL
/// (English alphabet, single letters) or IAC (Welsh alphabet, including
/// digraphs ch, dd, ff, ng, ll, ph, rh, th).
class BslAlphabetSvg extends StatefulWidget {
  final String letter;
  final BoxFit fit;
  final SignSystem signSystem;

  /// Override the fill colour for cls-1 (default: #ffd8bf).
  final String? fillColor;

  /// Override the stroke colour for cls-1 and cls-2 (default: #000000).
  final String? strokeColor;

  const BslAlphabetSvg({
    super.key,
    required this.letter,
    this.fit = BoxFit.contain,
    this.signSystem = SignSystem.bsl,
    this.fillColor,
    this.strokeColor,
  });

  @override
  State<BslAlphabetSvg> createState() => _BslAlphabetSvgState();
}

class _BslAlphabetSvgState extends State<BslAlphabetSvg> {
  static final Map<String, String> _cache = {};

  late Future<String> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _load(
        widget.letter, widget.signSystem, widget.fillColor, widget.strokeColor);
  }

  @override
  void didUpdateWidget(BslAlphabetSvg old) {
    super.didUpdateWidget(old);
    if (old.letter != widget.letter ||
        old.signSystem != widget.signSystem ||
        old.fillColor != widget.fillColor ||
        old.strokeColor != widget.strokeColor) {
      _svgFuture = _load(widget.letter, widget.signSystem, widget.fillColor,
          widget.strokeColor);
    }
  }

  static Future<String> _load(String letter, SignSystem signSystem,
      String? fillColor, String? strokeColor) async {
    final key =
        '${signSystem.name}|$letter|${fillColor ?? ""}|${strokeColor ?? ""}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final path = signSystem == SignSystem.iac
        ? AssetPaths.welshLetterSvg(letter)
        : AssetPaths.bslLetterSvg(letter);
    var svg = await rootBundle.loadString(path);
    svg = _applyStyles(svg, fillColor, strokeColor);
    _cache[key] = svg;
    return svg;
  }

  static String _applyStyles(
      String svg, String? fillColor, String? strokeColor) {
    final fill = fillColor ?? '#ffd8bf';
    final stroke = strokeColor ?? '#000000';

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
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return SvgPicture.string(snapshot.data!, fit: widget.fit);
      },
    );
  }
}
