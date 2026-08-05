import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/constants/game_filters.dart' show SignSystem;


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

  // ── User-configurable toggles ─────────────────────────────────────────────
  // Mirrored from SettingsProvider (which owns persistence) so the ~25 call
  // sites across the app don't each need to read SettingsProvider themselves.

  /// Whether short sound effects (correct/wrong/success chimes, camera
  /// shutter) play. Set by SettingsProvider.
  static bool sfxEnabled = true;

  /// Whether spoken game-intro instructions play. Set by SettingsProvider.
  static bool instructionsEnabled = true;

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
    'word_whirl': GameAudioConfig(
      introMp3: 'speech files/word_whirl_instructions.mp3',
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

  // ── Locale ──────────────────────────────────────────────────────────────────

  /// Recorded speech instructions exist for English (`speech files/`,
  /// MP3s) and Welsh (`speech_files_molly_cy/`, WAVs). Speech-playing
  /// methods below stay silent for any other [locale].
  static bool _isSupportedSpeechLocale(String locale) => locale == 'en' || locale == 'cy';

  /// Directory (relative to `assets/audio/`) holding recorded speech for [locale].
  static String _speechDir(String locale) =>
      locale == 'cy' ? 'speech_files_molly_cy' : 'speech files';

  /// File extension used by the recorded speech clips for [locale].
  static String _speechExt(String locale) => locale == 'cy' ? 'wav' : 'mp3';

  /// Subdirectory (under the locale's speech directory) holding single-letter
  /// alphabet clips. English covers the full alphabet; Welsh only covers the
  /// vowels used by the vowel/letter games (a, e, i, o, u, w, y).
  static String _alphabetDir(String locale) =>
      locale == 'cy' ? 'alphabet_welsh' : 'alphabet_english';

  /// Rewrites a speech-file path or bare filename (with or without
  /// extension) to the asset for [locale], swapping both the speech
  /// directory and the file extension. Only the basename is kept, so
  /// callers can pass an English-style path (e.g. `speech files/foo.mp3`)
  /// or a bare name (e.g. `foo.mp3` / `foo`) and get the right file for
  /// any supported locale.
  static String _localizeSpeechPath(String path, String locale) {
    final slash = path.lastIndexOf('/');
    final name = slash == -1 ? path : path.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    final base = dot == -1 ? name : name.substring(0, dot);
    return '${_speechDir(locale)}/$base.${_speechExt(locale)}';
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Plays the intro instructions for [gameId].
  ///
  /// Tries [GameAudioConfig.introMp3] first, then the auto-derived speech file
  /// (`<gameId_with_underscores>_intro`), localized to [locale].
  /// Silent if no audio file is found, or if [locale] isn't supported.
  static Future<void> playIntro(String gameId, {String locale = 'en'}) async {
    if (!instructionsEnabled) return;
    if (!_isSupportedSpeechLocale(locale)) return;
    final configured = _configs[gameId]?.introMp3;
    final mp3 = configured != null
        ? _localizeSpeechPath(configured, locale)
        : _derivedIntroPath(gameId, locale);
    if (await _hasAudioAsset(mp3)) {
      try {
        final player = await FlameAudio.play(mp3);
        _trackPlayer(player);
      } catch (e) {
        debugPrint('AudioService: intro MP3 playback error ($mp3): $e');
      }
    }
  }

  /// Plays the recorded game-title clip for [gameId] (e.g. "BSL Maths").
  ///
  /// Uses the auto-derived speech file (`<gameId_with_underscores>_title`),
  /// localized to [locale]. Silent if no audio file is found, or if [locale]
  /// isn't supported.
  static Future<void> playTitle(String gameId, {String locale = 'en'}) async {
    if (!instructionsEnabled) return;
    if (!_isSupportedSpeechLocale(locale)) return;
    final path = _derivedTitlePath(gameId, locale);
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
      } catch (e) {
        debugPrint('AudioService: title MP3 playback error ($path): $e');
      }
    }
  }

  /// Plays the recorded level-name clip for [gameId] level [levelNumber]
  /// (e.g. "Vowels" for bubble_pop's level 1), used when a level tile is
  /// tapped on the level-select screen.
  ///
  /// Tries the sign-system-specific file first
  /// (`<gameId>_<bsl|iac>_level<N>_name`) when [signSystem] is given, then
  /// falls back to the plain `<gameId>_level<N>_name` file used by games
  /// that don't split level-name audio by sign system. Silent if neither
  /// file is found, or if [locale] isn't supported.
  static Future<void> playLevelName(
    String gameId,
    int levelNumber, {
    String locale = 'en',
    SignSystem? signSystem,
  }) async {
    if (!instructionsEnabled) return;
    if (!_isSupportedSpeechLocale(locale)) return;
    final dir = _speechDir(locale);
    final ext = _speechExt(locale);
    final candidates = [
      if (signSystem != null)
        '$dir/${gameId}_${signSystem.name}_level${levelNumber}_name.$ext',
      '$dir/${gameId}_level${levelNumber}_name.$ext',
    ];
    for (final path in candidates) {
      if (await _hasAudioAsset(path)) {
        try {
          final player = await FlameAudio.play(path);
          _trackPlayer(player);
        } catch (e) {
          debugPrint('AudioService: level-name MP3 playback error ($path): $e');
        }
        return;
      }
    }
  }

  /// Plays the zoo's camera shutter click (`assets/audio/zoo/camera_shutter.wav`).
  ///
  /// Awaits playback (capped at [_shutterTimeout], comfortably longer than
  /// the ~0.4s clip) so callers can play it before a correct/wrong SFX
  /// rather than have the two overlap. Silent if the asset is missing.
  static const Duration _shutterTimeout = Duration(milliseconds: 500);

  static Future<void> playCameraShutter() async {
    if (!sfxEnabled) return;
    const path = 'zoo/camera_shutter.wav';
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, _shutterTimeout);
      } catch (e) {
        debugPrint('AudioService: camera shutter playback error: $e');
      }
    }
  }

  /// Plays the correct-answer SFX for [gameId] and triggers a haptic pulse.
  ///
  /// Returns a future that resolves once the SFX finishes playing, so
  /// callers can await it before triggering follow-up UI (e.g. a success
  /// overlay) — fire-and-forget callers may simply ignore the result.
  static Future<void> playCorrect(String gameId) {
    _haptic(_HapticType.correct);
    final sfx = _configs[gameId]?.correctSfx ?? defaultCorrectSfx;
    return _playSfx(sfx);
  }

  /// Plays the wrong-answer SFX for [gameId] and triggers a double-impact haptic.
  ///
  /// Returns a future that resolves once the SFX finishes playing, so
  /// callers can await it before triggering follow-up UI (e.g. a success
  /// overlay) — fire-and-forget callers may simply ignore the result.
  static Future<void> playWrong(String gameId) {
    _haptic(_HapticType.wrong);
    final sfx = _configs[gameId]?.wrongSfx ?? defaultWrongSfx;
    return _playSfx(sfx);
  }

  /// Plays the success overlay sound for [gameId] and triggers a triple-impact haptic.
  ///
  /// Uses [GameAudioConfig.successSfx] if configured; otherwise plays the
  /// recorded "well done" clip for [locale]. Silent if no file is found, or
  /// if [locale] isn't supported and no [GameAudioConfig.successSfx] is set.
  static Future<void> playSuccess(String gameId, {String locale = 'en'}) async {
    hapticSuccess();
    final sfx = _configs[gameId]?.successSfx;
    if (sfx != null) {
      _playSfx(sfx);
      return;
    }
    await speakWithMp3('Well Done!', mp3Path: 'general_well_done', locale: locale);
  }

  /// Plays the recorded "try again" clip for [locale]. Silent if the file
  /// isn't found, or [locale] isn't supported.
  static Future<void> playTryAgain({String locale = 'en'}) async {
    await speakWithMp3('Try again!', mp3Path: 'general_try_again.mp3', locale: locale);
  }

  /// Triple-impact haptic for success/celebration moments.
  static void hapticSuccess() {
    _haptic(_HapticType.success);
  }

  /// Plays the intro audio for [gameId] and waits for it to finish.
  ///
  /// Uses [GameAudioConfig.introMp3] if configured, awaiting the player's
  /// completion event. Falls back to the derived speech file path.
  /// Silent if no audio file is found, or if [locale] isn't supported.
  static Future<void> playIntroAndWait(String gameId, {String locale = 'en'}) async {
    if (!instructionsEnabled) return;
    if (!_isSupportedSpeechLocale(locale)) return;
    final configured = _configs[gameId]?.introMp3;
    final mp3 = configured != null
        ? _localizeSpeechPath(configured, locale)
        : _derivedIntroPath(gameId, locale);
    if (await _hasAudioAsset(mp3)) {
      try {
        final player = await FlameAudio.play(mp3);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: intro MP3 playback error ($mp3): $e');
      }
    }
  }

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> speakAndWait(String text, {String language = 'en-GB'}) async {}

  /// No-op — retained for call-site compatibility after TTS removal.
  static Future<void> speakWelsh(String text) async {}

  /// Plays [mp3Path1] then [mp3Path2] from the recorded speech directory for
  /// [locale] so they sound like one continuous sentence.
  ///
  /// Starts the second file [leadMs] milliseconds before the first ends to
  /// absorb the async-startup latency of FlameAudio.play, eliminating the
  /// audible gap that would otherwise appear between the two clips.
  /// Silent if [locale] isn't supported.
  static Future<void> speakSequentialMp3s(
    String mp3Path1,
    String mp3Path2, {
    int leadMs = 120,
    String locale = 'en',
  }) async {
    if (!_isSupportedSpeechLocale(locale)) return;
    final path1 = _localizeSpeechPath(mp3Path1, locale);
    final path2 = _localizeSpeechPath(mp3Path2, locale);
    if (!await _hasAudioAsset(path1) || !await _hasAudioAsset(path2)) return;
    try {
      final player1 = await FlameAudio.play(path1);
      _trackPlayer(player1);
      final duration = await player1.getDuration();
      if (duration != null && duration.inMilliseconds > leadMs) {
        await Future.delayed(duration - Duration(milliseconds: leadMs));
      } else {
        // getDuration() unavailable (e.g. Android SoundPool in low-latency mode);
        // use a fixed delay rather than hanging on onPlayerComplete for 30 s.
        await Future.delayed(const Duration(milliseconds: 3500));
      }
      final player2 = await FlameAudio.play(path2);
      _trackPlayer(player2);
      await _awaitCompletion(player2, const Duration(seconds: 30));
    } catch (e) {
      debugPrint('AudioService: speakSequentialMp3s error: $e');
    }
  }

  /// Plays [mp3Path] from the recorded speech directory for [locale],
  /// waiting for completion.
  ///
  /// Silent if [mp3Path] is null, the file is unavailable, or [locale]
  /// isn't supported.
  static Future<void> speakWithMp3(String text, {String? mp3Path, String locale = 'en'}) async {
    if (!_isSupportedSpeechLocale(locale)) return;
    if (mp3Path == null) return;
    final path = _localizeSpeechPath(mp3Path, locale);
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: speech MP3 playback error ($path): $e');
      }
    }
  }

  /// Plays a single letter's recorded sound from the alphabet folder for
  /// [signSystem] — BSL spells in English (`alphabet_english/`), IAC spells
  /// in Welsh (`alphabet_welsh/`, vowels a, e, i, o, u, w, y only).
  ///
  /// Driven by the sign system, not the UI [locale]: a Welsh-speaking child
  /// playing with BSL hears English letters, and an English-speaking child
  /// playing with IAC hears Welsh ones. Silent if the file is unavailable.
  static Future<void> playLetterMp3(
    String letter, {
    SignSystem signSystem = SignSystem.bsl,
  }) async {
    final locale = signSystem == SignSystem.iac ? 'cy' : 'en';
    final path =
        '${_speechDir(locale)}/${_alphabetDir(locale)}/${letter.toLowerCase()}.${_speechExt(locale)}';
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: playLetterMp3 error ($path): $e');
      }
    }
  }

  /// Plays the recorded name of a Letter Bingo reward animal, keyed by its
  /// bingo [letter] (e.g. `bingo/animals/x.mp3` for the X animal, "X-ray
  /// Tetra") rather than its display name — sidesteps spaces/hyphens in
  /// names like that one. Silent if the file is unavailable.
  static Future<void> playAnimalName(String letter) async {
    final path = 'bingo/animals/${letter.toLowerCase()}.mp3';
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: playAnimalName error ($path): $e');
      }
    }
  }

  /// Plays [path] relative to `assets/audio/`. Silent if unavailable.
  static Future<void> playMp3(String path) async {
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: playMp3 error ($path): $e');
      }
    }
  }

  /// Plays `general_[name.toLowerCase()]` from the recorded speech directory
  /// for [locale]. Silent if the file is unavailable, or if [locale] isn't
  /// supported.
  static Future<void> playSpeechMp3(String name, {String locale = 'en'}) async {
    if (!_isSupportedSpeechLocale(locale)) return;
    final path = '${_speechDir(locale)}/general_${name.toLowerCase()}.${_speechExt(locale)}';
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        await _awaitCompletion(player, const Duration(seconds: 30));
      } catch (e) {
        debugPrint('AudioService: playSpeechMp3 error ($path): $e');
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
  /// Replaces dots with underscores and appends `_intro`, so for English
  /// `'vowel_hand.level1'` → `'speech files/vowel_hand_level1_intro.mp3'`.
  static String _derivedIntroPath(String gameId, String locale) =>
      '${_speechDir(locale)}/${gameId.replaceAll('.', '_')}_intro.${_speechExt(locale)}';

  /// Derives the speech-file path for a game title from its [gameId].
  ///
  /// Replaces dots with underscores and appends `_title`, so for English
  /// `'bsl_maths'` → `'speech files/bsl_maths_title.mp3'`.
  static String _derivedTitlePath(String gameId, String locale) =>
      '${_speechDir(locale)}/${gameId.replaceAll('.', '_')}_title.${_speechExt(locale)}';

  /// Waits for [player] to finish, capped at [timeout].
  ///
  /// On Android, `FlameAudio.play()` uses `PlayerMode.lowLatency`
  /// (`SoundPool`), whose `onPlayerComplete` event is never emitted by the
  /// platform plugin — so awaiting it directly would hang until [timeout]
  /// on every call. Reaching [timeout] there is therefore expected, not an
  /// error, so it resolves silently instead of throwing.
  static Future<void> _awaitCompletion(AudioPlayer player, Duration timeout) =>
      player.onPlayerComplete.first.timeout(timeout, onTimeout: () {});

  /// Generation counter — incremented on every SFX request.
  /// Any in-flight play() future that resolves with a stale generation is
  /// stopped immediately, preventing queued sounds from playing.
  static int _sfxGeneration = 0;
  static AudioPlayer? _sfxPlayer;

  static Future<void> _playSfx(String path) async {
    if (!sfxEnabled) return;
    final myGeneration = ++_sfxGeneration;

    // Stop whatever SFX is currently playing or pending.
    _sfxPlayer?.stop().catchError((_) {});
    _sfxPlayer = null;

    try {
      final player = await FlameAudio.play(path);
      if (myGeneration != _sfxGeneration) {
        // A newer tap arrived before this sound could start — discard it.
        player.stop().catchError((_) {});
        return;
      }
      _sfxPlayer = player;
      _trackPlayer(player);
      await _awaitCompletion(player, const Duration(seconds: 2));
    } catch (e) {
      debugPrint('AudioService: SFX failed ($path): $e');
    }
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
