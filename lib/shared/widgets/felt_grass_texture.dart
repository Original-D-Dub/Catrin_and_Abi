import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';

/// Tiles the felt grass texture over whatever is beneath it with
/// [BlendMode.overlay], one texture pixel per device pixel so it stays
/// sharp on any screen. The texture is centred on mid-grey, so it adds
/// felt grain without lightening or darkening the hill colours overall.
class FeltGrassTexture extends StatefulWidget {
  const FeltGrassTexture({super.key});

  static const _grassTexture =
      'assets/games/bubble_shooter/background/grass_felt.jpg';

  @override
  State<FeltGrassTexture> createState() => _FeltGrassTextureState();
}

class _FeltGrassTextureState extends State<FeltGrassTexture> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = info;
    });
  }, onError: (error, _) => debugPrint('Grass texture failed to load: $error'));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      FeltGrassTexture._grassTexture,
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
    return CustomPaint(
      painter: _FeltGrassTexturePainter(
        image,
        1 / MediaQuery.devicePixelRatioOf(context),
      ),
    );
  }
}

class _FeltGrassTexturePainter extends CustomPainter {
  _FeltGrassTexturePainter(this.image, this.scale);

  final ui.Image image;

  /// Logical pixels per texture pixel.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.overlay
        ..filterQuality = FilterQuality.medium
        ..shader = ImageShader(
          image,
          TileMode.mirror,
          TileMode.mirror,
          Matrix4.diagonal3Values(scale, scale, 1).storage,
        ),
    );
  }

  @override
  bool shouldRepaint(_FeltGrassTexturePainter old) => old.image != image;
}
