import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/game_filters.dart' show SignSystem;
import '../../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/game_instructions_service.dart';
import 'button.dart';

/// Full-screen intro shown when a timed game starts.
///
/// Phase 1 – Instruction: radial-gradient screen with the instruction text in
///   a speech bubble and Catrin as the speaker character.
/// Phase 2 – Countdown: 3 → 2 → 1 → Go! with elastic animation and MP3 audio.
/// [onComplete] is called after "Go!" finishes.
class GameIntroCountdown extends StatefulWidget {
  final String gameId;
  final VoidCallback onComplete;

  /// Called when the back button is tapped, to return to the level select
  /// screen instead of starting the countdown.
  final VoidCallback onBack;

  /// Asset path for the character shown below the speech bubble.
  /// Defaults to Catrin when not specified.
  final String? characterImage;

  /// UI locale ('en' or 'cy') used to look up the instruction text.
  final String locale;

  /// Background image asset path. Defaults to the blue radial gradient
  /// when not specified.
  final String? backgroundImage;

  /// Heading text shown above the speech bubble, in large LuckiestGuy type.
  /// Omitted when not specified.
  final String? topText;

  /// When true, replaces the tailed speech bubble with a plain rounded
  /// rectangle placed directly below the character image (no gap), instead
  /// of above it with a pointing tail.
  final bool roundedBubble;

  /// Level number announced via [AudioService.playLevelName] in place of
  /// the instruction screen when a returning player has already seen it.
  final int levelNumber;

  /// Base game id used for that level-name lookup, when it differs from
  /// [gameId] — e.g. games whose [gameId] embeds a level suffix or a
  /// sign-system-specific prefix for the intro/title clips (which
  /// [AudioService.playLevelName] doesn't use). Defaults to [gameId].
  final String? levelNameGameId;

  /// Sign system passed through to [AudioService.playLevelName]'s BSL/IAC
  /// audio lookup. Defaults to null (single-sign-system games).
  final SignSystem? signSystem;

  const GameIntroCountdown({
    super.key,
    required this.gameId,
    required this.onComplete,
    required this.onBack,
    required this.levelNumber,
    this.characterImage,
    this.locale = 'en',
    this.backgroundImage,
    this.topText,
    this.roundedBubble = false,
    this.levelNameGameId,
    this.signSystem,
  });

  @override
  State<GameIntroCountdown> createState() => _GameIntroCountdownState();
}

enum _Phase { checking, instruction, countdown }

class _GameIntroCountdownState extends State<GameIntroCountdown> {
  _Phase _phase = _Phase.checking;
  double _instructionOpacity = 1.0;
  int _countdownValue = 3;
  bool _cancelled = false;

  final _instructionsService = GameInstructionsService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Shows the instruction screen only on the player's first play of
  /// [GameIntroCountdown.gameId]; on repeat plays it skips straight to the
  /// title-then-countdown flow.
  Future<void> _init() async {
    final seen = await _instructionsService.hasSeenInstructions(widget.gameId);
    if (!mounted || _cancelled) return;
    if (seen) {
      _runReturningFlow();
    } else {
      setState(() => _phase = _Phase.instruction);
      // Play intro audio in the background; the player triggers
      // the countdown by tapping Play.
      AudioService.playIntro(widget.gameId, locale: widget.locale);
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    AudioService.stopAll();
    super.dispose();
  }

  Future<void> _onPlayTapped() async {
    if (_cancelled) return;
    await AudioService.stopAll();
    _instructionsService.markInstructionsSeen(widget.gameId);
    setState(() => _instructionOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _cancelled) return;
    _runCountdownLoop();
  }

  Future<void> _onBackTapped() async {
    if (_cancelled) return;
    await AudioService.stopAll();
    widget.onBack();
  }

  /// Skips the instruction screen for a returning player: announces the
  /// level name, gives it 1.5s to play, then runs the normal countdown.
  Future<void> _runReturningFlow() async {
    setState(() => _phase = _Phase.countdown);
    AudioService.playLevelName(
      widget.levelNameGameId ?? widget.gameId,
      widget.levelNumber,
      locale: widget.locale,
      signSystem: widget.signSystem,
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _cancelled) return;
    _runCountdownLoop();
  }

  Future<void> _runCountdownLoop() async {
    setState(() => _phase = _Phase.countdown);

    for (int i = 3; i >= 1; i--) {
      if (!mounted || _cancelled) return;
      setState(() => _countdownValue = i);
      AudioService.playSpeechMp3('emph$i', locale: widget.locale).ignore();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted || _cancelled) return;
    setState(() => _countdownValue = 0);
    AudioService.playSpeechMp3('Go', locale: widget.locale).ignore();
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted || _cancelled) return;
    widget.onComplete();
  }

  static const _bgGradient = RadialGradient(
    colors: [Color(0xFF3A6FD1), Color(0xFF041F50)],
    radius: 0.85,
  );

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Positioned.fill(
      child: Stack(
        children: [
          // Background — 75% opaque during countdown so the game shows through
          Opacity(
            opacity: _phase == _Phase.countdown ? 0.75 : 1.0,
            child: widget.backgroundImage != null
                ? SizedBox.expand(
                    child: Image.asset(
                      widget.backgroundImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(gradient: _bgGradient),
                    child: SizedBox.expand(),
                  ),
          ),
          // Content — always fully opaque
          SafeArea(
            child: switch (_phase) {
              _Phase.checking => const SizedBox.shrink(),
              _Phase.instruction => _buildInstruction(localizer),
              _Phase.countdown => _buildCountdown(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(AppLocalizations localizer) {
    if (widget.roundedBubble) {
      return _buildInstructionRounded(localizer);
    }
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
                        fontFamily: 'Quicksand',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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

          // ── Back + Play buttons ───────────────────────────────────────
          _buildActionRow(localizer),
        ],
      ),
    );
  }

  /// Font size for [GameIntroCountdown.topText] — shrunk below
  /// [AppTheme.wideDeviceBreakpoint] so longer words don't wrap onto a
  /// second line on narrow phones.
  double _topTextFontSize(BuildContext context) {
    return MediaQuery.of(context).size.width < AppTheme.wideDeviceBreakpoint
        ? 38
        : 52;
  }

  /// Alternate instruction layout: heading text at the top, the character
  /// image, then a plain rounded-rectangle text box placed directly below
  /// it with no gap (instead of a tailed speech bubble above it).
  Widget _buildInstructionRounded(AppLocalizations localizer) {
    return AnimatedOpacity(
      opacity: _instructionOpacity,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.8,
          heightFactor: 0.8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (widget.topText != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    widget.topText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'LuckiestGuy',
                      fontSize: _topTextFontSize(context),
                      height: 1,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0x80013595),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Character image — fills remaining space above the box ──
                Expanded(
                  child: Image.asset(
                    widget.characterImage ?? AssetPaths.catrinDefault,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),

                // ── Rounded text box — sits directly below with no gap ────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF0091CE), width: 1),
                  ),
                  child: Text(
                    localizer('${widget.gameId}.intro'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002D97),
                      height: 1.45,
                    ),
                  ),
                ),

                // ── Back + Play buttons ─────────────────────────────────
                _buildActionRow(localizer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Row containing the Back (tertiary blue) and Play (green) buttons, shared
  /// by both instruction layouts. Each button expands to fill half the row.
  /// Carries its own vertical spacing so both call sites can just place it
  /// directly after the preceding content.
  Widget _buildActionRow(AppLocalizations localizer) {
    // Welsh labels run longer than English — shrink the button text so it
    // doesn't wrap or overflow.
    final fontSize = widget.locale == 'cy' ? 16.0 : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TertiaryButton(
              label: localizer('general.back'),
              onPressed: _onBackTapped,
              expanded: true,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PrimaryButton(
              label: localizer('general.play'),
              onPressed: _onPlayTapped,
              expanded: true,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final localizer = AppLocalizations(locale: widget.locale);
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
            fontFamily: 'Quicksand',
            fontSize: 140,
            fontWeight: FontWeight.w600,
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
