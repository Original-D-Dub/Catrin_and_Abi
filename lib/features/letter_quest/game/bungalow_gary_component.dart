import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show VoidCallback;

import '../models/bungalow_config.dart';
import 'base_letter_quest_game.dart';
import 'bed_component.dart';
import 'desk_component.dart';
import 'player_component.dart';
import 'simple_room_component.dart';

/// Gary for the bungalow level with room-aware pathfinding.
class BungalowGaryComponent extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<BaseLetterQuestGame> {
  static const double diameter = 72.0;
  static const double chaseSpeed = 120.0;
  static const double _catchRadius = 54.0;
  static const double _graceSeconds = 3.0;

  final PositionComponent _player;
  final VoidCallback onPlayerCaught;

  bool _isCaught = false;
  double _startDelay;
  double _previousX = 0;

  BungalowGaryComponent({
    required Vector2 position,
    required PositionComponent player,
    required this.onPlayerCaught,
    double startDelay = _graceSeconds,
  })  : _player = player,
        _startDelay = startDelay,
        super(
          position: position,
          size: Vector2(diameter * 2, diameter * 2),
          anchor: Anchor.center,
        );

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

  @override
  void update(double dt) {
    super.update(dt);
    if (_isCaught) return;

    final p = _player;
    final playerJumping = p is PlayerComponent && p.isJumping;
    if (!playerJumping &&
        position.distanceTo(_player.position) <= _catchRadius) {
      _isCaught = true;
      onPlayerCaught();
      return;
    }

    if (_startDelay > 0) {
      _startDelay -= dt;
      _previousX = position.x;
      return;
    }

    final target = _navigationTarget();
    final delta = target - position;
    if (delta.length > 1) {
      position += delta.normalized() * chaseSpeed * dt;
    }

    final dx = position.x - _previousX;
    if (dx > 0.5) {
      scale.x = -1.0;
    } else if (dx < -0.5) {
      scale.x = 1.0;
    }
    _previousX = position.x;
  }

  Vector2 _navigationTarget() {
    final garyRoom = BungalowConfig.roomAt(position);
    final playerRoom = BungalowConfig.roomAt(_player.position);

    if (garyRoom == playerRoom) return _player.position;

    final nextRoom = BungalowConfig.nextRoomOnPath(garyRoom, playerRoom);
    final center = BungalowConfig.doorwayCenter(garyRoom, nextRoom);
    final isVert = BungalowConfig.isDoorwayVertical(garyRoom, nextRoom);
    const halfGap = BungalowConfig.doorwayWidth / 2 - 20;

    // Phase 1: align with the doorway gap before approaching the wall.
    final alignAxis = isVert ? (position.y - center.y) : (position.x - center.x);
    if (alignAxis.abs() > halfGap) {
      return isVert
          ? Vector2(position.x, center.y)
          : Vector2(center.x, position.y);
    }

    // Phase 2: walk through the doorway into the next room.
    return BungalowConfig.waypointInto(garyRoom, nextRoom);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is TiledWallComponent) _resolve(other);
    if (other is BedComponent) _resolve(other);
    if (other is DeskComponent) _resolve(other);
  }

  void _resolve(PositionComponent obstacle) {
    final oc = obstacle.absolutePosition + obstacle.size / 2;
    final delta = position - oc;
    final halfW = obstacle.size.x / 2 + diameter / 2;
    final halfH = obstacle.size.y / 2 + diameter / 2;
    final ox = halfW - delta.x.abs();
    final oy = halfH - delta.y.abs();
    if (ox <= 0 || oy <= 0) return;
    if (ox < oy) {
      position.x += delta.x > 0 ? ox : -ox;
    } else {
      position.y += delta.y > 0 ? oy : -oy;
    }
  }

  void reset(Vector2 startPosition) {
    position = startPosition.clone();
    _isCaught = false;
    _startDelay = 2.0;
  }
}
