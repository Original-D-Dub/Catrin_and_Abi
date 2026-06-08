import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';


/// Audio configuration for a single game.
///
/// **Adding a custom MP3 for any slot:**
/// 1. Drop the file in `assets/audio/{gameId}/` (e.g. `assets/audio/card_matching/intro.mp3`).
/// 2. Register the path in [AudioService._configs] below (relative to `assets/audio/`).
/// 3. Declare the directory in `pubspec.yaml` under `flutter > assets`.
/// 4. Run `flutter pub get` and rebuild.
class GameAudioConfig {
  /// Path to a custom intro MP3, relative to `assets/audio/`.
  final String? introMp3;

  /// Custom correct-answer SFX path (relative to `assets/audio/`).
  /// Defaults to [AudioService.defaultCorrectSfx].
  final String? correctSfx;

  /// Custom wrong-answer SFX path (relative to `assets/audio/`).
  /// Defaults to [AudioService.defaultWrongSfx].
  final String? wrongSfx;

  /// Custom success-overlay MP3/WAV path (relative to `assets/audio/`).
  final String? successSfx;

  const GameAudioConfig({
    this.introMp3,
    this.correctSfx,
    this.wrongSfx,
    this.successSfx,
  });
}

enum _HapticType { correct, wrong, success }

/// Central audio service for all games.
///
/// Handles intro instructions, correct/wrong SFX, and success overlay sounds.
///
/// All FlameAudio paths are relative to `assets/audio/`.
/// Default correct/wrong SFX reuse the existing counting_game sounds.
class AudioService {
  AudioService._();

  // ── Shared defaults (reuse existing counting_game assets) ─────────────────

  static const String defaultCorrectSfx = 'counting_game/correct.wav';
  static const String defaultWrongSfx = 'counting_game/wrong.wav';

  // ── Per-game configuration ─────────────────────────────────────────────────
  // Keys must match GameIds constants in game_stats_service.dart.
  // Only games with custom SFX paths need an entry here.

  static final Map<String, GameAudioConfig> _configs = {
    'bubble_pop': GameAudioConfig(
      correctSfx: 'bubble_pop/pop_correct.mp3',
      wrongSfx: 'bubble_pop/pop.mp3',
    ),
    'counting_game': GameAudioConfig(
      correctSfx: 'counting_game/correct.wav',
      wrongSfx: 'counting_game/wrong.wav',
    ),
    'letter_quest': GameAudioConfig(
      correctSfx: 'letter_quest/collect_correct.wav',
      wrongSfx: 'letter_quest/collect_wrong.wav',
      successSfx: 'letter_quest/game_complete.wav',
    ),
  };

  // ── Active player tracking ─────────────────────────────────────────────────

  static final List<AudioPlayer> _activePlayers = [];

  static void _trackPlayer(AudioPlayer player) {
    _activePlayers.add(player);
    player.onPlayerComplete.listen((_) => _activePlayers.remove(player));
  }

  // ── Asset existence cache ──────────────────────────────────────────────────

  static final Map<String, bool> _assetCache = {};

  /// Returns true if `assets/audio/[path]` exists in the asset bundle.
  /// Caches the result so subsequent calls are synchronous.
  static Future<bool> _hasAudioAsset(String path) async {
    if (_assetCache.containsKey(path)) return _assetCache[path]!;
    try {
      await rootBundle.load('assets/audio/$path');
      return _assetCache[path] = true;
    } catch (_) {
      return _assetCache[path] = false;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Plays the intro instructions for [gameId].
  ///
  /// Tries [GameAudioConfig.introMp3] first, then the auto-derived speech file
  /// (`speech files/<gameId_with_underscores>_intro.mp3`).
  /// Silent if no audio file is found.
  static Future<void> playIntro(String gameId) async {
    final mp3 = _configs[gameId]?.introMp3 ?? _derivedIntroPath(gameId);
    if (await _hasAudioAsset(mp3)) {
      try {
        final player = await FlameAudio.play(mp3);
        _trackPlayer(player);
      } catch (e) {
        debugPrint('AudioService: intro MP3 playback error ($mp3): $e');
      }
    }
  }

  /// Plays the correct-answer SFX for [gameId] and triggers a haptic pulse.
  static void playCorrect(String gameId) {
    _haptic(_HapticType.correct);
    final sfx = _configs[gameId]?.correctSfx ?? defaultCorrectSfx;
    _playSfx(sfx);
  }

  /// Plays the wrong-answer SFX for [gameId] and triggers a double-impact haptic.
  static void playWrong(String gameId) {
    _haptic(_HapticType.wrong);
    final sfx = _configs[gameId]?.wrongSfx ?? defaultWrongSfx;
    _playSfx(sfx);
  }

  /// Plays the success overlay sound for [gameId] and triggers a triple-impact haptic.
  ///
  /// Uses [GameAudioConfig.successSfx] if configured; otherwise plays
  /// `speech files/general_well_done.mp3`. Silent if no file is found.
  static Future<void> playSuccess(String gameId) async {
    hapticSuccess();
    final sfx = _configs[gameId]?.successSfx;
    if (sfx != null) {
      _playSfx(sfx);
      return;
    }
    await speakWithMp3('Well Done!', mp3Path: 'general_well_done.mp3');
  }

  /// Plays `speech files/general_try_again.mp3`. Silent if file not found.
  static Future<void> playTryAgain() async {
    await speakWithMp3('Try again!', mp3Path: 'general_try_again.mp3');
  }

  /// Triple-impact haptic for success/celebration moments.
  static void hapticSuccess() {
    _haptic(_HapticType.success);
  }

  /// Plays the intro audio for [gameId] and waits for it to finish.
  ///
  /// Uses [GameAudioConfig.introMp3] if configured, awaiting the player's
  /// completion event. Falls back to the derived speech file path.
  /// Silent if no audio file is found.
  static Future<void> playIntroAndWait(String gameId) async {
    final mp3 = _configs[gameId]?.introMp3 ?? _derivedIntroPath(gameId);
    if (await _hasAudioAsset(mp3)) {
      try {
        final player = await FlameAudio.play(mp3);
        _trackPlayer(player);
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
        );
      } catch (e) {
        debugPrint('AudioService: intro MP3 playback error ($mp3): $e');
      }
    }
  }

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> speakAndWait(String text, {String language = 'en-GB'}) async {}

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> speakWelsh(String text) async {}

  /// Plays [mp3Path1] then [mp3Path2] from `assets/audio/speech files/` so
  /// they sound like one continuous sentence.
  ///
  /// Starts the second file [leadMs] milliseconds before the first ends to
  /// absorb the async-startup latency of FlameAudio.play, eliminating the
  /// audible gap that would otherwise appear between the two clips.
  static Future<void> speakSequentialMp3s(
    String mp3Path1,
    String mp3Path2, {
    int leadMs = 120,
  }) async {
    final path1 = 'speech files/$mp3Path1';
    final path2 = 'speech files/$mp3Path2';
    if (!await _hasAudioAsset(path1) || !await _hasAudioAsset(path2)) return;
    try {
      final player1 = await FlameAudio.play(path1);
      _trackPlayer(player1);
      final duration = await player1.getDuration();
      if (duration != null && duration.inMilliseconds > leadMs) {
        await Future.delayed(duration - Duration(milliseconds: leadMs));
      } else {
        await player1.onPlayerComplete.first.timeout(const Duration(seconds: 30));
      }
      final player2 = await FlameAudio.play(path2);
      _trackPlayer(player2);
      await player2.onPlayerComplete.first.timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('AudioService: speakSequentialMp3s error: $e');
    }
  }

  /// Plays [mp3Path] from `assets/audio/speech files/`, waiting for completion.
  ///
  /// Silent if [mp3Path] is null or the file is unavailable.
  static Future<void> speakWithMp3(String text, {String? mp3Path}) async {
    if (mp3Path != null && await _hasAudioAsset('speech files/$mp3Path')) {
      try {
        final player = await FlameAudio.play('speech files/$mp3Path');
        _trackPlayer(player);
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
        );
      } catch (e) {
        debugPrint('AudioService: speech MP3 playback error ($mp3Path): $e');
      }
    }
  }

  /// Plays a single English letter mp3 from
  /// `assets/audio/speech files/alphabet_english/[letter].mp3`.
  /// Silent if the file is unavailable.
  static Future<void> playLetterMp3(String letter) =>
      speakWithMp3(letter, mp3Path: 'alphabet_english/$letter.mp3');

  /// Plays [path] relative to `assets/audio/`. Silent if unavailable.
  static Future<void> playMp3(String path) async {
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
        );
      } catch (e) {
        debugPrint('AudioService: playMp3 error ($path): $e');
      }
    }
  }

  /// Plays `assets/audio/speech files/general_[name.toLowerCase()].mp3`.
  /// Silent if the file is unavailable.
  static Future<void> playSpeechMp3(String name) async {
    final fileName = 'general_${name.toLowerCase()}.mp3';
    if (await _hasAudioAsset('speech files/$fileName')) {
      try {
        final player = await FlameAudio.play('speech files/$fileName');
        _trackPlayer(player);
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
        );
      } catch (e) {
        debugPrint('AudioService: playSpeechMp3 error ($fileName): $e');
      }
    }
  }

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> speak(String text) async {}

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> stopTts() async {}

  /// Stops all playing SFX/intro audio players.
  ///
  /// Call this whenever the player leaves a game (back arrow, hardware back button).
  static Future<void> stopAll() async {
    for (final player in List.of(_activePlayers)) {
      try {
        await player.stop();
      } catch (_) {}
    }
    _activePlayers.clear();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Derives the speech-file path for a game intro from its [gameId].
  ///
  /// Replaces dots with underscores and appends `_intro.mp3`, so
  /// `'vowel_hand.level1'` → `'speech files/vowel_hand_level1_intro.mp3'`.
  static String _derivedIntroPath(String gameId) =>
      'speech files/${gameId.replaceAll('.', '_')}_intro.mp3';

  /// Generation counter — incremented on every SFX request.
  /// Any in-flight play() future that resolves with a stale generation is
  /// stopped immediately, preventing queued sounds from playing.
  static int _sfxGeneration = 0;
  static AudioPlayer? _sfxPlayer;

  static void _playSfx(String path) {
    final myGeneration = ++_sfxGeneration;

    // Stop whatever SFX is currently playing or pending.
    _sfxPlayer?.stop().catchError((_) {});
    _sfxPlayer = null;

    FlameAudio.play(path).then((player) {
      if (myGeneration != _sfxGeneration) {
        // A newer tap arrived before this sound could start — discard it.
        player.stop().catchError((_) {});
      } else {
        _sfxPlayer = player;
        _trackPlayer(player);
      }
    }).catchError((Object e) {
      debugPrint('AudioService: SFX failed ($path): $e');
    });
  }

  /// Platform-aware haptic feedback.
  ///
  /// On Android, uses [Vibration.vibrate] directly (bypasses performHapticFeedback,
  /// which is unreliable on tablets like Samsung Galaxy A7).
  /// On iOS/other, falls back to Flutter's [HapticFeedback].
  static void _haptic(_HapticType type) {
    if (!kIsWeb && Platform.isAndroid) {
      switch (type) {
        case _HapticType.correct:
          Vibration.vibrate(duration: 50);
        case _HapticType.wrong:
          Vibration.vibrate(pattern: [0, 80, 120, 80]);
        case _HapticType.success:
          Vibration.vibrate(pattern: [0, 80, 150, 80, 150, 80]);
      }
    } else {
      switch (type) {
        case _HapticType.correct:
          HapticFeedback.mediumImpact();
        case _HapticType.wrong:
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 120), HapticFeedback.heavyImpact);
        case _HapticType.success:
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 150), HapticFeedback.heavyImpact);
          Future.delayed(const Duration(milliseconds: 300), HapticFeedback.heavyImpact);
      }
    }
  }
}
