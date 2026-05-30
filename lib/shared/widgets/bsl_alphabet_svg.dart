import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_paths.dart';

/// Renders a BSL alphabet SVG with styles applied as inline attributes.
///
/// flutter_svg does not reliably resolve CSS class rules on Android — elements
/// with class="cls-1" render as solid black when the <style> block is ignored.
/// This widget replaces class attributes with equivalent inline fill/stroke
/// attributes at load time, matching the same pattern used by ClothingSvgWidget.
class BslAlphabetSvg extends StatefulWidget {
  final String letter;
  final BoxFit fit;

  const BslAlphabetSvg({
    super.key,
    required this.letter,
    this.fit = BoxFit.contain,
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
    _svgFuture = _load(widget.letter);
  }

  @override
  void didUpdateWidget(BslAlphabetSvg old) {
    super.didUpdateWidget(old);
    if (old.letter != widget.letter) {
      _svgFuture = _load(widget.letter);
    }
  }

  static Future<String> _load(String letter) async {
    final cached = _cache[letter];
    if (cached != null) return cached;

    var svg = await rootBundle.loadString(AssetPaths.bslLetterSvg(letter));
    svg = _applyStyles(svg);
    _cache[letter] = svg;
    return svg;
  }

  static String _applyStyles(String svg) {
    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-1"'),
      'fill="#ffd8bf" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-2"'),
      'fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="dash"'),
      'fill="none" stroke="#000000" stroke-dasharray="2 2"',
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
