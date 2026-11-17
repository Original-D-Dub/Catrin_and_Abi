import 'dart:math';
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'button.dart';
import 'felt_grass_texture.dart';
import 'treasure_chest.dart';

export 'treasure_chest.dart' show ChestState;

/// One decoration beside [GameLevelMap]'s path: an image [asset] drawn
/// [widthFraction] of the path's width wide. [aspectRatio] is the image's
/// height over its width, used to keep scattered decorations clear of the
/// path (see [GameLevelMap.scatterScenery]).
///
/// With scattering on, [nearLevel] pins the decoration beside that level
/// instead of a random spot: it aims for the point level with the stop and
/// [towardCentre] of the way from the stop to the screen's centre (0 = on
/// the stop, 1 = the centre, above 1 = past the centre), and takes the nearest spot to that which is
/// clear of the path, the stops and other decorations.
class MapScenery {
  final String asset;
  final double widthFraction;
  final double aspectRatio;
  final int? nearLevel;
  final double towardCentre;

  const MapScenery(
    this.asset,
    this.widthFraction, {
    this.aspectRatio = 1,
    this.nearLevel,
    this.towardCentre = 0.5,
  });
}

/// A pattern over a [MapSection]'s grass, on top of the felt texture.
enum MapGroundPattern {
  plain,

  /// Light and dark stripes, like a freshly mown lawn.
  mownStripes,

  /// Little felt flowers scattered over the grass.
  flowers,
}

/// A run of levels on [GameLevelMap] — [firstLevel] to [lastLevel] — shown
/// as its own patch of meadow: [grassColour] ground with [groundPattern]
/// over it, a stitched seam where it meets the next section and, with a
/// [label], a wooden sign beside the path between its second and third
/// levels.
class MapSection {
  final int firstLevel;
  final int lastLevel;
  final Color grassColour;
  final MapGroundPattern groundPattern;
  final String? label;

  const MapSection({
    required this.firstLevel,
    required this.lastLevel,
    required this.grassColour,
    this.groundPattern = MapGroundPattern.plain,
    this.label,
  });
}

/// Felt meadow scenery for [GameLevelMap]: sky, trees and daffodils.
///
/// The art set was drawn for Bubble Shooter's level map and now belongs to
/// the shared map — point [GameLevelMap.sceneryAssetDir] elsewhere to skin
/// the meadow differently.
const String _sceneryDir = 'assets/games/bubble_shooter/background';

/// "Choose a level" map for any game: a felt meadow with a stitched sand
/// path winding up from level 1 at the bottom, trees and daffodils along
/// the edges, optional treasure-chest prize levels, and an optional
/// character thumbnail standing at the player's next level.
///
/// The map draws the scenery, path, level coins and markers; the caller
/// supplies everything game-specific through the constructor — how levels
/// unlock ([highestCompleted]), which levels are chests ([isChestLevel])
/// and their state ([chestState]), and where each tap goes. Levels past
/// the player's next one are locked: plain grey coins that can't be tapped.
///
/// The meadow fills the map's whole box and grows to at least the viewport
/// height, so the grass always reaches the bottom edge — place the widget
/// full-bleed (e.g. inside a `SafeArea(bottom: false)`) so it covers the
/// bottom safe area too. Decorations stack top-of-screen first, so lower
/// elements paint in front where they overlap and the meadow keeps its
/// sense of depth.
///
/// Originally built for Bubble Shooter (as BubbleShooterLevelMap) and
/// promoted to a shared widget so other games can use the same style of
/// level map in place of a "choose a level" list.
class GameLevelMap extends StatefulWidget {
  /// Number of levels on the path.
  final int levelCount;

  /// Highest level completed (0 if none) — earlier levels show as done and
  /// the character stands on the next one.
  final int highestCompleted;

  /// Called with the 1-based level number when an unlocked non-chest level
  /// is tapped.
  final ValueChanged<int> onLevelSelected;

  /// Thumbnail image of the character marker standing at the player's next
  /// level, or null for no marker at all.
  final String? characterThumb;

  /// Semantic label for the character marker.
  final String? characterLabel;

  /// Called when the character marker is tapped (e.g. to choose another).
  final VoidCallback? onCharacterTapped;

  /// Which levels are treasure-chest levels — drawn as a large coin with
  /// the chest sitting on it — or null for no chest levels at all.
  final bool Function(int level)? isChestLevel;

  /// State of the chest after [level]. Only consulted for chest levels;
  /// defaults to [ChestState.locked].
  final ChestState Function(int level)? chestState;

  /// Called instead of [onLevelSelected] when a reached chest level is
  /// tapped.
  final ValueChanged<int>? onChestTapped;

  /// Semantic label for a level node, given its number.
  final String Function(int level) levelLabel;

  /// Semantic label for a chest, given its level. Only consulted for chest
  /// levels.
  final String Function(int level)? chestLabel;

  /// The level the player just finished, when that moved them on: the
  /// character starts there and hops along the path to [currentLevel].
  final int? movedFromLevel;

  /// Whether levels past the player's next one are locked. When false,
  /// every level can be played in any order; levels not yet reached show
  /// their number on a blue coin instead of a blank grey one.
  final bool lockAhead;

  /// Overrides the decoration beside the path between stops [gap] + 1 and
  /// [gap] + 2: return the [MapScenery] to draw there, or null to leave
  /// that spot empty. When not set, the spots cycle through the default
  /// small tree, daffodils and large tree.
  final MapScenery? Function(int gap)? scenery;

  /// Whether decorations are scattered across the meadow — each at a
  /// fixed pseudo-random spot level with its gap, clear of the path, the
  /// level stops and each other — instead of lining the left and right
  /// edges. A decoration with no clear spot falls back to its edge place.
  final bool scatterScenery;

  /// Splits the map into sections, each with its own grass and sign (see
  /// [MapSection]), or null for one meadow throughout. Levels outside
  /// every section keep the default meadow.
  final List<MapSection>? sections;

  const GameLevelMap({
    super.key,
    required this.levelCount,
    required this.highestCompleted,
    required this.onLevelSelected,
    this.characterThumb,
    this.characterLabel,
    this.onCharacterTapped,
    this.isChestLevel,
    this.chestState,
    this.onChestTapped,
    required this.levelLabel,
    this.chestLabel,
    this.movedFromLevel,
    this.lockAhead = true,
    this.scenery,
    this.scatterScenery = false,
    this.sections,
  });

  /// The level the character stands on.
  int get currentLevel => min(highestCompleted + 1, levelCount);

  @override
  State<GameLevelMap> createState() => _GameLevelMapState();
}

class _GameLevelMapState extends State<GameLevelMap>
    with SingleTickerProviderStateMixin {
  static const double _spacing = 118;
  static const double _topSpace = 230;
  static const double _bottomSpace = 150;
  static const double _nodeSize = 76;

  /// Felt meadow colours the path is drawn over. They mirror
  /// BubbleShooterBackground's hill colours — the map and the game screen
  /// share the same meadow.
  static const Color _frontHillColour = Color(0xFF65A94F);
  static const Color _backHillColour = Color(0xFFB5D530);

  /// Chest levels' coins are larger, to balance the chest on top.
  static const double _chestSize = 100;

  /// Chest levels' coins are always Abi pink, so prize levels stand out.
  static const ButtonFill _chestCoinFill = ButtonFill(
    AppColors.buttonSecondaryGradStart,
    AppColors.abiPink,
    AppColors.buttonSecondaryGradEnd,
  );
  static const double _maxPathWidth = 520;

  final _scroll = ScrollController();
  bool _scrolledToCurrent = false;

  /// Pause before the character sets off, so the player sees where it
  /// starts; then the time it takes per level travelled.
  static const _moveDelay = Duration(milliseconds: 500);
  static const _moveDurationPerLevel = Duration(milliseconds: 1100);

  /// Index (into the path's points) the character walks from, or null when
  /// it just stands at the current level.
  int? _fromIndex;
  late final AnimationController _move;

  @override
  void initState() {
    super.initState();
    final from = widget.movedFromLevel;
    final steps = from == null ? 0 : widget.currentLevel - from;
    _move = AnimationController(
      vsync: this,
      duration: _moveDurationPerLevel * max(steps, 1),
      value: 1,
    );
    if (from != null && from >= 1 && steps > 0) {
      _fromIndex = from - 1;
      _move.value = 0;
      Future.delayed(_moveDelay, () {
        if (!mounted) return;
        if (MediaQuery.of(context).disableAnimations) {
          _move.value = 1;
        } else {
          _move.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _move.dispose();
    super.dispose();
  }

  /// The point a fraction [t] of the way along the path from stop [from]
  /// to stop [to], following the same curve [_PathPainter] draws.
  static Offset _alongPath(List<Offset> points, int from, int to, double t) {
    final s = t * (to - from);
    final i = min(from + s.floor(), to - 1);
    final u = s - (i - from);
    final p0 = i == 0 ? points[i] : points[i - 1];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    final v = 1 - u;
    return p1 * (v * v * v) +
        c1 * (3 * v * v * u) +
        c2 * (3 * v * u * u) +
        p2 * (u * u * u);
  }

  /// Whether [level] is a treasure-chest level.
  bool _isChest(int level) => widget.isChestLevel?.call(level) ?? false;

  /// The chest state after [level], defaulting to locked.
  ChestState _chestStateFor(int level) =>
      widget.chestState?.call(level) ?? ChestState.locked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pathWidth = min(width, _maxPathWidth);
        final left = (width - pathWidth) / 2;
        final count = widget.levelCount;
        // The meadow always fills the viewport: when few levels make the
        // path shorter than the screen, the extra ground is added below —
        // and, when the caller places the map full-bleed, it covers the
        // bottom safe area — so the grass always reaches the bottom of the
        // screen. The path stays anchored to the bottom of the content.
        final viewportHeight = constraints.maxHeight;
        final pathHeight = _topSpace + _bottomSpace + (count - 1) * _spacing;
        final height = viewportHeight.isFinite
            ? max(pathHeight, viewportHeight)
            : pathHeight;

        // Winding path: a gentle S-curve swinging between the sides.
        Offset centreOf(int i) => Offset(
          left + pathWidth / 2 + pathWidth * 0.27 * sin(i * 0.85 + 0.3),
          height - _bottomSpace - i * _spacing,
        );
        // points[i] is level i + 1.
        final points = [for (var i = 0; i < count; i++) centreOf(i)];

        final currentIndex = widget.currentLevel - 1;
        if (!_scrolledToCurrent && currentIndex >= 0) {
          _scrolledToCurrent = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scroll.hasClients) return;
            final target =
                points[currentIndex].dy - constraints.maxHeight * 0.6;
            _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
          });
        }

        return SingleChildScrollView(
          controller: _scroll,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ..._scenery(width, height, points, left, pathWidth),
                Positioned.fill(
                  child: CustomPaint(painter: _PathPainter(points)),
                ),
                ..._sectionSigns(points, width),
                for (var i = 0; i < count; i++) _stopWidget(i + 1, points[i]),
                if (currentIndex >= 0 && widget.characterThumb != null)
                  // Its own full-size layer so the moving marker can stay a
                  // Positioned child of a Stack; only the marker takes taps.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _move,
                      builder: (context, _) {
                        final from = _fromIndex;
                        final t = Curves.easeInOut.transform(_move.value);
                        var centre = points[currentIndex];
                        var size = _sizeOf(widget.currentLevel);
                        if (from != null && t < 1) {
                          centre = _alongPath(points, from, currentIndex, t);
                          // Little hops along the way.
                          final hops = 3.0 * (currentIndex - from);
                          centre -= Offset(0, 14 * sin(t * pi * hops).abs());
                          size = ui.lerpDouble(_sizeOf(from + 1), size, t)!;
                        }
                        return Stack(
                          children: [
                            _characterMarker(
                              centre,
                              size,
                              // Beside the level, away from where the path goes
                              // next (or came from, at the top), unless that's
                              // off-screen.
                              onLeft: _markerOnLeft(
                                points,
                                currentIndex,
                                width,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Felt sky and hills at the top, felt grass below, and trees and
  /// daffodils — along the edges on the side the path is furthest from, or
  /// scattered over the meadow with [GameLevelMap.scatterScenery].
  ///
  /// Decorations are painted from the top of the screen downwards: in a
  /// Stack, later children paint over earlier ones, so the lower-down
  /// elements end up in front of higher ones where they overlap,
  /// maintaining the illusion of depth.
  List<Widget> _scenery(
    double width,
    double height,
    List<Offset> points,
    double left,
    double pathWidth,
  ) {
    const skyHeight = 200.0;
    final decorations = <Widget>[];
    const defaults = [
      MapScenery('$_sceneryDir/tree_small.png', 0.24),
      MapScenery('$_sceneryDir/daffodils.png', 0.22),
      MapScenery('$_sceneryDir/tree_large.png', 0.3),
    ];
    final pathSamples = widget.scatterScenery ? _samplePath(points) : null;
    final placed = <(Rect, String)>[];
    final items = [
      for (var i = points.length - 2; i >= 0; i--)
        (
          i,
          widget.scenery != null
              ? widget.scenery!(i)
              : defaults[i % defaults.length],
        ),
    ];
    // Pinned decorations claim their spots first; the rest scatter around
    // them.
    final pinned = pathSamples == null
        ? <(int, MapScenery?)>[]
        : items.where((e) => e.$2?.nearLevel != null).toList();
    for (final (i, item) in [
      ...pinned,
      ...items.where((e) => !pinned.contains(e)),
    ]) {
      if (item == null) continue;
      final w = pathWidth * item.widthFraction;
      final size = Size(w, w * item.aspectRatio);
      Rect? rect;
      final taken = [for (final (r, _) in placed) r];
      final pinLevel = item.nearLevel;
      if (pathSamples != null &&
          pinLevel != null &&
          pinLevel >= 1 &&
          pinLevel <= points.length) {
        final stop = points[pinLevel - 1];
        rect = _spotNear(
          Offset(
            ui.lerpDouble(stop.dx, width / 2, item.towardCentre)!,
            stop.dy,
          ),
          size: size,
          width: width,
          points: points,
          pathSamples: pathSamples,
          taken: taken,
        );
      }
      if (pathSamples != null && rect == null) {
        rect = _scatteredSpot(
          gap: i,
          size: size,
          width: width,
          points: points,
          pathSamples: pathSamples,
          taken: taken,
        );
      }
      // Edge place: between stops i and i+1, opposite the side the path
      // is on.
      if (rect == null) {
        final mid = Offset.lerp(points[i], points[i + 1], 0.5)!;
        final onLeft = mid.dx > left + pathWidth / 2;
        rect = Rect.fromLTWH(
          onLeft ? left - w * 0.15 : left + pathWidth - w * 0.85,
          mid.dy - w * 0.75,
          w,
          w * item.aspectRatio,
        );
      }
      placed.add((rect, item.asset));
    }
    // Paint from the top of the screen down, so lower decorations sit in
    // front of higher ones where they overlap.
    placed.sort((a, b) => a.$1.bottom.compareTo(b.$1.bottom));
    for (final (rect, asset) in placed) {
      decorations.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          child: IgnorePointer(child: Image.asset(asset, fit: BoxFit.contain)),
        ),
      );
    }
    final bands = _sectionBands(points, height);
    return [
      const Positioned.fill(child: ColoredBox(color: _frontHillColour)),
      if (bands.isNotEmpty)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SectionGroundPainter(bands)),
          ),
        ),
      const Positioned.fill(child: IgnorePointer(child: FeltGrassTexture())),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: skyHeight,
        child: Image.asset(
          '$_sceneryDir/sky_felt.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      // Back hill along the horizon, under the sky's lower edge.
      Positioned(
        left: 0,
        right: 0,
        top: skyHeight - 60,
        height: 120,
        child: ClipPath(
          clipper: _HillClipper(),
          child: const Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: _backHillColour),
              FeltGrassTexture(),
            ],
          ),
        ),
      ),
      ...decorations,
    ];
  }

  double _sizeOf(int level) => _isChest(level) ? _chestSize : _nodeSize;

  /// Each section's patch of ground: from halfway between its first level
  /// and the one below to halfway between its last level and the one
  /// above (or the map's bottom and top edges at the ends of the path).
  List<_SectionBand> _sectionBands(List<Offset> points, double height) {
    final count = points.length;
    return [
      for (final section in widget.sections ?? const <MapSection>[])
        if (section.firstLevel <= count && section.lastLevel >= 1)
          _SectionBand(
            section,
            top: section.lastLevel >= count
                ? 0
                : (points[section.lastLevel - 1].dy +
                          points[section.lastLevel].dy) /
                      2,
            bottom: section.firstLevel <= 1
                ? height
                : (points[section.firstLevel - 1].dy +
                          points[section.firstLevel - 2].dy) /
                      2,
          ),
    ];
  }

  /// A wooden sign for each labelled section, in the gap between its
  /// second and third levels — clear of the level stops and the
  /// character standing beside them — on the side away from the path.
  List<Widget> _sectionSigns(List<Offset> points, double width) {
    const signHeight = 60.0;
    const pathClearance = 40.0;
    final signs = <Widget>[];
    for (final section in widget.sections ?? const <MapSection>[]) {
      final label = section.label;
      final first = section.firstLevel;
      if (label == null || first < 1 || first + 1 >= points.length) continue;
      final mid = _alongPath(points, first, first + 1, 0.5);
      final onRight = mid.dx < width / 2;
      final maxWidth = (onRight ? width - mid.dx : mid.dx) - pathClearance - 12;
      signs.add(
        Positioned(
          left: onRight ? mid.dx + pathClearance : null,
          right: onRight ? null : width - mid.dx + pathClearance,
          top: mid.dy - signHeight / 2,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max(maxWidth, 60)),
            child: _SectionSign(label: label),
          ),
        ),
      );
    }
    return signs;
  }

  /// Points closely spaced along the drawn path, for clearance checks.
  static List<Offset> _samplePath(List<Offset> points) => [
    for (var i = 0; i < points.length - 1; i++)
      for (var s = 0; s < 24; s++) _alongPath(points, i, i + 1, s / 24),
    points.last,
  ];

  /// A spot for a [size] decoration in the band of map between stops [gap]
  /// + 1 and [gap] + 2, chosen from candidates seeded by [gap] so the
  /// layout is the same on every visit. It must keep clear of the path,
  /// every stop (chests include the lid above them) and the [taken] spots,
  /// and stay mostly on-screen. Prefers a spot at least a quarter of the
  /// map's width sideways from the last decoration placed, so neighbours
  /// zig-zag across the meadow rather than forming a column; failing that,
  /// takes the first clear spot. Null if no candidate fits.
  Rect? _scatteredSpot({
    required int gap,
    required Size size,
    required double width,
    required List<Offset> points,
    required List<Offset> pathSamples,
    required List<Rect> taken,
  }) {
    final random = Random(gap * 7919 + 17);
    final top = points[gap + 1].dy;
    final bottom = points[gap].dy;
    final previous = taken.isEmpty ? null : taken.last;
    Rect? firstClear;
    for (var attempt = 0; attempt < 60; attempt++) {
      final x =
          -size.width * 0.15 + random.nextDouble() * (width - size.width * 0.7);
      final y = top + random.nextDouble() * (bottom - top) - size.height / 2;
      final rect = Rect.fromLTWH(x, y, size.width, size.height);
      if (!_isClearSpot(rect, points, pathSamples, taken)) continue;
      firstClear ??= rect;
      if (previous == null ||
          (rect.center.dx - previous.center.dx).abs() >= width * 0.25) {
        return rect;
      }
    }
    return firstClear;
  }

  /// The clear spot for a [size] decoration whose centre is nearest
  /// [target], searching outwards in rings; null if none within reach.
  /// Kept mostly on-screen, like scattered spots.
  Rect? _spotNear(
    Offset target, {
    required Size size,
    required double width,
    required List<Offset> points,
    required List<Offset> pathSamples,
    required List<Rect> taken,
  }) {
    final minX = -size.width * 0.15;
    final maxX = width - size.width * 0.85;
    for (var r = 0.0; r <= 240; r += 8) {
      final steps = r == 0 ? 1 : 24;
      for (var k = 0; k < steps; k++) {
        final a = 2 * pi * k / steps;
        final centre = target + Offset(cos(a), sin(a)) * r;
        final x = centre.dx - size.width / 2;
        if (x < minX || x > maxX) continue;
        final rect = Rect.fromLTWH(
          x,
          centre.dy - size.height / 2,
          size.width,
          size.height,
        );
        if (_isClearSpot(rect, points, pathSamples, taken)) return rect;
      }
    }
    return null;
  }

  /// Whether a decoration drawn in [rect] keeps clear of the path, every
  /// stop (a chest's lid included) and the [taken] spots.
  bool _isClearSpot(
    Rect rect,
    List<Offset> points,
    List<Offset> pathSamples,
    List<Rect> taken,
  ) {
    // Half the drawn path's width (50) plus a little grass either side.
    const pathClearance = 25.0 + 10.0;
    const stopClearance = 10.0;
    // The images have transparent margins, so test a slightly smaller box
    // than the full image.
    final body = rect.deflate(rect.shortestSide * 0.08);
    bool clearOf(Offset p, double r) => !body.inflate(r).contains(p);
    if (!pathSamples.every((p) => clearOf(p, pathClearance))) return false;
    for (var s = 0; s < points.length; s++) {
      final level = s + 1;
      final radius = _sizeOf(level) / 2 + stopClearance;
      if (!clearOf(points[s], radius)) return false;
      // A chest's lid rises above its coin.
      if (_isChest(level) &&
          !clearOf(points[s] - Offset(0, _chestSize * 0.5), radius)) {
        return false;
      }
    }
    return !taken.any((t) => t.deflate(t.shortestSide * 0.1).overlaps(body));
  }

  Widget _stopWidget(int level, Offset centre) {
    final size = _sizeOf(level);
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      width: size,
      height: size,
      child: _isChest(level) ? _chest(level) : _levelNode(level),
    );
  }

  /// Whether the player can play [level]: levels done and the current one
  /// — or every level when [GameLevelMap.lockAhead] is off. Locked levels
  /// are plain grey coins with no number that can't be tapped.
  bool _isUnlocked(int level) =>
      !widget.lockAhead || level <= widget.currentLevel;

  /// Gold once done, purple for the current level, blue for open levels
  /// further on (when [GameLevelMap.lockAhead] is off), grey otherwise.
  ButtonFill _fillFor(int level) {
    if (level <= widget.highestCompleted) {
      return const ButtonFill(
        Color(0xFFFFE07A),
        Color(0xFFF5B400),
        Color(0xFFC98A00),
      );
    }
    if (level == widget.currentLevel) {
      return const ButtonFill(
        Color(0xFFC79BFF),
        Color(0xFF8E44EC),
        Color(0xFF6A1FBF),
      );
    }
    if (!widget.lockAhead) {
      return const ButtonFill(
        Color(0xFF9FD8FF),
        Color(0xFF3B9BE0),
        Color(0xFF1F6FB0),
      );
    }
    return const ButtonFill(
      Color(0xFFE4E4E4),
      Color(0xFFBDBDBD),
      Color(0xFF8E8E8E),
    );
  }

  Widget _levelNode(int level) {
    final fill = _fillFor(level);
    final current = level == widget.currentLevel;
    return Semantics(
      button: true,
      enabled: _isUnlocked(level),
      label: widget.levelLabel(level),
      child: GestureDetector(
        onTap: _isUnlocked(level) ? () => widget.onLevelSelected(level) : null,
        child: CustomPaint(
          painter: _CoinPainter(fill, glow: current),
          child: !_isUnlocked(level)
              ? null
              : Align(
                  // Centred on the coin's top face, which sits above the box's
                  // centre (the edge and shadow take up the bottom).
                  alignment: const Alignment(0, -0.22),
                  // Nudged up so the digits look centred on the face.
                  child: Transform.translate(
                    offset: const Offset(0, -3),
                    child: ExcludeSemantics(
                      child: Text(
                        '$level',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(color: fill.end, offset: const Offset(0, 2)),
                            Shadow(
                              color: fill.end.withValues(alpha: 0.6),
                              offset: const Offset(0, 3),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// A chest level: a large Abi pink coin with the
  /// treasure chest — locked, ready to open, or opened — sitting on its
  /// face, and the level's number on the front of the face once reached.
  Widget _chest(int level) {
    final state = _chestStateFor(level);
    const fill = _chestCoinFill;
    const chestSize = _chestSize;
    final chest = CustomPaint(
      painter: TreasureChestPainter(state),
      size: const Size.square(chestSize),
    );
    return Semantics(
      button: true,
      enabled: _isUnlocked(level),
      label: widget.chestLabel?.call(level) ?? '',
      child: GestureDetector(
        onTap: _isUnlocked(level)
            ? () => widget.onChestTapped?.call(level)
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CoinPainter(fill, glow: level == widget.currentLevel),
              ),
            ),
            // The chest's base rests on the middle of the coin's face, its
            // lid rising above the coin.
            Positioned(
              top: -_chestSize * 0.34,
              child: state == ChestState.ready ? _Bounce(child: chest) : chest,
            ),
            if (_isUnlocked(level))
              Positioned(
                left: 0,
                right: 0,
                top: _chestSize * 0.57,
                child: ExcludeSemantics(
                  child: Text(
                    '$level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      height: 1,
                      shadows: [
                        Shadow(color: fill.end, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const double _markerSize = 60;
  static const double _pointerLength = 12;

  bool _markerOnLeft(List<Offset> points, int index, double width) {
    final here = points[index];
    final other = index + 1 < points.length
        ? points[index + 1]
        : (index > 0 ? points[index - 1] : here);
    var onLeft = other.dx >= here.dx;
    final reach = _nodeSize / 2 + _pointerLength + _markerSize;
    if (onLeft && here.dx - reach < 0) onLeft = false;
    if (!onLeft && here.dx + reach > width) onLeft = true;
    return onLeft;
  }

  Widget _characterMarker(
    Offset levelCentre,
    double levelSize, {
    required bool onLeft,
  }) {
    const size = _markerSize;
    const total = size + _pointerLength;
    final pointer = CustomPaint(
      size: const Size(_pointerLength, 18),
      painter: _PointerPainter(const Color(0xFF3979A7), pointRight: onLeft),
    );
    return Positioned(
      left: onLeft
          ? levelCentre.dx - levelSize / 2 - total
          : levelCentre.dx + levelSize / 2,
      top: levelCentre.dy - size * 0.75,
      width: total,
      height: size,
      child: Semantics(
        button: true,
        label: widget.characterLabel ?? '',
        child: GestureDetector(
          onTap: widget.onCharacterTapped,
          child: Row(
            children: [
              if (!onLeft) pointer,
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3979A7), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(widget.characterThumb!, fit: BoxFit.cover),
              ),
              if (onLeft) pointer,
            ],
          ),
        ),
      ),
    );
  }
}

/// A level button drawn as a glossy 3D coin tilted back as if lying on the
/// ground: an oval top face in [fill]'s colours over a thick darker edge,
/// with a soft shadow beneath. [glow] adds a warm halo (the current level).
class _CoinPainter extends CustomPainter {
  _CoinPainter(this.fill, {this.glow = false});

  final ButtonFill fill;
  final bool glow;

  /// Height of the top face as a fraction of its width — the tilt.
  static const double _tilt = 0.68;

  /// Thickness of the coin's edge, as a fraction of its width.
  static const double _depth = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final faceH = w * _tilt;
    final depth = w * _depth;
    final top = (size.height - faceH - depth) / 2;
    final face = Rect.fromLTWH(0, top, w, faceH);
    final bottomFace = face.shift(Offset(0, depth));

    // Shadow on the ground.
    canvas.drawOval(
      bottomFace.shift(Offset(0, depth * 0.5)).inflate(-w * 0.02),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    if (glow) {
      canvas.drawOval(
        face.inflate(w * 0.14),
        Paint()
          ..color = const Color(0xCCFFF59D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Edge: the band between the top face and the same oval shifted down.
    final edge = Path()
      ..addOval(bottomFace)
      ..addRect(Rect.fromLTRB(0, face.center.dy, w, bottomFace.center.dy));
    final darkEdge = Color.lerp(fill.end, Colors.black, 0.25)!;
    canvas.drawPath(
      edge,
      Paint()
        ..shader = LinearGradient(
          colors: [darkEdge, fill.end, darkEdge],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    // Top face: lit from the upper left.
    canvas.drawOval(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 1.0,
          colors: [fill.start, fill.middle, fill.end],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(face),
    );
    // Rim where the face meets the edge.
    canvas.drawOval(
      face.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.lerp(
          fill.start,
          Colors.white,
          0.4,
        )!.withValues(alpha: 0.7),
    );
    // Glossy highlight across the upper face.
    final gloss = Rect.fromLTWH(
      w * 0.18,
      face.top + faceH * 0.08,
      w * 0.64,
      faceH * 0.36,
    );
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(gloss),
    );
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.fill.start != fill.start ||
      old.fill.middle != fill.middle ||
      old.fill.end != fill.end ||
      old.glow != glow;
}

/// Gentle bobbing for a chest that's ready to open.
class _Bounce extends StatefulWidget {
  final Widget child;
  const _Bounce({required this.child});

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// The sand path: a smooth curve through every stop, drawn as a felt strip
/// (darker edge, sand fill) with a dashed stitch down the middle.
class _PathPainter extends CustomPainter {
  _PathPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    // Catmull-Rom through the points, as cubic Béziers.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      stroke(Colors.black.withValues(alpha: 0.18), 50),
    );
    canvas.drawPath(path, stroke(const Color(0xFFC99A5B), 50));
    canvas.drawPath(path, stroke(const Color(0xFFEBCB92), 40));

    final stitch = stroke(const Color(0xB3A8743F), 2);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, d + 8), stitch);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}

/// A [MapSection]'s patch of ground on the map, from [top] to [bottom].
class _SectionBand {
  const _SectionBand(this.section, {required this.top, required this.bottom});

  final MapSection section;
  final double top;
  final double bottom;
}

/// Paints each section's grass and pattern, with a stitched seam along
/// its top edge — one sweeping curve across the map — where it meets the
/// section above. Sections are painted top of the map first, so each
/// one's curved edge overlaps the section above it.
class _SectionGroundPainter extends CustomPainter {
  _SectionGroundPainter(this.bands);

  final List<_SectionBand> bands;

  /// How far the seam bows up or down from its line at the middle.
  static const double _bow = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = [...bands]..sort((a, b) => a.top.compareTo(b.top));
    for (final band in ordered) {
      final edge = band.top > 0
          ? _curvedEdge(
              size.width,
              band.top,
              bowUp: ordered.indexOf(band).isOdd,
            )
          : null;
      final area = Path();
      if (edge != null) {
        area.addPath(edge, Offset.zero);
      } else {
        area
          ..moveTo(0, 0)
          ..lineTo(size.width, 0);
      }
      area
        ..lineTo(size.width, band.bottom + _bow * 2)
        ..lineTo(0, band.bottom + _bow * 2)
        ..close();

      canvas.save();
      canvas.clipPath(area);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = band.section.grassColour,
      );
      _paintPattern(canvas, band, size.width);
      canvas.restore();

      if (edge != null) _paintSeam(canvas, edge);
    }
  }

  /// One sweeping curve across the map, centred on [y]: it dips from one
  /// side to the other through a single bow, up or down by [bowUp], so
  /// neighbouring seams curve opposite ways.
  static Path _curvedEdge(double width, double y, {required bool bowUp}) {
    final sign = bowUp ? -1 : 1;
    return Path()
      ..moveTo(0, y - sign * _bow * 0.5)
      ..quadraticBezierTo(
        width / 2,
        y + sign * _bow * 1.5,
        width,
        y - sign * _bow * 0.5,
      );
  }

  /// A felt seam: a soft shadow under a dashed white stitch.
  static void _paintSeam(Canvas canvas, Path edge) {
    canvas.drawPath(
      edge.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    final stitch = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final metric in edge.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 18) {
        canvas.drawPath(metric.extractPath(d, d + 9), stitch);
      }
    }
  }

  static void _paintPattern(Canvas canvas, _SectionBand band, double width) {
    final top = band.top - _bow;
    final bottom = band.bottom + _bow * 2;
    switch (band.section.groundPattern) {
      case MapGroundPattern.plain:
        break;
      case MapGroundPattern.mownStripes:
        final light = Paint()..color = Colors.white.withValues(alpha: 0.09);
        const stripe = 34.0;
        for (var x = 0.0; x < width; x += stripe * 2) {
          canvas.drawRect(Rect.fromLTRB(x, top, x + stripe, bottom), light);
        }
      case MapGroundPattern.flowers:
        // Seeded by the section so the flowers stay put between visits.
        final random = Random(band.section.firstLevel * 131 + 7);
        final count = (width * (bottom - top) / 5200).round();
        const petalColours = [
          Color(0xFFFFFFFF),
          Color(0xFFFFD6EC),
          Color(0xFFFFF3A6),
        ];
        final centre = Paint()..color = const Color(0xFFF5B400);
        for (var i = 0; i < count; i++) {
          final at = Offset(
            random.nextDouble() * width,
            top + random.nextDouble() * (bottom - top),
          );
          final petals = Paint()
            ..color = petalColours[random.nextInt(petalColours.length)]
                .withValues(alpha: 0.85);
          for (var k = 0; k < 5; k++) {
            final angle = k * 2 * pi / 5;
            canvas.drawCircle(
              at + Offset(cos(angle), sin(angle)) * 3.4,
              2.6,
              petals,
            );
          }
          canvas.drawCircle(at, 2, centre);
        }
    }
  }

  @override
  bool shouldRepaint(_SectionGroundPainter old) => old.bands != bands;
}

/// A little wooden sign on a post, naming a [MapSection].
class _SectionSign extends StatelessWidget {
  const _SectionSign({required this.label});

  final String label;

  static const Color _wood = Color(0xFF9A6533);
  static const Color _woodDark = Color(0xFF5E3A17);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _wood,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _woodDark, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: _woodDark, offset: Offset(1, 1.5))],
              ),
            ),
          ),
          Container(width: 6, height: 14, color: _woodDark),
        ],
      ),
    );
  }
}

/// A small triangle pointing sideways from the character to its level.
class _PointerPainter extends CustomPainter {
  _PointerPainter(this.colour, {required this.pointRight});
  final Color colour;
  final bool pointRight;

  @override
  void paint(Canvas canvas, Size size) {
    final tipX = pointRight ? size.width : 0.0;
    final baseX = pointRight ? 0.0 : size.width;
    canvas.drawPath(
      Path()
        ..moveTo(baseX, 0)
        ..lineTo(tipX, size.height / 2)
        ..lineTo(baseX, size.height)
        ..close(),
      Paint()..color = colour,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.colour != colour || old.pointRight != pointRight;
}

/// A rolling hill top across the full width.
class _HillClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(w * 0.25, h * 0.05, w * 0.55, h * 0.25)
      ..quadraticBezierTo(w * 0.8, h * 0.4, w, h * 0.15)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(_HillClipper old) => false;
}
