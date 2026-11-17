import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/sign_letter_image.dart';
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

/// Left / right edges of the track at the bottom of the screen, as fractions
/// of screen width. Track is 38% wider than the screen (19% beyond each edge).
const double _kTrackLeftFrac = -0.19;
const double _kTrackRightFrac = 1.19;

/// Width of one lane at the bottom of the screen, as a fraction of width.
const double _kLaneWidthFrac = (_kTrackRightFrac - _kTrackLeftFrac) / 3;

/// Lane centres at the ground level, as fractions of screen width.
const List<double> _kLaneBottomXFracs = [
  _kTrackLeftFrac + _kLaneWidthFrac * 0.5,
  _kTrackLeftFrac + _kLaneWidthFrac * 1.5,
  _kTrackLeftFrac + _kLaneWidthFrac * 2.5,
];

/// Size multiplier for items and the racer, matching the 15% wider track.
const double _kTrackSizeScale = 1.15;

/// The road is painted down to the bottom of the screen, but depth 1.0 maps
/// to [_kGroundFrac]. This converts depth into the fraction of the way from
/// the vanishing point to the painted bottom edge, so items and the racer
/// sit centred in the painted lanes.
const double _kGroundToBottomRatio =
    (_kGroundFrac - _kHorizonFrac) / (1.0 - _kHorizonFrac);

// ── Perspective helpers ────────────────────────────────────────────────────

/// Maps a normalised depth [t] (0 = horizon, 1 = ground) to a screen Y pixel.
double _perspY(double t, double gameH) =>
    gameH * _kHorizonFrac + t * gameH * (_kGroundFrac - _kHorizonFrac);

/// Maps a [lane] + depth [t] to a screen X pixel (lanes converge at horizon).
double _perspX(int lane, double t, double gameW) {
  final vanishX = gameW * _kVanishXFrac;
  final laneBottomX = gameW * _kLaneBottomXFracs[lane];
  return vanishX + t * _kGroundToBottomRatio * (laneBottomX - vanishX);
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

// ── Racer run-cycle sprite ─────────────────────────────────────────────────

/// Sky backdrop shown above the horizon.
const String _kSkyAsset = 'assets/games/bsl_sprint/sky.jpg';

// ── Roadside trees ─────────────────────────────────────────────────────────

/// Tree images and their width / height aspect ratios.
const List<String> _kTreeAssets = [
  'assets/games/bsl_sprint/tree-1.png',
  'assets/games/bsl_sprint/tree-2.png',
];
const List<double> _kTreeAspects = [476 / 500, 402 / 500];

/// Number of trees scattered at the start of a game, and the most allowed
/// at once. After the start, new trees only appear at the horizon.
const int _kMinTrees = 3;
const int _kMaxTrees = 7;

/// Trees approach at this fraction of the track's speed (parallax).
const double _kTreeParallax = 0.6;

/// Tree height range relative to the racer (a child of roughly 1–1.7 m),
/// measured when the tree is level with the racer.
const double _kTreeMinHeightMultiple = 5.0;
const double _kTreeMaxHeightMultiple = 10.0;

/// Depth at which new trees appear, and beyond which they are removed.
const double _kTreeSpawnT = 0.08;
const double _kTreeExitT = 1.6;

/// Maximum extra distance beyond the kerb (fraction of width at the bottom).
const double _kTreeMaxGap = 0.3;

/// A decorative tree on the grass beside the track. Screen-only; it has no
/// effect on gameplay.
class _SideTree {
  final int variant; // index into _kTreeAssets / _kTreeAspects
  final bool leftSide;

  /// Extra distance beyond the kerb, as a fraction of width at the bottom.
  final double gap;

  /// Height as a multiple of the racer's height at the same depth.
  final double heightMultiple;

  /// Normalised depth, as for track items (0 = horizon, 1 = ground).
  double t;

  _SideTree({
    required this.variant,
    required this.leftSide,
    required this.gap,
    required this.heightMultiple,
    required this.t,
  });
}

/// Source image aspect ratio shared by every racer's frames (317 × 450 px).
const double _kRacerAspect = 317 / 450;

/// Number of frames in each racer's run cycle.
const int _kRunFrameCount = 4;

/// Run-cycle frames advanced per full road-scroll cycle. Matches the number
/// of track markings in [_PerspectiveRoadPainter._drawTrackMarkings], so one
/// frame is shown for each marking that passes under the racer's feet.
const double _kRunFramesPerScrollCycle = 14;

/// Frame-rate bounds so the slow Training level doesn't look like slow motion
/// and top speed doesn't strobe faster than the display can show.
const double _kMinRunFps = 6;
const double _kMaxRunFps = 20;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BslSprintScreen extends StatefulWidget {
  /// UI locale ('en' or 'cy') used for titles, level info, and overlay text.
  final String locale;

  const BslSprintScreen({super.key, this.locale = 'en'});

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

  /// Continuous position in the racer's run cycle; floor % frame count = frame shown.
  double _runPhase = 0.0;

  bool _showingIntro = false;

  // Roadside trees (scenery only)
  final math.Random _treeRng = math.Random();

  /// Play-area size from the last build, used to cull off-screen trees.
  Size? _playSize;
  final List<_SideTree> _trees = [];
  double _treeSpawnTimer = 0.0;

  // Swipe detection
  double? _swipeStartX;
  double? _swipeStartY;

  @override
  void initState() {
    super.initState();
    _provider = context.read<BslSprintProvider>();
    _focusNode = FocusNode();
    _ticker = createTicker(_onTick)..start();
    _seedTrees();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Thumbnails for the racer-select grid, which is the first thing shown.
    for (final racer in SprintRacer.all) {
      precacheImage(AssetImage(racer.thumbnail), context);
    }
    precacheImage(const AssetImage(_kSkyAsset), context);
    for (final asset in _kTreeAssets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _selectRacer(SprintRacer racer) {
    // Decode the run frames up front so the first cycle doesn't flicker.
    for (final frame in [
      ...racer.runFrames,
      racer.jumpFrame,
      racer.landingFrame,
    ]) {
      precacheImage(AssetImage(frame), context);
    }
    _provider.selectRacer(racer);
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = _previousElapsed == Duration.zero
        ? 0.0
        : (elapsed - _previousElapsed).inMilliseconds / 1000.0;
    _previousElapsed = elapsed;

    if (_provider.state == SprintState.playing) {
      final scrollRate =
          _provider.scrollSpeed * _provider.currentLevel.scrollMultiplier;
      _scrollOffset = (_scrollOffset + scrollRate * dt) % 1.0;

      // Legs keep pace with the road; pause the cycle while airborne/landing.
      if (!_provider.isJumping && !_provider.isLanding) {
        final fps = (scrollRate * _kRunFramesPerScrollCycle)
            .clamp(_kMinRunFps, _kMaxRunFps);
        _runPhase = (_runPhase + fps * dt) % _kRunFrameCount;
      }
      _updateTrees(dt);
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

  // ── Roadside trees ─────────────────────────────────────────────────────────

  _SideTree _newTree(double t) => _SideTree(
        variant: _treeRng.nextInt(_kTreeAssets.length),
        leftSide: _treeRng.nextBool(),
        gap: _treeRng.nextDouble() * _kTreeMaxGap,
        heightMultiple: _kTreeMinHeightMultiple +
            _treeRng.nextDouble() *
                (_kTreeMaxHeightMultiple - _kTreeMinHeightMultiple),
        t: t,
      );

  double _nextTreeSpawnDelay() => 0.8 + _treeRng.nextDouble() * 1.6;

  /// Scatters a random number of trees at random depths.
  void _seedTrees() {
    _trees.clear();
    final count =
        _kMinTrees + _treeRng.nextInt(_kMaxTrees - _kMinTrees + 1);
    for (var i = 0; i < count; i++) {
      _trees.add(_newTree(_kTreeSpawnT + _treeRng.nextDouble() * 0.8));
    }
    _treeSpawnTimer = _nextTreeSpawnDelay();
  }

  /// Moves trees toward the player with the same perspective model as track
  /// items, but slower (parallax). Trees are removed once fully off screen;
  /// new ones only appear at the horizon, up to [_kMaxTrees] at once.
  void _updateTrees(double dt) {
    final worldSpeed = _provider.worldSpeed * _kTreeParallax;
    for (final tree in _trees) {
      final denom = 1.0 - tree.t * worldSpeed * dt;
      tree.t = denom > 0.01 ? tree.t / denom : _kTreeExitT;
    }
    final playSize = _playSize;
    _trees.removeWhere((tree) =>
        tree.t >= _kTreeExitT ||
        (playSize != null && !_isTreeOnScreen(tree, playSize)));

    _treeSpawnTimer -= dt;
    if (_treeSpawnTimer <= 0 && _trees.length < _kMaxTrees) {
      _trees.add(_newTree(_kTreeSpawnT));
      _treeSpawnTimer = _nextTreeSpawnDelay();
    }
  }

  bool _isTreeOnScreen(_SideTree tree, Size size) {
    final rect = _treeRect(tree, size);
    return rect.right > 0 && rect.left < size.width && rect.top < size.height;
  }

  void _restartGame() {
    _seedTrees();
    _scrollOffset = 0.0;
    _runPhase = 0.0;
    _previousElapsed = Duration.zero;
    _provider.resetForCountdown();
    setState(() => _showingIntro = true);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    final localizer = AppLocalizations(locale: widget.locale);
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: provider.showRacerSelect || provider.showLevelSelect
            ? GameAppBar(
                title: localizer.translate('bsl_sprint.title'),
                onBack: () {
                  if (provider.showRacerSelect) {
                    Navigator.of(context).pop();
                  } else {
                    provider.showRacerSelection();
                  }
                },
              )
            : null,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/backgrounds/felt-background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                // The game screen handles the bottom inset itself so the
                // track can be painted all the way to the screen edge.
                bottom: provider.showRacerSelect || provider.showLevelSelect,
                child: provider.showRacerSelect
                    ? _RacerSelectScreen(
                        locale: widget.locale,
                        onSelected: _selectRacer,
                      )
                    : provider.showLevelSelect
                    ? _buildLevelSelectScreen(context, provider)
                    : _buildGameScreen(context, provider),
              ),
              if (provider.state == SprintState.gameOver &&
                  !_showingIntro &&
                  !provider.showRacerSelect &&
                  !provider.showLevelSelect)
                Positioned.fill(
                  child: GameSuccessOverlay(
                    gameId: 'bsl_sprint',
                    locale: widget.locale,
                    scoreStyle: SuccessScoreStyle.custom,
                    imageAsset: provider.racer.thumbnail,
                    customScoreLine: localizer
                        .translate('bsl_sprint.success_summary')
                        .replaceAll('{words}', '${provider.wordsCompleted}')
                        .replaceAll('{score}', '${provider.score}'),
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
                  levelNumber: provider.currentLevel.number,
                  levelNameGameId: 'bsl_sprint',
                  locale: widget.locale,
                  onComplete: () {
                    setState(() => _showingIntro = false);
                    _provider.startGame();
                  },
                  onBack: () {
                    setState(() => _showingIntro = false);
                    _provider.showLevelSelection();
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
    final l = AppLocalizations(locale: widget.locale);
    return LevelSelectScreen(
      locale: widget.locale,
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
          onBack: () {
            // Stop the run (tick ignores anything but playing) before
            // returning to the level select.
            provider.resetForCountdown();
            provider.showLevelSelection();
          },
          scoreValue: '${provider.score}',
          levelNumber: provider.currentLevel.number,
          centerContent: _SprintCenterHud(provider: provider, locale: widget.locale),
        ),
        Expanded(
          child: CustomMultiChildLayout(
            delegate: _SkyUnderWordBarLayout(
              bottomInset: MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              LayoutId(
                id: _GameSlot.sky,
                child: Image.asset(
                  _kSkyAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  gaplessPlayback: true,
                ),
              ),
              LayoutId(id: _GameSlot.game, child: _buildGameArea(provider)),
              LayoutId(
                id: _GameSlot.wordBar,
                child: _WordBar(
                  word: provider.currentWord,
                  letterIndex: provider.letterIndex,
                  levelNumber: provider.currentLevel.number,
                  locale: widget.locale,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The track, items and racer. The sky above the horizon is left
  /// transparent so the sky image laid out behind it shows through.
  Widget _buildGameArea(BslSprintProvider provider) {
    return GestureDetector(
      onTap: () {
        if (_provider.state == SprintState.playing) {
          _provider.jump();
        }
      },
      onPanStart: _onPanStart,
      onPanEnd: _onPanEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullSize = constraints.biggest;
          // Items and the racer stay clear of the bottom safe-area
          // inset; only the road is painted underneath it.
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final size = Size(fullSize.width, fullSize.height - bottomInset);
          _playSize = size;
          final sortedItems = provider.items
              .where((item) => item.isActive && item.y > 0.02)
              .toList()
            ..sort((a, b) => a.y.compareTo(b.y));
          final sortedTrees = [..._trees]..sort((a, b) => a.t.compareTo(b.t));
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              CustomPaint(
                size: fullSize,
                painter: _PerspectiveRoadPainter(
                  playHeight: size.height,
                  scrollOffset: _scrollOffset,
                  characterLane: provider.characterLane,
                ),
              ),
              for (final tree in sortedTrees) _buildTree(tree, size),
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
    );
  }

  // ── Tree positioning ──────────────────────────────────────────────────────

  /// Places a tree on the grass using the same perspective as the track.
  /// Its base follows a line converging on the vanishing point, set outside
  /// the kerb by half the tree's width plus [_SideTree.gap], so it never
  /// overlaps the track at any depth.
  Widget _buildTree(_SideTree tree, Size size) {
    return Positioned.fromRect(
      rect: _treeRect(tree, size),
      child: Image.asset(
        _kTreeAssets[tree.variant],
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        gaplessPlayback: true,
      ),
    );
  }

  /// Screen rect of [tree] in a play area of [size].
  Rect _treeRect(_SideTree tree, Size size) {
    final t = tree.t;
    final aspect = _kTreeAspects[tree.variant];
    // Scale with depth from the racer's size at the racer's depth.
    final heightPerT = _racerHeight(size.width) *
        tree.heightMultiple /
        BslSprintProvider.characterBaseY;
    final h = t * heightPerT;
    final w = h * aspect;

    // Half the tree's width, converted to the bottom-of-track units the
    // converging line uses, keeps it off the track at every depth.
    final clearance = tree.gap +
        heightPerT * aspect / (2 * _kGroundToBottomRatio * size.width);
    final lineFrac = tree.leftSide
        ? _kTrackLeftFrac - clearance
        : _kTrackRightFrac + clearance;
    final vanishX = size.width * _kVanishXFrac;
    final cx = vanishX +
        t * _kGroundToBottomRatio * (size.width * lineFrac - vanishX);
    final cy = _perspY(t, size.height);

    return Rect.fromLTWH(cx - w / 2, cy - h, w, h);
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
      final w = (t * _kLaneWidthFrac * size.width).clamp(
        12.0,
        size.width * 0.45 * _kTrackSizeScale,
      );
      final h = 234.0 * _kTrackSizeScale * scale;
      return Positioned(
        left: cx - w / 2,
        top: cy - h,
        child: _BarrierWidget(width: w, height: h),
      );
    }

    if (item.isObstacle) {
      final w = (t * _kLaneWidthFrac * size.width).clamp(
        12.0,
        size.width * 0.45 * _kTrackSizeScale,
      );
      final h = w * 0.7; // preserves original 56:80 aspect ratio
      return Positioned(
        left: cx - w / 2,
        top: cy - h,
        child: _ObstacleWidget(width: w, height: h),
      );
    }

    // BSL symbol disc — fills lane width at this perspective depth
    final symW = (t * _kLaneWidthFrac * size.width).clamp(
      12.0,
      size.width * 0.5 * _kTrackSizeScale,
    );
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

  /// On-screen racer height for a game area of [width].
  double _racerHeight(double width) =>
      180.0 * _kTrackSizeScale * _responsiveScale(width);

  Widget _buildCharacter(BslSprintProvider provider, Size size) {
    final charH = _racerHeight(size.width);
    final charW = charH * _kRacerAspect;

    // The character stands at ground level in their current lane.
    final lane = provider.characterLane;
    final cx = _perspX(lane, BslSprintProvider.characterBaseY, size.width);

    // Base feet position (ground level for characterBaseY depth).
    final groundPy = _perspY(BslSprintProvider.characterBaseY, size.height);

    // Visual jump: move upward on screen as jumpOffset increases.
    // Scaled so the arc reads clearly in perspective without leaping too high.
    final jumpPixels = provider.jumpOffset *
        size.height *
        (_kGroundFrac - _kHorizonFrac) *
        0.98;
    final py = groundPy - jumpPixels;

    return Positioned(
      left: cx - charW / 2,
      top: py - charH,
      child: _RunnerSprite(
        asset: provider.isJumping
            ? provider.racer.jumpFrame
            : provider.isLanding
            ? provider.racer.landingFrame
            : provider.racer.runFrames[_runPhase.floor() % _kRunFrameCount],
        width: charW,
        height: charH,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Who would you like to race as?" — racer select grid
//
// 2 columns on devices under 600 px wide, 3 columns otherwise.
// ─────────────────────────────────────────────────────────────────────────────

class _RacerSelectScreen extends StatelessWidget {
  final String locale;
  final ValueChanged<SprintRacer> onSelected;

  const _RacerSelectScreen({required this.locale, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(locale: locale);
    final crossAxisCount = MediaQuery.sizeOf(context).width < 600 ? 2 : 3;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(
                l.translate('bsl_sprint.choose_racer'),
                textAlign: TextAlign.center,
                style: AppTheme.title.copyWith(
                  fontSize: AppSizes.fontSizeTitle,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              // Rows of equal-width cells rather than a GridView, so each
              // card is exactly as tall as its image and name — a fixed grid
              // aspect ratio would leave empty space around the image.
              for (
                var start = 0;
                start < SprintRacer.all.length;
                start += crossAxisCount
              ) ...[
                if (start > 0) const SizedBox(height: AppSizes.spacingMedium),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = start; i < start + crossAxisCount; i++) ...[
                      if (i > start)
                        const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(
                        child: i < SprintRacer.all.length
                            ? _RacerCard(
                                racer: SprintRacer.all[i],
                                onTap: () => onSelected(SprintRacer.all[i]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Width of the blue border drawn over the edge of each racer card.
const double _kRacerCardBorderWidth = 3;

class _RacerCard extends StatelessWidget {
  final SprintRacer racer;
  final VoidCallback onTap;

  const _RacerCard({required this.racer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: racer.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Clip the edge-to-edge image to the card's rounded corners.
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          // Drawn on top so the full-bleed image doesn't cover the card edge.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            border: Border.all(
              color: AppColors.catrinBlue,
              width: _kRacerCardBorderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full card width, no padding.
              AspectRatio(
                aspectRatio: _kRacerAspect,
                child: Image.asset(racer.thumbnail, fit: BoxFit.cover),
              ),
              // Name centred vertically between the image and the card's
              // bottom edge. The extra bottom padding offsets the card border
              // drawn over this band, and the even leading splits the font's
              // line spacing equally above and below the glyphs.
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.spacingSmall,
                  bottom: AppSizes.spacingSmall + _kRacerCardBorderWidth,
                ),
                child: Text(
                  racer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textHeightBehavior: const TextHeightBehavior(
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game screen layout — sky behind a glass word bar
//
// The word bar sits at the top; the game area fills the rest. The sky image
// spans from the top of the word bar down to the game area's horizon, so the
// word bar's blur has sky behind it. Paint order: sky, game, word bar.
// ─────────────────────────────────────────────────────────────────────────────

enum _GameSlot { sky, game, wordBar }

class _SkyUnderWordBarLayout extends MultiChildLayoutDelegate {
  /// Bottom safe-area inset the game area paints under (see _buildGameArea).
  final double bottomInset;

  _SkyUnderWordBarLayout({required this.bottomInset});

  @override
  void performLayout(Size size) {
    final wordBarH = layoutChild(
      _GameSlot.wordBar,
      BoxConstraints.tightFor(width: size.width),
    ).height;
    positionChild(_GameSlot.wordBar, Offset.zero);

    final gameH = math.max(0.0, size.height - wordBarH);
    layoutChild(_GameSlot.game, BoxConstraints.tight(Size(size.width, gameH)));
    positionChild(_GameSlot.game, Offset(0, wordBarH));

    final horizonY = math.max(0.0, gameH - bottomInset) * _kHorizonFrac;
    layoutChild(
      _GameSlot.sky,
      BoxConstraints.tight(Size(size.width, wordBarH + horizonY)),
    );
    positionChild(_GameSlot.sky, Offset.zero);
  }

  @override
  bool shouldRelayout(_SkyUnderWordBarLayout old) =>
      old.bottomInset != bottomInset;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Perspective road painter
// ─────────────────────────────────────────────────────────────────────────────

class _PerspectiveRoadPainter extends CustomPainter {
  /// Height of the play area that the perspective fractions are based on.
  /// The canvas may be taller (it runs under the bottom safe-area inset);
  /// the road is extended down to the canvas bottom.
  final double playHeight;
  final double scrollOffset;
  final int characterLane;

  const _PerspectiveRoadPainter({
    required this.playHeight,
    required this.scrollOffset,
    required this.characterLane,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = playHeight;
    final horizonY = h * _kHorizonFrac;
    final groundY = h * _kGroundFrac;
    final vanishX = w * _kVanishXFrac;

    // Road lines are defined to reach their bottom X at the play-area bottom;
    // extend them along the same slope down to the canvas bottom.
    final bottomY = size.height;
    final stretch = (bottomY - horizonY) / (h - horizonY);
    double bottomX(double frac) => vanishX + (w * frac - vanishX) * stretch;

    // ── Sky ────────────────────────────────────────────────────────────────
    // Drawn by the sky image behind this painter (see _kSkyAsset).

    // ── Road trapezoid — athletics track red ───────────────────────────────
    // Track extends beyond each screen edge (see _kTrackLeftFrac / Right).
    final roadRect = Rect.fromLTWH(0, horizonY, w, bottomY - horizonY);
    final roadPath = Path()
      ..moveTo(vanishX, horizonY)
      ..lineTo(bottomX(_kTrackLeftFrac), bottomY)
      ..lineTo(bottomX(_kTrackRightFrac), bottomY)
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
      ..lineTo(bottomX(_kTrackLeftFrac), bottomY)
      ..close();
    final rightGrassPath = Path()
      ..moveTo(w, horizonY)
      ..lineTo(vanishX, horizonY)
      ..lineTo(bottomX(_kTrackRightFrac), bottomY)
      ..close();
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF66BB6A), Color(0xFF81C784)],
      ).createShader(roadRect);
    canvas.drawPath(leftGrassPath, grassPaint);
    canvas.drawPath(rightGrassPath, grassPaint);

    // Road kerb lines — thick white edge lines
    _drawConvergingLine(
      canvas,
      vanishX, horizonY, bottomX(_kTrackLeftFrac), bottomY,
      paint: Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    _drawConvergingLine(
      canvas,
      vanishX, horizonY, bottomX(_kTrackRightFrac), bottomY,
      paint: Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // ── Lane dividers — solid white lines (running track style) ───────────
    _drawSolidConvergingLine(
      canvas,
      vanishX,
      horizonY,
      bottomX(_kTrackLeftFrac + _kLaneWidthFrac),
      bottomY,
    );
    _drawSolidConvergingLine(
      canvas,
      vanishX,
      horizonY,
      bottomX(_kTrackRightFrac - _kLaneWidthFrac),
      bottomY,
    );

    // ── Scrolling horizontal track markings (motion cue) ──────────────────
    _drawTrackMarkings(canvas, vanishX, horizonY, groundY, w, scrollOffset);

    // ── Current-lane highlight ─────────────────────────────────────────────
    final laneL = _kTrackLeftFrac + characterLane * _kLaneWidthFrac;
    final laneR = laneL + _kLaneWidthFrac;
    final highlightPath = Path()
      ..moveTo(vanishX, horizonY)
      ..lineTo(bottomX(laneL), bottomY)
      ..lineTo(bottomX(laneR), bottomY)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
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
      final xLeft = vanishX +
          t * _kGroundToBottomRatio * (w * _kTrackLeftFrac - vanishX);
      final xRight = vanishX +
          t * _kGroundToBottomRatio * (w * _kTrackRightFrac - vanishX);

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
      old.playHeight != playHeight ||
      old.scrollOffset != scrollOffset ||
      old.characterLane != characterLane;
}

// ─────────────────────────────────────────────────────────────────────────────
// Runner sprite
//
// Shows one frame of the 4-frame run cycle, or the jump pose while airborne.
// The screen picks the run frame from a phase that advances with the road
// scroll, so stride rate tracks speed. Feet are anchored to the road ground
// line.
// ─────────────────────────────────────────────────────────────────────────────

class _RunnerSprite extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  const _RunnerSprite({
    required this.asset,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      // Keep the previous frame on screen while the next one resolves.
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BSL symbol disc — round white token
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiscPainter(scale: scale, highlightBorder: highlightBorder),
        // Clip circle sits 2 px inside the disc edge.
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: SignLetterImage(
              letter: letter,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disc painter — round white token with a soft shadow and grey rim
// ─────────────────────────────────────────────────────────────────────────────

class _DiscPainter extends CustomPainter {
  final double scale;
  final bool highlightBorder;
  const _DiscPainter({required this.scale, this.highlightBorder = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromLTWH(w * 0.06, h * 0.10, w, h),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (8 * scale).clamp(3, 12)),
    );

    // Rim — grey band below the face simulating depth
    canvas.drawOval(
      Rect.fromLTWH(0, h * 0.06, w, h),
      Paint()..color = const Color(0xFFB0BEC5),
    );

    // Face — white
    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);

    // Training-mode highlight — green ring around the correct disc
    if (highlightBorder) {
      canvas.drawOval(
        Rect.fromLTWH(-4, -4, w + 8, h + 8),
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
  final String locale;
  const _SprintCenterHud({required this.provider, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(locale: locale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lives hearts
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            provider.currentMaxLives,
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
            Text(
              l.translate('bsl_sprint.words_label'),
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${provider.wordsCompleted}',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 22,
                fontWeight: FontWeight.w600,
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

/// Frosted-glass strip that blurs whatever is painted behind it (the sky).
class _GlassPanel extends StatelessWidget {
  final double? height;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const _GlassPanel({
    this.height,
    this.alignment,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          height: height,
          alignment: alignment,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WordBar extends StatelessWidget {
  final String word;
  final int letterIndex;
  final int levelNumber;
  final String locale;

  const _WordBar({
    required this.word,
    required this.letterIndex,
    required this.levelNumber,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final s = (levelNumber <= 1 ? 1.5 : 1.0) * 1.25;
    final showBsl = levelNumber <= 1;
    final l = AppLocalizations(locale: locale);

    if (word.isEmpty) {
      return _GlassPanel(
        height: 80 * s,
        alignment: Alignment.center,
        child: Text(
          l.translate('bsl_sprint.get_ready'),
          style: const TextStyle(
              color: Colors.white60, fontFamily: 'Quicksand', fontSize: 20),
        ),
      );
    }

    return _GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.translate('bsl_sprint.collect_instruction'),
            style: const TextStyle(
                color: Colors.white60, fontSize: 11, fontFamily: 'Quicksand'),
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
                            child: SignLetterImage(
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
                          fontFamily: 'OpenDyslexic',
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


