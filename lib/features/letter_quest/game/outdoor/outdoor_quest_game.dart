import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../../providers/letter_quest_provider.dart';
import '../base_letter_quest_game.dart';
import '../player_component.dart';
import 'outdoor_map_manager.dart';

/// The main Flame game for Letter Quest Level 4 (outdoor adventure).
///
/// Manages a procedurally generated outdoor world with trees, rocks,
/// lakes, streams, and bridges. The player explores the open map to
/// collect BSL letter signs scattered at random positions.
///
/// Shares the same provider, player, letter, HUD, and overlay
/// system as Level 3. Only the world generation differs.
///
/// Asset loading is identical to Level 3 (BSL alphabet + Pero sprite).
class OutdoorQuestGame extends BaseLetterQuestGame {
  /// Reference to the game state provider
  @override
  final LetterQuestProvider provider;

  /// The player character (Pero)
  late final PlayerComponent player;

  /// Manages outdoor map generation and letter placement
  late final OutdoorMapManager mapManager;

  /// The game world instance (kept for replay/regeneration)
  late final World _gameWorld;

  /// Whether the provider listener has been attached
  bool _listenerAttached = false;

  /// Creates the outdoor quest game.
  OutdoorQuestGame({required this.provider});

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
    _gameWorld = World();
    add(_gameWorld);

    // Generate outdoor map
    mapManager = OutdoorMapManager(
      provider: provider,
      gameWorld: _gameWorld,
    );
    mapManager.generateMap();

    // Place letters for the first word
    mapManager.placeLettersForCurrentWord();

    // Create player at the map's starting position
    player = PlayerComponent(position: mapManager.playerStartPosition);
    _gameWorld.add(player);

    // Set up camera to follow player
    final cameraComponent = CameraComponent(world: _gameWorld)
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
    try {
      FlameAudio.play('letter_quest/word_complete.wav');
    } catch (e) {
      // Continue without sound
    }

    HapticFeedback.heavyImpact();

    // After 2 seconds, advance to next word and place new letters
    Future.delayed(const Duration(seconds: 2), () {
      provider.advanceToNextWord();

      if (provider.phase == LetterQuestPhase.playing) {
        mapManager.clearAndReplaceLetters();
      }
    });
  }

  /// Resets the game with a new randomly generated map.
  ///
  /// Called from the victory overlay's "Play Again" button.
  /// Regenerates terrain, places new letters, and repositions the player.
  void restartWithNewMap() {
    mapManager.regenerateMap();
    mapManager.placeLettersForCurrentWord();
    player.position.setFrom(mapManager.playerStartPosition);
    _gameWorld.add(player);
  }

  /// Handles game victory: plays fanfare, shows victory overlay.
  void _handleVictory() {
    try {
      FlameAudio.play('letter_quest/game_complete.wav');
    } catch (e) {
      // Continue without sound
    }

    HapticFeedback.heavyImpact();

    overlays.add('victory');
  }

  @override
  void onRemove() {
    if (_listenerAttached) {
      provider.removeListener(_onProviderChanged);
      _listenerAttached = false;
    }
    super.onRemove();
  }
}
