import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A grandstand packed with a cheering, bobbing crowd, with a jumbotron on
/// top showing [message] (e.g. "Choose your racer!").
///
/// The crowd stays still when the device asks for reduced motion.
class RaceGrandstand extends StatefulWidget {
  /// Text shown on the jumbotron screen.
  final String message;

  const RaceGrandstand({super.key, required this.message});

  static const double _postHeight = 14;

  static bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600;

  /// Height of the stand itself (awning, crowd and railing), below the
  /// jumbotron and its posts.
  static double standHeightFor(BuildContext context) =>
      _isWide(context) ? 190.0 : 140.0;

  /// Total height: jumbotron, posts and stand.
  static double heightFor(BuildContext context) =>
      _Jumbotron.heightFor(_isWide(context)) +
      _postHeight +
      standHeightFor(context);

  @override
  State<RaceGrandstand> createState() => _RaceGrandstandState();
}

class _RaceGrandstandState extends State<RaceGrandstand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cheer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _cheer.stop();
    } else if (!_cheer.isAnimating) {
      _cheer.repeat();
    }
  }

  @override
  void dispose() {
    _cheer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = RaceGrandstand._isWide(context);
    final standHeight = RaceGrandstand.standHeightFor(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Jumbotron(message: widget.message, isWide: isWide),
        // Two support posts running down into the stand's roof.
        SizedBox(
          height: RaceGrandstand._postHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [_Post(), SizedBox(width: 120), _Post()],
          ),
        ),
        SizedBox(
          height: standHeight,
          width: double.infinity,
          child: CustomPaint(painter: _GrandstandPainter(_cheer)),
        ),
      ],
    );
  }
}

class _Post extends StatelessWidget {
  const _Post();

  @override
  Widget build(BuildContext context) =>
      Container(width: 10, color: const Color(0xFF455A64));
}

// ── Jumbotron ───────────────────────────────────────────────────────────────

class _Jumbotron extends StatelessWidget {
  final String message;
  final bool isWide;

  const _Jumbotron({required this.message, required this.isWide});

  static const _frame = Color(0xFF263238);
  static const _screen = Color(0xFF0B1A10);
  static const _led = Color(0xFFFFD54A);

  static const double _framePadding = 8;
  static const double _frameBorder = 3;

  static double _screenHeight(bool isWide) => isWide ? 96 : 68;

  /// Height of the whole jumbotron: screen, frame padding and border.
  static double heightFor(bool isWide) =>
      _screenHeight(isWide) + 2 * (_framePadding + _frameBorder);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isWide ? 560 : 340),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(_framePadding),
      decoration: BoxDecoration(
        color: _frame,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF546E7A), width: _frameBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Container(
        height: _screenHeight(isWide),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _screen,
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          // Faint LED grid behind the text.
          painter: _LedGridPainter(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                message,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: isWide ? 44 : 30,
                  fontWeight: FontWeight.w800,
                  color: _led,
                  shadows: const [
                    Shadow(color: Color(0xCCFFB300), blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const step = 5.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Stand and crowd ───────────────────────────────────────────────────────

class _GrandstandPainter extends CustomPainter {
  final Animation<double> cheer;

  _GrandstandPainter(this.cheer) : super(repaint: cheer);

  static const _rows = 4;
  static const _roofHeight = 14.0;
  static const _railHeight = 16.0;

  static const _shirts = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFF00ACC1),
    Color(0xFFEC407A),
    Colors.white,
  ];
  static const _skins = [
    Color(0xFFFFDBAC),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF5C3A1E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Roof canopy, striped like a racecourse awning.
    const stripe = 24.0;
    for (var x = 0.0, i = 0; x < w; x += stripe, i++) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, stripe, _roofHeight),
        Paint()..color = i.isEven ? AppColors.catrinBlue : Colors.white,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, _roofHeight, w, 3),
      Paint()..color = const Color(0xFF37474F),
    );

    // Back wall of the stand.
    final standTop = _roofHeight + 3;
    final standBottom = h - _railHeight;
    canvas.drawRect(
      Rect.fromLTRB(0, standTop, w, standBottom),
      Paint()..color = const Color(0xFF78909C),
    );

    // Tiers, back (top) to front (bottom), so front rows overlap.
    final rowHeight = (standBottom - standTop) / _rows;
    final t = cheer.value * 2 * pi;
    for (var row = 0; row < _rows; row++) {
      final seatY = standTop + rowHeight * (row + 1);
      // Step / seat strip for this tier.
      canvas.drawRect(
        Rect.fromLTWH(0, seatY - 6, w, 6),
        Paint()
          ..color = row.isEven
              ? const Color(0xFF546E7A)
              : const Color(0xFF607D8B),
      );
      _paintCrowdRow(canvas, w, seatY - 6, rowHeight, row, t);
    }

    // Front railing with posts.
    final railTop = standBottom;
    canvas.drawRect(
      Rect.fromLTWH(0, railTop, w, _railHeight),
      Paint()..color = const Color(0xFFECEFF1),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, railTop, w, 4),
      Paint()..color = AppColors.catrinBlue,
    );
    final postPaint = Paint()..color = const Color(0xFFB0BEC5);
    for (var x = 12.0; x < w; x += 40) {
      canvas.drawRect(
        Rect.fromLTWH(x, railTop + 4, 3, _railHeight - 4),
        postPaint,
      );
    }
  }

  /// One row of spectators sitting on the seat at [seatY]. Colours and
  /// positions come from a seeded [Random], so they stay put between frames;
  /// only the bounce changes.
  void _paintCrowdRow(
    Canvas canvas,
    double width,
    double seatY,
    double rowHeight,
    int row,
    double t,
  ) {
    final random = Random(17 + row * 31);
    final scale = (rowHeight / 34).clamp(0.6, 1.4);
    final spacing = 20.0 * scale;
    final headRadius = 5.5 * scale;
    final bodyW = 13.0 * scale;
    final bodyH = 12.0 * scale;
    // Offset alternate rows so heads don't line up in columns.
    var x = (row.isEven ? 0.4 : 0.9) * spacing;
    while (x < width + spacing) {
      final jitter = (random.nextDouble() - 0.5) * spacing * 0.3;
      final shirt = _shirts[random.nextInt(_shirts.length)];
      final skin = _skins[random.nextInt(_skins.length)];
      final phase = random.nextDouble() * 2 * pi;
      final cheersHard = random.nextDouble() < 0.35;
      // Bounce: only ever upwards, from sitting.
      final bounce = max(0.0, sin(t + phase)) * (cheersHard ? 6 : 3) * scale;
      final cx = x + jitter;
      final bodyBottom = seatY - bounce;
      final bodyRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - bodyW / 2, bodyBottom - bodyH, bodyW, bodyH),
        topLeft: Radius.circular(bodyW / 2),
        topRight: Radius.circular(bodyW / 2),
      );
      final headCentre = Offset(cx, bodyBottom - bodyH - headRadius + 1);

      // Arms up for the keenest fans when they're high in their bounce.
      if (cheersHard && bounce > 3 * scale) {
        final arm = Paint()
          ..color = skin
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round;
        final shoulderY = bodyBottom - bodyH + 3 * scale;
        canvas.drawLine(
          Offset(cx - bodyW / 2 + 1, shoulderY),
          Offset(cx - bodyW / 2 - 3 * scale, shoulderY - 12 * scale),
          arm,
        );
        canvas.drawLine(
          Offset(cx + bodyW / 2 - 1, shoulderY),
          Offset(cx + bodyW / 2 + 3 * scale, shoulderY - 12 * scale),
          arm,
        );
      }

      canvas.drawRRect(bodyRect, Paint()..color = shirt);
      canvas.drawCircle(headCentre, headRadius, Paint()..color = skin);
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _GrandstandPainter oldDelegate) =>
      oldDelegate.cheer != cheer;
}
