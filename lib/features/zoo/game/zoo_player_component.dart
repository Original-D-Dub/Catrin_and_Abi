import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter/services.dart' show rootBundle;

import '../models/zoo_character.dart';
import 'zoo_map_game_base.dart';

/// Player character for the zoo map.
///
/// Drawn as the character chosen on the pick-a-player screen
/// ([ZooProvider.characterId]); characters whose art doesn't exist yet
/// fall back to a plain ellipse placeholder.
///
/// Geometry: a small circle at the component's position handles collision
/// with the walkable path, while the visible body (sprite or ellipse) is
/// twice the circle's height, rising above it so the character visually
/// overlaps the path edges (like standing behind them).
///
/// Movement uses the same touch-and-drag mechanism as Letter Quest's
/// [PlayerComponent]: touch the character, drag to steer (distance maps
/// to speed), and the drag anchor re-centres beyond [_dragRadius] for
/// continuous steering. Blocked moves fall back to the x-only or y-only
/// component so the player slides along path edges.
class ZooPlayerComponent extends PositionComponent
    with HasGameReference<ZooMapGameBase>, DragCallbacks {
  /// Radius of the collision circle (world units), sized to sit within
  /// the ~50-unit walkways.
  static const double collisionRadius = 14.0;

  /// Scales the visible body up relative to the collision circle, so the
  /// character reads larger on screen without widening the hitbox used
  /// for path collision. Bumped up further in landscape, where the map
  /// shows more world width and the character would otherwise read small.
  static const double _portraitBodyScale = 1.5;
  static const double _landscapeBodyScale = 1.75;
  double _bodyScale = _portraitBodyScale;

  /// Visible body: an ellipse one collision-circle wide and twice as
  /// tall (before [_bodyScale]), its base aligned with the bottom of the
  /// collision circle.
  double get bodyWidth => collisionRadius * 2 * _bodyScale;
  double get bodyHeight => collisionRadius * 4 * _bodyScale;

  /// Movement speed in world units per second (matches Letter Quest).
  static const double moveSpeed = 250.0;

  /// Virtual drag radius in canvas pixels: dragging this distance from
  /// the anchor produces full-speed movement (magnitude 1.0).
  static const double _dragRadius = 80.0;

  /// Fallback body colour for characters whose art doesn't exist yet.
  static const Color _bodyColor = Color(0xFF7E57C2);
  static const Color _outlineColor = Color(0xFF4D3591);

  /// The chosen character's portrait, or null while loading / when the
  /// character has no art yet (ellipse fallback).
  Sprite? _sprite;
  Image? _spriteImage;

  /// The chosen character's height multiplier ([ZooCharacter.heightScale]),
  /// applied to the sprite only — the collision circle stays the standard
  /// size regardless.
  double _heightScale = 1.0;

  /// Current movement direction (magnitude 0-1).
  final Vector2 moveDirection = Vector2.zero();

  /// Canvas-space position where the current drag started.
  /// Null when not dragging.
  Vector2? _dragAnchorCanvas;

  /// Points on the collision circle tested against the walkable path
  /// (centre + 8 around the circumference), as unit offsets.
  static final List<Offset> _samplePoints = [
    Offset.zero,
    for (var i = 0; i < 8; i++)
      Offset(cos(i * pi / 4), sin(i * pi / 4)),
  ];

  /// [position] is the collision-circle centre. The component's size is
  /// the visible body plus margin so the ellipse stays a comfortable
  /// touch target for dragging.
  ZooPlayerComponent({required super.position})
      : super(
          // Orientation isn't known yet at construction time (not mounted
          // to the game tree); starts at the portrait size and is
          // corrected by [onGameResize], which fires immediately on mount.
          size: Vector2(
            collisionRadius * 2 * _portraitBodyScale * 3,
            collisionRadius * 4 * _portraitBodyScale * 1.6,
          ),
          anchor: Anchor.center,
          priority: 1,
        );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _bodyScale = size.x > size.y ? _landscapeBodyScale : _portraitBodyScale;
    this.size = Vector2(bodyWidth * 3, bodyHeight * 1.6);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final character = ZooCharacter.byId(game.characterId);
    _heightScale = character.heightScale;
    final asset = character.fullAsset;
    try {
      final data = await rootBundle.load(asset);
      _spriteImage = await decodeImageFromList(data.buffer.asUint8List());
      _sprite = Sprite(_spriteImage!);
    } catch (_) {
      // Character art not created yet — keep the ellipse placeholder.
    }
  }

  @override
  void onRemove() {
    _spriteImage?.dispose();
    _spriteImage = null;
    _sprite = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final centre = (size / 2).toOffset();

    // Character sprite: same height as the placeholder ellipse (width
    // follows the image's aspect ratio), base level with the collision
    // circle's bottom edge.
    final sprite = _sprite;
    if (sprite != null) {
      final spriteHeight = bodyHeight * _heightScale;
      final spriteWidth = spriteHeight * sprite.srcSize.x / sprite.srcSize.y;
      sprite.render(
        canvas,
        position: Vector2(
          centre.dx - spriteWidth / 2,
          centre.dy + collisionRadius - spriteHeight,
        ),
        size: Vector2(spriteWidth, spriteHeight),
      );
      return;
    }

    // Body ellipse: base level with the collision circle's bottom edge.
    final body = Rect.fromLTRB(
      centre.dx - bodyWidth / 2,
      centre.dy + collisionRadius - bodyHeight,
      centre.dx + bodyWidth / 2,
      centre.dy + collisionRadius,
    );
    canvas.drawOval(body, Paint()..color = _bodyColor);
    canvas.drawOval(
      body,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  // -------------------------
  // Drag handling (as Letter Quest)
  // -------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragAnchorCanvas = event.canvasPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragAnchorCanvas == null) return;

    final currentCanvas = event.canvasStartPosition;
    final rawDelta = currentCanvas - _dragAnchorCanvas!;

    // Dead zone — ignore tiny finger jitter.
    if (rawDelta.length < _dragRadius * 0.1) {
      moveDirection.setZero();
      return;
    }

    // Clamp to _dragRadius and re-centre the anchor so the user can
    // steer continuously without lifting their finger.
    final clamped = rawDelta.clone();
    if (clamped.length > _dragRadius) {
      clamped.scaleTo(_dragRadius);
      _dragAnchorCanvas = currentCanvas - clamped;
    }

    moveDirection.setFrom(clamped / _dragRadius);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragAnchorCanvas = null;
    moveDirection.setZero();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragAnchorCanvas = null;
    moveDirection.setZero();
  }

  // -------------------------
  // Movement
  // -------------------------

  @override
  void update(double dt) {
    super.update(dt);
    if (moveDirection.length > 0.1) {
      _tryMove(moveDirection.normalized() * moveSpeed * dt);
    }
  }

  /// Moves by [delta] if the collision circle stays on the walkway,
  /// otherwise slides along whichever single axis remains walkable.
  void _tryMove(Vector2 delta) {
    if (_circleWalkable(position + delta)) {
      position.add(delta);
      return;
    }
    if (delta.x != 0 && _circleWalkable(position + Vector2(delta.x, 0))) {
      position.x += delta.x;
      return;
    }
    if (delta.y != 0 && _circleWalkable(position + Vector2(0, delta.y))) {
      position.y += delta.y;
    }
  }

  /// Whether the whole collision circle centred at [centre] is on the
  /// walkable path.
  bool _circleWalkable(Vector2 centre) {
    final c = centre.toOffset();
    return _samplePoints
        .every((p) => game.isWalkable(c + p * collisionRadius));
  }
}
