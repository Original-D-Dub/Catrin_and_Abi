import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'base_letter_quest_game.dart';
import 'letter_collectible.dart';
import 'outdoor/boundary_wall_component.dart';
import 'outdoor/rock_component.dart';
import 'outdoor/tree_component.dart';
import 'outdoor/water_component.dart';
import 'simple_room_component.dart';
import 'wall_component.dart';

/// Movement direction states for sprite animation selection.
enum _PeroDirection { idle, left, right }

/// The player character (Pero the hearing dog) in Letter Quest.
///
/// Pero is displayed using an animated sprite sheet (`peroSprite4.png`),
/// a 3x3 grid of 200x150px frames (9 frames total).
/// - Moving left: cycles through frames 0-5 (first 6)
/// - Moving right: cycles through frames 3-8 (last 6)
/// - Idle: shows the first frame of the last movement direction
///
/// Movement is controlled by touching and dragging Pero directly.
///
/// Drag mechanics:
/// - Touch Pero to start dragging
/// - Drag in any direction to move — distance maps to speed (0-1 range)
/// - Release to stop movement
/// - Drag anchor re-centres when exceeding [_dragRadius] for continuous steering
///
/// Handles collision with:
/// - [WallComponent] / [TiledWallComponent]: prevents passing through walls
/// - [WaterComponent]: prevents crossing water (Level 4)
/// - [LetterCollectible]: triggers letter collection logic
///
/// Used by all Letter Quest levels via [BaseLetterQuestGame].
class PlayerComponent extends SpriteAnimationGroupComponent<_PeroDirection>
    with
        CollisionCallbacks,
        HasGameReference<BaseLetterQuestGame>,
        DragCallbacks {
  /// Player width in world units
  static const double playerWidth = 100.0;

  /// Player height in world units
  static const double playerHeight = 80.0;

  /// Movement speed in world units per second
  static const double moveSpeed = 200.0;

  /// Virtual drag radius in canvas pixels.
  ///
  /// Dragging this distance from the anchor point produces full-speed
  /// movement (magnitude 1.0), comparable to the joystick's knob radius.
  static const double _dragRadius = 80.0;

  /// Sprite sheet layout: 3 columns, 4 rows, 200x150px per frame.
  static const int _sheetColumns = 3;
  static const int _sheetRows = 4;
  static const double _frameWidth = 200.0;
  static const double _frameHeight = 150.0;

  /// Animation step time (seconds per frame)
  static const double _stepTime = 0.15;

  /// Current movement direction (magnitude 0-1).
  ///
  /// Set by [onDragUpdate] and cleared by [onDragEnd].
  /// Applied each frame in [update].
  Vector2 moveDirection = Vector2.zero();

  /// Canvas-space position where the current drag started.
  ///
  /// Stored in canvas (screen) space so the camera following the player
  /// does not shift the reference point each frame.
  /// Null when not dragging.
  Vector2? _dragAnchorCanvas;

  /// Creates the player at the given world position.
  PlayerComponent({required super.position})
      : super(
          size: Vector2(playerWidth, playerHeight),
          anchor: Anchor.center,
          current: _PeroDirection.idle,
        );

  @override
  Future<void> onLoad() async {
    final sheetImage =
        game.images.fromCache('games/letter_quest/peroSprite4.png');

    // Extract all 12 sprites from the 3x4 grid (row-major order)
    final allSprites = <Sprite>[];
    for (int row = 0; row < _sheetRows; row++) {
      for (int col = 0; col < _sheetColumns; col++) {
        allSprites.add(Sprite(
          sheetImage,
          srcPosition: Vector2(col * _frameWidth, row * _frameHeight),
          srcSize: Vector2(_frameWidth, _frameHeight),
        ));
      }
    }

    // Left animation: frames 1-6 (indices 0-5)
    final leftFrames = allSprites.sublist(0, 6);
    final leftAnimation = SpriteAnimation.spriteList(
      leftFrames,
      stepTime: _stepTime,
    );

    // Right animation: frames 7-12 (indices 6-11)
    final rightFrames = allSprites.sublist(6, 12);
    final rightAnimation = SpriteAnimation.spriteList(
      rightFrames,
      stepTime: _stepTime,
    );

    // Idle: single frame (first sprite), non-looping
    final idleAnimation = SpriteAnimation.spriteList(
      [allSprites[0]],
      stepTime: 1.0,
      loop: false,
    );

    animations = {
      _PeroDirection.idle: idleAnimation,
      _PeroDirection.left: leftAnimation,
      _PeroDirection.right: rightAnimation,
    };

    // Circular hitbox for smooth collision with walls and letters
    add(CircleHitbox());
  }

  // -------------------------
  // Drag handling
  // -------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Record finger-down position in canvas space (screen-relative)
    _dragAnchorCanvas = event.canvasPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragAnchorCanvas == null) return;

    // Current finger position in canvas space
    final currentCanvas = event.canvasStartPosition;

    // Vector from anchor to current finger, in canvas pixels
    final rawDelta = currentCanvas - _dragAnchorCanvas!;

    // Dead zone — ignore tiny finger jitter
    if (rawDelta.length < _dragRadius * 0.1) {
      moveDirection.setZero();
      return;
    }

    // Clamp to _dragRadius and re-centre the anchor so the user
    // can steer continuously without lifting their finger
    final clamped = rawDelta.clone();
    if (clamped.length > _dragRadius) {
      clamped.scaleTo(_dragRadius);
      _dragAnchorCanvas = currentCanvas - clamped;
    }

    // Normalize to 0-1 range, matching the old joystick relativeDelta
    moveDirection = clamped / _dragRadius;
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

    // Apply drag movement and update animation direction
    if (moveDirection.length > 0.1) {
      position += moveDirection.normalized() * moveSpeed * dt;

      // Switch animation based on horizontal movement direction
      if (moveDirection.x < 0) {
        current = _PeroDirection.left;
      } else {
        current = _PeroDirection.right;
      }
    } else {
      current = _PeroDirection.idle;
    }
  }

  // -------------------------
  // Collision
  // -------------------------

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is WallComponent || other is TiledWallComponent) {
      _resolveRectCollision(other);
    }

    // Water uses the same pushback logic as walls (Level 4)
    if (other is WaterComponent) {
      _resolveRectCollision(other);
    }

    // Tree and rock obstacles (Level 4)
    if (other is TreeComponent) {
      _resolveRectCollision(other);
    }
    if (other is RockComponent) {
      _resolveRectCollision(other);
    }

    // Boundary wall (Level 4 treeline edge)
    if (other is BoundaryWallComponent) {
      _resolveRectCollision(other);
    }

    if (other is LetterCollectible) {
      other.onPlayerContact(game.provider);
    }
  }

  /// Resolves collision with a rectangular obstacle by pushing the player out.
  ///
  /// Works for any [PositionComponent] with a size (walls, water, etc.).
  /// Uses the component's position and size to determine which side
  /// the player hit and pushes them back along that axis only,
  /// allowing sliding along obstacles.
  void _resolveRectCollision(PositionComponent obstacle) {
    final obstacleCenter = obstacle.absolutePosition + obstacle.size / 2;
    final playerCenter = position;
    final delta = playerCenter - obstacleCenter;

    // Calculate overlap on each axis
    final halfW = obstacle.size.x / 2 + playerWidth / 2;
    final halfH = obstacle.size.y / 2 + playerHeight / 2;
    final overlapX = halfW - delta.x.abs();
    final overlapY = halfH - delta.y.abs();

    if (overlapX <= 0 || overlapY <= 0) return;

    // Push out along the axis with less overlap (minimum penetration)
    if (overlapX < overlapY) {
      position.x += delta.x > 0 ? overlapX : -overlapX;
    } else {
      position.y += delta.y > 0 ? overlapY : -overlapY;
    }
  }
}
