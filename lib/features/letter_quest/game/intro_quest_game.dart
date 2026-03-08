import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../providers/letter_quest_provider.dart';
import 'base_letter_quest_game.dart';
import 'intro_room_manager.dart';
import 'player_component.dart';

/// The Flame game for Letter Quest Level 1 (intro room).
///
/// Manages a simple game world with a single 900x1200 room divided
/// by a vertical wall with two doorways.
///
/// Only the 3 correct letters are shown — no distractors.
/// Uses the same mechanics as Level 2:
/// - Touch and drag Pero to move
/// - Letter collection in order
/// - 3 words to complete
/// - Victory overlay on completion
class IntroQuestGame extends BaseLetterQuestGame {
  /// Reference to the game state provider
  @override
  final LetterQuestProvider provider;

  /// The player character (Pero)
  late final PlayerComponent player;

  /// Manages room generation and letter placement
  late final IntroRoomManager roomManager;

  /// Whether the provider listener has been attached
  bool _listenerAttached = false;

  /// Creates the Intro Quest game.
  IntroQuestGame({required this.provider});

  @override
  Future<void> onLoad() async {
    // Set image prefix to match project asset structure
    images.prefix = 'assets/';

    // Pre-load all BSL alphabet sprites (A-Z)
    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      await images.load('bsl_alphabet/$letter.png');
    }

    // Pre-load Pero sprite sheet
    await images.load('games/letter_quest/peroSprite4.png');

    // Pre-load floor tile for intro room
    await images.load('games/letter_quest/floor-tile-wood-pale.png');

    // Pre-load wall tile for intro room
    await images.load('games/letter_quest/wall-tile-brick.png');

    // Pre-cache audio files
    try {
      await FlameAudio.audioCache.loadAll([
        'letter_quest/collect_correct.wav',
        'letter_quest/collect_wrong.wav',
        'letter_quest/word_complete.wav',
        'letter_quest/game_complete.wav',
      ]);
    } catch (e) {
      // Audio loading may fail on some platforms — game continues without sound
    }

    // Create game world
    final gameWorld = World();
    add(gameWorld);

    // Generate intro room
    roomManager = IntroRoomManager(
      provider: provider,
      gameWorld: gameWorld,
    );
    roomManager.generateRoom();

    // Place letters for the first word
    roomManager.placeLettersForCurrentWord();

    // Create player in center of room
    player = PlayerComponent(position: roomManager.playerStartPosition);
    gameWorld.add(player);

    // Set up camera to follow player
    final cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center
      ..follow(player);
    add(cameraComponent);

    // Listen for provider state changes
    _listenerAttached = true;
    provider.addListener(_onProviderChanged);
  }

  /// Reacts to provider state transitions.
  void _onProviderChanged() {
    switch (provider.phase) {
      case LetterQuestPhase.wordComplete:
        _handleWordComplete();
        break;
      case LetterQuestPhase.victory:
        _handleVictory();
        break;
      case LetterQuestPhase.playing:
        break;
    }
  }

  /// Handles word completion: plays sound, waits, advances to next word.
  void _handleWordComplete() {
    // Play word complete sound
    try {
      FlameAudio.play('letter_quest/word_complete.wav');
    } catch (e) {
      // Continue without sound
    }

    // Heavy haptic for celebration
    HapticFeedback.heavyImpact();

    // After 2 seconds, advance to next word and place new letters
    Future.delayed(const Duration(seconds: 2), () {
      provider.advanceToNextWord();

      if (provider.phase == LetterQuestPhase.playing) {
        roomManager.clearAndReplaceLetters();
      }
    });
  }

  /// Handles game victory: plays fanfare, shows overlay.
  void _handleVictory() {
    // Play game complete fanfare
    try {
      FlameAudio.play('letter_quest/game_complete.wav');
    } catch (e) {
      // Continue without sound
    }

    HapticFeedback.heavyImpact();

    // Show victory overlay
    overlays.add('victory');
  }

  @override
  void onRemove() {
    // Clean up provider listener
    if (_listenerAttached) {
      provider.removeListener(_onProviderChanged);
      _listenerAttached = false;
    }
    super.onRemove();
  }
}
