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

  /// Recorded speech instructions exist for English (`speech files/`) and
  /// Welsh (`speech_files_molly_cy/`), both as MP3s. Speech-playing methods
  /// below stay silent for any other [locale].
  static bool _isSupportedSpeechLocale(String locale) => locale == 'en' || locale == 'cy';

  /// Directory (relative to `assets/audio/`) holding recorded speech for [locale].
  static String _speechDir(String locale) =>
      locale == 'cy' ? 'speech_files_molly_cy' : 'speech files';

  /// Subdirectory (under the locale's speech directory) holding single-letter
  /// alphabet clips. English covers the full alphabet; Welsh only covers the
  /// vowels used by the vowel/letter games (a, e, i, o, u, w, y).
  static String _alphabetDir(String locale) =>
      locale == 'cy' ? 'alphabet_welsh' : 'alphabet_english';

  /// Rewrites a speech-file path or bare filename (with or without
  /// extension) to the MP3 asset for [locale], swapping the speech
  /// directory, keeping only the basename. Callers can pass an
  /// English-style path (e.g. `speech files/foo.mp3`) or a bare name (e.g.
  /// `foo.mp3` / `foo`) and get the right file for any supported locale.
  static String _localizeSpeechPath(String path, String locale) {
    final slash = path.lastIndexOf('/');
    final name = slash == -1 ? path : path.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    final base = dot == -1 ? name : name.substring(0, dot);
    return '${_speechDir(locale)}/$base.mp3';
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
    final candidates = [
      if (signSystem != null)
        '$dir/${gameId}_${signSystem.name}_level${levelNumber}_name.mp3',
      '$dir/${gameId}_level${levelNumber}_name.mp3',
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

  /// Starts a named instruction clip for [gameId] — e.g. `name: 'tap_first'`
  /// plays `<gameId>_tap_first` — localized to [locale], returning the
  /// playing [AudioPlayer] (or null if nothing played). Shared by
  /// [playInstructionClip] (fire-and-forget) and [playInstructionClipAndWait]
  /// (awaits completion).
  ///
  static Future<AudioPlayer?> _startInstructionClip(
    String gameId,
    String name,
    String locale,
  ) async {
    if (!instructionsEnabled) return null;
    if (!_isSupportedSpeechLocale(locale)) return null;
    final path = '${_speechDir(locale)}/${gameId}_$name.mp3';
    if (await _hasAudioAsset(path)) {
      try {
        final player = await FlameAudio.play(path);
        _trackPlayer(player);
        return player;
      } catch (e) {
        debugPrint('AudioService: instruction clip playback error ($path): $e');
      }
    }
    return null;
  }

  /// Plays a named instruction clip for [gameId] — see [_startInstructionClip].
  /// Silent if no audio file is found, instructions are disabled, or
  /// [locale] isn't supported.
  static Future<void> playInstructionClip(
    String gameId,
    String name, {
    String locale = 'en',
  }) async {
    await _startInstructionClip(gameId, name, locale);
  }

  /// Plays a named instruction clip for [gameId] — see [_startInstructionClip]
  /// — and waits for it to finish before resolving. Resolves immediately if
  /// no audio file is found, instructions are disabled, or [locale] isn't
  /// supported, so callers can always safely await it as a gate.
  ///
  /// If [isCancelled] returns true once the clip has loaded, it's stopped
  /// straight away — this catches a [stopAll] that ran while the clip was
  /// still loading (and so had no player to stop yet).
  static Future<void> playInstructionClipAndWait(
    String gameId,
    String name, {
    String locale = 'en',
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) return;
    final player = await _startInstructionClip(gameId, name, locale);
    if (player == null) return;
    if (isCancelled?.call() ?? false) {
      _activePlayers.remove(player);
      await player.stop().catchError((_) {});
      return;
    }
    await _awaitCompletion(player, const Duration(seconds: 10));
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

  /// Short till-key beep. A rapid second tap cuts off the previous beep
  /// rather than queueing behind it.
  static Future<void> playTillBeep() => _playSfx('till/beep.mp3');

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
  /// Uses [GameAudioConfig.successSfx] if configured; otherwise speaks the
  /// recorded `general_[messageName]` clip for [locale] (`'well_done'`,
  /// `'congratulations'`, or `'personal_best'` — see
  /// [GameSuccessOverlay._successAudioName]). Silent if no file is found, or
  /// if [locale] isn't supported and no [GameAudioConfig.successSfx] is set.
  static Future<void> playSuccess(
    String gameId, {
    String locale = 'en',
    String messageName = 'well_done',
  }) async {
    hapticSuccess();
    final sfx = _configs[gameId]?.successSfx;
    if (sfx != null) {
      _playSfx(sfx);
      return;
    }
    await speakWithMp3('', mp3Path: 'general_$messageName', locale: locale);
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

  /// Plays the intro audio for [gameId] and waits for it to finish, plus
  /// a 600 ms breathing gap before returning.
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
    await Future.delayed(const Duration(milliseconds: 600));
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
    await _playPathsSequentially([path1, path2], leadMs: leadMs);
  }

  /// Plays each name in [names] (bare speech-file names, see
  /// [_localizeSpeechPath]) back-to-back for [locale], so they read as one
  /// sentence. Entries whose file isn't found are skipped rather than
  /// aborting the rest of the sequence. Does nothing if [locale] isn't
  /// supported or no entry is found.
  static Future<void> speakSequence(
    List<String> names, {
    String locale = 'en',
    int leadMs = 120,
  }) async {
    if (!_isSupportedSpeechLocale(locale)) return;
    final paths = <String>[];
    for (final name in names) {
      final path = _localizeSpeechPath(name, locale);
      if (await _hasAudioAsset(path)) paths.add(path);
    }
    await _playPathsSequentially(paths, leadMs: leadMs);
  }

  /// Bare speech-file names (see [_localizeSpeechPath]) that together speak
  /// whole number [n], using the recorded `general_1`..`general_20` clips
  /// for 1-20. Larger numbers combine the nearest ten's clip
  /// (`general30`..`general100` — recorded without the underscore used by
  /// the 1-20 clips) with a `general_1`..`general_9` units clip, e.g.
  /// 42 -> `['general40', 'general_2']`.
  static List<String> _numberSpeechNames(int n) {
    if (n <= 20) return ['general_$n'];
    final tens = (n ~/ 10) * 10;
    final units = n % 10;
    final tensName = tens == 20 ? 'general_20' : 'general$tens';
    return units == 0 ? [tensName] : [tensName, 'general_$units'];
  }

  /// Plays [prefix], then the recorded number [count], then [suffix],
  /// back-to-back as one sentence for [locale] — e.g. "card_matching_success_moves"
  /// + 42 + "card_matching_moves_suffix" reads as "You did it in 42 moves!".
  /// See [_numberSpeechNames] for how [count] is spoken. Silent for any clip
  /// that isn't found, or if [locale] isn't supported.
  static Future<void> playCountResult(
    String prefix,
    int count,
    String suffix, {
    String locale = 'en',
  }) {
    return speakSequence(
      [prefix, ..._numberSpeechNames(count), suffix],
      locale: locale,
    );
  }

  /// Plays [paths] (already-localized asset paths) back-to-back, starting
  /// each one [leadMs] milliseconds before the previous ends to absorb the
  /// async-startup latency of `FlameAudio.play` — see
  /// [speakSequentialMp3s]. Does nothing if [paths] is empty.
  static Future<void> _playPathsSequentially(
    List<String> paths, {
    required int leadMs,
  }) async {
    if (paths.isEmpty) return;
    try {
      for (var i = 0; i < paths.length; i++) {
        final player = await FlameAudio.play(paths[i]);
        _trackPlayer(player);
        if (i == paths.length - 1) {
          await _awaitCompletion(player, const Duration(seconds: 30));
        } else {
          final duration = await player.getDuration();
          if (duration != null && duration.inMilliseconds > leadMs) {
            await Future.delayed(duration - Duration(milliseconds: leadMs));
          } else {
            // getDuration() unavailable (e.g. Android SoundPool in
            // low-latency mode); use a fixed delay rather than hanging on
            // onPlayerComplete for 30 s.
            await Future.delayed(const Duration(milliseconds: 3500));
          }
        }
      }
    } catch (e) {
      debugPrint('AudioService: _playPathsSequentially error: $e');
    }
  }

  /// Plays [mp3Path] from the recorded speech directory for [locale],
  /// waiting for completion. Silent if [mp3Path] is null, no file is found,
  /// or [locale] isn't supported.
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
        '${_speechDir(locale)}/${_alphabetDir(locale)}/${letter.toLowerCase()}.mp3';
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

  /// Plays the recorded "Bingo!" celebration clip (`letter_bingo_bingo`) for
  /// [locale]. Silent if unavailable.
  static Future<void> playBingoCelebration({String locale = 'en'}) {
    return speakWithMp3(
      'Bingo!',
      mp3Path: 'letter_bingo_bingo',
      locale: locale,
    );
  }

  /// Plays the recorded "You have a (new) friend" greeting clip for
  /// [locale] on the bingo success screen.
  ///
  /// Welsh clips use a `letter_bingo_`-prefixed name
  /// (`letter_bingo_new_friend` / `letter_bingo_friend`) where English uses
  /// `bingo_you_have_a_new_friend` / `bingo_you_have_a_friend`.
  /// Silent if unavailable.
  static Future<void> playFriendGreeting({
    required bool isNew,
    String locale = 'en',
  }) {
    return speakWithMp3(
      '',
      mp3Path: locale == 'cy'
          ? (isNew ? 'letter_bingo_new_friend' : 'letter_bingo_friend')
          : (isNew
              ? 'bingo_you_have_a_new_friend'
              : 'bingo_you_have_a_friend'),
      locale: locale,
    );
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
    final path = '${_speechDir(locale)}/general_${name.toLowerCase()}.mp3';
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
      '${_speechDir(locale)}/${gameId.replaceAll('.', '_')}_intro.mp3';

  /// Waits for [player] to finish, capped at [timeout].
  ///
  /// On Android, `FlameAudio.play()` uses `PlayerMode.lowLatency`
  /// (`SoundPool`), whose `onPlayerComplete` event is never emitted by the
  /// platform plugin — so awaiting it directly would hang until [timeout]
  /// on every call. Reaching [timeout] there is therefore expected, not an
  /// error, so it resolves silently instead of throwing.
  static Future<void> _awaitCompletion(AudioPlayer player, Duration timeout) =>
      // `.map<void>` forces a genuinely void-typed stream: onPlayerComplete
      // is declared `Stream<void>` but is actually built from `.where()` on
      // the player's `Stream<AudioEvent>`, so its reified type parameter is
      // still AudioEvent. Timing out that future directly makes the runtime
      // check `onTimeout`'s return type against AudioEvent instead of void,
      // which an `() {}` closure fails only on Android.
      player.onPlayerComplete.map<void>((_) {}).first.timeout(timeout, onTimeout: () {});

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
