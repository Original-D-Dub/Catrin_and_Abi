import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../models/school_scene.dart';
import '../providers/school_explorer_provider.dart';
import 'iso_painter.dart';
import 'object_details.dart';

/// Flame game drawing one School Explorer area in isometric 2.5D.
///
/// Listens to [SchoolExplorerProvider]: rebuilds the world when the area
/// changes, and reads selection / find-feedback state every frame for the
/// highlight, bounce and shake animations. Drag pans the view and pinch
/// zooms; taps on objects go back to the provider.
class SchoolExplorerGame extends FlameGame {
  final SchoolExplorerProvider provider;

  SchoolExplorerGame({required this.provider});

  /// Screen space covered by Flutter chrome (header above, area bar
  /// below), so the fitted scene sits in the clear middle.
  double topInset = 110;
  double bottomInset = 140;

  SchoolArea? _shownArea;
  Rect _sceneBounds = Rect.zero;
  double _fitZoom = 1;

  /// The zoom the child chose by pinching or with the +/− buttons. Once
  /// set it's kept — across area changes and screen rotations — until
  /// they tap the "fit" button ([resetView]).
  double? _heldZoom;

  /// Whether the child has zoomed away from the fitted view.
  bool get hasHeldZoom => _heldZoom != null;

  /// On-screen size of one grid unit (≈ one metre) at which close-up
  /// detail starts fading in, and where it's fully shown. Measured in
  /// screen pixels rather than relative to the fitted zoom, so detail
  /// appears when objects are actually big enough to show it — sooner on
  /// a large tablet than on a phone.
  static const double _detailStartPx = 65;
  static const double _detailFullPx = 95;

  /// 0 → 1 fade for [ObjectDetails] close-up detail at the current zoom.
  double get detailOpacity {
    final unitPx = camera.viewfinder.zoom * IsoPainter.unitHeight;
    return ((unitPx - _detailStartPx) / (_detailFullPx - _detailStartPx)).clamp(
      0.0,
      1.0,
    );
  }

  double get _minZoom => _fitZoom * 0.8;

  /// Far enough in that a single object (a tap, a button) fills the view.
  double get _maxZoom => math.max(_fitZoom * 4, 280 / IsoPainter.unitHeight);

  @override
  Color backgroundColor() => _shownArea == SchoolArea.playground
      ? const Color(0xFFBFE3F7)
      : const Color(0xFFF7F1E6);

  @override
  Future<void> onLoad() async {
    _showArea(provider.area);
    provider.addListener(_onProviderChanged);
  }

  @override
  void onRemove() {
    provider.removeListener(_onProviderChanged);
    super.onRemove();
  }

  void _onProviderChanged() {
    if (provider.area != _shownArea) _showArea(provider.area);
  }

  void _showArea(SchoolArea area) {
    final previousArea = _shownArea;
    _shownArea = area;
    world.removeAll(world.children);
    final scene = provider.scene;

    world.add(_PanBackdrop(this)..priority = -1000);
    world.add(_RoomShell(scene)..priority = -900);

    final sorted = IsoPainter.sortForDrawing(
      scene.objects,
      IsoPainter.boxOfObject,
    );
    for (var i = 0; i < sorted.length; i++) {
      world.add(SchoolObjectComponent(sorted[i], this)..priority = i);
    }

    // Bounds of everything drawn: floor, walls and objects.
    final shell = [
      IsoPart(
        0,
        0,
        0,
        scene.width.toDouble(),
        scene.depth.toDouble(),
        scene.hasWalls ? scene.wallHeight : 0,
        const Color(0x00000000),
      ),
    ];
    _sceneBounds = IsoPainter.bounds([
      ...shell,
      for (final o in scene.objects) ...o.parts,
    ]);

    _computeFitZoom();
    final held = _heldZoom;
    if (held == null) {
      resetView();
      return;
    }
    // Keep the child's zoom. Arriving through a door, start at that
    // door's twin on this side, so it feels like walking through.
    camera.viewfinder.zoom = held.clamp(_minZoom, _maxZoom);
    final arrivalDoor = previousArea == null
        ? null
        : scene.objects.where((o) => o.leadsTo == previousArea).firstOrNull;
    final focus = arrivalDoor != null
        ? IsoPainter.bounds(arrivalDoor.parts).center
        : _sceneBounds.center;
    _lookAt(focus);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_shownArea == null) return;
    _computeFitZoom();
    final held = _heldZoom;
    if (held == null) {
      resetView();
    } else {
      camera.viewfinder.zoom = held.clamp(_minZoom, _maxZoom);
      _panBy(Vector2.zero());
    }
  }

  void _computeFitZoom() {
    if (size.x <= 0 || size.y <= 0 || _sceneBounds.isEmpty) return;
    const margin = 16.0;
    final availW = size.x - margin * 2;
    final availH = math.max(100.0, size.y - topInset - bottomInset - margin);
    _fitZoom = math.min(
      availW / _sceneBounds.width,
      availH / _sceneBounds.height,
    );
  }

  /// Fits the whole area into the clear part of the screen and forgets
  /// any zoom the child chose.
  void resetView() {
    if (size.x <= 0 || size.y <= 0 || _sceneBounds.isEmpty) return;
    _heldZoom = null;
    _computeFitZoom();
    camera.viewfinder.zoom = _fitZoom;
    _lookAt(_sceneBounds.center);
  }

  /// Centres [worldPoint] in the clear band between the header and the
  /// bottom bar (not the middle of the whole screen).
  void _lookAt(Offset worldPoint) {
    final zoom = camera.viewfinder.zoom;
    final bandCentreY = (topInset + size.y - bottomInset) / 2;
    final offsetY = (bandCentreY - size.y / 2) / zoom;
    camera.viewfinder.position = Vector2(
      worldPoint.dx,
      worldPoint.dy - offsetY,
    );
    _panBy(Vector2.zero());
  }

  void _panBy(Vector2 screenDelta) {
    final zoom = camera.viewfinder.zoom;
    final p = camera.viewfinder.position - screenDelta / zoom;
    // Keep some of the scene on screen, however far the child drags.
    final r = _sceneBounds.inflate(40);
    camera.viewfinder.position = Vector2(
      p.x.clamp(r.left, r.right),
      p.y.clamp(r.top, r.bottom),
    );
  }

  double _pinchStartZoom = 1;

  void _startPinch() => _pinchStartZoom = camera.viewfinder.zoom;

  void _pinchTo(double scale) => _setZoom(_pinchStartZoom * scale);

  /// Zooms in (factor > 1) or out around the middle of the view — for the
  /// on-screen +/− buttons.
  void zoomBy(double factor) => _setZoom(camera.viewfinder.zoom * factor);

  void _setZoom(double zoom) {
    final z = zoom.clamp(_minZoom, _maxZoom);
    camera.viewfinder.zoom = z;
    _heldZoom = z;
  }
}

/// Invisible full-world layer that catches drags (pan), pinches (zoom) and
/// taps on empty space (deselect).
class _PanBackdrop extends Component
    with DragCallbacks, ScaleCallbacks, TapCallbacks {
  final SchoolExplorerGame game;
  _PanBackdrop(this.game);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    game._panBy(event.canvasDelta);
  }

  @override
  void onScaleStart(ScaleStartEvent event) {
    super.onScaleStart(event);
    game._startPinch();
  }

  @override
  void onScaleUpdate(ScaleUpdateEvent event) {
    if (event.pointerCount >= 2) game._pinchTo(event.scale);
  }

  @override
  void onTapUp(TapUpEvent event) => game.provider.clearSelection();
}

/// Floor tiles plus the two back walls (indoors).
class _RoomShell extends Component {
  final SchoolScene scene;
  _RoomShell(this.scene);

  @override
  void render(Canvas canvas) {
    final w = scene.width.toDouble();
    final d = scene.depth.toDouble();
    final p = IsoPainter.project;

    // Floor.
    final floor = Path()
      ..addPolygon([p(0, 0, 0), p(w, 0, 0), p(w, d, 0), p(0, d, 0)], true);
    canvas.drawPath(floor, Paint()..color = scene.floorColor);
    final grid = Paint()
      ..color = scene.floorLineColor
      ..strokeWidth = 1;
    for (var x = 1; x < scene.width; x++) {
      canvas.drawLine(p(x.toDouble(), 0, 0), p(x.toDouble(), d, 0), grid);
    }
    for (var y = 1; y < scene.depth; y++) {
      canvas.drawLine(p(0, y.toDouble(), 0), p(w, y.toDouble(), 0), grid);
    }

    // Floor edge thickness so the room reads as a solid block.
    const slab = 0.3;
    final edgeLeft = Path()
      ..addPolygon([
        p(0, d, 0),
        p(w, d, 0),
        p(w, d, -slab),
        p(0, d, -slab),
      ], true);
    final edgeRight = Path()
      ..addPolygon([
        p(w, 0, 0),
        p(w, d, 0),
        p(w, d, -slab),
        p(w, 0, -slab),
      ], true);
    canvas.drawPath(
      edgeLeft,
      Paint()..color = IsoPainter.darken(scene.floorColor, 0.25),
    );
    canvas.drawPath(
      edgeRight,
      Paint()..color = IsoPainter.darken(scene.floorColor, 0.35),
    );

    if (!scene.hasWalls) return;
    final h = scene.wallHeight;

    // Back-right wall (y = 0) and back-left wall (x = 0).
    final backWall = Path()
      ..addPolygon([p(0, 0, 0), p(w, 0, 0), p(w, 0, h), p(0, 0, h)], true);
    final sideWall = Path()
      ..addPolygon([p(0, 0, 0), p(0, d, 0), p(0, d, h), p(0, 0, h)], true);
    canvas.drawPath(backWall, Paint()..color = scene.wallColor);
    canvas.drawPath(
      sideWall,
      Paint()..color = IsoPainter.darken(scene.wallColor, 0.08),
    );

    // Skirting boards.
    const skirt = 0.15;
    final skirtColour = IsoPainter.darken(scene.wallColor, 0.3);
    canvas.drawPath(
      Path()..addPolygon([
        p(0, 0, 0),
        p(w, 0, 0),
        p(w, 0, skirt),
        p(0, 0, skirt),
      ], true),
      Paint()..color = skirtColour,
    );
    canvas.drawPath(
      Path()..addPolygon([
        p(0, 0, 0),
        p(0, d, 0),
        p(0, d, skirt),
        p(0, 0, skirt),
      ], true),
      Paint()..color = IsoPainter.darken(skirtColour, 0.08),
    );

    // Wall tops (thickness caps) — thick enough to hold a recessed window.
    const t = 0.35;
    final cap = Paint()..color = IsoPainter.darken(scene.wallColor, 0.2);
    canvas.drawPath(
      Path()
        ..addPolygon([p(-t, -t, h), p(w, -t, h), p(w, 0, h), p(0, 0, h)], true),
      cap,
    );
    canvas.drawPath(
      Path()
        ..addPolygon([p(-t, -t, h), p(0, 0, h), p(0, d, h), p(-t, d, h)], true),
      cap,
    );
  }
}

/// One tappable object, drawn from its parts in painter's order.
class SchoolObjectComponent extends PositionComponent with TapCallbacks {
  final SchoolObject object;
  final SchoolExplorerGame game;

  late final List<IsoPart> _sortedParts = IsoPainter.sortForDrawing(
    object.parts,
    IsoPainter.boxOfPart,
  );
  late final List<Path> _visibleHulls = [
    for (final p in object.parts)
      if (p.visible) IsoPainter.hull(p),
  ];
  late final List<Path> _hulls = [
    for (final p in object.parts) IsoPainter.hull(p),
  ];

  late final DetailPainter? _detailPainter = ObjectDetails.painterFor(object);
  late final DetailPainter? _artPainter = ObjectDetails.artPainterFor(object);

  SchoolObjectComponent(this.object, this.game);

  /// Time since this object was last tapped (drives bounce/shake/flash).
  double _sinceTap = 10;
  int _seenFeedbackSerial = -1;
  double _time = 0;

  @override
  bool containsLocalPoint(Vector2 point) {
    final o = point.toOffset();
    return _hulls.any((h) => h.contains(o));
  }

  @override
  void onTapUp(TapUpEvent event) {
    _sinceTap = 0;
    game.provider.tapObject(object);
  }

  @override
  void update(double dt) {
    _time += dt;
    _sinceTap += dt;
    final provider = game.provider;
    if (provider.feedbackSerial != _seenFeedbackSerial) {
      _seenFeedbackSerial = provider.feedbackSerial;
      if (provider.feedbackObjectId == object.id) _sinceTap = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final provider = game.provider;
    final isSelected = provider.selected?.id == object.id;
    final isFeedbackTarget = provider.feedbackObjectId == object.id;
    final feedback = isFeedbackTarget ? provider.feedback : FindFeedback.none;

    canvas.save();
    // A little hop when tapped; a side-to-side shake for a wrong guess.
    if (_sinceTap < 0.5) {
      final t = _sinceTap / 0.5;
      if (feedback == FindFeedback.wrong) {
        canvas.translate(math.sin(t * math.pi * 6) * 6 * (1 - t), 0);
      } else {
        canvas.translate(0, -math.sin(t * math.pi) * 10);
      }
    }

    for (final part in object.parts) {
      IsoPainter.paintShadow(canvas, part);
    }
    for (final part in _sortedParts) {
      IsoPainter.paintPart(canvas, part);
    }
    final opacity = game.detailOpacity;
    _artPainter?.call(canvas, object, opacity, _time);
    final detail = _detailPainter;
    if (detail != null && opacity > 0) detail(canvas, object, opacity, _time);

    Color? glow;
    if (isSelected) {
      // Gentle pulse so the selected object is easy to spot.
      final pulse = 0.6 + 0.4 * math.sin(_time * 5);
      glow = const Color(0xFFFFC928).withValues(alpha: pulse);
    } else if (feedback == FindFeedback.correct && _sinceTap < 1.5) {
      glow = const Color(
        0xFF34C759,
      ).withValues(alpha: 1 - (_sinceTap / 1.5).clamp(0, 1));
    } else if (feedback == FindFeedback.wrong && _sinceTap < 0.8) {
      glow = const Color(
        0xFFFF3B30,
      ).withValues(alpha: 1 - (_sinceTap / 0.8).clamp(0, 1));
    }
    if (glow != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..color = glow;
      // Outline only what's drawn — not invisible volumes like the
      // plant's foliage box, which would show as a stray hexagon.
      for (final h in _visibleHulls) {
        canvas.drawPath(h, stroke);
      }
    }
    canvas.restore();
  }
}
