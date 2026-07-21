import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import 'level_select_screen.dart';

/// Scrollable "Choose a Level" map: numbered level circles laid out along
/// the winding bezier path drawn by
/// `assets/images/number_race/map-path.svg`.
///
/// Originally built for Number Race and now shared (also used by the zoo
/// game). The widget draws only the title, path and nodes — the caller
/// supplies the screen background and chrome around it.
///
/// All [totalMapNodes] nodes are always drawn; nodes past [unlockedLevels]
/// are greyed out with a lock icon. Tapping an unlocked node calls
/// [onLevelSelected] with its 1-based level number.
class LevelPathMap extends StatelessWidget {
  /// UI language for the title ('en' or 'cy').
  final String locale;

  /// Number of playable levels; nodes beyond this are locked.
  final int unlockedLevels;

  /// Marks a level as an end-of-section game — its node gets a flag badge.
  final bool Function(int level) isFinalLevel;

  /// Called with the 1-based level number when an unlocked node is tapped.
  final ValueChanged<int> onLevelSelected;

  const LevelPathMap({
    super.key,
    this.locale = 'en',
    required this.unlockedLevels,
    this.isFinalLevel = _neverFinal,
    required this.onLevelSelected,
  });

  static bool _neverFinal(int level) => false;

  /// Number of level circles drawn along the path.
  static const int totalMapNodes = 16;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    const nodeSize = 88.0;
    const svgWidth = 1498.0;
    const svgHeight = 1958.0;
    // Per-level y nudge in screen pixels (negative = up, positive = down).
    const Map<int, double> nodeYNudge = {};
    // Breathing room kept between the closest pair of level nodes once
    // stretched, as a multiple of the node's on-screen diameter.
    const overlapMargin = 1.15;
    // How much taller than the visible viewport the stretched map should
    // aim to be, so every device gets a consistent "peek" of further
    // levels below the fold instead of a fixed stretch that over- or
    // under-fills short/tall or narrow/wide screens.
    const viewportOverflowFactor = 1.3;
    // Rough height of the title text + spacing above the map, subtracted
    // from the viewport so the fill target reflects the space actually
    // left for the map itself.
    const estimatedChromeHeight = AppSizes.paddingLarge * 2 + 66.0;

    final svgNodePoints = _svgMapNodePoints(totalMapNodes);

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final availableForMap =
            (viewportConstraints.maxHeight - estimatedChromeHeight).clamp(200.0, double.infinity);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizer('level_select.title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final scaleX = screenWidth / svgWidth;

                  // Narrower screens pack the path's switchbacks closer
                  // together horizontally, so they need more vertical
                  // stretch to keep nodes apart; wider screens need less -
                  // this is solved per-device rather than fixed, so tablets
                  // aren't stretched (and scrolled) far more than necessary.
                  final overlapFreeStretch = _minVerticalStretchToAvoidOverlap(
                    svgNodePoints,
                    scaleX: scaleX,
                    minDistance: nodeSize * overlapMargin,
                    nodeYNudge: nodeYNudge,
                  );

                  final unstretchedHeight = svgHeight * scaleX;
                  final fillStretch =
                      (availableForMap * viewportOverflowFactor) / unstretchedHeight;

                  final verticalStretch = math.max(overlapFreeStretch, fillStretch);
                  final scaleY = scaleX * verticalStretch;
                  final mapHeight = svgHeight * scaleY;

                  // If any nudged node would go above y=0, push the whole map
                  // (SVG + all nodes) down so nothing is clipped.
                  double minRawTop = 0.0;
                  for (int i = 0; i < totalMapNodes; i++) {
                    final rawTop =
                        svgNodePoints[i].dy * scaleY - nodeSize / 2 + (nodeYNudge[i + 1] ?? 0.0);
                    if (rawTop < minRawTop) minRawTop = rawTop;
                  }
                  final extraTop = minRawTop < 0 ? -minRawTop : 0.0;
                  final totalHeight = mapHeight + extraTop;

                  return SizedBox(
                    width: screenWidth,
                    height: totalHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          top: extraTop,
                          left: 0,
                          right: 0,
                          child: SvgPicture.asset(
                            'assets/images/number_race/map-path.svg',
                            width: screenWidth,
                            height: mapHeight,
                            fit: BoxFit.fill,
                          ),
                        ),
                        for (int i = 0; i < totalMapNodes; i++)
                          Positioned(
                            left: (svgNodePoints[i].dx * scaleX - nodeSize / 2)
                                .clamp(0.0, screenWidth - nodeSize),
                            top: (svgNodePoints[i].dy * scaleY - nodeSize / 2 +
                                    (nodeYNudge[i + 1] ?? 0.0) +
                                    extraTop)
                                .clamp(0.0, totalHeight - nodeSize),
                            width: nodeSize,
                            height: nodeSize,
                            child: _LevelNode(
                              level: i + 1,
                              isFinal: isFinalLevel(i + 1),
                              isLocked: i >= unlockedLevels,
                              onTap: () => onLevelSelected(i + 1),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single level circle on the level map, numbered and coloured by
/// [levelColor]. The final level gets a flag badge to mark it as the
/// end-of-section game.
class _LevelNode extends StatelessWidget {
  final int level;
  final bool isFinal;
  final bool isLocked;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.isFinal,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked ? Colors.grey.shade400 : levelColor(level - 1),
              border: Border.all(
                color: isLocked ? Colors.grey.shade300 : Colors.white,
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3)),
              ],
            ),
            child: Center(
              child: isLocked
                  ? Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.8), size: 32)
                  : Text(
                      '$level',
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: AppSizes.fontSizeHeading,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (isFinal && !isLocked)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Icon(Icons.flag, color: AppColors.accentRed, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

/// Smallest y-stretch (applied on top of [scaleX], which alone positions x)
/// that keeps every pair of [nodesSvg] at least [minDistance] apart on
/// screen. The map path folds back on itself, so nodes from different loops
/// can otherwise land close together; how much stretch that needs depends on
/// [scaleX] (how spread out the path already is horizontally on this
/// device), so it's solved per-device rather than using one fixed constant.
double _minVerticalStretchToAvoidOverlap(
  List<Offset> nodesSvg, {
  required double scaleX,
  required double minDistance,
  required Map<int, double> nodeYNudge,
  double minStretch = 1.0,
  double maxStretch = 4.0,
}) {
  double minPairDistanceAt(double stretch) {
    final scaleY = scaleX * stretch;
    var closest = double.infinity;
    for (int i = 0; i < nodesSvg.length; i++) {
      final xi = nodesSvg[i].dx * scaleX;
      final yi = nodesSvg[i].dy * scaleY + (nodeYNudge[i + 1] ?? 0.0);
      for (int j = i + 1; j < nodesSvg.length; j++) {
        final xj = nodesSvg[j].dx * scaleX;
        final yj = nodesSvg[j].dy * scaleY + (nodeYNudge[j + 1] ?? 0.0);
        final dist = (Offset(xi, yi) - Offset(xj, yj)).distance;
        if (dist < closest) closest = dist;
      }
    }
    return closest;
  }

  if (minPairDistanceAt(maxStretch) < minDistance) return maxStretch;

  var lo = minStretch;
  var hi = maxStretch;
  for (int i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (minPairDistanceAt(mid) < minDistance) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return hi;
}

/// Returns [count] evenly arc-length-spaced points along the bezier path
/// defined in assets/images/number_race/map-path.svg (viewBox 1498×1958).
List<Offset> _svgMapNodePoints(int count) {
  const start = Offset(245.557, 141.314);
  // Each sub-list: [cp1x, cp1y, cp2x, cp2y, endX, endY] for one C segment.
  final segmentData = <List<double>>[
    [475.058, 141.314, 509.124, 62.6114, 691.058, 26.8136],
    [941.341, -22.4325, 1161.06, 4.31357, 1260.06, 141.314],
    [1335.98, 246.379, 1314.23, 368.538, 1217.56, 442.314],
    [1114.1, 521.271, 899.058, 556.814, 733.558, 514.814],
    [533.887, 464.142, 473.157, 437.54, 302.058, 425.814],
    [-18.942, 403.814, -156.815, 763.103, 281.558, 837.313],
    [568.058, 885.813, 771.496, 809.583, 927.058, 728.313],
    [1116.56, 629.313, 1272.06, 623.813, 1419.06, 742.813],
    [1510.19, 816.589, 1522.6, 978.103, 1431.56, 1135.81],
    [1387.4, 1212.31, 1239.48, 1288.6, 1143.06, 1303.31],
    [907.058, 1339.31, 791.558, 1264.81, 598.058, 1242.81],
    [404.558, 1220.81, 229.058, 1180.81, 116.058, 1273.31],
    [3.05801, 1365.81, -47.3452, 1590.28, 159.246, 1680.81],
    [273.348, 1730.81, 421.574, 1733.47, 561.268, 1680.81],
    [727.089, 1618.31, 787.558, 1571.81, 993.558, 1579.81],
    [1169.06, 1586.63, 1305.43, 1654.31, 1340.56, 1757.31],
    [1364.96, 1828.85, 1302.56, 1976.81, 1084.56, 1950.81],
    [866.558, 1924.81, 810.799, 1880.31, 598.058, 1888.31],
    [385.317, 1896.31, 180.574, 1930.31, 116.058, 1950.81],
  ];

  const samplesPerSegment = 40;
  final samples = <Offset>[start];
  var p0 = start;

  for (final seg in segmentData) {
    final p1 = Offset(seg[0], seg[1]);
    final p2 = Offset(seg[2], seg[3]);
    final p3 = Offset(seg[4], seg[5]);
    for (int s = 1; s <= samplesPerSegment; s++) {
      final t = s / samplesPerSegment;
      final u = 1.0 - t;
      samples.add(Offset(
        u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
        u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
      ));
    }
    p0 = p3;
  }

  final cumLength = <double>[0];
  for (int i = 1; i < samples.length; i++) {
    cumLength.add(cumLength.last + (samples[i] - samples[i - 1]).distance);
  }
  final totalLength = cumLength.last;

  Offset pointAtLength(double target) {
    int lo = 0, hi = cumLength.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cumLength[mid] < target) { lo = mid; } else { hi = mid; }
    }
    final segLen = cumLength[hi] - cumLength[lo];
    final f = segLen == 0 ? 0.0 : (target - cumLength[lo]) / segLen;
    return Offset.lerp(samples[lo], samples[hi], f)!;
  }

  return [
    for (int i = 0; i < count; i++)
      pointAtLength(totalLength * i / (count - 1)),
  ];
}
