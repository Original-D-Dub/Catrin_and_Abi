import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../models/bungalow_config.dart';
import '../providers/letter_quest_provider.dart';
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

    for (final name in [
      'sink-image', 'toilet-image', 'bath-mat 1', 'shower-tray',
    ]) {
      await images.load('games/letter_quest/bungalow/bathroom/$name.png');
    }

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
    roomManager.placeLettersForCurrentWord();

    player = PlayerComponent(position: BungalowConfig.playerStart.clone());
    gameWorld.add(player);

    _gary = BungalowGaryComponent(
      position: BungalowConfig.garyStart.clone(),
      player: player,
      onPlayerCaught: _handlePlayerCaught,
    );
    gameWorld.add(_gary);

    final camera = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center
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
