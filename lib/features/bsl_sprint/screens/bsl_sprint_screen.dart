import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/sprint_models.dart';
import '../providers/bsl_sprint_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Perspective layout constants
//
// All fractions are relative to the game area height/width.
// ─────────────────────────────────────────────────────────────────────────────

/// Y fraction (of game area) where the horizon sits.
const double _kHorizonFrac = 0.22;

/// Y fraction (of game area) that maps to item normalised depth 1.0.
/// Items at depth 1.0 appear here; the character stands here too.
const double _kGroundFrac = 0.90;

/// X position of the vanishing point (centre of screen).
const double _kVanishXFrac = 0.50;

/// Lane centres at the ground level, as fractions of screen width.
/// Track is 20% wider than screen (extends 10% beyond each edge).
const List<double> _kLaneBottomXFracs = [0.1, 0.5, 0.9];

// ── Perspective helpers ────────────────────────────────────────────────────

/// Maps a normalised depth [t] (0 = horizon, 1 = ground) to a screen Y pixel.
double _perspY(double t, double gameH) =>
    gameH * _kHorizonFrac + t * gameH * (_kGroundFrac - _kHorizonFrac);

/// Maps a [lane] + depth [t] to a screen X pixel (lanes converge at horizon).
double _perspX(int lane, double t, double gameW) {
  final vanishX = gameW * _kVanishXFrac;
  final laneBottomX = gameW * _kLaneBottomXFracs[lane];
  return vanishX + t * (laneBottomX - vanishX);
}

/// Perspective scale factor: items shrink toward the horizon.
double _perspScale(double t) => (t * 0.88 + 0.12).clamp(0.12, 1.0);

/// Responsive size multiplier based on game-area width.
///
/// Breakpoints:
///   < 500 px  → phone portrait  (1.0×)
///   500–899 px → large phone / small tablet (1.4×)
///   ≥ 900 px  → tablet / desktop (1.9×)
double _responsiveScale(double gameAreaWidth) {
  if (gameAreaWidth >= 900) return 1.9;
  if (gameAreaWidth >= 500) return 1.4;
  return 1.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BslSprintScreen extends StatefulWidget {
  const BslSprintScreen({super.key});

  @override
  State<BslSprintScreen> createState() => _BslSprintScreenState();
}

class _BslSprintScreenState extends State<BslSprintScreen>
    with SingleTickerProviderStateMixin {
  late final BslSprintProvider _provider;
  late final Ticker _ticker;
  late final FocusNode _focusNode;
  Duration _previousElapsed = Duration.zero;

  /// Drives the scrolling road-marking animation.
  double _scrollOffset = 0.0;

  bool _showingIntro = false;

  // Swipe detection
  double? _swipeStartX;
  double? _swipeStartY;

  @override
  void initState() {
    super.initState();
    _provider = context.read<BslSprintProvider>();
    _focusNode = FocusNode();
    _ticker = createTicker(_onTick)..start();

  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = _previousElapsed == Duration.zero
        ? 0.0
        : (elapsed - _previousElapsed).inMilliseconds / 1000.0;
    _previousElapsed = elapsed;

    if (_provider.state == SprintState.playing) {
      _scrollOffset = (_scrollOffset +
              _provider.scrollSpeed *
                  _provider.currentLevel.scrollMultiplier *
                  dt) %
          1.0;
    }
    _provider.tick(dt);
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    AudioService.stopAll();
    super.dispose();
  }

  // ── Input handlers ─────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    _swipeStartX = d.globalPosition.dx;
    _swipeStartY = d.globalPosition.dy;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_provider.state != SprintState.playing) return;
    final dx = d.globalPosition.dx - (_swipeStartX ?? d.globalPosition.dx);
    final dy = d.globalPosition.dy - (_swipeStartY ?? d.globalPosition.dy);
    _swipeStartX = null;
    _swipeStartY = null;
    // Upward swipe takes priority when it dominates the gesture direction.
    if (dy < -30 && dy.abs() >= dx.abs()) {
      _provider.jump();
    } else if (dx < -30) {
      _provider.swipeLeft();
    } else if (dx > 30) {
      _provider.swipeRight();
    }
  }

  /// Handles desktop keyboard input.
  /// Arrow Left / Right → change lane. Space → jump.
  /// Only fires on [KeyDownEvent] so holding a key doesn't repeat lane changes.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_provider.state != SprintState.playing) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _provider.swipeLeft();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _provider.swipeRight();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _provider.jump();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _restartGame() {
    _scrollOffset = 0.0;
    _previousElapsed = Duration.zero;
    _provider.resetForCountdown();
    setState(() => _showingIntro = true);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: provider.showLevelSelect
            ? GameAppBar(
                title: AppLocalizations(locale: 'en').translate('bsl_sprint.title'),
                onBack: () => Navigator.of(context).pop(),
              )
            : null,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: provider.showLevelSelect
                    ? _buildLevelSelectScreen(context, provider)
                    : _buildGameScreen(context, provider),
              ),
              if (provider.state == SprintState.gameOver && !_showingIntro && !provider.showLevelSelect)
                Positioned.fill(
                  child: GameSuccessOverlay(
                    gameId: 'bsl_sprint',
                    scoreStyle: SuccessScoreStyle.custom,
                    customScoreLine:
                        'Words: ${provider.wordsCompleted}  •  Score: ${provider.score}',
                    showPersonalBest: true,
                    isNewPersonalBest: provider.lastResult?.isNewPersonalBest ?? false,
                    personalBest: provider.lastResult?.personalBest,
                    onPlayAgain: _restartGame,
                    onChangeLevel: () => provider.showLevelSelection(),
                  ),
                ),
              if (_showingIntro)
                GameIntroCountdown(
                  gameId: 'bsl_sprint.level${provider.currentLevel.number}',
                  onComplete: () {
                    setState(() => _showingIntro = false);
                    _provider.startGame();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectScreen(
      BuildContext context, BslSprintProvider provider) {
    final l = AppLocalizations(locale: 'en');
    return LevelSelectScreen(
      levels: SprintLevel.all.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: l.translate('bsl_sprint.level${level.number}.name'),
          description: l.translate('bsl_sprint.level${level.number}.description'),
          color: levelColor(level.number),
          onTap: () {
            provider.setLevel(level.number);
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }

  Widget _buildGameScreen(
      BuildContext context, BslSprintProvider provider) {
    return Column(
      children: [
        GameHeaderBar(
          onBack: () => Navigator.of(context).pop(),
          scoreValue: '${provider.score}',
          levelNumber: provider.currentLevel.number,
          centerContent: _SprintCenterHud(provider: provider),
        ),
        _WordBar(
          word: provider.currentWord,
          letterIndex: provider.letterIndex,
          levelNumber: provider.currentLevel.number,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_provider.state == SprintState.playing) {
                _provider.jump();
              }
            },
            onPanStart: _onPanStart,
            onPanEnd: _onPanEnd,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final sortedItems = provider.items
                    .where((item) => item.isActive && item.y > 0.02)
                    .toList()
                  ..sort((a, b) => a.y.compareTo(b.y));
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _PerspectiveRoadPainter(
                        scrollOffset: _scrollOffset,
                        characterLane: provider.characterLane,
                      ),
                    ),
                    for (final item in sortedItems)
                      _buildPerspectiveItem(
                        item,
                        size,
                        provider.nextLetter,
                        provider.currentLevel.number == 0,
                      ),
                    _buildCharacter(provider, size),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── 3D item positioning ───────────────────────────────────────────────────

  Widget _buildPerspectiveItem(
      SprintItem item, Size size, String nextLetter, bool isTraining) {
    final t = item.y.clamp(0.0, 1.2); // depth: 0 = horizon, 1 = ground
    // Combine perspective shrink with device-size multiplier.
    final scale = _perspScale(t) * _responsiveScale(size.width);
    final cx = _perspX(item.lane, t, size.width);
    final cy = _perspY(t, size.height);

    if (item.isBarrier) {
      final w = (t * 0.4 * size.width).clamp(12.0, size.width * 0.45);
      final h = 234.0 * scale;
      return Positioned(
        left: cx - w / 2,
        top: cy - h,
        child: _BarrierWidget(width: w, height: h),
      );
    }

    if (item.isObstacle) {
      final w = (t * 0.4 * size.width).clamp(12.0, size.width * 0.45);
      final h = w * 0.7; // preserves original 56:80 aspect ratio
      return Positioned(
        left: cx - w / 2,
        top: cy - h,
        child: _ObstacleWidget(width: w, height: h),
      );
    }

    // BSL symbol disc — fills lane width at this perspective depth
    final symW = (t * 0.4 * size.width).clamp(12.0, size.width * 0.5);
    return Positioned(
      left: cx - symW / 2,
      top: cy - symW,
      child: _BslSymbolWidget(
        letter: item.letter,
        size: symW,
        scale: scale,
        highlightBorder: isTraining && item.letter == nextLetter,
      ),
    );
  }

  // ── Character positioning ─────────────────────────────────────────────────

  Widget _buildCharacter(BslSprintProvider provider, Size size) {
    final rs = _responsiveScale(size.width);
    final charW = 48.0 * rs;
    final charH = 72.0 * rs;

    // The character stands at ground level in their current lane.
    final lane = provider.characterLane;
    final cx = _perspX(lane, BslSprintProvider.characterBaseY, size.width);

    // Base feet position (ground level for characterBaseY depth).
    final groundPy = _perspY(BslSprintProvider.characterBaseY, size.height);

    // Visual jump: move upward on screen as jumpOffset increases.
    // We amplify slightly so the arc feels satisfying in perspective.
    final jumpPixels = provider.jumpOffset *
        size.height *
        (_kGroundFrac - _kHorizonFrac) *
        1.4;
    final py = groundPy - jumpPixels;

    return Positioned(
      left: cx - charW / 2,
      top: py - charH,
      child: _CharacterPlaceholder(
        isJumping: provider.isJumping,
        width: charW,
        height: charH,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Perspective road painter
// ─────────────────────────────────────────────────────────────────────────────

class _PerspectiveRoadPainter extends CustomPainter {
  final double scrollOffset;
  final int characterLane;

  const _PerspectiveRoadPainter({
    required this.scrollOffset,
    required this.characterLane,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * _kHorizonFrac;
    final groundY = h * _kGroundFrac;
    final vanishX = w * _kVanishXFrac;

    // ── Sky ────────────────────────────────────────────────────────────────
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B6B), Color(0xFF3949AB)],
        ).createShader(skyRect),
    );

    // Sun / glow at vanishing point
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amber.withValues(alpha: 0.55),
          Colors.amber.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(vanishX, horizonY), radius: 60),
      );
    canvas.drawCircle(Offset(vanishX, horizonY), 60, sunPaint);

    // ── Road trapezoid — athletics track red ───────────────────────────────
    // Track extends 10% beyond each screen edge (20% wider total).
    final roadRect = Rect.fromLTWH(0, horizonY, w, h - horizonY);
    final roadPath = Path()
      ..moveTo(vanishX, horizonY)
      ..lineTo(-w * 0.1, h)
      ..lineTo(w * 1.1, h)
      ..close();
    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFD94A44), Color(0xFFF85A54)],
        ).createShader(roadRect),
    );

    // Grass / shoulders — narrow slivers where road edge crosses screen edge
    final leftGrassPath = Path()
      ..moveTo(0, horizonY)
      ..lineTo(vanishX, horizonY)
      ..lineTo(-w * 0.1, h)
      ..close();
    final rightGrassPath = Path()
      ..moveTo(w, horizonY)
      ..lineTo(vanishX, horizonY)
      ..lineTo(w * 1.1, h)
      ..close();
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ).createShader(roadRect);
    canvas.drawPath(leftGrassPath, grassPaint);
    canvas.drawPath(rightGrassPath, grassPaint);

    // Road kerb lines — thick white edge lines
    _drawConvergingLine(
      canvas,
      vanishX, horizonY, -w * 0.1, h,
      paint: Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    _drawConvergingLine(
      canvas,
      vanishX, horizonY, w * 1.1, h,
      paint: Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // ── Lane dividers — solid white lines (running track style) ───────────
    _drawSolidConvergingLine(canvas, vanishX, horizonY, w * 0.3, h);
    _drawSolidConvergingLine(canvas, vanishX, horizonY, w * 0.7, h);

    // ── Scrolling horizontal track markings (motion cue) ──────────────────
    _drawTrackMarkings(canvas, vanishX, horizonY, groundY, w, scrollOffset);

    // ── Current-lane highlight ─────────────────────────────────────────────
    final laneL = w * (-0.1 + characterLane * 0.4);
    final laneR = laneL + w * 0.4;
    final highlightPath = Path()
      ..moveTo(vanishX, horizonY)
      ..lineTo(laneL, groundY)
      ..lineTo(laneR, groundY)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // ── Horizon glow strip ─────────────────────────────────────────────────
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      Paint()
        ..color = Colors.amber.withValues(alpha: 0.25)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  /// Draws a solid line from the vanishing point to a bottom X position.
  void _drawConvergingLine(
    Canvas canvas,
    double vanishX,
    double horizonY,
    double bottomX,
    double bottomY, {
    required Paint paint,
  }) {
    canvas.drawLine(
      Offset(vanishX, horizonY),
      Offset(bottomX, bottomY),
      paint,
    );
  }

  /// Draws a solid white lane divider converging to the vanishing point.
  void _drawSolidConvergingLine(
    Canvas canvas,
    double vanishX,
    double horizonY,
    double bottomX,
    double bottomY,
  ) {
    canvas.drawLine(
      Offset(vanishX, horizonY),
      Offset(bottomX, bottomY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Draws scrolling horizontal lines across the full track width.
  ///
  /// Markings are placed at equal world-Z intervals so they are visually
  /// compressed near the horizon, matching correct perspective projection.
  /// Formula: t = 1 / (1 + (1 − raw) × zRatio) maps raw ∈ [0,1] to
  /// t ∈ [tFar, tNear] with correct 1/Z compression.
  void _drawTrackMarkings(
    Canvas canvas,
    double vanishX,
    double horizonY,
    double groundY,
    double w,
    double scrollOffset,
  ) {
    // zNear = 1/playerT (player depth), zFar = far horizon depth.
    // zRatio = zFar/zNear − 1 controls how much compression is applied.
    const double zNear = 1.25; // 1 / 0.80 (character base Y)
    const double zFar = 16.0;
    const double zRatio = zFar / zNear - 1.0; // ≈ 11.8
    const int steps = 14;

    for (int i = 0; i < steps; i++) {
      // raw advances toward 1 as scrollOffset increases → t increases → marking
      // moves from horizon toward player, then wraps back.
      final raw = ((i / steps) + scrollOffset) % 1.0;
      // Perspective-compressed t: equal world-Z spacing → nonlinear screen spacing
      final t = 1.0 / (1.0 + (1.0 - raw) * zRatio);
      if (t < 0.06) continue; // skip slivers too close to horizon

      final y = horizonY + t * (groundY - horizonY);
      final xLeft = vanishX + t * (-w * 0.1 - vanishX);
      final xRight = vanishX + t * (w * 1.1 - vanishX);

      canvas.drawLine(
        Offset(xLeft, y),
        Offset(xRight, y),
        Paint()
          ..color = Colors.white.withValues(alpha: (0.30 * t).clamp(0.0, 0.30))
          ..strokeWidth = (2.0 * t).clamp(0.4, 2.0),
      );
    }
  }

  @override
  bool shouldRepaint(_PerspectiveRoadPainter old) =>
      old.scrollOffset != scrollOffset || old.characterLane != characterLane;
}

// ─────────────────────────────────────────────────────────────────────────────
// Character placeholder
//
// Swap _CharacterPlaceholder for your real sprite widget.
// The widget is 48 × 72 px; feet are anchored to the road ground line.
// Pass [isJumping] to drive a jump animation on the sprite.
// ─────────────────────────────────────────────────────────────────────────────

class _CharacterPlaceholder extends StatelessWidget {
  final bool isJumping;
  final double width;
  final double height;

  const _CharacterPlaceholder({
    required this.isJumping,
    this.width = 48,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = (28.0 * width / 48).clamp(16.0, 56.0);
    final fontSize = (11.0 * width / 48).clamp(8.0, 22.0);
    final radius = 12.0 * width / 48;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isJumping
            ? const Color(0xFFE91E63).withValues(alpha: 0.80)
            : const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, color: Colors.white, size: iconSize),
          SizedBox(height: 2 * width / 48),
          Text(
            'Abi',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontFamily: 'ComicRelief',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BSL symbol disc — 3D lit circular token
// ─────────────────────────────────────────────────────────────────────────────

class _BslSymbolWidget extends StatelessWidget {
  final String letter;
  final double size;
  final double scale;
  final bool highlightBorder;

  const _BslSymbolWidget({
    required this.letter,
    required this.size,
    required this.scale,
    this.highlightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final cornerRadius = math.min(24.0, size * 0.35);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiscPainter(scale: scale, highlightBorder: highlightBorder),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: BslAlphabetSvg(
            letter: letter,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-D disc painter — indigo token with rim, radial gradient and specular spot
// ─────────────────────────────────────────────────────────────────────────────

class _DiscPainter extends CustomPainter {
  final double scale;
  final bool highlightBorder;
  const _DiscPainter({required this.scale, this.highlightBorder = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cr = Radius.circular(math.min(24.0, w * 0.35));

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.10, w, h),
      cr,
    );
    canvas.drawRRect(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (8 * scale).clamp(3, 12)),
    );

    // Rim — dark band simulating depth
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.08, w, h), cr),
      Paint()..color = const Color(0xFF0D1340),
    );

    // Face — radial gradient: near-white top-left → deep indigo
    final faceRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, cr),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.38),
          radius: 1.0,
          colors: [
            Color(0xFFEEF0FF),
            Color(0xFF7986CB),
            Color(0xFF283593),
          ],
          stops: [0.0, 0.52, 1.0],
        ).createShader(faceRect),
    );

    // Specular highlight — soft white oval at top-left
    final hlCenter = Offset(w * 0.30, h * 0.24);
    final hlRect = Rect.fromCenter(center: hlCenter, width: w * 0.40, height: h * 0.40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hlRect, cr),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.50),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(hlRect),
    );

    // Training-mode highlight — green border around the correct tile
    if (highlightBorder) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, w + 8, h + 8),
          Radius.circular(math.min(28.0, w * 0.38)),
        ),
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0,
      );
    }
  }

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.scale != scale || old.highlightBorder != highlightBorder;
}

// ─────────────────────────────────────────────────────────────────────────────
// Barrier widget — unjumpable brick wall (level 2 only)
// ─────────────────────────────────────────────────────────────────────────────

class _BarrierWidget extends StatelessWidget {
  final double width;
  final double height;
  const _BarrierWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: const _BrickWallPainter(),
    );
  }
}

class _BrickWallPainter extends CustomPainter {
  const _BrickWallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const radius = Radius.circular(4);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), radius),
      Paint()..color = const Color(0xFFC62828),
    );

    // Mortar lines
    final mortar = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.5;

    const rowH = 13.0;
    // Horizontal
    for (double y = rowH; y < h; y += rowH) {
      canvas.drawLine(Offset(0, y), Offset(w, y), mortar);
    }
    // Vertical — alternating offset per row
    int row = 0;
    for (double y = 0; y < h; y += rowH, row++) {
      final brickW = w / 3;
      final xOff = row.isEven ? 0.0 : brickW / 2;
      for (double x = xOff; x < w; x += brickW) {
        if (x > 0) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, (y + rowH).clamp(0.0, h)),
            mortar,
          );
        }
      }
    }

    // Warning stripe at top
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, 9), radius),
      Paint()..color = const Color(0xFFFFC107),
    );

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), radius),
      Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_BrickWallPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Obstacle widget — scales with perspective depth
// ─────────────────────────────────────────────────────────────────────────────

class _ObstacleWidget extends StatelessWidget {
  final double width;
  final double height;
  const _ObstacleWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        'assets/games/bsl_sprint/hurdle.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GameHeaderBar centre content — lives + word progress
// ─────────────────────────────────────────────────────────────────────────────

class _SprintCenterHud extends StatelessWidget {
  final BslSprintProvider provider;
  const _SprintCenterHud({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lives hearts
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            BslSprintProvider.maxLives,
            (i) => Icon(
              i < provider.lives ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Word progress
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Words',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${provider.wordsCompleted}',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Word display bar
// ─────────────────────────────────────────────────────────────────────────────

class _WordBar extends StatelessWidget {
  final String word;
  final int letterIndex;
  final int levelNumber;

  const _WordBar({
    required this.word,
    required this.letterIndex,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context) {
    final s = (levelNumber <= 1 ? 1.5 : 1.0) * 1.25;
    final showBsl = levelNumber <= 1;

    if (word.isEmpty) {
      return Container(
        height: 80 * s,
        color: const Color(0xFF0D1B6B),
        alignment: Alignment.center,
        child: const Text(
          'Get ready!',
          style: TextStyle(
              color: Colors.white60, fontFamily: 'ComicRelief', fontSize: 20),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1B6B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Collect the letters to spell:',
            style: TextStyle(
                color: Colors.white60, fontSize: 11, fontFamily: 'ComicRelief'),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: word.split('').asMap().entries.map((entry) {
              final i = entry.key;
              final letter = entry.value;
              final isCollected = i < letterIndex;
              final isNext = i == letterIndex;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3 * s),
                child: Container(
                  width: 46 * s,
                  height: 56 * s,
                  decoration: BoxDecoration(
                    color: isCollected
                        ? const Color(0xFF388E3C)
                        : isNext
                            ? const Color(0xFFFFA000)
                            : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8 * s),
                    border: Border.all(
                      color: isNext ? Colors.amber.shade300 : Colors.transparent,
                      width: isNext ? 2 : 0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showBsl && (isCollected || isNext))
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(2 * s),
                            child: BslAlphabetSvg(
                              letter: letter,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      else if (showBsl)
                        const Spacer(),
                      Text(
                        isCollected || isNext ? letter : '?',
                        style: TextStyle(
                          color: isCollected || isNext
                              ? Colors.white
                              : Colors.white24,
                          fontFamily: 'ComicRelief',
                          fontSize: showBsl ? 16 * s : 28 * s,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


