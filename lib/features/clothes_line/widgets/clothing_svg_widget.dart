import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';

/// Renders a clothing SVG with colours injected programmatically.
///
/// Each SVG has a `defs/style` block with named CSS classes:
///   `.colour`  – main fabric fill
///   `.outline` – dark edge / structural lines
///   `.shadow`  – shadow or stitching areas (where present)
///   `.button`  – buttons, bands, or decorative light details (where present)
///
/// Colours are derived from [AppColors] bslXxx / bslXxxOutline pairs.
class ClothingSvgWidget extends StatefulWidget {
  const ClothingSvgWidget({
    super.key,
    required this.assetPath,
    required this.colourName,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final String colourName;
  final BoxFit fit;

  // ── Static cache ─────────────────────────────────────────────────────────────

  static final Map<String, String> _cache = {};

  static String _cacheKey(String assetPath, String colourName) =>
      '${assetPath}_$colourName';

  /// Pre-loads and colour-injects all [assetPaths] × [colourNames] combinations.
  ///
  /// Call this before entering a level that spawns clothing items dynamically.
  /// Each [ClothingSvgWidget] will then read from the cache synchronously in
  /// [initState], eliminating the one-frame blank that would otherwise appear
  /// while the async load completes.
  static Future<void> precache(
    List<String> assetPaths,
    List<String> colourNames,
  ) async {
    final rawStrings = await Future.wait(
      assetPaths.map((p) => rootBundle.loadString(p)),
    );
    for (int i = 0; i < assetPaths.length; i++) {
      for (final colour in colourNames) {
        final key = _cacheKey(assetPaths[i], colour);
        _cache.putIfAbsent(key, () => _applyColours(rawStrings[i], colour));
      }
    }
  }

  // ── Colour injection ─────────────────────────────────────────────────────────

  static String _applyColours(String svg, String colourName) {
    final main    = _bslColour(colourName);
    final outline = _bslOutline(colourName);
    const button  = Color(0xFFe4ddc9); // warm cream – hat bands, buttons, hems

    var result = svg;
    result = result.replaceAll('class="colour"',  'fill="${_toHex(main)}"');
    result = result.replaceAll('class="outline"', 'fill="${_toHex(outline)}"');
    result = result.replaceAll('class="button"',  'fill="${_toHex(button)}"');
    result = result.replaceAll('class="shadow"',  'fill="#000000" fill-opacity="0.2" style="mix-blend-mode: multiply;"');
    return result;
  }

  static String _toHex(Color c) {
    int ch(double v) => (v * 255.0).round().clamp(0, 255);
    return '#${ch(c.r).toRadixString(16).padLeft(2, '0')}'
        '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
        '${ch(c.b).toRadixString(16).padLeft(2, '0')}';
  }

  static Color _bslColour(String name) => switch (name) {
        'red'    => AppColors.bslRed,
        'blue'   => AppColors.bslBlue,
        'green'  => AppColors.bslGreen,
        'yellow' => AppColors.bslYellow,
        'orange' => AppColors.bslOrange,
        'purple' => AppColors.bslPurple,
        'pink'   => AppColors.bslPink,
        'brown'  => AppColors.bslBrown,
        'black'  => AppColors.bslBlack,
        'white'  => AppColors.bslWhite,
        _        => AppColors.bslWhite,
      };

  static Color _bslOutline(String name) => switch (name) {
        'red'    => AppColors.bslRedOutline,
        'blue'   => AppColors.bslBlueOutline,
        'green'  => AppColors.bslGreenOutline,
        'yellow' => AppColors.bslYellowOutline,
        'orange' => AppColors.bslOrangeOutline,
        'purple' => AppColors.bslPurpleOutline,
        'pink'   => AppColors.bslPinkOutline,
        'brown'  => AppColors.bslBrownOutline,
        'black'  => AppColors.bslBlackOutline,
        'white'  => AppColors.bslWhiteOutline,
        _        => AppColors.bslWhiteOutline,
      };

  @override
  State<ClothingSvgWidget> createState() => _ClothingSvgWidgetState();
}

class _ClothingSvgWidgetState extends State<ClothingSvgWidget> {
  String? _svgString;

  @override
  void initState() {
    super.initState();
    final cached = ClothingSvgWidget._cache[
        ClothingSvgWidget._cacheKey(widget.assetPath, widget.colourName)];
    if (cached != null) {
      _svgString = cached; // synchronous — build sees it on the first frame
    } else {
      _loadSvg();
    }
  }

  @override
  void didUpdateWidget(ClothingSvgWidget old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath ||
        old.colourName != widget.colourName) {
      final cached = ClothingSvgWidget._cache[
          ClothingSvgWidget._cacheKey(widget.assetPath, widget.colourName)];
      if (cached != null) {
        setState(() => _svgString = cached);
      } else {
        _loadSvg();
      }
    }
  }

  Future<void> _loadSvg() async {
    final key = ClothingSvgWidget._cacheKey(widget.assetPath, widget.colourName);
    final raw = await rootBundle.loadString(widget.assetPath);
    final coloured = ClothingSvgWidget._applyColours(raw, widget.colourName);
    ClothingSvgWidget._cache[key] = coloured;
    if (mounted) setState(() => _svgString = coloured);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) return const SizedBox.shrink();
    return SvgPicture.string(
      _svgString!,
      fit: widget.fit,
    );
  }
}
