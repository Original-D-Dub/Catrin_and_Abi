import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../models/room_config.dart';
import '../providers/letter_quest_provider.dart';
import 'base_letter_quest_game.dart';
import 'gary_component.dart';
import 'letter_collectible.dart';
import 'player_component.dart';
import 'room_component.dart';
import 'wall_component.dart';

/// Letter Quest Level 2 — "Find Gary".
///
/// Uses the same five-room cross layout as Level 3, but with a different
/// gameplay mechanic:
///
/// - Gary is hidden (stationary) in one randomly chosen edge room (A, E, O, U).
/// - Pero freely explores the hub room (Room I) and the corridors.
/// - **On room entry**: the connecting doorway locks (a [WallComponent] blocks
///   the gap), the room's word challenge appears at the bottom of the screen,
///   and the word's letters are placed inside the room.
/// - **On word complete**: the door unlocks and Pero can leave.
/// - **Gary's room**: completing the word challenge reveals Gary — the level
///   is won and the victory overlay is shown.
///
/// Room I (hub) is never locked. Completed rooms can be freely re-entered.
class Level2QuestGame extends BaseLetterQuestGame {
  @override
  final LetterQuestProvider provider;

  late final PlayerComponent player;
  late final World _gameWorld;
  late final List<RoomConfig> _roomConfigs;

  /// Vowel of the room Gary is hiding in (one of 'a', 'e', 'o', 'u').
  late final String _garyVowel;

  /// Gary's component — null until Pero enters his room.
  GaryComponent? _gary;

  /// The currently locked doorway wall, or null if no room is locked.
  WallComponent? _lockedDoor;

  /// The vowel of the currently locked room, or null.
  String? _lockedVowel;

  /// Letters placed inside the currently challenged room.
  final List<LetterCollectible> _challengeLetters = [];

  /// Rooms whose word challenge has already been completed.
  final Set<String> _completedVowels = {};

  /// Room vowel waiting for the player to clear the doorway before locking.
  String? _pendingLockVowel;

  /// Vowel string of the room the player is currently in ('i' = hub).
  String _playerVowel = 'i';

  bool _listenerAttached = false;
  final _rng = Random();

  Level2QuestGame({required this.provider});

  // ── Room geometry constants ─────────────────────────────────────────────────

  static const double _rw = RoomConfig.roomWidth;  // 900
  static const double _rh = RoomConfig.roomHeight; // 680

  // ── Flame lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      await images.load('bsl_alphabet/$letter.png');
    }
    await images.load('games/letter_quest/peroSprite4.png');
    await images.load('games/letter_quest/floor-tile-wood-pale.png');
    await images.load('games/letter_quest/wall-tile-brick.png');
    await images.load('games/letter_quest/Gary.png');

    try {
      await FlameAudio.audioCache.loadAll([
        'letter_quest/collect_correct.wav',
        'letter_quest/collect_wrong.wav',
        'letter_quest/word_complete.wav',
        'letter_quest/game_complete.wav',
      ]);
    } catch (_) {}

    _gameWorld = World();
    add(_gameWorld);

    // Build the five-room cross layout
    _roomConfigs = RoomConfig.generateAllRooms();
    for (final config in _roomConfigs) {
      _gameWorld.add(RoomComponent(config: config));
    }

    // Gary hides in one of the four edge rooms (not the hub)
    const edgeVowels = ['a', 'e', 'o', 'u'];
    _garyVowel = edgeVowels[_rng.nextInt(edgeVowels.length)];

    // Player starts in the centre hub (Room I)
    final hub = _roomConfigs.firstWhere((r) => r.vowel == 'i');
    player = PlayerComponent(position: hub.center);
    _gameWorld.add(player);

    final camera = CameraComponent(world: _gameWorld)
      ..viewfinder.anchor = Anchor.center
      ..follow(player);
    add(camera);

    _listenerAttached = true;
    provider.addListener(_onProviderChanged);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _detectRoomChange();
    _checkPendingLock();
  }

  @override
  void onRemove() {
    if (_listenerAttached) {
      provider.removeListener(_onProviderChanged);
      _listenerAttached = false;
    }
    super.onRemove();
  }

  // ── Room entry detection ────────────────────────────────────────────────────

  void _detectRoomChange() {
    final vowel = _roomVowelAt(player.position);
    if (vowel == _playerVowel) return;

    final prev = _playerVowel;
    _playerVowel = vowel;
    _onRoomEntered(vowel, from: prev);
  }

  void _onRoomEntered(String vowel, {required String from}) {
    _pendingLockVowel = null;

    if (vowel == 'i') {
      // Returned to hub — hide word bar
      overlays.remove('wordProgress');
      return;
    }

    // Already completed — free access
    if (_completedVowels.contains(vowel)) return;

    // Defer the lock until the player's body is fully past the doorway threshold
    _pendingLockVowel = vowel;

    // Reveal Gary if this is his room — collision triggers victory immediately
    if (vowel == _garyVowel && _gary == null) {
      final config = _roomConfigs.firstWhere((r) => r.vowel == vowel);
      _gary = GaryComponent(
        position: config.center + Vector2(80, 0),
        player: player,
        onPlayerCaught: () => provider.forceVictory(),
        isHiding: true,
      );
      _gameWorld.add(_gary!);
    }

    // Place word letters inside the room
    _placeLetters(vowel);

    // Point the provider at this room's word
    provider.setActiveWordByVowel(vowel);

    // Show the word progress bar
    overlays.add('wordProgress');

    _lockedVowel = vowel;
  }

  // ── Door locking ────────────────────────────────────────────────────────────

  /// Called every frame to lock the door once the player's body clears the
  /// doorway. If the player retreats before that happens, the lock is cancelled.
  void _checkPendingLock() {
    final vowel = _pendingLockVowel;
    if (vowel == null) return;

    if (_playerVowel != vowel) {
      _pendingLockVowel = null;
      return;
    }

    if (_isPlayerClearOfDoorway(vowel)) {
      _pendingLockVowel = null;
      _lockDoor(vowel);
    }
  }

  /// True when the player's body has fully crossed into [vowel]'s room,
  /// meaning the door can close without clipping through the player.
  bool _isPlayerClearOfDoorway(String vowel) {
    final p = player.position;
    final dp = _doorwayPos(vowel);
    final ds = _doorwaySize(vowel);
    const hw = PlayerComponent.playerWidth / 2;
    const hh = PlayerComponent.playerHeight / 2;
    return switch (vowel) {
      'a' => p.x + hw < dp.x,           // right edge clears door left edge
      'o' => p.x - hw > dp.x + ds.x,   // left edge clears door right edge
      'e' => p.y + hh < dp.y,           // bottom edge clears door top edge
      'u' => p.y - hh > dp.y + ds.y,   // top edge clears door bottom edge
      _ => true,
    };
  }

  void _lockDoor(String vowel) {
    _lockedDoor?.removeFromParent();
    _lockedDoor = null;

    // Dark mahogany fill — visually distinct from the brick walls
    _lockedDoor = WallComponent(
      position: _doorwayPos(vowel),
      size: _doorwaySize(vowel),
      color: const Color(0xFF4A1800),
    );
    _gameWorld.add(_lockedDoor!);
  }

  void _unlockDoor() {
    _lockedDoor?.removeFromParent();
    _lockedDoor = null;
    _lockedVowel = null;
    _clearLetters();
    overlays.remove('wordProgress');
    provider.resetPhaseToPlaying();
  }

  // ── Letter management ───────────────────────────────────────────────────────

  void _placeLetters(String vowel) {
    _clearLetters();
    final config = _roomConfigs.firstWhere((r) => r.vowel == vowel);
    final word = provider.words.firstWhere((w) => w.vowel == vowel);
    final positions = List<Vector2>.from(config.letterPositions)..shuffle(_rng);

    for (int i = 0; i < word.word.length && i < positions.length; i++) {
      final collectible = LetterCollectible(
        letter: word.word[i],
        position: config.worldPosition + positions[i],
      );
      _gameWorld.add(collectible);
      _challengeLetters.add(collectible);
    }
  }

  void _clearLetters() {
    for (final l in _challengeLetters) {
      if (l.isMounted) l.removeFromParent();
    }
    _challengeLetters.clear();
  }

  // ── Provider listener ───────────────────────────────────────────────────────

  void _onProviderChanged() {
    switch (provider.phase) {
      case LetterQuestPhase.wordComplete:
        _handleRoomWordComplete();
        break;
      case LetterQuestPhase.victory:
        _handleVictory();
        break;
      case LetterQuestPhase.playing:
        break;
    }
  }

  /// Called when the player collects all letters in a locked room.
  void _handleRoomWordComplete() {
    try {
      FlameAudio.play('letter_quest/word_complete.wav');
    } catch (_) {}
    HapticFeedback.heavyImpact();

    final completed = _lockedVowel;
    if (completed == null) return;

    _completedVowels.add(completed);

    // Unlock the door — in Gary's room the player can now leave freely,
    // but victory still only fires when they physically touch Gary.
    Future.delayed(const Duration(seconds: 2), _unlockDoor);
  }

  void _handleVictory() {
    try {
      FlameAudio.play('letter_quest/game_complete.wav');
    } catch (_) {}
    HapticFeedback.heavyImpact();
    overlays.add('victory');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the vowel character for the room containing [p], or 'i' for hub.
  String _roomVowelAt(Vector2 p) {
    if (p.x < _rw && p.y >= _rh && p.y < _rh * 2) return 'a';
    if (p.x >= _rw && p.x < _rw * 2 && p.y < _rh) return 'e';
    if (p.x >= _rw * 2 && p.y >= _rh && p.y < _rh * 2) return 'o';
    if (p.x >= _rw && p.x < _rw * 2 && p.y >= _rh * 2) return 'u';
    return 'i'; // hub
  }

  /// World-space top-left corner of the doorway gap for [vowel]'s room.
  ///
  /// The gap spans both wall segments (one on each side of the threshold).
  /// Geometry derived from [RoomConfig] wall placement:
  ///   wallThickness = 40, doorwayWidth = 120, centred on each wall face.
  Vector2 _doorwayPos(String vowel) {
    if (vowel == 'a') return Vector2(860, 960);   // A right / I left
    if (vowel == 'e') return Vector2(1290, 640);  // E bottom / I top
    if (vowel == 'o') return Vector2(1760, 960);  // I right / O left
    if (vowel == 'u') return Vector2(1290, 1320); // I bottom / U top
    return Vector2.zero();
  }

  /// Size of the locked door component for [vowel]'s room.
  Vector2 _doorwaySize(String vowel) {
    if (vowel == 'a' || vowel == 'o') return Vector2(80, 120); // vertical gap
    if (vowel == 'e' || vowel == 'u') return Vector2(120, 80); // horizontal gap
    return Vector2(80, 120);
  }
}
