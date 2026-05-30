import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/asset_paths.dart';
import '../services/audio_service.dart';

/// Full-screen intro shown when a timed game starts.
///
/// Phase 1 – Instruction: radial-gradient screen with the instruction text in
///   a speech bubble and Catrin as the speaker character.
/// Phase 2 – Countdown: 3 → 2 → 1 → Go! with elastic animation and TTS.
/// [onComplete] is called after "Go!" finishes.
class GameIntroCountdown extends StatefulWidget {
  final String gameId;
  final VoidCallback onComplete;

  /// Asset path for the character shown below the speech bubble.
  /// Defaults to Catrin when not specified.
  final String? characterImage;

  const GameIntroCountdown({
    super.key,
    required this.gameId,
    required this.onComplete,
    this.characterImage,
  });

  @override
  State<GameIntroCountdown> createState() => _GameIntroCountdownState();
}

enum _Phase { instruction, countdown }

class _GameIntroCountdownState extends State<GameIntroCountdown> {
  _Phase _phase = _Phase.instruction;
  double _instructionOpacity = 1.0;
  int _countdownValue = 3;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    // Play intro audio in the background; the player triggers
    // the countdown by tapping Play.
    AudioService.playIntro(widget.gameId);
  }

  @override
  void dispose() {
    _cancelled = true;
    AudioService.stopTts();
    super.dispose();
  }

  Future<void> _onPlayTapped() async {
    if (_cancelled) return;
    await AudioService.stopAll();
    _runCountdown();
  }

  Future<void> _runCountdown() async {
    setState(() => _instructionOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _cancelled) return;

    setState(() => _phase = _Phase.countdown);

    for (int i = 3; i >= 1; i--) {
      if (!mounted || _cancelled) return;
      setState(() => _countdownValue = i);
      await Future.wait([
        AudioService.playSpeechMp3('$i'),
        Future.delayed(const Duration(seconds: 1)),
      ]);
    }

    if (!mounted || _cancelled) return;
    setState(() => _countdownValue = 0);
    await Future.wait([
      AudioService.playSpeechMp3('Go'),
      Future.delayed(const Duration(milliseconds: 600)),
    ]);

    if (!mounted || _cancelled) return;
    widget.onComplete();
  }

  static const _bgGradient = RadialGradient(
    colors: [Color(0xFF3A6FD1), Color(0xFF041F50)],
    radius: 0.85,
  );

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    return Positioned.fill(
      child: Stack(
        children: [
          // Background — 75% opaque during countdown so the game shows through
          Opacity(
            opacity: _phase == _Phase.countdown ? 0.75 : 1.0,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: _bgGradient),
              child: SizedBox.expand(),
            ),
          ),
          // Content — always fully opaque
          SafeArea(
            child: _phase == _Phase.instruction
                ? _buildInstruction(localizer)
                : _buildCountdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(AppLocalizations localizer) {
    return AnimatedOpacity(
      opacity: _instructionOpacity,
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Speech bubble — hugs the text vertically ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomPaint(
                  painter: _SpeechBubblePainter(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        32, 32, 32, 32 + _SpeechBubblePainter._dTipY),
                    child: Text(
                      localizer('${widget.gameId}.intro'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002D97),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Character + ground shadow — fills remaining space ──────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      widget.characterImage ?? AssetPaths.catrinDefault,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: CustomPaint(
                      size: Size(240, 32),
                      painter: _GroundShadowPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Play button ────────────────────────────────────────────────
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: _onPlayTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20A754),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicRelief',
                  ),
                ),
                child: Text(localizer('general.play')),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final localizer = AppLocalizations.of(context);
    final isGo = _countdownValue == 0;
    final label = isGo ? localizer('general.go') : '$_countdownValue';
    final color = isGo ? const Color(0xFF43A047) : Colors.white;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        ),
        child: Text(
          label,
          key: ValueKey(label),
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 140,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: const [
              Shadow(blurRadius: 30, color: Colors.black54, offset: Offset(0, 4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speech bubble painter
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a speech-bubble shape:
/// - topLeft corner radius 48 px, bottomRight 48 px
/// - topRight corner radius 24 px, bottomLeft 24 px
/// - Diamond tail at the bottom-left edge, pointing down
/// - 4 px #3A6FD1 border
class _SpeechBubblePainter extends CustomPainter {
  static const _borderColor = Color(0xFF3A6FD1);
  static const _fillColor = Colors.white;

  // Per-corner radii
  static const double _tl = 48;
  static const double _tr = 24;
  static const double _br = 48;
  static const double _bl = 24;

  // Diamond tail dimensions
  static const double _dLeft = 48;   // left base point x
  static const double _dRight = 96;  // right base point x
  static const double _dTipX = 64;   // tip x
  static const double _dTipY = 32;   // how far tip protrudes below bubble

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(
      path,
      Paint()
        ..color = _fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _buildPath(Size s) {
    final w = s.width;
    // Bubble body occupies the top portion; the diamond tip lands at s.height.
    final h = s.height - _dTipY;

    return Path()
      ..moveTo(_tl, 0)
      ..lineTo(w - _tr, 0)
      ..quadraticBezierTo(w, 0, w, _tr)
      ..lineTo(w, h - _br)
      ..quadraticBezierTo(w, h, w - _br, h)
      ..lineTo(w - _dLeft, h)
      ..lineTo(w - _dTipX, h + _dTipY) // diamond tip at s.height
      ..lineTo(w - _dRight, h)
      ..lineTo(_bl, h)
      ..quadraticBezierTo(0, h, 0, h - _bl)
      ..lineTo(0, _tl)
      ..quadraticBezierTo(0, 0, _tl, 0)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ground shadow painter
// ─────────────────────────────────────────────────────────────────────────────

/// Elliptical radial gradient shadow beneath the character's feet.
///
/// Paints a circle in a y-scaled coordinate space so the circular radial
/// gradient maps to a true ellipse in screen space — opaque #031840 at the
/// centre, fully transparent at the edge.
class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    // Squish the y-axis so a circle becomes an ellipse matching [size]
    canvas.scale(1.0, size.height / size.width);

    final center = Offset(size.width / 2, size.width / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF031840), Color(0x00031840)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter old) => false;
}
