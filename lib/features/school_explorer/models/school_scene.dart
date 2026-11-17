import 'dart:ui';

/// The four places a child can explore in School Explorer.
///
/// [index] + 1 doubles as the per-area level number for score tracking
/// (`GameStatsService.recordGameResult(..., level:)`).
enum SchoolArea {
  classroom,
  hall,
  playground,
  canteen;

  /// Translation key for the area's display name.
  String get titleKey => 'school_explorer.area.$name';
}

/// Surface pattern painted on an [IsoPart]'s visible faces, for details
/// that a plain coloured box can't show (clock hands, window panes...).
enum IsoDecal {
  none,
  clock,
  window,
  books,
  screen,
  writing,
  pictures,
  keys,
  pianoKeys,
  door,
  hopscotch,
  lines,
  leaves,
  food,
}

/// One axis-aligned box of an object, in grid units.
///
/// `x` runs down-right on screen, `y` runs down-left and `z` is up. A part
/// with `h == 0` is flat (a rug, a painted line) and only its top is drawn.
class IsoPart {
  final double x, y, z;
  final double w, d, h;
  final Color color;
  final IsoDecal decal;

  /// Optional name, so a close-up detail painter (see `ObjectDetails`) can
  /// find a specific part — e.g. the fountain's `spout`.
  final String? id;

  /// False for an invisible volume: not painted, but still counted for
  /// tapping, draw order and camera bounds — e.g. the space a plant's
  /// hand-drawn leaves fill (see `ObjectDetails` art painters).
  final bool visible;

  /// True for a window or door set into a wall rather than stuck on it. The part
  /// is then the hole's volume *behind* the wall face — ending at `x == 0`
  /// for the x == 0 wall (when `w < d`) or `y == 0` for the y == 0 wall —
  /// and is painted as an opening you look into, not as a box. Its
  /// [color] is the wall's, used for the inside of the opening.
  final bool recessed;

  /// For a [recessed] part, what fills the back of the hole: the door's
  /// colour for a doorway; null for a window's glass.
  final Color? insetColor;

  const IsoPart(
    this.x,
    this.y,
    this.z,
    this.w,
    this.d,
    this.h,
    this.color, {
    this.decal = IsoDecal.none,
    this.id,
    this.visible = true,
    this.recessed = false,
    this.insetColor,
  });

  /// Draw-order key: parts (and objects) further back have a smaller sum.
  double get depth => (x + w / 2) + (y + d / 2) + z * 0.01;
}

/// A tappable thing in a [SchoolScene] — built from one or more [IsoPart]s.
class SchoolObject {
  /// Unique within its area; also used for speech clip names
  /// (`school_explorer_<id>.mp3`).
  final String id;

  /// Translation key root: `<nameKey>` is the display name and
  /// `<nameKey>.find` the "Can you find...?" question.
  final String nameKey;

  final List<IsoPart> parts;

  /// When set, this object is a doorway to that area (arriving from it,
  /// the camera starts at this door).
  final SchoolArea? leadsTo;

  /// Whether this object can be picked as a "Can you find...?" target.
  final bool findable;

  const SchoolObject({
    required this.id,
    required this.nameKey,
    required this.parts,
    this.leadsTo,
    this.findable = true,
  });

  double get depth {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final p in parts) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x + p.w > maxX) maxX = p.x + p.w;
      if (p.y + p.d > maxY) maxY = p.y + p.d;
    }
    return (minX + maxX) / 2 + (minY + maxY) / 2;
  }
}

/// One explorable area: floor, optional back walls and its objects.
class SchoolScene {
  final SchoolArea area;

  /// Floor size in grid units.
  final int width, depth;

  final Color floorColor;
  final Color floorLineColor;

  /// Indoors areas have two back walls; the playground has none.
  final bool hasWalls;
  final Color wallColor;
  final double wallHeight;

  final List<SchoolObject> objects;

  const SchoolScene({
    required this.area,
    required this.width,
    required this.depth,
    required this.floorColor,
    required this.floorLineColor,
    this.hasWalls = true,
    this.wallColor = const Color(0xFFF3E6C8),
    this.wallHeight = 3.2,
    required this.objects,
  });

  List<SchoolObject> get findableObjects =>
      objects.where((o) => o.findable).toList();
}
