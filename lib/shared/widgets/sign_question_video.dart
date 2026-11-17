import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_sizes.dart';

/// Plays a BSL question video once, reports when it has been watched (or
/// after 4 seconds, whichever is first), then keeps looping it.
///
/// Callers typically hide the answer buttons until [onPlayedOnce] fires.
/// When [videoAssetPath] is null or playback fails, [onPlayedOnce] fires
/// straight away so the player is never stranded behind hidden buttons.
/// Give each question its own [key] so the video restarts per question.
class SignQuestionVideo extends StatefulWidget {
  final String? videoAssetPath;
  final VoidCallback? onPlayedOnce;

  const SignQuestionVideo({
    super.key,
    required this.videoAssetPath,
    this.onPlayedOnce,
  });

  @override
  State<SignQuestionVideo> createState() => _SignQuestionVideoState();
}

class _SignQuestionVideoState extends State<SignQuestionVideo> {
  VideoPlayerController? _controller;
  bool _hasPlayedOnce = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final path = widget.videoAssetPath;
    if (path == null) {
      // No video for this item — nothing to wait for, so unlock immediately.
      _hasPlayedOnce = true;
      widget.onPlayedOnce?.call();
      return;
    }

    final controller = VideoPlayerController.asset(path);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      // Play once, unlooped, so completion can be detected — then switch
      // to looping once the caller has been notified of the first playthrough.
      controller.addListener(_onVideoTick);
      await controller.play();
      setState(() => _controller = controller);
      // Reveal the answers after 4 seconds rather than waiting for the whole
      // video; it carries on looping underneath.
      _revealTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _hasPlayedOnce) return;
        _hasPlayedOnce = true;
        widget.onPlayedOnce?.call();
        _controller?.setLooping(true);
      });
    } catch (_) {
      controller.dispose();
      // Playback failed — don't strand the player behind hidden buttons.
      _hasPlayedOnce = true;
      widget.onPlayedOnce?.call();
    }
  }

  void _onVideoTick() {
    if (_hasPlayedOnce) return;
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _hasPlayedOnce = true;
      widget.onPlayedOnce?.call();
      _controller?.setLooping(true);
      _controller?.seekTo(Duration.zero);
      _controller?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: controller != null && controller.value.isInitialized
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          : const Center(
              child: Icon(
                Icons.videocam_off_outlined,
                color: Colors.white30,
                size: 32,
              ),
            ),
    );
  }
}
