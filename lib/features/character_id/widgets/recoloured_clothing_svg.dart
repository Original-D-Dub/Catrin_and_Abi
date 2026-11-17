import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';

/// Renders a character_id clothing SVG recoloured to [colourName].
///
/// Each SVG has a single fabric colour and a single outline colour as plain
/// hex attributes; every `fill="#xxxxxx"` becomes the BSL fabric colour and
/// every `stroke="#xxxxxx"` its matching outline (see
/// [AppColors.bslFabricFor] / [AppColors.bslOutlineFor]). `fill="none"` is
/// left alone.
///
/// Mirrors the caching approach of the Clothes Line `ClothingSvgWidget`.
class RecolouredClothingSvg extends StatefulWidget {
  const RecolouredClothingSvg({
    super.key,
    required this.assetPath,
    required this.colourName,
    this.fit = BoxFit.fill,
  });

  final String assetPath;
  final String colourName;
  final BoxFit fit;

  // ── Static cache ─────────────────────────────────────────────────────────────

  static final Map<String, String> _cache = {};

  static String _cacheKey(String assetPath, String colourName) =>
      '${assetPath}_$colourName';

  /// Pre-loads and recolours all [assetPaths] × [colourNames] combinations so
  /// widgets can build synchronously on their first frame.
  static Future<void> precache(
    List<String> assetPaths,
    List<String> colourNames,
  ) async {
    final rawStrings = await Future.wait(
      assetPaths.map((p) => rootBundle.loadString(p)),
    );
    for (int i = 0; i < assetPaths.length; i++) {
      for (final colour in colourNames) {
        _cache.putIfAbsent(
          _cacheKey(assetPaths[i], colour),
          () => _applyColours(rawStrings[i], colour),
        );
      }
    }
  }

  // ── Colour injection ─────────────────────────────────────────────────────────

  static final RegExp _fillHex = RegExp(r'fill="#[0-9A-Fa-f]{3,8}"');
  static final RegExp _strokeHex = RegExp(r'stroke="#[0-9A-Fa-f]{3,8}"');

  static String _applyColours(String svg, String colourName) {
    final fabric = AppColors.toSvgHex(AppColors.bslFabricFor(colourName));
    final outline = AppColors.toSvgHex(AppColors.bslOutlineFor(colourName));
    return svg
        .replaceAll(_fillHex, 'fill="$fabric"')
        .replaceAll(_strokeHex, 'stroke="$outline"');
  }

  @override
  State<RecolouredClothingSvg> createState() => _RecolouredClothingSvgState();
}

class _RecolouredClothingSvgState extends State<RecolouredClothingSvg> {
  String? _svgString;

  String? get _cached => RecolouredClothingSvg._cache[
      RecolouredClothingSvg._cacheKey(widget.assetPath, widget.colourName)];

  @override
  void initState() {
    super.initState();
    _svgString = _cached; // synchronous — build sees it on the first frame
    if (_svgString == null) _loadSvg();
  }

  @override
  void didUpdateWidget(RecolouredClothingSvg old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath ||
        old.colourName != widget.colourName) {
      final cached = _cached;
      if (cached != null) {
        setState(() => _svgString = cached);
      } else {
        _loadSvg();
      }
    }
  }

  Future<void> _loadSvg() async {
    final assetPath = widget.assetPath;
    final colourName = widget.colourName;
    final raw = await rootBundle.loadString(assetPath);
    final coloured = RecolouredClothingSvg._applyColours(raw, colourName);
    RecolouredClothingSvg._cache[
        RecolouredClothingSvg._cacheKey(assetPath, colourName)] = coloured;
    // Ignore stale loads if the widget changed while loading.
    if (mounted &&
        widget.assetPath == assetPath &&
        widget.colourName == colourName) {
      setState(() => _svgString = coloured);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) return const SizedBox.shrink();
    return SvgPicture.string(_svgString!, fit: widget.fit);
  }
}
