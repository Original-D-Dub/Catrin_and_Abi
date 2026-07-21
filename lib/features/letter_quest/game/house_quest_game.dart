import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../providers/letter_quest_provider.dart';
import 'base_letter_quest_game.dart';
import 'house_room_manager.dart';
import 'player_component.dart';

/// Flame game for the house top-floor level of Letter Quest.
class HouseQuestGame extends BaseLetterQuestGame {
  @override
  final LetterQuestProvider provider;

  late final PlayerComponent player;
  late final HouseRoomManager roomManager;
  bool _listenerAttached = false;

  HouseQuestGame({required this.provider});

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    await loadSignSvgs();

    await images.load('games/letter_quest/peroSprite4.png');
    await images.load('games/letter_quest/wall-tile-brick.png');
    await images.load('games/letter_quest/floor-tile-wood-pale.png');
    await images.load(
        'games/letter_quest/catrin-bedroom/catrin_bedroom.png');
    await images.load(
        'games/letter_quest/abi-bedroom/abi_bedrooms.png');
    await images.load(
        'games/letter_quest/bathroom/Bathroom.png');
    await images.load(
        'games/letter_quest/mum-dad-bedroom/CAT&ABI Mum and Dads room.png');

    // Catrin's bedroom furniture
    for (final name in [
      'catrin-Bed', 'catrin-books-1', 'catrin-books', 'catrin-chair',
      'catrin-computer', 'catrin-keyboard', 'catrin-lamp', 'catrin-mouse',
      'catrin-night-stand-1', 'catrin-table', 'catrin-vase',
    ]) {
      await images.load('games/letter_quest/catrin-bedroom/$name.png');
    }

    // Abi's bedroom furniture
    for (final name in [
      'abi-Pencil', 'abi-Shoe Right', 'abi-chair', 'abi-clock', 'abi-desk',
      'abi-shoe-left', 'abi-single-bed-messy-duvet',
      'abi-table-lamp', 'abi-vase', 'abi-night-stand-2',
    ]) {
      await images.load('games/letter_quest/abi-bedroom/$name.png');
    }
    await images.load('games/letter_quest/bungalow/livingroom/toybox.png');

    // Mum & Dad's bedroom furniture
    for (final name in [
      'md-bed', 'md-plant', 'md-rug', 'md-table-1', 'md-table-2',
      'md-wardrobe-1', 'md-wardrobe-2',
    ]) {
      await images.load('games/letter_quest/mum-dad-bedroom/$name.png');
    }

    // Bathroom furniture
    for (final name in [
      'bath-image', 'bath-mat 1', 'shower-tray', 'sink-image',
      'toilet-image',
    ]) {
      await images.load('games/letter_quest/bathroom/$name.png');
    }

    try {
      await FlameAudio.audioCache.loadAll([
        'letter_quest/collect_correct.wav',
        'letter_quest/collect_wrong.wav',
        'letter_quest/word_complete.wav',
        'letter_quest/game_complete.wav',
      ]);
    } catch (e) {
      // Audio loading may fail on some platforms
    }

    final gameWorld = World();
    add(gameWorld);

    roomManager = HouseRoomManager(
      provider: provider,
      gameWorld: gameWorld,
    );
    roomManager.generateRoom();
    roomManager.placeLettersForCurrentWord();

    player = PlayerComponent(
      position: roomManager.playerStartPosition,
      sizeMultiplier: characterScale,
    );
    gameWorld.add(player);

    final cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center
      ..viewfinder.zoom = mapZoom
      ..follow(player);
    add(cameraComponent);

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
    } catch (e) {
      // Continue without sound
    }
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
