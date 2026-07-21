import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/zoo_map_data.dart';
import 'zoo_player_component.dart';

/// Shared base for games played on the zoo map (`zoo_map.png`): the
/// exploration map ([ZooQuestGame]) and the BSL video quiz ([ZooQuizGame]).
///
/// Renders the map PNG as the world, spawns the draggable player
/// ([ZooPlayerComponent]) at the entrance plaza, and follows them with a
/// map-bounded camera. Subclasses supply the chosen character, the
/// walkable geometry, and their own per-frame zone logic in [update].
abstract class ZooMapGameBase extends FlameGame {
  late final ZooPlayerComponent _player;

  /// The player component, exposed for subclasses and tests.
  ZooPlayerComponent get player => _player;

  /// World-unit height the camera aims to show on screen.
  /// The final zoom level is yet to be decided — tune this constant.
  static const double _targetVisibleHeight = 1000.0;

  /// Player spawn point — the entrance plaza.
  @visibleForTesting
  static final Vector2 startPosition = Vector2(1000, 1242);

  /// The chosen character's [ZooCharacter.id], drawn by the player
  /// component.
  String get characterId;

  /// Whether [point] (map coordinates) is on the walkway network.
  bool isWalkable(Offset point);

  @override
  Color backgroundColor() => const Color(0xFFDFEDC6);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    final mapImage = await images.load('games/zoo/zoo_map.png');
    world.add(SpriteComponent(
      sprite: Sprite(mapImage),
      size: Vector2(ZooMapData.mapWidth, ZooMapData.mapHeight),
    ));

    _player = ZooPlayerComponent(position: startPosition.clone());
    world.add(_player);

    camera.follow(_player);
    _applyZoom(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _applyZoom(size);
  }

  /// Shows ~[_targetVisibleHeight] world units vertically, but never zooms
  /// out beyond the map bounds, and clamps the camera so the viewport
  /// stays inside the map.
  ///
  /// The camera bounds are computed here in world units (half the visible
  /// world inset from each map edge) rather than with Flame's
  /// `setBounds(considerViewport: true)`, which subtracts the viewport
  /// size in *screen pixels* from world-unit bounds — wrong whenever
  /// zoom != 1, cutting the top/bottom of the map out of reach on tall
  /// portrait screens.
  void _applyZoom(Vector2 canvasSize) {
    final zoom = math.max(
      canvasSize.y / _targetVisibleHeight,
      canvasSize.x / ZooMapData.mapWidth,
    );
    camera.viewfinder.zoom = zoom;

    final halfVisibleX =
        math.min(canvasSize.x / zoom, ZooMapData.mapWidth) / 2;
    final halfVisibleY =
        math.min(canvasSize.y / zoom, ZooMapData.mapHeight) / 2;
    camera.setBounds(
      Rectangle.fromLTRB(
        halfVisibleX,
        halfVisibleY,
        ZooMapData.mapWidth - halfVisibleX,
        ZooMapData.mapHeight - halfVisibleY,
      ),
    );
  }
}
