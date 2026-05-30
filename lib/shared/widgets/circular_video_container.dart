import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';

/// A circular video player widget that auto-plays on creation and replays on tap.
///
/// Positioned identically to the colouring-page variant:
///   Positioned(bottom: -50, right: -20, child: CircularVideoContainer(...))
/// inside a Stack(clipBehavior: Clip.none).
class CircularVideoContainer extends StatefulWidget {
  final double size;
  final String? videoAssetPath;
  final String label;
  final bool autoPlay;

  const CircularVideoContainer({
    super.key,
    required this.size,
    required this.label,
    required this.autoPlay,
    this.videoAssetPath,
  });

  @override
  State<CircularVideoContainer> createState() => _CircularVideoContainerState();
}

class _CircularVideoContainerState extends State<CircularVideoContainer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.videoAssetPath != null) {
      _loadAndPlay();
    }
  }

  @override
  void didUpdateWidget(covariant CircularVideoContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoAssetPath != widget.videoAssetPath) {
      _loadAndPlay();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isInitialized && _controller != null) {
      await _controller!.seekTo(Duration.zero);
      _controller!.play();
    } else {
      _loadAndPlay();
    }
  }

  Future<void> _loadAndPlay() async {
    final previous = _controller;
    setState(() {
      _controller = null;
      _isInitialized = false;
    });
    previous?.dispose();

    if (widget.videoAssetPath == null) return;

    final controller = VideoPlayerController.asset(widget.videoAssetPath!);
    setState(() => _controller = controller);

    await controller.initialize();

    if (!mounted || _controller != controller) {
      controller.dispose();
      return;
    }

    setState(() => _isInitialized = true);
    controller.play();
  }

  Widget _buildContent() {
    if (_isInitialized && _controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    if (_controller != null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
      );
    }
    final hasVideo = widget.videoAssetPath != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasVideo ? Icons.play_circle_outline : Icons.help_outline,
          color: hasVideo ? Colors.white70 : Colors.white38,
          size: widget.size * 0.28,
        ),
        SizedBox(height: widget.size * 0.04),
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'ComicRelief',
            fontSize: widget.size * 0.09,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.headerBackgroundLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.headerBorderDark, width: 2),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }
}
