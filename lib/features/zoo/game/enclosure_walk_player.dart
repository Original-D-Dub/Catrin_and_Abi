import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Placeholder player character for the enclosure walk levels.
///
/// Side-scroller variant of the zoo map's placeholder player: the
/// character is moved by touching and dragging it horizontally (drag
/// distance maps to speed, and the anchor re-centres beyond [_dragRadius]
/// for continuous walking — the same mechanism as Letter Quest and the
/// zoo map). Movement is x-only; the feet stay on the floor baseline.
///
/// Drawn from primitive shapes until character art exists. Three facings:
/// walking left / walking right show a side profile with an eye; stopped
/// in front of a window shows the character from behind (no face), as if
/// looking into the enclosure.
class EnclosureWalkPlayer extends PositionComponent with DragCallbacks {
  /// Movement speed in logical px per second, scaled up with the
  /// character so tablets don't feel slower.
  double get _moveSpeed => size.y * 1.4;

  /// Virtual drag radius in canvas pixels: dragging this far from the
  /// anchor produces full walking speed.
  static const double _dragRadius = 80.0;

  static const Color _shirt = Color(0xFF00897B);
  static const Color _shirtBack = Color(0xFF00695C);
  static const Color _shorts = Color(0xFF37474F);
  static const Color _skin = Color(0xFFFFCC80);
  static const Color _hair = Color(0xFF5D4037);

  /// Current horizontal input, -1..1. Zero when not dragging.
  double _moveX = 0;

  /// Canvas-space x where the current drag started, null when idle.
  double? _dragAnchorX;

  /// True while walking right (or last walked right) — flips the profile.
  bool _facingRight = true;

  /// Set by the game each frame: true when stopped in front of a window,
  /// which draws the back view.
  bool facingWindow = false;

  /// Horizontal range the feet may occupy, set by the game from the
  /// world layout.
  double minX = 0;
  double maxX = double.infinity;

  /// [position] is the feet (bottom-centre); [height] comes from
  /// [EnclosureWalkLayout.playerHeight].
  EnclosureWalkPlayer({required super.position, required double height})
      : super(
          size: Vector2(height * 0.52, height),
          anchor: Anchor.bottomCenter,
          priority: 2,
        );

  /// Whether the character is currently being walked.
  bool get isMoving => _moveX.abs() > 0.1;

  // -------------------------
  // Drag handling (x-only variant of the shared mechanism)
  // -------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragAnchorX = event.canvasPosition.x;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final anchor = _dragAnchorX;
    if (anchor == null) return;

    final currentX = event.canvasStartPosition.x;
    var delta = currentX - anchor;

    // Dead zone — ignore tiny finger jitter.
    if (delta.abs() < _dragRadius * 0.1) {
      _moveX = 0;
      return;
    }

    // Clamp to _dragRadius and re-centre the anchor so the user can keep
    // walking without lifting their finger.
    if (delta.abs() > _dragRadius) {
      delta = delta.sign * _dragRadius;
      _dragAnchorX = currentX - delta;
    }

    _moveX = delta / _dragRadius;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragAnchorX = null;
    _moveX = 0;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragAnchorX = null;
    _moveX = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMoving) return;
    _facingRight = _moveX > 0;
    position.x =
        (position.x + _moveX * _moveSpeed * dt).clamp(minX, maxX);
  }

  // -------------------------
  // Placeholder rendering
  // -------------------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;

    canvas.save();
    if (!facingWindow && !_facingRight) {
      // Mirror the side profile to walk left.
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final fill = Paint();

    // Legs.
    fill.color = _shorts;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.60, w * 0.17, h * 0.38),
        Radius.circular(w * 0.08),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.55, h * 0.60, w * 0.17, h * 0.38),
        Radius.circular(w * 0.08),
      ),
      fill,
    );

    // Body.
    fill.color = facingWindow ? _shirtBack : _shirt;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.64, h * 0.40),
        Radius.circular(w * 0.16),
      ),
      fill,
    );

    // Head.
    final headCentre = Offset(w * 0.5, h * 0.14);
    final headRadius = h * 0.13;
    fill.color = _skin;
    canvas.drawCircle(headCentre, headRadius, fill);

    fill.color = _hair;
    if (facingWindow) {
      // Back of the head: hair covers the whole crown.
      canvas.drawCircle(headCentre, headRadius, fill);
    } else {
      // Side profile: hair cap plus an eye on the leading side.
      canvas.drawArc(
        Rect.fromCircle(center: headCentre, radius: headRadius),
        3.34, // ~191°: cap tilted slightly over the forehead
        2.75, // sweep ~158°
        true,
        fill,
      );
      fill.color = const Color(0xFF212121);
      canvas.drawCircle(
        headCentre + Offset(headRadius * 0.55, headRadius * 0.15),
        h * 0.017,
        fill,
      );
    }

    canvas.restore();
  }
}
