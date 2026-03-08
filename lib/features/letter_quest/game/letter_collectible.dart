import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/letter_quest_provider.dart';
import 'base_letter_quest_game.dart';

/// A BSL letter sign collectible placed on the map.
///
/// Displays the BSL alphabet PNG for a letter, with a gentle floating
/// animation and soft white glow behind it. When the player walks over it:
///
/// - **Correct letter**: Scale-down removal + chime + light haptic
/// - **Wrong letter**: Fade out, reappear after 10 seconds + buzz + medium haptic
///
/// BSL alphabet PNGs are at `assets/bsl_alphabet/A.png` (150x100 pixels),
/// scaled down to 64x43 in-game.
///
/// Used by both Level 3 (indoor rooms) and Level 4 (outdoor) via
/// [BaseLetterQuestGame].
class LetterCollectible extends SpriteComponent
    with CollisionCallbacks, HasGameReference<BaseLetterQuestGame> {
  /// The lowercase letter this collectible represents
  final String letter;

  /// Display width of the BSL sign in world units
  static const double displayWidth = 72.0;

  /// Display height of the BSL sign (maintains 150:100 aspect ratio)
  static const double displayHeight = 48.0;

  /// Radius of the circle background behind the sprite
  static const double circleRadius = 40.0;

  /// Border thickness of the coloured circle
  static const double circleBorderWidth = 4.0;

  /// Whether this letter has been correctly collected (permanently removed)
  bool _collected = false;

  /// Whether this letter is temporarily hidden (wrong letter cooldown)
  bool _hidden = false;

  /// Flame timer for wrong-letter respawn (10 seconds)
  Timer? _respawnTimer;

  /// Fill paint for the white circle background
  late final Paint _circleFillPaint;

  /// Stroke paint for the coloured circle border
  late final Paint _circleBorderPaint;

  /// Creates a letter collectible.
  ///
  /// [letter] is the lowercase letter character (e.g., 'c').
  /// [position] is the world position (center anchor).
  LetterCollectible({
    required this.letter,
    required super.position,
  }) : super(
          size: Vector2(displayWidth, displayHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Load the BSL alphabet sprite for this letter
    sprite = Sprite(
      game.images.fromCache('bsl_alphabet/${letter.toUpperCase()}.png'),
    );

    // Collision hitbox
    add(RectangleHitbox());

    // White circle fill
    _circleFillPaint = Paint()..color = const Color(0xFFFFFFFF);

    // Coloured circle border (uses letterPairColors for this letter)
    final borderColor =
        AppColors.letterPairColors[letter] ?? AppColors.abiPink;
    _circleBorderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleBorderWidth;

    // Gentle floating bob animation
    add(MoveByEffect(
      Vector2(0, 6),
      EffectController(
        duration: 1.5,
        reverseDuration: 1.5,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (!_hidden && !_collected) {
      final center = Offset(displayWidth / 2, displayHeight / 2);
      // White filled circle background
      canvas.drawCircle(center, circleRadius, _circleFillPaint);
      // Coloured circle border
      canvas.drawCircle(center, circleRadius, _circleBorderPaint);
    }
    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _respawnTimer?.update(dt);
  }

  /// Called when the player makes contact with this collectible.
  ///
  /// Checks with the provider whether this is the correct next letter.
  /// Handles correct/wrong feedback with sound and haptics.
  void onPlayerContact(LetterQuestProvider provider) {
    if (_collected || _hidden) return;
    if (provider.phase != LetterQuestPhase.playing) return;

    final isCorrect = provider.tryCollectLetter(letter);

    if (isCorrect) {
      _handleCorrectCollection();
    } else {
      _handleWrongCollection();
    }
  }

  /// Handles correct letter collection.
  ///
  /// Plays ascending chime, light haptic, and removes with scale-down animation.
  void _handleCorrectCollection() {
    _collected = true;

    // Sound effect
    try {
      FlameAudio.play('letter_quest/collect_correct.wav');
    } catch (e) {
      // Audio may fail silently — game continues
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Scale down and remove
    add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.3, curve: Curves.easeIn),
      onComplete: removeFromParent,
    ));
  }

  /// Handles wrong letter collection.
  ///
  /// Plays descending buzz, medium haptic, fades out, then reappears after 10s.
  void _handleWrongCollection() {
    _hidden = true;

    // Sound effect
    try {
      FlameAudio.play('letter_quest/collect_wrong.wav');
    } catch (e) {
      // Audio may fail silently — game continues
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Fade out
    add(OpacityEffect.to(
      0.0,
      EffectController(duration: 0.3),
      onComplete: () {
        // Start 10-second respawn timer
        _respawnTimer = Timer(
          10.0,
          onTick: _respawn,
        );
      },
    ));
  }

  /// Respawns the letter after wrong-collection cooldown.
  void _respawn() {
    _hidden = false;
    _respawnTimer = null;

    // Fade back in
    add(OpacityEffect.to(
      1.0,
      EffectController(duration: 0.3),
    ));
  }
}
