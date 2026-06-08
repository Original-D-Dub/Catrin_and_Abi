import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a Welsh (Wyddor IAC) alphabet SVG from assets/wyddor_iac_svg/.
///
/// Supports single letters (a, b, c…) and Welsh digraphs (ch, dd, ff, ll…).
/// Applies inline CSS styles at load time, same as BslAlphabetSvg.
class WelshAlphabetSvg extends StatefulWidget {
  final String letter;
  final BoxFit fit;

  const WelshAlphabetSvg({
    super.key,
    required this.letter,
    this.fit = BoxFit.contain,
  });

  @override
  State<WelshAlphabetSvg> createState() => _WelshAlphabetSvgState();
}

class _WelshAlphabetSvgState extends State<WelshAlphabetSvg> {
  static final Map<String, String> _cache = {};

  late Future<String> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _load(widget.letter);
  }

  @override
  void didUpdateWidget(WelshAlphabetSvg old) {
    super.didUpdateWidget(old);
    if (old.letter != widget.letter) {
      _svgFuture = _load(widget.letter);
    }
  }

  static Future<String> _load(String letter) async {
    final key = letter.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final path = 'assets/wyddor_iac_svg/$key.svg';
    var svg = await rootBundle.loadString(path);
    svg = _applyStyles(svg);
    _cache[key] = svg;
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
