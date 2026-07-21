import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../models/bungalow_config.dart';
import '../providers/letter_quest_provider.dart';
import '../services/letter_quest_words_service.dart';
import 'base_letter_quest_game.dart';
import 'bungalow_gary_component.dart';
import 'bungalow_room_component.dart';
import 'bungalow_room_manager.dart';
import 'player_component.dart';

/// Letter Quest Level 5 — Bungalow.
///
/// Pero explores a seven-room bungalow collecting BSL letters while
/// Gary chases through the rooms. Same mechanics as Level 4 (indoor
/// rooms) but with a different floor plan.
class BungalowQuestGame extends BaseLetterQuestGame {
  @override
  final LetterQuestProvider provider;

  late final PlayerComponent player;
  late final BungalowGaryComponent _gary;
  late final BungalowRoomManager roomManager;
  bool _listenerAttached = false;

  BungalowQuestGame({required this.provider});

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    await loadSignSvgs();

    await images.load('games/letter_quest/peroSprite4.png');
    await images.load('games/letter_quest/floor-tile-wood-pale.png');
    await images.load('games/letter_quest/wall-tile-brick.png');
    await images.load('characters/Gary/Gary-sprite.png');
    await images.load('games/letter_quest/bungalow/garden/Grass.jpg');
    await images.load('games/letter_quest/bungalow/garden/tree-small.png');
    await images.load('games/letter_quest/bungalow/garden/gardenborder.jpg');
    await images.load('games/letter_quest/bungalow/garden/shed2.png');
    await images.load('games/letter_quest/bungalow/garden/path.jpg');

    await images.load('games/letter_quest/bungalow/bedroom/bed.png');
    await images.load('games/letter_quest/bungalow/bedroom/dogbed.png');
    await images.load('games/letter_quest/bungalow/bedroom/pile-clothes.png');
    await images.load('games/letter_quest/bungalow/bedroom/dressing-table.png');
    for (final name in [
      'md-plant', 'md-table-1', 'md-table-2', 'md-wardrobe-1',
    ]) {
      await images.load('games/letter_quest/mum-dad-bedroom/$name.png');
    }
    for (final name in [
      'abi-chair', 'abi-desk', 'abi-night-stand-1',
      'abi-Shoe Right', 'abi-shoe-left', 'abi-single-bed-messy-duvet',
    ]) {
      await images.load('games/letter_quest/abi-bedroom/$name.png');
    }

    for (final name in [
      'sink-image', 'toilet', 'bath', 'bathmat',
    ]) {
      await images.load('games/letter_quest/bungalow/bathroom/$name.png');
    }

    for (final name in [
      'coats', 'crocks', 'dogfood', 'kitchen-chair',
      'left-wall', 'oak-counter-top', 'table', 'wellies1',
    ]) {
      await images.load('games/letter_quest/bungalow/kitchen/$name.png');
    }

    for (final name in [
      'TV', '4seater-pale-blue', '2seater-pale-blue', 'coffeetable', 'toybox',
    ]) {
      await images.load('games/letter_quest/bungalow/livingroom/$name.png');
    }
    await images.load('games/letter_quest/bungalow/livingroom/living-room-rug.jpg');

    try {
      await FlameAudio.audioCache.loadAll([
        'letter_quest/collect_correct.wav',
        'letter_quest/collect_wrong.wav',
        'letter_quest/word_complete.wav',
        'letter_quest/game_complete.wav',
      ]);
    } catch (_) {}

    final gameWorld = World();
    add(gameWorld);

    gameWorld.add(BungalowRoomComponent());

    roomManager = BungalowRoomManager(
      provider: provider,
      gameWorld: gameWorld,
    );

    final supabaseWords = await LetterQuestWordsService().fetchRandomWords();
    if (supabaseWords.isNotEmpty) {
      provider.initializeFromWordList(supabaseWords);
    }

    roomManager.placeLettersForCurrentWord();

    player = PlayerComponent(position: BungalowConfig.playerStart.clone());
    gameWorld.add(player);

    _gary = BungalowGaryComponent(
      position: BungalowConfig.garyStart.clone(),
      player: player,
      onPlayerCaught: _handlePlayerCaught,
    );
    gameWorld.add(_gary);

    final treeW = BungalowConfig.gardenW * 0.5;
    gameWorld.add(SpriteComponent(
      sprite: Sprite(images.fromCache(
          'games/letter_quest/bungalow/garden/tree-small.png')),
      position: Vector2(
          BungalowConfig.wallThickness + 40,
          BungalowConfig.wallThickness + 40),
      size: Vector2(treeW, treeW),
      priority: 100,
    ));

    final camera = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center
      ..viewfinder.zoom = mapZoom
      ..follow(player);
    add(camera);

    _listenerAttached = true;
    provider.addListener(_onProviderChanged);
  }

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

  void _handleWordComplete() {
    try {
      FlameAudio.play('letter_quest/word_complete.wav');
    } catch (_) {}
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      provider.advanceToNextWord();
      if (provider.phase == LetterQuestPhase.playing) {
        roomManager.clearAndReplaceLetters();
      }
    });
  }

  void _handleVictory() {
    try {
      FlameAudio.play('letter_quest/game_complete.wav');
    } catch (_) {}
    HapticFeedback.heavyImpact();
    overlays.add('victory');
  }

  /// Re-fetches words from Supabase and restarts the game. Called by the
  /// victory overlay's "play again" button instead of [provider.resetGame()].
  Future<void> handlePlayAgain() async {
    final words = await LetterQuestWordsService().fetchRandomWords();
    if (words.isNotEmpty) {
      provider.initializeFromWordList(words);
      roomManager.clearAndReplaceLetters();
    }
  }

  void _handlePlayerCaught() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      player.position = BungalowConfig.playerStart.clone();
      _gary.reset(BungalowConfig.garyStart.clone());
    });
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
