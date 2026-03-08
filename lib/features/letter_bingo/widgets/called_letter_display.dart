import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/tts_helper.dart';


/// Displays the currently called letter at the bottom of the screen.
///
/// Shows:
/// - "Find the letter:" label
/// - The lowercase letter underneath
///
/// When the [letter] changes, plays a TTS audio prompt
/// ("Find the letter A") and animates the entrance with
/// a scale/fade transition.
///
/// Parameters:
/// - [letter]: The currently called letter (lowercase)
class CalledLetterDisplay extends StatefulWidget {
  /// The letter currently being called (lowercase, e.g. 'a')
  final String letter;

  const CalledLetterDisplay({
    super.key,
    required this.letter,
  });

  @override
  State<CalledLetterDisplay> createState() => _CalledLetterDisplayState();
}

class _CalledLetterDisplayState extends State<CalledLetterDisplay> {
  /// Text-to-speech engine instance
  late final FlutterTts _tts;

  /// Whether TTS has been initialized
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Initializes the TTS engine with a British female voice.
  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await TtsHelper.configure(_tts);
      _ttsReady = true;
      // Speak the initial letter
      _speakLetter(widget.letter);
    } catch (e) {
      // TTS may not be available on all platforms — game continues without
      debugPrint('TTS initialization failed: $e');
    }
  }

  @override
  void didUpdateWidget(CalledLetterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Speak the new letter when it changes
    if (oldWidget.letter != widget.letter) {
      _speakLetter(widget.letter);
    }
  }

  /// Speaks "Find the letter [X]" using TTS.
  ///
  /// Silently fails if TTS is not available.
  Future<void> _speakLetter(String letter) async {
    if (!_ttsReady) return;
    try {
      await _tts.speak('Find the letter ${letter.toUpperCase()}');
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tts.stop();
    } catch (e) {
      // Ignore disposal errors
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusXLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Column(
          key: ValueKey(widget.letter),
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            const Text(
              'Find the letter:',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXSmall),

            // Called letter (lowercase only)
            Text(
              widget.letter.toLowerCase(),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontSizeTitle,
                color: AppColors.accentNavyBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
