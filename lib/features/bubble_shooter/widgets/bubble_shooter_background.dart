import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const String _dir = 'assets/games/bubble_shooter/background';

/// Felt landscape behind the bubble shooter board: a blue felt sky, two
/// rolling felt hills, a small tree on the left, a large tree cut off by the
/// right edge and daffodils in the bottom-right corner.
///
/// Everything is laid out in fractions of the board's width, measured up
/// from the bottom, so the scene keeps its shape on any board size. The
/// decorations stay in the bottom corners, outside the reach of the cannon
/// (its body and barrel at every aim angle sit within about 0.38 × width of
/// its centre), leaving the middle of the board clear for the bubbles.
class BubbleShooterBackground extends StatelessWidget {
  const BubbleShooterBackground({super.key});

  // Hill heights above the bottom edge (fractions of width) at the left
  // edge, the peak and the right edge, with the peak's x position.
  static const _backHill = (left: 0.40, peakX: 0.55, peak: 0.45, right: 0.40);
  static const _frontHill = (left: 0.28, peakX: 0.3, peak: 0.31, right: 0.30);

  static const backHillColour = Color(0xFFB5D530);
  static const frontHillColour = Color(0xFF65A94F);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // [left] and [bottom] in fractions of w; [width] likewise.
        Widget placed(
          String asset, {
          required double left,
          required double bottom,
          required double width,
        }) {
          return Positioned(
            left: left * w,
            bottom: bottom * w,
            width: width * w,
            child: Image.asset('$_dir/$asset', fit: BoxFit.contain),
          );
        }

        final hills = [_hillPath(_backHill, w, h), _hillPath(_frontHill, w, h)];

        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.asset(
                  '$_dir/sky_felt.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              placed('tree_small.png', left: -0.02, bottom: 0.37, width: 0.21),
              Positioned.fill(
                child: CustomPaint(
                  painter: _HillsPainter(hills, [
                    backHillColour,
                    frontHillColour,
                  ]),
                ),
              ),
              // Felt texture over both hills.
              for (final hill in hills)
                Positioned.fill(
                  child: ClipPath(
                    clipper: _PathClipper(hill),
                    child: const GrassTexture(),
                  ),
                ),
              placed('tree_large.png', left: 0.82, bottom: 0.26, width: 0.36),
              placed('daffodils.png', left: 0.86, bottom: -0.02, width: 0.2),
            ],
          ),
        );
      },
    );
  }

  /// Closed path for a hill running from the left edge, over its peak, to
  /// the right edge, then down to the bottom of the board.
  static Path _hillPath(
    ({double left, double peakX, double peak, double right}) hill,
    double w,
    double h,
  ) {
    double y(double fraction) => h - fraction * w;
    return Path()
      ..moveTo(0, h)
      ..lineTo(0, y(hill.left))
      ..quadraticBezierTo(
        hill.peakX * w * 0.5,
        y(hill.peak),
        hill.peakX * w,
        y(hill.peak),
      )
      ..quadraticBezierTo(
        (1 + hill.peakX) * w * 0.5,
        y(hill.peak),
        w,
        y(hill.right),
      )
      ..lineTo(w, h)
      ..close();
  }
}

/// Tiles the felt grass texture over whatever is beneath it with
/// [BlendMode.overlay], one texture pixel per device pixel so it stays sharp
/// on any screen. The texture is centred on mid-grey, so it adds felt grain
/// without lightening or darkening the hill colours overall.
class GrassTexture extends StatefulWidget {
  const GrassTexture({super.key});

  static const _grassTexture = '$_dir/grass_felt.jpg';

  @override
  State<GrassTexture> createState() => _GrassTextureState();
}

class _GrassTextureState extends State<GrassTexture> {
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
      GrassTexture._grassTexture,
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
      painter: _GrassTexturePainter(
        image,
        1 / MediaQuery.devicePixelRatioOf(context),
      ),
    );
  }
}

class _GrassTexturePainter extends CustomPainter {
  _GrassTexturePainter(this.image, this.scale);

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
  bool shouldRepaint(_GrassTexturePainter old) =>
      old.image != image || old.scale != scale;
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.hills, this.colours);

  final List<Path> hills;
  final List<Color> colours;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < hills.length; i++) {
      canvas.drawPath(hills[i], Paint()..color = colours[i]);
    }
  }

  @override
  bool shouldRepaint(_HillsPainter old) => old.hills != hills;
}

class _PathClipper extends CustomClipper<Path> {
  _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}
