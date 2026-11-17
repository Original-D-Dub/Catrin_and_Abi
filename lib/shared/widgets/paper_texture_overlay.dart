import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const String _paperTexture = 'assets/backgrounds/paper-texture-overlay2.jpg';

/// Opacity of [_paperTexture] over the background beneath it.
const double _paperOpacity = 0.5;

/// Paints [_paperTexture] over whatever is beneath it with
/// [BlendMode.overlay] at [_paperOpacity], scaled to cover its area. Used
/// behind the content of the success overlays to give them a paper look.
///
/// When [textureOffset] is set, the texture is instead drawn at its native
/// size (never scaled), and this widget shows a window onto it: each
/// component of [textureOffset] (0–1) picks where along the image's spare
/// width/height that window sits, so several widgets given different
/// offsets each show a different patch of paper.
///
/// When [coverScreen] is true, it instead paints the whole screen — edge
/// to edge, including the safe-area insets (status bar / home indicator
/// strips) — wherever this widget sits and even outside its own bounds,
/// with the texture scaled to cover the screen. Place it where nothing
/// between it and the screen edges clips its painting.
class PaperTextureOverlay extends StatefulWidget {
  const PaperTextureOverlay({
    super.key,
    this.textureOffset,
    this.asset = _paperTexture,
    this.blendMode = BlendMode.overlay,
    this.coverScreen = false,
  });

  /// Texture image to paint; defaults to [_paperTexture].
  final String asset;

  /// How the texture blends with what's beneath it.
  final BlendMode blendMode;

  /// Paint the whole screen, safe areas included, not just this widget.
  final bool coverScreen;

  /// Fractional position (0–1 on each axis) of this widget's window onto
  /// the native-size texture. Null scales the texture to cover instead.
  final Offset? textureOffset;

  @override
  State<PaperTextureOverlay> createState() => _PaperTextureOverlayState();
}

class _PaperTextureOverlayState extends State<PaperTextureOverlay> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = info;
    });
  }, onError: (error, _) => debugPrint('Paper texture failed to load: $error'));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(PaperTextureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image?.image;
    if (image == null) return const SizedBox.shrink();
    if (widget.coverScreen) {
      // The full screen size from the view itself, unaffected by any
      // SafeArea or padding this widget sits inside.
      final view = View.of(context);
      MediaQuery.sizeOf(context); // Rebuild on rotation / resize.
      return IgnorePointer(
        child: _ScreenTexture(
          image: image,
          blendMode: widget.blendMode,
          screenSize: view.physicalSize / view.devicePixelRatio,
        ),
      );
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PaperTexturePainter(
          image,
          widget.textureOffset,
          widget.blendMode,
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  _PaperTexturePainter(this.image, this.textureOffset, this.blendMode);

  final ui.Image image;
  final Offset? textureOffset;
  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final offset = textureOffset;
    if (offset != null) {
      // Native size: shift the image so the chosen patch lands under this
      // widget, keeping the window inside the image where it fits (tiling
      // only if the widget is bigger than the image).
      final dx =
          offset.dx.clamp(0.0, 1.0) * math.max(0.0, image.width - size.width);
      final dy =
          offset.dy.clamp(0.0, 1.0) * math.max(0.0, image.height - size.height);
      final paint = Paint()
        ..shader = ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.translationValues(-dx, -dy, 0).storage,
          filterQuality: FilterQuality.medium,
        )
        ..color = Color.fromRGBO(0, 0, 0, _paperOpacity)
        ..blendMode = blendMode;
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.cover,
      blendMode: blendMode,
      opacity: _paperOpacity,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PaperTexturePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.textureOffset != textureOffset ||
      oldDelegate.blendMode != blendMode;
}

/// Fills its parent but paints the texture over the whole screen, located
/// from its own position on screen.
class _ScreenTexture extends LeafRenderObjectWidget {
  const _ScreenTexture({
    required this.image,
    required this.blendMode,
    required this.screenSize,
  });

  final ui.Image image;
  final BlendMode blendMode;
  final Size screenSize;

  @override
  _RenderScreenTexture createRenderObject(BuildContext context) =>
      _RenderScreenTexture(image, blendMode, screenSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderScreenTexture renderObject,
  ) {
    renderObject
      ..image = image
      ..blendMode = blendMode
      ..screenSize = screenSize;
  }
}

class _RenderScreenTexture extends RenderBox {
  _RenderScreenTexture(this._image, this._blendMode, this._screenSize);

  ui.Image _image;
  set image(ui.Image value) {
    if (value == _image) return;
    _image = value;
    markNeedsPaint();
  }

  BlendMode _blendMode;
  set blendMode(BlendMode value) {
    if (value == _blendMode) return;
    _blendMode = value;
    markNeedsPaint();
  }

  Size _screenSize;
  set screenSize(Size value) {
    if (value == _screenSize) return;
    _screenSize = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    // The screen's rect in this box's paint coordinates.
    final screen = (offset - localToGlobal(Offset.zero)) & _screenSize;
    paintImage(
      canvas: context.canvas,
      rect: screen,
      image: _image,
      fit: BoxFit.cover,
      blendMode: _blendMode,
      opacity: _paperOpacity,
      filterQuality: FilterQuality.medium,
    );
  }
}
