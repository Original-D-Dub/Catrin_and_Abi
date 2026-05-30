import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import '../../core/localization/translations_en.dart';
import '../../core/tts_helper.dart';

/// Audio configuration for a single game.
///
/// **Adding a custom MP3 for any slot:**
/// 1. Drop the file in `assets/audio/{gameId}/` (e.g. `assets/audio/card_matching/intro.mp3`).
/// 2. Register the path in [AudioService._configs] below (relative to `assets/audio/`).
/// 3. Declare the directory in `pubspec.yaml` under `flutter > assets`.
/// 4. Run `flutter pub get` and rebuild.
class GameAudioConfig {
  /// Path to a custom intro MP3, relative to `assets/audio/`.
  /// When null, [introText] is spoken via TTS instead.
  final String? introMp3;

  /// Text spoken via TTS when [introMp3] is null or fails to load.
  final String? introText;

  /// Custom correct-answer SFX path (relative to `assets/audio/`).
  /// Defaults to [AudioService.defaultCorrectSfx].
  final String? correctSfx;

  /// Custom wrong-answer SFX path (relative to `assets/audio/`).
  /// Defaults to [AudioService.defaultWrongSfx].
  final String? wrongSfx;

  /// Custom success-overlay MP3/WAV path (relative to `assets/audio/`).
  /// When null, "Well Done!" is spoken via TTS.
  final String? successSfx;

  const GameAudioConfig({
    this.introMp3,
    this.introText,
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

  static final Map<String, GameAudioConfig> _configs = {
    'bubble_pop': GameAudioConfig(
      introText: translationsEn['bubble_pop.intro'],
      correctSfx: 'bubble_pop/pop_correct.mp3',
      wrongSfx: 'bubble_pop/pop.mp3',
    ),
    'card_matching': GameAudioConfig(
      introText: translationsEn['card_matching.intro'],
    ),
    'bsl_maths': GameAudioConfig(
      introText: translationsEn['bsl_maths.intro'],
    ),
    'letter_bingo': GameAudioConfig(
      introText: translationsEn['letter_bingo.intro'],
    ),
    'counting_game': GameAudioConfig(
      introText: translationsEn['counting_game.intro'],
      correctSfx: 'counting_game/correct.wav',
      wrongSfx: 'counting_game/wrong.wav',
    ),
    'character_id': GameAudioConfig(
      introText: translationsEn['character_id.intro'],
    ),
    'number_line_game': GameAudioConfig(
      introText: translationsEn['number_line_game.intro'],
    ),
    'counting_back': GameAudioConfig(
      introText: 'Count backwards to find the missing number!',
    ),
    'more_or_less': GameAudioConfig(
      introText: translationsEn['more_or_less.intro'],
    ),
    'bsl_sprint.level0': GameAudioConfig(
      introText: translationsEn['bsl_sprint.level0.intro'],
    ),
    'bsl_sprint.level1': GameAudioConfig(
      introText: translationsEn['bsl_sprint.level1.intro'],
    ),
    'bsl_sprint.level2': GameAudioConfig(
      introText: translationsEn['bsl_sprint.level2.intro'],
    ),
    'higher_or_lower': GameAudioConfig(
      introText: translationsEn['higher_or_lower.intro'],
    ),
    'vowel_hand.level1': GameAudioConfig(
      introText: translationsEn['vowel_hand.level1.intro'],
    ),
    'vowel_hand.level2': GameAudioConfig(
      introText: translationsEn['vowel_hand.level2.intro'],
    ),
    'vowel_hand.level3': GameAudioConfig(
      introText: translationsEn['vowel_hand.level3.intro'],
    ),
    'vowel_hand.level4': GameAudioConfig(
      introText: translationsEn['vowel_hand.level4.intro'],
    ),
    'my_special_dog.level1': GameAudioConfig(
      introText: translationsEn['my_special_dog.intro'],
    ),
    'my_special_dog.level2': GameAudioConfig(
      introText: translationsEn['my_special_dog.level2.intro'],
    ),
    'my_special_dog.level3': GameAudioConfig(
      introText: translationsEn['my_special_dog.level3.intro'],
    ),
    'camera_vowels': GameAudioConfig(  
      introText: 'Touch each fingertip to learn the B.S.L. vowel hand signs!',
    ),
    'wave_hello': GameAudioConfig(
      introText: 'Wave hello to Catrin by moving your hand up and down!',
    ),
    'letter_quest': GameAudioConfig(
      correctSfx: 'letter_quest/collect_correct.wav',
      wrongSfx: 'letter_quest/collect_wrong.wav',
      successSfx: 'letter_quest/game_complete.wav',
    ),
    'letter_quest.level1': GameAudioConfig(
      introText: translationsEn['letter_quest.level1.intro'],
    ),
    'letter_quest.level2': GameAudioConfig(
      introText: translationsEn['letter_quest.level2.intro'],
    ),
    'letter_quest.level3': GameAudioConfig(
      introText: translationsEn['letter_quest.level3.intro'],
    ),
    'letter_quest.level4': GameAudioConfig(
      introText: translationsEn['letter_quest.level4.intro'],
    ),
    'colouring': GameAudioConfig(
      introText: 'Tap a colour and then tap the picture to colour it in!',
    ),
  };

  // ── TTS singleton ──────────────────────────────────────────────────────────

  static FlutterTts? _tts;
  static bool _ttsInitialised = false;

  static Future<void> _ensureTts() async {
    if (_ttsInitialised) return;
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      _ttsInitialised = true;
    } catch (e) {
      debugPrint('AudioService: TTS init failed: $e');
    }
  }

  static Future<void> _speak(String text) async {
    await _ensureTts();
    try {
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('AudioService: TTS speak failed: $e');
    }
  }

  // ── Active player tracking ─────────────────────────────────────────────────

  static final List<AudioPlayer> _activePlayers = [];

  static void _trackPlayer(AudioPlayer player) {
    _activePlayers.add(player);
    player.onPlayerComplete.listen((_) => _activePlayers.remove(player));
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Plays the intro instructions for [gameId].
  ///
  /// Tries [GameAudioConfig.introMp3] first, then the auto-derived speech file
  /// (`speech files/<gameId_with_underscores>_intro.mp3`), then falls back to
  /// TTS using [GameAudioConfig.introText].
  static Future<void> playIntro(String gameId) async {
    final config = _configs[gameId];
    if (config == null) return;

    // final mp3 = config.introMp3 ?? _derivedIntroPath(gameId);
    // try {
    //   final player = await FlameAudio.play(mp3);
    //   _trackPlayer(player);
    //   return;
    // } catch (e) {
    //   debugPrint('AudioService: intro MP3 failed ($mp3), using TTS: $e');
    // }

    if (config.introText != null) {
      await _speak(config.introText!);
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
  /// `speech files/general_well_done.mp3`, falling back to TTS "Well Done!".
  static Future<void> playSuccess(String gameId) async {
    hapticSuccess();
    final sfx = _configs[gameId]?.successSfx;
    if (sfx != null) {
      _playSfx(sfx);
      return;
    }
    await speakWithMp3('Well Done!', mp3Path: 'general_well_done.mp3');
  }

  /// Plays `speech files/general_try_again.mp3`, falling back to TTS "Try again!".
  static Future<void> playTryAgain() async {
    await speakWithMp3('Try again!', mp3Path: 'general_try_again.mp3');
  }

  /// Triple-impact haptic for success/celebration moments.
  ///
  /// Call directly when a success screen appears without going through [playSuccess]
  /// (e.g. [BingoSuccessOverlay] which uses its own TTS).
  static void hapticSuccess() {
    _haptic(_HapticType.success);
  }

  /// Returns the intro instruction text for [gameId], or null if not configured.
  static String? introText(String gameId) => _configs[gameId]?.introText;

  /// Plays the intro audio for [gameId] and waits for it to finish.
  ///
  /// Uses [GameAudioConfig.introMp3] if configured, awaiting the player's
  /// completion event. Falls back to [speakAndWait] with [introText].
  static Future<void> playIntroAndWait(String gameId) async {
    final config = _configs[gameId];
    if (config == null) return;

    // final mp3 = config.introMp3 ?? _derivedIntroPath(gameId);
    // try {
    //   final player = await FlameAudio.play(mp3);
    //   _trackPlayer(player);
    //   await player.onPlayerComplete.first.timeout(
    //     const Duration(seconds: 30),
    //     onTimeout: () {},
    //   );
    //   return;
    // } catch (e) {
    //   debugPrint('AudioService: intro MP3 failed ($mp3), using TTS: $e');
    // }

    if (config.introText != null) {
      await speakAndWait(config.introText!);
    }
  }

  /// Speaks [text] via TTS and waits for the utterance to finish before returning.
  ///
  /// Falls back to a time-estimate if TTS is unavailable or the completion
  /// handler never fires (e.g. the utterance is interrupted).
  static Future<void> speakAndWait(String text) async {
    if (text.isEmpty) return;
    await _ensureTts();
    if (_tts == null) {
      await Future.delayed(
        Duration(milliseconds: (text.length * 80).clamp(1000, 10000)),
      );
      return;
    }

    final completer = Completer<void>();
    _tts!.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts!.setErrorHandler((msg) {
      debugPrint('AudioService: TTS error in speakAndWait: $msg');
      if (!completer.isCompleted) completer.complete();
    });

    try {
      await _tts!.speak(text);
      await completer.future.timeout(
        Duration(
          milliseconds: (text.length * 100 + 2500).clamp(2500, 20000),
        ),
        onTimeout: () {},
      );
    } catch (e) {
      debugPrint('AudioService: speakAndWait failed: $e');
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      _tts!.setCompletionHandler(() {});
      _tts!.setErrorHandler((_) {});
    }
  }

  /// Plays [mp3Path] from `assets/audio/speech files/`, waiting for completion.
  ///
  /// Falls back to TTS [text] if [mp3Path] is null or the file fails to load.
  /// [mp3Path] uses underscores in place of the dots used in translation keys,
  /// e.g. key `'bubble_pop.intro'` → mp3Path `'bubble_pop_intro.mp3'`.
  static Future<void> speakWithMp3(String text, {String? mp3Path}) async {
    // if (mp3Path != null) {
    //   try {
    //     final player = await FlameAudio.play('speech files/$mp3Path');
    //     _trackPlayer(player);
    //     await player.onPlayerComplete.first.timeout(
    //       const Duration(seconds: 30),
    //       onTimeout: () {},
    //     );
    //     return;
    //   } catch (e) {
    //     debugPrint('AudioService: speech MP3 failed ($mp3Path), using TTS: $e');
    //   }
    // }
    await speakAndWait(text);
  }

  /// Plays a single English letter mp3 from
  /// `assets/audio/speech files/alphabet_english/[letter].mp3`,
  /// falling back to TTS speaking the letter name.
  static Future<void> playLetterMp3(String letter) =>
      speakWithMp3(letter, mp3Path: 'alphabet_english/$letter.mp3');

  /// Plays [path] relative to `assets/audio/`.
  /// If the file fails and [fallbackText] is provided, speaks it via TTS.
  static Future<void> playMp3(String path, {String? fallbackText}) async {
    try {
      final player = await FlameAudio.play(path);
      _trackPlayer(player);
      await player.onPlayerComplete.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      return;
    } catch (e) {
      debugPrint('AudioService: playMp3 failed ($path): $e');
    }
    if (fallbackText != null) {
      await speakAndWait(fallbackText);
    }
  }

  /// Plays `assets/audio/speech files/general_[name.toLowerCase()].mp3`,
  /// falling back to TTS speaking [name] if the file is unavailable.
  static Future<void> playSpeechMp3(String name) async {
    // final fileName = 'general_${name.toLowerCase()}.mp3';
    // try {
    //   final player = await FlameAudio.play('speech files/$fileName');
    //   _trackPlayer(player);
    //   await player.onPlayerComplete.first.timeout(
    //     const Duration(seconds: 30),
    //     onTimeout: () {},
    //   );
    //   return;
    // } catch (e) {
    //   debugPrint('AudioService: playSpeechMp3 failed ($fileName): $e');
    // }
    await speakAndWait(name);
  }

  /// Speaks arbitrary [text] via TTS.
  static Future<void> speak(String text) => _speak(text);

  /// Stops any active TTS speech.
  static Future<void> stopTts() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Stops all audio: TTS and any playing SFX/intro audio players.
  ///
  /// Call this whenever the player leaves a game (back arrow, hardware back button).
  static Future<void> stopAll() async {
    await stopTts();
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
  // /// `'vowel_hand.level1'` → `'speech files/vowel_hand_level1_intro.mp3'`.
  // static String _derivedIntroPath(String gameId) =>
  //     'speech files/${gameId.replaceAll('.', '_')}_intro.mp3';

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