import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../core/localization/app_localizations.dart';
import '../models/enclosure_level_config.dart';
import '../providers/enclosure_walk_provider.dart';
import 'enclosure_walk_layout.dart';
import 'enclosure_walk_player.dart';
import 'enclosure_window_component.dart';
import 'exit_door_component.dart';

/// Side-scrolling Flame game for the zoo's walk-through buildings
/// (aquarium now, reptile house next) — all content comes from the
/// provider's [EnclosureLevelConfig].
///
/// The world is a horizontal strip of rocky wall with enclosure windows
/// set into it and a slightly darker rock floor. The player walks left and
/// right by dragging the character ([EnclosureWalkPlayer]); the camera
/// follows horizontally. Each frame, if the player is standing still in
/// front of a window they turn to face it and the provider is told which
/// enclosure is active — the screen shows the Take a Picture button in
/// response.
///
/// Everything is sized from the canvas ([EnclosureWalkLayout]) at camera
/// zoom 1, so world units are logical pixels; the whole world is rebuilt
/// on resize/rotation, preserving the player's progress.
class EnclosureWalkGame extends FlameGame {
  final EnclosureWalkProvider provider;

  /// Called when the exit door after the last enclosure is tapped — the
  /// screen pops back to the zoo map.
  final VoidCallback onExitTapped;

  EnclosureWalkGame({required this.provider, required this.onExitTapped});

  EnclosureWalkLayout? _layout;
  EnclosureWalkPlayer? _player;

  @visibleForTesting
  EnclosureWalkLayout get layout => _layout!;

  @visibleForTesting
  EnclosureWalkPlayer get player => _player!;

  @override
  Color backgroundColor() => provider.config.wallColor;

  @override
  Future<void> onLoad() async {
    _build(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_layout != null && size.toSize() != _layout!.canvas) {
      _build(size);
    }
  }

  /// (Re)creates the world for the given canvas size. On resize the
  /// player keeps their fractional progress along the world.
  void _build(Vector2 canvasSize) {
    final config = provider.config;
    final localizer = AppLocalizations(locale: provider.locale);

    final previous = _layout;
    final progress = previous == null
        ? null
        : _player!.position.x / previous.worldWidth;

    final layout = EnclosureWalkLayout.forCanvas(
      canvasSize.toSize(),
      config.enclosures.length,
    );
    _layout = layout;

    world.removeAll(world.children.toList());

    // Rocky wall behind everything, then the darker floor strip.
    world.add(_RockSurfaceComponent(
      position: Vector2.zero(),
      size: Vector2(layout.worldWidth, layout.floorTop),
      baseColor: config.wallColor,
      texture: config.texture,
      seed: 1,
    ));
    world.add(_RockSurfaceComponent(
      position: Vector2(0, layout.floorTop),
      size: Vector2(
          layout.worldWidth, canvasSize.y - layout.floorTop),
      baseColor: config.floorColor,
      texture: config.texture,
      seed: 2,
      topEdge: true,
    ));

    for (var i = 0; i < config.enclosures.length; i++) {
      final spec = config.enclosures[i];
      world.add(EnclosureWindowComponent(
        spec: spec,
        label: localizer(config.enclosureNameKey(spec)),
        config: config,
        provider: provider,
        windowCenterX: layout.windowCenters[i],
        windowTop: layout.windowTop,
        windowWidth: layout.windowWidth,
        windowHeight: layout.windowHeight,
      ));
    }

    world.add(ExitDoorComponent(
      label: localizer('zoo.exit'),
      frameColor: config.frameColor,
      onTapped: onExitTapped,
      doorCenterX: layout.doorCenterX,
      floorTop: layout.floorTop,
      doorWidth: layout.doorWidth,
      doorHeight: layout.doorHeight,
    ));

    final player = EnclosureWalkPlayer(
      position: Vector2(
        progress == null
            ? layout.playerStartX
            : progress * layout.worldWidth,
        layout.playerBaselineY,
      ),
      height: layout.playerHeight,
    );
    player.minX = player.size.x / 2 + 12;
    player.maxX = layout.worldWidth - player.minX;
    world.add(player);
    _player = player;

    _setUpCamera(canvasSize, layout, player);
  }

  /// Fixed-height viewport that tracks the player horizontally, clamped
  /// to the world's ends.
  void _setUpCamera(
    Vector2 canvasSize,
    EnclosureWalkLayout layout,
    EnclosureWalkPlayer player,
  ) {
    final halfW = canvasSize.x / 2;
    final halfH = canvasSize.y / 2;

    camera.stop();
    camera.viewfinder.zoom = 1;
    camera.setBounds(Rectangle.fromLTRB(
      halfW,
      halfH,
      max(layout.worldWidth - halfW, halfW),
      halfH,
    ));
    camera.viewfinder.position = Vector2(
      player.position.x.clamp(halfW, max(layout.worldWidth - halfW, halfW)),
      halfH,
    );
    camera.follow(player, horizontalOnly: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final layout = _layout;
    final player = _player;
    if (layout == null || player == null) return;

    // A stopped player in front of a window turns to face it and arms
    // the Take a Picture button; in front of the exit door they turn to
    // face that too (the door itself is the tap target).
    final stopped = !player.isMoving;
    final index = stopped ? layout.windowIndexAt(player.position.x) : null;
    player.facingWindow =
        index != null || (stopped && layout.isAtDoor(player.position.x));
    provider.setActiveEnclosure(
        index == null ? null : provider.config.enclosures[index]);
  }
}

/// A flat wall or floor surface. [WallTexture.rock] is the base colour
/// plus seeded two-tone speckles so it reads as rocky texture rather than
/// a solid fill; [WallTexture.sand] is per-pixel noise grain (a repeating
/// noise tile with the grain baked over the base colour) so it reads as
/// grainy sandstone.
class _RockSurfaceComponent extends PositionComponent {
  final Color baseColor;
  final WallTexture texture;
  final int seed;

  /// Draws a shadow line along the top edge (floor meeting the wall).
  final bool topEdge;

  List<(Rect, Color)> _speckles = const [];
  Paint? _sandPaint;

  _RockSurfaceComponent({
    required super.position,
    required super.size,
    required this.baseColor,
    required this.texture,
    required this.seed,
    this.topEdge = false,
  }) : super(priority: 0);

  @override
  Future<void> onLoad() async {
    if (texture == WallTexture.sand) {
      _sandPaint = Paint()
        ..shader = ImageShader(
          await _sandTile(baseColor),
          TileMode.repeated,
          TileMode.repeated,
          _identityMatrix,
        );
      return;
    }
    final rnd = Random(seed);
    final count = min((size.x * size.y / 6000).round(), 600);
    _speckles = List.generate(count, (_) {
      final w = 8 + rnd.nextDouble() * 34;
      return (
        Rect.fromCenter(
          center: Offset(
            rnd.nextDouble() * size.x,
            rnd.nextDouble() * size.y,
          ),
          width: w,
          height: w * (0.35 + rnd.nextDouble() * 0.3),
        ),
        rnd.nextBool() ? const Color(0x14FFFFFF) : const Color(0x1F000000),
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final surface = Offset.zero & size.toSize();
    final paint = Paint();
    final sand = _sandPaint;
    if (sand != null) {
      canvas.drawRect(surface, sand);
    } else {
      paint.color = baseColor;
      canvas.drawRect(surface, paint);
      for (final (rect, shade) in _speckles) {
        paint.color = shade;
        canvas.drawOval(rect, paint);
      }
    }
    if (topEdge) {
      paint.color = const Color(0x40000000);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), paint);
    }
  }

  static final Float64List _identityMatrix = Float64List.fromList([
    1, 0, 0, 0, //
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);

  /// Opaque noise tiles keyed by base colour, shared by every surface of
  /// that colour (wall and floor get one each).
  static final Map<int, Future<Image>> _sandTiles = {};

  /// A 128×128 tile of the base colour with each pixel nudged lighter or
  /// darker by white noise — mostly fine grain, with occasional stronger
  /// flecks — tiled seamlessly across the surface by the [ImageShader].
  static Future<Image> _sandTile(Color base) =>
      _sandTiles.putIfAbsent(base.toARGB32(), () {
        const tileSize = 128;
        final rnd = Random(base.toARGB32());
        final pixels = Uint8List(tileSize * tileSize * 4);
        for (var i = 0; i < tileSize * tileSize; i++) {
          final amplitude = rnd.nextDouble() < 0.05 ? 42 : 14;
          final noise = (rnd.nextDouble() * 2 - 1) * amplitude;
          final o = i * 4;
          pixels[o] = (base.r * 255 + noise).round().clamp(0, 255);
          pixels[o + 1] = (base.g * 255 + noise).round().clamp(0, 255);
          pixels[o + 2] = (base.b * 255 + noise).round().clamp(0, 255);
          pixels[o + 3] = 255;
        }
        final completer = Completer<Image>();
        decodeImageFromPixels(
          pixels,
          tileSize,
          tileSize,
          PixelFormat.rgba8888,
          completer.complete,
        );
        return completer.future;
      });
}
