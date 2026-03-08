import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/tts_helper.dart';

/// Pulsing "BINGO" text celebration overlay.
///
/// Each letter (B, I, N, G, O) gets a different bright colour.
/// The text scales between 1.0 and 1.2 with a repeating animation.
///
/// **Level 1**: Centered overlay on full screen.
/// **Level 2**: Can be positioned to fill the completed row area
/// via the [alignment] parameter.
///
/// Calls [onDismiss] after 3 seconds or when tapped.
///
/// Parameters:
/// - [onDismiss]: Called when the celebration should be dismissed
/// - [alignment]: Where to position the text (default: center)
class BingoCelebration extends StatefulWidget {
  /// Callback when the celebration is dismissed (tap or timeout)
  final VoidCallback onDismiss;

  /// Alignment of the BINGO text within the overlay
  final Alignment alignment;

  /// Duration before auto-dismissal
  static const Duration autoDismissDelay = Duration(seconds: 3);

  const BingoCelebration({
    super.key,
    required this.onDismiss,
    this.alignment = Alignment.center,
  });

  @override
  State<BingoCelebration> createState() => _BingoCelebrationState();
}

class _BingoCelebrationState extends State<BingoCelebration>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulsing scale effect
  late final AnimationController _controller;

  /// Scale animation (1.0 → 1.2 → 1.0 repeating)
  late final Animation<double> _scaleAnimation;

  /// TTS engine for saying "Bingo!"
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();

    // Set up pulsing animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Say "Bingo!" via TTS
    _speakBingo();

    // Auto-dismiss after timeout
    Future.delayed(BingoCelebration.autoDismissDelay, () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  /// Speaks "Bingo!" using a British female TTS voice.
  Future<void> _speakBingo() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      await _tts!.speak('Bingo!');
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: widget.alignment,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildBingoText(),
          ),
        ),
      ),
    );
  }

  /// Builds the "BINGO" text with each letter in a different colour.
  ///
  /// Uses a [Row] of individually coloured [Text] widgets with
  /// drop shadow for visibility against any background.
  Widget _buildBingoText() {
    /// Colours for each letter: B=Red, I=Blue, N=Green, G=Orange, O=Purple
    const letterColors = [
      AppColors.accentRed,
      AppColors.accentNavyBlue,
      AppColors.accentLimeGreen,
      AppColors.accentOrange,
      AppColors.accentPurple,
    ];

    const letters = ['B', 'I', 'N', 'G', 'O'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (index) {
        return Text(
          letters[index],
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: letterColors[index],
            shadows: const [
              Shadow(
                color: Colors.black54,
                offset: Offset(3, 3),
                blurRadius: 6,
              ),
              Shadow(
                color: Colors.white70,
                offset: Offset(-1, -1),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }),
    );
  }
}
