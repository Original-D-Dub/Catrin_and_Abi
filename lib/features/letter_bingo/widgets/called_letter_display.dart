import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';


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
/// - [introFuture]: When provided, the first "Find the letter" is held until
///   this future completes (e.g. after the intro instructions finish).
class CalledLetterDisplay extends StatefulWidget {
  /// The letter currently being called (lowercase, e.g. 'a')
  final String letter;

  /// Optional future to await before speaking the first letter.
  final Future<void>? introFuture;

  const CalledLetterDisplay({
    super.key,
    required this.letter,
    this.introFuture,
  });

  @override
  State<CalledLetterDisplay> createState() => _CalledLetterDisplayState();
}

class _CalledLetterDisplayState extends State<CalledLetterDisplay> {
  @override
  void initState() {
    super.initState();
    _waitForIntroThenSpeak();
  }

  Future<void> _waitForIntroThenSpeak() async {
    await widget.introFuture;
    if (mounted) _speakLetter(widget.letter);
  }

  @override
  void didUpdateWidget(CalledLetterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) {
      _speakLetter(widget.letter);
    }
  }

  void _speakLetter(String letter) {
    AudioService.speak('Find the letter, ${letter.toUpperCase()}');
  }

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Column(
          key: ValueKey(widget.letter),
          mainAxisSize: MainAxisSize.min,
          children: [
            // Letter in white bordered box (mirrors BSL sign box in Bubble Pop)
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.headerBorderDark,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  widget.letter.toLowerCase(),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontWeight: FontWeight.w900,
                    fontSize: AppSizes.fontSizeTitle,
                    color: AppColors.accentNavyBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // "Find the letter" purple pill label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Find the letter',
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
