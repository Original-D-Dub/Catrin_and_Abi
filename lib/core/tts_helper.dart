import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared TTS configuration for the app.
///
/// Configures a British female voice across all features.
///
/// Voice selection priority:
/// 1. Stephanie or Kate (explicit en-GB female names)
/// 2. Any en-GB voice with a female gender/name indicator (platform-specific)
/// 3. Any en-GB voice
/// 4. Default en-GB language fallback
class TtsHelper {
  TtsHelper._();

  static Future<void> configure(FlutterTts tts) async {
    await tts.setLanguage('en-GB');
    await _selectBritishFemaleVoice(tts);
  }

  static Future<void> _selectBritishFemaleVoice(FlutterTts tts) async {
    try {
      final voices = await tts.getVoices;
      if (voices == null || voices is! List) return;

      final gbVoices = [
        for (final v in voices)
          if (v is Map &&
              (v['locale'] ?? '').toString().toLowerCase().contains('gb'))
            v,
      ];

      if (gbVoices.isEmpty) return;

      // Priority 1: well-known British female voice names
      const preferredNames = ['stephanie', 'kate'];
      for (final preferred in preferredNames) {
        for (final voice in gbVoices) {
          final name = (voice['name'] ?? '').toString().toLowerCase();
          if (name.contains(preferred)) {
            await tts.setVoice({
              'name': voice['name'].toString(),
              'locale': voice['locale'].toString(),
            });
            return;
          }
        }
      }

      // Priority 2: platform-specific female voice detection
      Map? chosenVoice;
      for (final voice in gbVoices) {
        final name = (voice['name'] ?? '').toString().toLowerCase();
        final gender = (voice['gender'] ?? '').toString().toLowerCase();

        if (!kIsWeb && Platform.isIOS) {
          // iOS voices expose a dedicated gender field
          if (gender.contains('female')) {
            chosenVoice = voice;
            break;
          }
        } else if (!kIsWeb && Platform.isAndroid) {
          // Android encodes gender in the identifier, e.g. 'en-gb-x-fis#female_1-local'
          if (name.contains('female')) {
            chosenVoice = voice;
            break;
          }
        } else {
          if (name.contains('female')) {
            chosenVoice = voice;
            break;
          }
        }
      }

      if (chosenVoice != null) {
        await tts.setVoice({
          'name': chosenVoice['name'].toString(),
          'locale': chosenVoice['locale'].toString(),
        });
        return;
      }

      // Priority 3: any en-GB voice (setLanguage already applied above)
      await tts.setVoice({
        'name': gbVoices.first['name'].toString(),
        'locale': gbVoices.first['locale'].toString(),
      });
    } catch (e) {
      debugPrint('TTS voice selection failed: $e');
    }
  }
}
