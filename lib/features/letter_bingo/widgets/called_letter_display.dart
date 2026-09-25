import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';


/// Displays the currently called letter at the bottom of the screen.
///
/// Shows:
/// - "Find the letter:" label
/// - The lowercase letter underneath
///
/// When the [letter] changes, plays its recorded sound (via
/// [AudioService.playLetterMp3], picked by [signSystem]) and animates the
/// entrance with a scale/fade transition.
///
/// Parameters:
/// - [letter]: The currently called letter (lowercase)
/// - [signSystem]: BSL or IAC — selects the English or Welsh letter sound.
/// - [introFuture]: When provided, the whole first "Find the letter"
///   display is hidden and its audio held until this future completes
///   (e.g. after the intro instructions finish), then the display fades
///   in and the letter is spoken.
/// - [secondCallGateFuture]: When provided, the *second* called letter's
///   sound is held until this future completes (e.g. letter_bingo's
///   tap_second instruction bubble finishing its spoken clip). Letters
///   after the second always speak as soon as they're called.
class CalledLetterDisplay extends StatefulWidget {
  /// The letter currently being called (lowercase, e.g. 'a')
  final String letter;

  /// BSL or IAC — selects which alphabet's recorded sound to play.
  final SignSystem signSystem;

  /// Optional future to await before speaking the first letter.
  final Future<void>? introFuture;

  /// Optional future to await before speaking the second letter.
  final Future<void>? secondCallGateFuture;

  /// UI locale ('en' or 'cy') used for the "Find the letter" label.
  final String locale;

  const CalledLetterDisplay({
    super.key,
    required this.letter,
    this.signSystem = SignSystem.bsl,
    this.introFuture,
    this.secondCallGateFuture,
    this.locale = 'en',
  });

  @override
  State<CalledLetterDisplay> createState() => _CalledLetterDisplayState();
}

class _CalledLetterDisplayState extends State<CalledLetterDisplay> {
  /// Whether the intro gate has lifted. While false, the whole display is
  /// hidden (and the letter stays silent) so the intro instructions can
  /// finish before the first "Find the letter" is revealed.
  late bool _introComplete;

  /// Number of distinct letters spoken so far this level — used to gate
  /// only the first (via [_waitForIntroThenSpeak]) and second (via
  /// [widget.secondCallGateFuture]) calls; every call after that speaks
  /// immediately.
  int _calledCount = 0;

  @override
  void initState() {
    super.initState();
    _introComplete = widget.introFuture == null;
    if (!_introComplete) _waitForIntroThenSpeak();
  }

  Future<void> _waitForIntroThenSpeak() async {
    await widget.introFuture;
    if (!mounted) return;
    setState(() => _introComplete = true);
    _speakLetter(widget.letter);
    _calledCount = 1;
  }

  @override
  void didUpdateWidget(CalledLetterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) {
      if (_calledCount == 1 && widget.secondCallGateFuture != null) {
        _waitForSecondGateThenSpeak(widget.letter, widget.secondCallGateFuture!);
      } else {
        _speakLetter(widget.letter);
      }
      _calledCount++;
    }
  }

  /// Holds the second letter's sound until [gate] (the tap_second
  /// instruction's spoken clip) finishes, then speaks [letter] — but only
  /// if it's still the current letter (guards against a rapid further
  /// change while waiting).
  Future<void> _waitForSecondGateThenSpeak(
      String letter, Future<void> gate) async {
    await gate;
    if (!mounted) return;
    if (widget.letter == letter) _speakLetter(letter);
  }

  void _speakLetter(String letter) {
    AudioService.playLetterMp3(letter, signSystem: widget.signSystem);
  }

  @override
  Widget build(BuildContext context) {
    final isWideDevice = MediaQuery.of(context).size.width > 600;
    final letterScale = isWideDevice ? 1.5 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: _introComplete
            ? Column(
                key: ValueKey(widget.letter),
                mainAxisSize: MainAxisSize.min,
                children: [
            // Letter in white bordered box (mirrors BSL sign box in Bubble Pop)
            Container(
              width: 120 * letterScale,
              height: 100 * letterScale,
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
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontWeight: FontWeight.w900,
                    fontSize: (widget.letter.length > 1
                            ? AppSizes.fontSizeTitle * 0.7
                            : AppSizes.fontSizeTitle) *
                        letterScale,
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
              child: Text(
                AppLocalizations(locale: widget.locale)('letter_bingo.find_letter'),
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        )
            : const SizedBox.shrink(key: ValueKey('intro-waiting')),
      ),
    );
  }
}
