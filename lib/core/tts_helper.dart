import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared TTS configuration for the app.
///
/// Configures a British female voice across all features.
///
/// Voice selection priority (iOS/macOS):
/// 1. Stephanie (en-GB female)
/// 2. Kate (en-GB female)
/// 3. Any en-GB female voice
/// 4. Any en-GB voice
/// 5. Default en-GB language fallback
class TtsHelper {
  TtsHelper._();

  /// Speech rate (slow and clear for children)
  static const double _speechRate = 0.35;

  /// Configures a [FlutterTts] instance with British female voice.
  ///
  /// Call this after creating a new [FlutterTts] instance to apply
  /// the standard voice settings used throughout the app.
  static Future<void> configure(FlutterTts tts) async {
    await tts.setLanguage('en-GB');
    await tts.setSpeechRate(_speechRate);
    await _selectBritishFemaleVoice(tts);
  }

  /// Selects a British female voice.
  static Future<void> _selectBritishFemaleVoice(FlutterTts tts) async {
    try {
      final voices = await tts.getVoices;
      if (voices == null || voices is! List) return;

      // Priority: British female voices (skip male voices like Daniel)
      const preferredNames = ['stephanie', 'kate'];

      for (final preferred in preferredNames) {
        for (final voice in voices) {
          if (voice is! Map) continue;
          final name = (voice['name'] ?? '').toString().toLowerCase();
          final locale = (voice['locale'] ?? '').toString().toLowerCase();

          if (locale.contains('gb') && name.contains(preferred)) {
            await tts.setVoice({
              'name': voice['name'].toString(),
              'locale': voice['locale'].toString(),
            });
            return;
          }
        }
      }

      // Fallback: any en-GB voice
      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = (voice['locale'] ?? '').toString().toLowerCase();

        if (locale.contains('gb')) {
          await tts.setVoice({
            'name': voice['name'].toString(),
            'locale': voice['locale'].toString(),
          });
          return;
        }
      }

      // Final fallback: setLanguage('en-GB') already applied
    } catch (e) {
      debugPrint('TTS voice selection failed: $e');
    }
  }
}
