import 'dart:math' as math;
import 'dart:ui';

/// Screen-space layout for an enclosure walk level.
///
/// The game runs at camera zoom 1, so world units are logical pixels and
/// everything can be sized as a fraction of the canvas. Recomputed from
/// scratch on every canvas resize (rotation, window resize).
///
/// Window sizing rule: 70% of screen width on mobile, 50% on tablet, with
/// the gap chosen as 40% of the remaining width so that when the player is
/// centred on one window the edge of the next is always on screen
/// (mobile: 0.12 + 0.35 = 0.47 < 0.5 screen-widths from centre;
/// tablet: 0.20 + 0.25 = 0.45).
class EnclosureWalkLayout {
  /// Canvas below this shortest side is treated as a phone.
  static const double tabletBreakpoint = 600;

  /// Player character height: 320 logical px on mobile, taller on tablet.
  static const double mobilePlayerHeight = 320;
  static const double tabletPlayerHeight = 430;

  final Size canvas;
  final bool isTablet;

  /// Enclosure window size and horizontal centres (world x), walk order.
  final double windowWidth;
  final double windowHeight;
  final double windowTop;
  final List<double> windowCenters;

  /// Gap of bare rock wall between adjacent windows.
  final double gap;

  /// Exit door after the last enclosure, standing on the floor line.
  final double doorCenterX;
  final double doorWidth;
  final double doorHeight;

  /// Total scrollable world width.
  final double worldWidth;

  /// Floor strip the player walks on (bottom of the screen).
  final double floorTop;

  final double playerHeight;

  /// World y of the player's feet — partway down the floor strip so the
  /// character reads as standing on it.
  final double playerBaselineY;

  /// Player spawn x — left of the first window so the walk starts by
  /// scrolling right.
  final double playerStartX;

  EnclosureWalkLayout._({
    required this.canvas,
    required this.isTablet,
    required this.windowWidth,
    required this.windowHeight,
    required this.windowTop,
    required this.windowCenters,
    required this.gap,
    required this.doorCenterX,
    required this.doorWidth,
    required this.doorHeight,
    required this.worldWidth,
    required this.floorTop,
    required this.playerHeight,
    required this.playerBaselineY,
    required this.playerStartX,
  });

  factory EnclosureWalkLayout.forCanvas(Size canvas, int enclosureCount) {
    final isTablet = canvas.shortestSide >= tabletBreakpoint;

    final windowWidth = canvas.width * (isTablet ? 0.5 : 0.7);
    final gap = (canvas.width - windowWidth) * 0.4;
    final spacing = windowWidth + gap;

    // First window centred one half-screen in, so the world starts and
    // ends with half a screen of wall on either side.
    final windowCenters = List<double>.generate(
      enclosureCount,
      (i) => canvas.width / 2 + i * spacing,
    );

    final floorHeight = canvas.height * 0.18;
    final floorTop = canvas.height - floorHeight;

    // Window vertically centred in the wall area, leaving headroom for
    // the name plaque above and a sill of rock below. In portrait the
    // window is shortened and pushed further down, clearing extra space
    // at the top of the wall so the BSL sign has room below the header
    // bar without covering the window or plaque.
    final isPortrait = canvas.height > canvas.width;
    final windowHeight = floorTop * (isPortrait ? 0.45 : 0.62);
    final windowTop = floorTop * (isPortrait ? 0.36 : 0.24);

    // Clamped so landscape phones (short canvases) don't get a character
    // taller than the room.
    final playerHeight = math.min(
      isTablet ? tabletPlayerHeight : mobilePlayerHeight,
      canvas.height * 0.62,
    );

    // Exit door after the last enclosure, one window-gap along, tall
    // enough for the character to fit through. Its near edge peeks into
    // view from the last window just like the next window would.
    final doorHeight =
        math.min(playerHeight * 1.35, floorTop * 0.75);
    final doorWidth = doorHeight * 0.52;
    final doorCenterX =
        windowCenters.last + windowWidth / 2 + gap + doorWidth / 2;
    final worldWidth = doorCenterX + canvas.width / 2;

    return EnclosureWalkLayout._(
      canvas: canvas,
      isTablet: isTablet,
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      windowTop: windowTop,
      windowCenters: windowCenters,
      gap: gap,
      doorCenterX: doorCenterX,
      doorWidth: doorWidth,
      doorHeight: doorHeight,
      worldWidth: worldWidth,
      floorTop: floorTop,
      playerHeight: playerHeight,
      playerBaselineY: canvas.height - floorHeight * 0.45,
      playerStartX: canvas.width * 0.22,
    );
  }

  /// Half-width of the "stopped in front of window i" zone around each
  /// window centre.
  double get triggerHalfWidth => windowWidth * 0.35;

  /// Index of the window the player at [x] is in front of, or null.
  int? windowIndexAt(double x) {
    for (var i = 0; i < windowCenters.length; i++) {
      if ((x - windowCenters[i]).abs() <= triggerHalfWidth) return i;
    }
    return null;
  }

  /// Whether the player at [x] is in front of the exit door.
  bool isAtDoor(double x) => (x - doorCenterX).abs() <= doorWidth * 0.6;
}
