import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The BSL question video container for the zoo quiz.
///
/// Sizing per design: 4:3 aspect ratio, 20px margin either side, at most
/// 560px wide, with a 16px corner radius. The video auto-plays and loops
/// [_autoPlayLoops] times; once it finishes the container shrinks to a
/// 120px-wide thumbnail pinned to the bottom left of the screen, so the
/// player can retrigger it as a reminder while they walk to the animal.
/// Tapping the video (full size or thumbnail) replays it from the start
/// and grows it back to full size. The 44x44 close button (full size
/// only — the thumbnail is too small for it, and tapping the thumbnail
/// itself already grows the video back) shrinks it to the thumbnail
/// immediately, the same as it does once playback finishes.
///
/// The question videos are still to be recorded, so a missing/unloadable
/// asset falls back to a neutral placeholder (a play icon and
/// [placeholderLabel]) which auto-shrinks to the thumbnail after
/// [_placeholderShrinkDelay], standing in for the loop-twice-then-shrink
/// timing real footage will drive once it's recorded.
///
/// [placeholderLabel] is currently set to the answer itself (see call
/// sites) for testing while there's no sign video to convey it — swap it
/// back to a neutral "watch the sign" label once real footage lands.
class BslQuestionVideo extends StatefulWidget {
  /// Asset path of the question's BSL video, or null while none exists.
  final String? videoAssetPath;

  /// Text shown on the placeholder while there is no playable video.
  final String placeholderLabel;

  const BslQuestionVideo({
    super.key,
    required this.videoAssetPath,
    required this.placeholderLabel,
  });

  @override
  State<BslQuestionVideo> createState() => _BslQuestionVideoState();
}

class _BslQuestionVideoState extends State<BslQuestionVideo> {
  /// How many times the question video auto-plays before shrinking to the
  /// reminder thumbnail.
  static const int _autoPlayLoops = 2;

  /// How long the no-video placeholder stays full size before auto-
  /// shrinking, standing in for real playback until footage is recorded.
  static const Duration _placeholderShrinkDelay = Duration(seconds: 3);

  static const double _maxFullWidth = 560;
  static const double _thumbnailWidth = 120;
  static const double _aspectRatio = 4 / 3;
  static const Duration _transitionDuration = Duration(milliseconds: 400);

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _loadFailed = false;
  int _playCount = 0;
  bool _shrunk = false;
  Timer? _placeholderShrinkTimer;

  @override
  void initState() {
    super.initState();
    _loadAndPlay();
  }

  @override
  void didUpdateWidget(covariant BslQuestionVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoAssetPath != widget.videoAssetPath) {
      _loadAndPlay();
    }
  }

  @override
  void dispose() {
    _placeholderShrinkTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  /// Watches playback for the end of a loop: replays while under
  /// [_autoPlayLoops], otherwise shrinks to the reminder thumbnail.
  void _onVideoTick() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.duration > Duration.zero &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _playCount++;
      if (_playCount < _autoPlayLoops) {
        controller.seekTo(Duration.zero);
        controller.play();
      } else if (mounted) {
        setState(() => _shrunk = true);
      }
    }
  }

  Future<void> _onTap() async {
    final controller = _controller;
    if (_isInitialized && controller != null) {
      _playCount = 0;
      if (_shrunk) setState(() => _shrunk = false);
      await controller.seekTo(Duration.zero);
      controller.play();
    } else {
      _loadAndPlay();
    }
  }

  /// Shrinks to the reminder thumbnail immediately — the close button's
  /// action, and also what the 3-second placeholder fallback triggers.
  void _shrinkToThumbnail() {
    _placeholderShrinkTimer?.cancel();
    _controller?.pause();
    if (!_shrunk) setState(() => _shrunk = true);
  }

  /// Starts (replacing any previous) the fallback timer that shrinks the
  /// no-video placeholder after [_placeholderShrinkDelay], standing in
  /// for real playback until the question video is recorded.
  void _schedulePlaceholderShrink() {
    _placeholderShrinkTimer?.cancel();
    _placeholderShrinkTimer = Timer(_placeholderShrinkDelay, () {
      if (mounted) setState(() => _shrunk = true);
    });
  }

  Future<void> _loadAndPlay() async {
    _placeholderShrinkTimer?.cancel();
    final previous = _controller;
    previous?.removeListener(_onVideoTick);
    setState(() {
      _controller = null;
      _isInitialized = false;
      _loadFailed = false;
      _playCount = 0;
      _shrunk = false;
    });
    previous?.dispose();

    final path = widget.videoAssetPath;
    if (path == null) {
      _schedulePlaceholderShrink();
      return;
    }

    final controller = VideoPlayerController.asset(path);
    setState(() => _controller = controller);

    try {
      await controller.initialize();
    } catch (_) {
      // Video not recorded/bundled yet — show the placeholder, and
      // auto-shrink it after a delay standing in for real playback.
      controller.dispose();
      if (mounted && _controller == controller) {
        setState(() {
          _controller = null;
          _loadFailed = true;
        });
        _schedulePlaceholderShrink();
      }
      return;
    }

    if (!mounted || _controller != controller) {
      controller.dispose();
      return;
    }

    controller.addListener(_onVideoTick);
    setState(() => _isInitialized = true);
    controller.play();
  }

  Widget _buildContent() {
    final controller = _controller;
    if (_isInitialized && controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    if (controller != null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
      );
    }
    // Shrunk: the icon+label placeholder below doesn't fit the
    // thumbnail — just the icon, small.
    if (_shrunk) {
      return Center(
        child: Icon(
          widget.videoAssetPath == null || _loadFailed
              ? Icons.videocam_off_outlined
              : Icons.play_circle_outline,
          color: Colors.white54,
          size: 28,
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.videoAssetPath == null || _loadFailed
              ? Icons.videocam_off_outlined
              : Icons.play_circle_outline,
          color: Colors.white54,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          widget.placeholderLabel,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ComicRelief',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// The decorated video box plus its close button, shared by both the
  /// full-size and thumbnail layouts.
  Widget _buildBox() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildContent(),
            ),
          ),
        ),
        // Hidden once shrunk — the thumbnail is too small for it, and
        // tapping the thumbnail itself already grows the video back.
        if (!_shrunk)
          Positioned(
            top: -14,
            right: -14,
            child: _CloseButton(onTap: _shrinkToThumbnail),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // In portrait the full-size video sits below the header bar (its
    // fixed 88px height plus the safe-area inset, and a margin); in
    // landscape there's no header to clear at the top, so it's anchored
    // to the bottom-right corner of the window instead — clearing enough
    // space above the Take a Picture button (also bottom-right) that the
    // two never overlap.
    final topClearance = MediaQuery.of(context).padding.top + 88 + 20;
    const cameraButtonClearance = 112.0;

    final EdgeInsets padding;
    final Alignment alignment;
    if (_shrunk) {
      // The thumbnail stays bottom-left regardless of orientation — it's
      // small enough to never reach the bottom-right camera button.
      padding = const EdgeInsets.fromLTRB(16, 0, 0, 16);
      alignment = Alignment.bottomLeft;
    } else if (isPortrait) {
      padding = EdgeInsets.fromLTRB(20, topClearance, 20, 0);
      alignment = Alignment.topCenter;
    } else {
      padding = const EdgeInsets.fromLTRB(0, 0, 20, cameraButtonClearance);
      alignment = Alignment.bottomRight;
    }

    return AnimatedPadding(
      duration: _transitionDuration,
      curve: Curves.easeInOut,
      padding: padding,
      child: AnimatedAlign(
        duration: _transitionDuration,
        curve: Curves.easeInOut,
        alignment: alignment,
        child: AnimatedSize(
          duration: _transitionDuration,
          curve: Curves.easeInOut,
          clipBehavior: Clip.none,
          child: _shrunk
              ? SizedBox(
                  width: _thumbnailWidth,
                  height: _thumbnailWidth / _aspectRatio,
                  child: _buildBox(),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxFullWidth),
                  child: AspectRatio(
                    aspectRatio: _aspectRatio,
                    child: _buildBox(),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A 44x44 close button hung over the top-right corner of the video
/// container, sized generously for small fingers regardless of how small
/// the container itself has shrunk to.
class _CloseButton extends StatelessWidget {
  static const double _size = 44;

  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: _size,
          height: _size,
          child: Icon(Icons.close, color: Colors.black87, size: 26),
        ),
      ),
    );
  }
}
