import 'package:flame/cache.dart' show Images;
import 'package:flame/components.dart' show Sprite, SpriteAnimation, Vector2;
import 'package:flame/sprite.dart' show SpriteAnimationTicker, SpriteSheet;
import 'package:flame/widgets.dart' show Anchor, SpriteAnimationWidget;
import 'package:flutter/material.dart';

import '../models/number_race_models.dart';

/// Image cache for the racer sprite sheets, kept separate from any Flame
/// [Images] cache used elsewhere so Number Race (a plain Flutter screen,
/// not a Flame game) can decode and reuse them independently.
final Images _spriteImages = Images(prefix: 'assets/');

Future<SpriteAnimation>? _garyAnimationFuture;
Future<SpriteAnimation>? _peroAnimationFuture;

/// Gary's walk cycle — row 0 of the same 256px sprite sheet used for him in
/// Letter Quest. The sheet faces left by default.
Future<SpriteAnimation> _loadGaryAnimation() {
  return _garyAnimationFuture ??=
      _spriteImages.load('characters/Gary/Gary-sprite.png').then((image) {
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(256));
    return sheet.createAnimation(row: 0, stepTime: 0.1);
  });
}

/// Pero's right-facing walk cycle, sliced from the same 3x4 grid of
/// 200x150 frames used for him in Letter Quest (frames 6-11 are the
/// right-facing half of the sheet).
Future<SpriteAnimation> _loadPeroAnimation() {
  return _peroAnimationFuture ??=
      _spriteImages.load('games/letter_quest/peroSprite4.png').then((image) {
    const columns = 3;
    const rows = 4;
    const frameWidth = 200.0;
    const frameHeight = 150.0;
    final allSprites = <Sprite>[
      for (int row = 0; row < rows; row++)
        for (int col = 0; col < columns; col++)
          Sprite(
            image,
            srcPosition: Vector2(col * frameWidth, row * frameHeight),
            srcSize: Vector2(frameWidth, frameHeight),
          ),
    ];
    return SpriteAnimation.spriteList(allSprites.sublist(6, 12), stepTime: 0.15);
  });
}

/// Renders a racer using the same animated walk-cycle sprite sheet as its
/// Letter Quest character, always facing right — the direction racers move
/// along the track, since progress in Number Race never goes backwards.
///
/// Falls back to the character's static portrait for JamJam (no Letter
/// Quest sprite sheet) and while the animation asset is still loading.
class AnimatedRacerSprite extends StatefulWidget {
  final RaceCharacter character;
  final double size;

  /// Whether the walk-cycle animation should be ticking. Paused (holding
  /// the current frame) while the racer is stationary between moves.
  final bool playing;

  const AnimatedRacerSprite({
    super.key,
    required this.character,
    required this.size,
    this.playing = true,
  });

  @override
  State<AnimatedRacerSprite> createState() => _AnimatedRacerSpriteState();
}

class _AnimatedRacerSpriteState extends State<AnimatedRacerSprite> {
  SpriteAnimation? _animation;
  SpriteAnimationTicker? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnimatedRacerSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _animation = null;
      _ticker = null;
      _load();
    }
  }

  void _load() {
    final Future<SpriteAnimation>? future = switch (widget.character) {
      RaceCharacter.gary => _loadGaryAnimation(),
      RaceCharacter.pero => _loadPeroAnimation(),
      RaceCharacter.jamjam => null,
    };
    future?.then((animation) {
      if (!mounted) return;
      setState(() {
        _animation = animation;
        _ticker = animation.createTicker();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = Image.asset(
      widget.character.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final animation = _animation;
    final ticker = _ticker;
    if (animation == null || ticker == null) return fallback;

    final sprite = SpriteAnimationWidget(
      animation: animation,
      animationTicker: ticker,
      anchor: Anchor.center,
      size: Size(size, size),
      playing: widget.playing,
    );

    if (widget.character != RaceCharacter.gary) return sprite;

    // Gary's sheet faces left by default; mirror so he faces right, the
    // direction racers move along the track.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: sprite,
    );
  }
}
