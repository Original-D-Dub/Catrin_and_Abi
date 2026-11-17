import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../services/audio_service.dart';
import 'button.dart';

/// In-game instruction bubble (e.g. "tap the first card"), styled as a
/// purple felt patch — the same gradient bevel, fuzz texture, stitching
/// (8px in from the edge) and drop shadow as [MasterButton].
///
/// Plays the `<audioGameId>_<messageKey>` instruction clip when shown, and
/// again (re-showing the bubble if it had faded) whenever [text] changes.
/// A "got it" link calls [onDismiss], which callers use to persist that the
/// instructions shouldn't be shown again; [InstructionBubbleState.dismiss]
/// does the same programmatically (e.g. once the player has shown they know
/// how to play).
///
/// Used by Card Match and Letter Bingo.
class InstructionBubble extends StatefulWidget {
  final String text;

  /// The gameId prefix passed to [AudioService.playInstructionClipAndWait].
  final String audioGameId;

  /// Identifies which prompt [text] is, e.g. `'tap_first'` or
  /// `'tap_second'` — the instruction clip name.
  final String messageKey;

  final String dismissLabel;
  final String locale;

  /// Called when the bubble is dismissed for good.
  final VoidCallback onDismiss;

  /// Called with [messageKey] once the clip played for [text] finishes.
  final void Function(String messageKey)? onAudioComplete;

  /// When set, the bubble fades out this long after it's shown (or after
  /// [text] last changed) without calling [onDismiss]. Null keeps it up
  /// until dismissed.
  final Duration? autoHideAfter;

  const InstructionBubble({
    super.key,
    required this.text,
    required this.audioGameId,
    required this.messageKey,
    required this.dismissLabel,
    required this.locale,
    required this.onDismiss,
    this.onAudioComplete,
    this.autoHideAfter,
  });

  @override
  State<InstructionBubble> createState() => InstructionBubbleState();
}

class InstructionBubbleState extends State<InstructionBubble> {
  static const _fadeDuration = Duration(milliseconds: 300);
  static const _colour = AppColors.accentPurple;
  static final _fill = ButtonFill.fromColour(_colour);

  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _playMessageAudio();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(InstructionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() => _visible = true);
      _playMessageAudio();
      _scheduleHide();
    }
  }

  Future<void> _playMessageAudio() async {
    final messageKey = widget.messageKey;
    await AudioService.playInstructionClipAndWait(
      widget.audioGameId,
      messageKey,
      locale: widget.locale,
    );
    widget.onAudioComplete?.call(messageKey);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final delay = widget.autoHideAfter;
    if (delay == null) return;
    _hideTimer = Timer(delay, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  /// Fades the bubble out and calls [InstructionBubble.onDismiss].
  void dismiss() {
    _hideTimer?.cancel();
    setState(() => _visible = false);
    widget.onDismiss();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: _fadeDuration,
      child: Container(
        width: isWideScreen ? 320 : 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FeltPanel(
          gradient: _fill.gradient,
          stitchColour: ButtonFill.strokeFor(_colour),
          child: Padding(
            // Clear of the stitching, which sits 8px inside the edge.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  fit: StackFit.passthrough,
                  children: [
                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1
                          ..color = const Color(0xFF0F57DD),
                      ),
                    ),
                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.dismissLabel,
                            style: const TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.thumb_up,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
