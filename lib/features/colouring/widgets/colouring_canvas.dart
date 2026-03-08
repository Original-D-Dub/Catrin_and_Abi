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

  /// Callback when the canvas is tapped
  /// Receives the tap position in widget coordinates
  final ValueChanged<Offset> onTap;

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
                  constraints,
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

  /// Handles tap events, accounting for zoom transformation
  void _handleTap(
    TapDownDetails details,
    BoxConstraints constraints,
    double displayWidth,
    double displayHeight,
  ) {
    // Get the current transformation matrix
    final matrix = _transformationController.value;

    // Convert global position to local position within the canvas
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Calculate offset to center of displayed image
    final offsetX = (constraints.maxWidth - displayWidth) / 2;
    final offsetY = (constraints.maxHeight - displayHeight) / 2;

    // Apply inverse transformation to get position in image coordinates
    final invertedMatrix = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(
      invertedMatrix,
      localPosition,
    );

    // Adjust for centering
    final adjustedPosition = Offset(
      transformedPoint.dx - offsetX,
      transformedPoint.dy - offsetY,
    );

    // Only forward tap if within the image bounds
    if (adjustedPosition.dx >= 0 &&
        adjustedPosition.dx <= displayWidth &&
        adjustedPosition.dy >= 0 &&
        adjustedPosition.dy <= displayHeight) {
      widget.onTap(adjustedPosition);
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
