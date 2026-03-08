import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/game_constants.dart';
import '../providers/letter_quest_provider.dart';
import 'base_letter_quest_game.dart';
import 'player_component.dart';
import 'room_manager.dart';

/// The main Flame game for Letter Quest Level 3 (indoor rooms).
///
/// Manages the game world containing rooms, walls, letters, and the player.
/// Uses a camera that follows the player. Movement via touch-drag on Pero.
///
/// Bridges to Flutter via:
/// - [LetterQuestProvider] for game state (words, collection tracking)
/// - Flame overlay system for Flutter widgets (HUD, word bar, victory screen)
///
/// Asset loading:
/// - BSL alphabet PNGs loaded via `images.load()` with prefix `assets/`
/// - Pero character PNG loaded for player sprite
/// - Audio files pre-cached via FlameAudio
class LetterQuestGame extends BaseLetterQuestGame {
  /// Reference to the game state provider (no Flame deps in provider)
  @override
  final LetterQuestProvider provider;

  /// The player character (Pero)
  late final PlayerComponent player;

  /// Manages room generation and letter placement
  late final RoomManager roomManager;

  /// Whether the provider listener has been attached
  bool _listenerAttached = false;

  /// Creates the Letter Quest game.
  LetterQuestGame({required this.provider});

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

    // Pre-load floor and wall tile sprites (same as Levels 1 & 2)
    await images.load('games/letter_quest/floor-tile-wood-pale.png');
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

    // Generate rooms
    roomManager = RoomManager(
      provider: provider,
      gameWorld: gameWorld,
    );
    roomManager.generateRooms();

    // Place letters for the first word
    roomManager.placeLettersForCurrentWord();

    // Create player in center of hub room (Room I)
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
  ///
  /// Handles word completion celebration and victory screen.
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

  /// Handles game victory: plays fanfare, persists completion, shows overlay.
  void _handleVictory() {
    // Play game complete fanfare
    try {
      FlameAudio.play('letter_quest/game_complete.wav');
    } catch (e) {
      // Continue without sound
    }

    HapticFeedback.heavyImpact();

    // Persist Level 3 completion to unlock Level 4
    _saveLevel3Completed();

    // Show victory overlay
    overlays.add('victory');
  }

  /// Saves the Level 3 completion flag to SharedPreferences.
  ///
  /// This unlocks Level 4 (outdoor) on the level select screen.
  Future<void> _saveLevel3Completed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        GameConstants.letterQuestLevel3CompletedKey,
        true,
      );
    } catch (e) {
      // Non-critical — game continues even if persistence fails
    }
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
