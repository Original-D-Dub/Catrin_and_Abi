import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show VoidCallback;

import '../models/room_config.dart';
import 'base_letter_quest_game.dart';
import 'bed_component.dart';
import 'desk_component.dart';
import 'player_component.dart';
import 'simple_room_component.dart';

/// Which room of the five-room cross layout a position belongs to.
enum _Room { a, e, i, o, u }

/// The chasing character in Letter Quest Level 3.
///
/// Gary navigates the five-room cross layout at 80 % of the player's top speed
/// (160 world-units/s vs the player's 200). He uses the same doorways and wall
/// collision resolution as the player, so he must physically walk through the
/// gaps rather than cutting through walls.
///
/// Navigation uses a two-stage waypoint strategy:
///   1. If Gary and the player share a room → move directly toward the player.
///   2. Otherwise → aim for a point just inside the adjacent room on the path
///      toward the player (edge rooms route through Room I first).
///
/// When Gary is within [_catchRadius] of the player [onPlayerCaught] is called.
/// A [_startDelay] gives the player a head-start at the beginning and after
/// each catch-and-reset.
class GaryComponent extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<BaseLetterQuestGame> {
  // ── Constants ──────────────────────────────────────────────────────────────

  /// Visual diameter (world units) — matches the spec.
  static const double diameter = 72.0;

  /// 60 % of the player's top speed of 200 units/s.
  static const double chaseSpeed = 120.0;

  /// Catch radius: sum of Gary's and player's approximate circle radii.
  static const double _catchRadius = 54.0;

  /// Seconds Gary waits before starting to chase after spawn / reset.
  static const double _graceSeconds = 3.0;

  // ── State ──────────────────────────────────────────────────────────────────

  final PositionComponent _player;
  final VoidCallback onPlayerCaught;

  /// When true Gary stands still and never triggers [onPlayerCaught].
  /// Used in Level 2 where Gary hides in a room rather than chasing.
  final bool isHiding;

  bool _isCaught = false;
  double _startDelay;
  double _previousX = 0;

  // ── Constructor ────────────────────────────────────────────────────────────

  final double _sizeMultiplier;

  GaryComponent({
    required Vector2 position,
    required PositionComponent player,
    required this.onPlayerCaught,
    this.isHiding = false,
    double startDelay = _graceSeconds,
    double sizeMultiplier = 1.0,
  })  : _player = player,
        _startDelay = startDelay,
        _sizeMultiplier = sizeMultiplier,
        super(
          position: position,
          size: Vector2(
              diameter * 2 * sizeMultiplier, diameter * 2 * sizeMultiplier),
          anchor: Anchor.center,
        );

  // ── Flame lifecycle ────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    final sheet = SpriteSheet(
      image: game.images.fromCache('characters/Gary/Gary-sprite.png'),
      srcSize: Vector2.all(256),
    );
    animation = sheet.createAnimation(row: 0, stepTime: 0.1);
    _previousX = position.x;
    add(CircleHitbox());
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_isCaught) return;

    // Catch check — skip if the player is mid-jump (safe on a bed).
    final p = _player;
    final playerJumping = p is PlayerComponent && p.isJumping;
    if (!playerJumping &&
        position.distanceTo(_player.position) <=
            _catchRadius * _sizeMultiplier) {
      _isCaught = true;
      onPlayerCaught();
      return;
    }

    // When hiding Gary stands still — skip movement and grace period.
    if (isHiding) {
      _previousX = position.x;
      return;
    }

    // Grace period — give the player a head-start
    if (_startDelay > 0) {
      _startDelay -= dt;
      _previousX = position.x;
      return;
    }

    // Move toward waypoint
    final target = _navigationTarget();
    final delta = target - position;
    if (delta.length > 1) {
      position += delta.normalized() * chaseSpeed * dt;
    }

    // Flip sprite to face the direction of travel
    final dx = position.x - _previousX;
    if (dx > 0.5) {
      scale.x = -1.0; // moving right — flip
    } else if (dx < -0.5) {
      scale.x = 1.0;  // moving left — normal
    }
    _previousX = position.x;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Returns the world-space point Gary should move toward this frame.
  ///
  /// Same room → aim directly at the player.
  /// Different rooms → aim for a point just inside the next room on the route.
  /// Edge rooms always route through Room I (the hub).
  Vector2 _navigationTarget() {
    final garyRoom = _roomAt(position);
    final playerRoom = _roomAt(_player.position);

    if (garyRoom == playerRoom) return _player.position;

    return garyRoom == _Room.i
        ? _waypointIntoRoom(playerRoom) // already in hub → head for player's room
        : _waypointIntoHub(garyRoom);  // in edge room → head for hub first
  }

  /// A point just inside Room I, beyond the doorway from [edgeRoom].
  ///
  /// The 100-unit margin past the wall boundary ensures Gary's heading
  /// passes cleanly through the doorway gap rather than into a wall corner.
  Vector2 _waypointIntoHub(_Room edgeRoom) {
    switch (edgeRoom) {
      case _Room.a:
        return Vector2(1040, 1020); // past I's left wall  (x 900–940)
      case _Room.e:
        return Vector2(1350, 820);  // past I's top wall   (y 680–720)
      case _Room.o:
        return Vector2(1660, 1020); // past I's right wall (x 1760–1800)
      case _Room.u:
        return Vector2(1350, 1220); // past I's bottom wall (y 1320–1360)
      case _Room.i:
        return position; // already in hub
    }
  }

  /// A point just inside [targetRoom], beyond the doorway from Room I.
  Vector2 _waypointIntoRoom(_Room targetRoom) {
    switch (targetRoom) {
      case _Room.a:
        return Vector2(760, 1020);  // past A's right wall (x 860–900)
      case _Room.e:
        return Vector2(1350, 540);  // past E's bottom wall (y 640–680)
      case _Room.o:
        return Vector2(1940, 1020); // past O's left wall  (x 1800–1840)
      case _Room.u:
        return Vector2(1350, 1500); // past U's top wall   (y 1360–1400)
      case _Room.i:
        return _player.position;
    }
  }

  // ── Room detection ─────────────────────────────────────────────────────────

  // Room layout (each room 900 × 680 world units):
  //
  //               (900, 0)
  //              +--------+
  //              | Room E |
  //              +--------+
  //   (0, 680)   (900,680) (1800,680)
  //   +--------+ +--------+ +--------+
  //   | Room A | | Room I | | Room O |
  //   +--------+ +--------+ +--------+
  //              (900,1360)
  //              +--------+
  //              | Room U |
  //              +--------+

  static const double _rw = RoomConfig.roomWidth;  // 900
  static const double _rh = RoomConfig.roomHeight; // 680

  _Room _roomAt(Vector2 p) {
    if (p.x < _rw && p.y >= _rh && p.y < _rh * 2) return _Room.a;
    if (p.x >= _rw && p.x < _rw * 2 && p.y < _rh) return _Room.e;
    if (p.x >= _rw * 2 && p.y >= _rh && p.y < _rh * 2) return _Room.o;
    if (p.x >= _rw && p.x < _rw * 2 && p.y >= _rh * 2) return _Room.u;
    return _Room.i; // center hub (default)
  }

  // ── Collision ──────────────────────────────────────────────────────────────

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is TiledWallComponent) _resolveRectCollision(other);
    if (other is BedComponent) _resolveRectCollision(other);
    if (other is DeskComponent) _resolveRectCollision(other);
  }

  /// Identical minimum-penetration pushback to [PlayerComponent._resolveRectCollision].
  void _resolveRectCollision(PositionComponent obstacle) {
    final obstacleCenter = obstacle.absolutePosition + obstacle.size / 2;
    final delta = position - obstacleCenter;
    final scaledRadius = diameter / 2 * _sizeMultiplier;
    final halfW = obstacle.size.x / 2 + scaledRadius;
    final halfH = obstacle.size.y / 2 + scaledRadius;
    final overlapX = halfW - delta.x.abs();
    final overlapY = halfH - delta.y.abs();
    if (overlapX <= 0 || overlapY <= 0) return;
    if (overlapX < overlapY) {
      position.x += delta.x > 0 ? overlapX : -overlapX;
    } else {
      position.y += delta.y > 0 ? overlapY : -overlapY;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Moves Gary back to [startPosition] and re-enables chasing after a short
  /// grace period.
  void reset(Vector2 startPosition) {
    position = startPosition.clone();
    _isCaught = false;
    _startDelay = 2.0; // shorter grace on subsequent catches
  }
}
