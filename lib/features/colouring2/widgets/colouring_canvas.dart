import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A canvas widget that displays a colouring image and handles tap interactions.
///
/// The canvas renders the ui.Image and forwards tap events for flood-fill
/// operations. The image is scaled to fit within the available space
/// while maintaining its aspect ratio.
///
/// Supports pinch-to-zoom and double-tap to reset zoom.
///
/// Usage:
/// ```dart
/// ColouringCanvas(
///   image: loadedImage,
///   onTap: (point) => handleTap(point),
/// )
/// ```
class ColouringCanvas extends StatefulWidget {
  /// The image to display and colour
  final ui.Image image;

  /// Callback when the canvas is tapped.
  /// Receives the tap position in display image coordinates and the display size.
  final void Function(Offset point, Size displaySize) onTap;

  const ColouringCanvas({
    super.key,
    required this.image,
    required this.onTap,
  });

  @override
  State<ColouringCanvas> createState() => _ColouringCanvasState();
}

class _ColouringCanvasState extends State<ColouringCanvas>
    with SingleTickerProviderStateMixin {
  /// Controller for managing zoom and pan transformations
  final TransformationController _transformationController =
      TransformationController();

  /// Animation controller for smooth zoom reset
  late AnimationController _animationController;

  /// Animation for zooming back to default
  Animation<Matrix4>? _zoomResetAnimation;

  /// Minimum zoom scale
  static const double _minScale = 1.0;

  /// Maximum zoom scale
  static const double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(_onAnimateReset);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Animates zoom reset on each frame
  void _onAnimateReset() {
    if (_zoomResetAnimation != null) {
      _transformationController.value = _zoomResetAnimation!.value;
    }
  }

  /// Resets zoom to default with animation
  void _resetZoom() {
    _zoomResetAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the size to fit the image within constraints
        // while maintaining aspect ratio
        final imageAspectRatio = widget.image.width / widget.image.height;
        final constraintAspectRatio =
            constraints.maxWidth / constraints.maxHeight;

        double displayWidth;
        double displayHeight;

        if (imageAspectRatio > constraintAspectRatio) {
          // Image is wider - fit to width
          displayWidth = constraints.maxWidth;
          displayHeight = constraints.maxWidth / imageAspectRatio;
        } else {
          // Image is taller - fit to height
          displayHeight = constraints.maxHeight;
          displayWidth = constraints.maxHeight * imageAspectRatio;
        }

        return Center(
          child: GestureDetector(
            onDoubleTap: _resetZoom,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              child: GestureDetector(
                onTapDown: (details) => _handleTap(
                  details,
                  displayWidth,
                  displayHeight,
                ),
                child: SizedBox(
                  width: displayWidth,
                  height: displayHeight,
                  child: CustomPaint(
                    painter: _ImagePainter(image: widget.image),
                    size: Size(displayWidth, displayHeight),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handles tap events.
  ///
  /// Because the inner [GestureDetector] sits inside the [InteractiveViewer],
  /// Flutter's hit-testing already applies the inverse transform before the
  /// event reaches the child, so [TapDownDetails.localPosition] is in the
  /// natural (unscaled) coordinate space of the [SizedBox] — i.e. display
  /// image coordinates — regardless of the current zoom level.
  void _handleTap(
    TapDownDetails details,
    double displayWidth,
    double displayHeight,
  ) {
    final pos = details.localPosition;
    if (pos.dx >= 0 &&
        pos.dx <= displayWidth &&
        pos.dy >= 0 &&
        pos.dy <= displayHeight) {
      widget.onTap(pos, Size(displayWidth, displayHeight));
    }
  }
}

/// Custom painter that renders the ui.Image to the canvas.
class _ImagePainter extends CustomPainter {
  /// The image to paint
  final ui.Image image;

  _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    // Source rectangle (entire image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Destination rectangle (fit to canvas size)
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Paint with default settings (no filtering for crisp edges)
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    // Repaint when the image changes
    return oldDelegate.image != image;
  }
}
