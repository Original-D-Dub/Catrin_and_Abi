import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Animation, PaintingStyle;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/clothes_line_models.dart';
import '../providers/clothes_line_provider.dart';
import '../widgets/clothing_svg_widget.dart';

class ClothesLineScreen extends StatelessWidget {
  const ClothesLineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClothesLineProvider(),
      child: const _ClothesLineView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ClothesLineView extends StatefulWidget {
  const _ClothesLineView();

  @override
  State<_ClothesLineView> createState() => _ClothesLineViewState();
}

class _ClothesLineViewState extends State<_ClothesLineView>
    with TickerProviderStateMixin {
  late final ClothesLineProvider _provider;
  late final AnimationController _slideController;
  late final Animation<double> _slide;

  // ── Level 2 conveyor-belt scroll ──────────────────────────────────────────
  late final Ticker _l2Ticker;
  Duration _l2PrevElapsed = Duration.zero;
  final _rng = math.Random();

  final List<_L2Item> _l2Items = [];
  bool _l2SpawnNextAsTarget = false;
  int _l2SkipBeforeTarget = 0;   // random items to spawn before respawning target
  ClothingItem? _l2NextTargetItem; // pre-set from questions array before spawning

  static const double _l2ScrollSpeed  = 0.06;  // screen widths / second
  static const double _l2SlotFraction = 0.28;  // spacing between item centres
  static const double _l2ExitThreshold = -0.18; // remove item when centre x < this
  static const double _l2SpawnLimit   = 1.38;  // keep items queued up to this x

  @override
  void initState() {
    super.initState();
    _provider = context.read<ClothesLineProvider>();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = CurvedAnimation(parent: _slideController, curve: Curves.easeInOut);
    _l2Ticker = createTicker(_onL2Tick);
    ClothingSvgWidget.precache(
      clothingDefinitions.map((d) => 'assets/images/clothes-svg/${d.name}.svg').toList(),
      clothingColours,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _l2Ticker.dispose();
    super.dispose();
  }

  // ── Level 1 handlers ────────────────────────────────────────────────────────

  Future<void> _handleCorrect() async {
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    await _slideController.animateTo(1.0);
    if (!mounted) return;
    _provider.nextItem();
    _slideController.value = 0.0;
  }

  Future<void> _handleWrong() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _provider.resumePlaying();
  }

  // ── Level 2 — conveyor-belt tick ────────────────────────────────────────────

  void _onL2Tick(Duration elapsed) {
    if (_provider.state != ClothesLineState.playing) {
      _l2PrevElapsed = elapsed; // keep clock synced so dt stays 0 on resume
      return;
    }

    final dt = _l2PrevElapsed == Duration.zero
        ? 0.0
        : (elapsed - _l2PrevElapsed).inMilliseconds / 1000.0;
    _l2PrevElapsed = elapsed;

    // Scroll every item left
    for (final item in _l2Items) {
      item.xNorm -= _l2ScrollSpeed * dt;
    }

    // Handle items that have exited the left edge
    final exited = _l2Items.where((it) => it.xNorm < _l2ExitThreshold).toList();
    for (final ex in exited) {
      _l2Items.remove(ex);
      if (ex.isTarget) {
        // Target missed — schedule respawn 1 or 2 items later
        _l2SpawnNextAsTarget = true;
        _l2SkipBeforeTarget = _rng.nextInt(2);
      }
    }

    // Maintain items queued up to _l2SpawnLimit
    double maxX = _l2Items.isEmpty
        ? 0.6
        : _l2Items.map((e) => e.xNorm).reduce(math.max);
    while (maxX < _l2SpawnLimit) {
      maxX += _l2SlotFraction;
      final bool spawnTarget =
          _l2SpawnNextAsTarget && _l2SkipBeforeTarget <= 0;
      if (_l2SpawnNextAsTarget) {
        if (spawnTarget) {
          _l2SpawnNextAsTarget = false;
        } else {
          _l2SkipBeforeTarget--;
        }
      }
      final targetItem = _l2NextTargetItem ?? _provider.currentItem;
      final visibleDefs = _l2Items.map((it) => it.clothingItem.definition).toSet()
          ..add(targetItem.definition);
      // Also block the next question's clothing type from appearing as a
      // distractor so it can never be on screen when it becomes the target.
      final nextIdx = _provider.currentIndex + 1;
      if (nextIdx < _provider.questions.length) {
        visibleDefs.add(_provider.questions[nextIdx].item.definition);
      }
      _l2Items.add(_L2Item(
        clothingItem:
            spawnTarget ? targetItem : _randomClothingItem(exclude: visibleDefs),
        xNorm: maxX,
        isTarget: spawnTarget,
      ));
      if (spawnTarget) _l2NextTargetItem = null;
    }

    setState(() {});
  }

  // ── Level 2 — helpers ────────────────────────────────────────────────────────

  void _initL2Items() {
    _l2Items.clear();
    _l2SpawnNextAsTarget = false;
    _l2SkipBeforeTarget = 0;
    _l2PrevElapsed = Duration.zero;
    _l2NextTargetItem = null;

    // Place items centred around 0.7 (right of centre, scrolling left into view).
    // Build the exclude set incrementally so no two initial slots share a definition,
    // and pre-exclude the next question's type so it can't appear as a distractor.
    final usedDefs = <ClothingDefinition>{_provider.currentItem.definition};
    final nextIdx = _provider.currentIndex + 1;
    if (nextIdx < _provider.questions.length) {
      usedDefs.add(_provider.questions[nextIdx].item.definition);
    }
    for (int i = 0; i < 5; i++) {
      final x = 0.14 + i * _l2SlotFraction;
      final isTarget = i == 2; // third item is the target
      ClothingItem clothingItem;
      if (isTarget) {
        clothingItem = _provider.currentItem;
      } else {
        clothingItem = _randomClothingItem(exclude: usedDefs);
        usedDefs.add(clothingItem.definition);
      }
      _l2Items.add(_L2Item(clothingItem: clothingItem, xNorm: x, isTarget: isTarget));
    }
  }

  ClothingItem _randomClothingItem({required Set<ClothingDefinition> exclude}) {
    var available = clothingDefinitions.where((d) => !exclude.contains(d)).toList();
    // Fallback: if every definition is already on screen, only respect the target.
    if (available.isEmpty) {
      available = clothingDefinitions.where((d) => d != exclude.first).toList();
    }
    final def = available[_rng.nextInt(available.length)];
    final colour = clothingColours[_rng.nextInt(clothingColours.length)];
    return ClothingItem(definition: def, colour: colour);
  }

  // ── Level 2 handlers ─────────────────────────────────────────────────────────

  Future<void> _handleCorrectL2() async {
    // Un-highlight the answered item while feedback shows.
    for (final it in _l2Items) {
      if (it.isTarget) it.isTarget = false;
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _provider.nextItem();
    // Queue the new target for the next spawn (unless game just finished).
    if (_provider.state != ClothesLineState.finished) {
      // Snapshot the item from the pre-generated questions array so the spawn
      // logic always uses the correct colour regardless of tick timing.
      _l2NextTargetItem = _provider.currentItem;
      _l2SpawnNextAsTarget = true;
      _l2SkipBeforeTarget = 0;
    }
  }

  Future<void> _handleWrongL2() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _provider.resumePlaying();
  }

  // ── Shared answer dispatcher ─────────────────────────────────────────────────

  void _onAnswer(String colour) {
    final correct = _provider.selectAnswer(colour);
    if (_provider.level == 3) {
      if (correct) { _handleCorrectL2(); } else { _handleWrongL2(); }
    } else {
      if (correct) { _handleCorrect(); } else { _handleWrong(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClothesLineProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.state == ClothesLineState.finished
              ? null
              : GameAppBar(
                  title: 'Clothes Line',
                  onBack: provider.showLevelSelect
                      ? () => Navigator.pop(context)
                      : () {
                          if (_l2Ticker.isActive) _l2Ticker.stop();
                          provider.goToLevelSelect();
                        },
                ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFFE0F4FF)],
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(context, provider)
                      : Column(
                    children: [
                      // Score bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score: ${provider.score}',
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              '${provider.currentIndex + 1} / ${ClothesLineProvider.totalItems}',
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 18,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Question
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          provider.state == ClothesLineState.finished
                              ? 'Well done!'
                              : provider.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Clothes line
                      Expanded(
                        child: provider.level == 3
                            ? _L2ClothesLineView(
                                items: _l2Items,
                                gameState: provider.state,
                              )
                            : AnimatedBuilder(
                                animation: _slide,
                                builder: (context, _) => _ClothesLine(
                                  items: provider.items,
                                  currentIndex: provider.currentIndex,
                                  slideValue: _slide.value,
                                  gameState: provider.state,
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      // Answer buttons
                      if (provider.state != ClothesLineState.finished)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const gaps = 3 * 8.0;
                              final buttonSize =
                                  (constraints.maxWidth - gaps) / 4;
                              return SizedBox(
                                height: buttonSize,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: provider.answerChoices
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final colour = e.value;
                                    final isDisabled = provider.state !=
                                        ClothesLineState.playing;
                                    final isCorrect =
                                        provider.state ==
                                                ClothesLineState.correct &&
                                            provider.selectedAnswer == colour;
                                    final isWrong =
                                        provider.state ==
                                                ClothesLineState.wrong &&
                                            provider.selectedAnswer == colour;
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            left: e.key == 0 ? 0 : 8),
                                        child: _ColourButton(
                                          colourName: colour,
                                          isCorrect: isCorrect,
                                          isWrong: isWrong,
                                          isDisabled: isDisabled,
                                          onPressed: () => _onAnswer(colour),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Success overlay
                if (provider.state == ClothesLineState.finished)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'clothes_line',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: false,
                      onPlayAgain: () {
                        provider.resetGame();
                        if (provider.level == 3) {
                          _initL2Items();
                          if (!_l2Ticker.isActive) _l2Ticker.start();
                        }
                      },
                      onChangeLevel: () {
                        if (_l2Ticker.isActive) _l2Ticker.stop();
                        provider.goToLevelSelect();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level select ─────────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, ClothesLineProvider provider) {
    final l = AppLocalizations(locale: 'en');
    return LevelSelectScreen(
      levels: [
        LevelSelectItem(
          number: 1,
          name: l.translate('clothes_line.level1.name'),
          description: l.translate('clothes_line.level1.description'),
          color: levelColor(0),
          onTap: () {
            if (_l2Ticker.isActive) _l2Ticker.stop();
            provider.selectLevel(1);
          },
        ),
        LevelSelectItem(
          number: 2,
          name: l.translate('clothes_line.level2.name'),
          description: l.translate('clothes_line.level2.description'),
          color: levelColor(1),
          onTap: () {
            if (_l2Ticker.isActive) _l2Ticker.stop();
            provider.selectLevel(2);
          },
        ),
        LevelSelectItem(
          number: 3,
          name: l.translate('clothes_line.level3.name'),
          description: l.translate('clothes_line.level3.description'),
          color: levelColor(2),
          onTap: () {
            provider.selectLevel(3);
            _initL2Items();
            _l2Ticker.start();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 2 line item (mutable — position and target flag change each tick)
// ─────────────────────────────────────────────────────────────────────────────

class _L2Item {
  ClothingItem clothingItem;
  double xNorm; // centre x as fraction of screen width (0 = left, 1 = right)
  bool isTarget;

  _L2Item({
    required this.clothingItem,
    required this.xNorm,
    this.isTarget = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 1 clothes line widget
// ─────────────────────────────────────────────────────────────────────────────

class _ClothesLine extends StatelessWidget {
  final List<ClothingItem> items;
  final int currentIndex;
  final double slideValue; // 0.0 = steady, 1.0 = slid one slot left
  final ClothesLineState gameState;

  const _ClothesLine({
    required this.items,
    required this.currentIndex,
    required this.slideValue,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final itemW = w * 0.55;
      const ropeY = 48.0;
      const pegH = 22.0;
      final cx = w / 2;

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: _RopePainter(ropeY: ropeY, pegXs: [cx], pegH: pegH, itemW: itemW),
          ),
          Positioned(
            left: cx - itemW / 2,
            top: ropeY + pegH,
            child: _ClothingItemWidget(
              item: items[currentIndex],
              width: itemW,
              isCurrent: true,
              isPast: false,
              gameState: gameState,
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rope painter
// ─────────────────────────────────────────────────────────────────────────────

class _RopePainter extends CustomPainter {
  final double ropeY;
  final List<double> pegXs;
  final double pegH;
  final double itemW;

  const _RopePainter({
    required this.ropeY,
    required this.pegXs,
    required this.pegH,
    required this.itemW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rope
    final ropePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF8D6E63),
          const Color(0xFFBCAAA4),
          const Color(0xFF8D6E63),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, ropeY - 3, size.width, 6))
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, ropeY),
      Offset(size.width, ropeY),
      ropePaint,
    );

    // Wooden pegs at each item position
    for (final cx in pegXs) {
      _drawPeg(canvas, cx, ropeY, pegH);
    }
  }

  void _drawPeg(Canvas canvas, double cx, double ropeY, double pegH) {
    const pegW = 10.0;
    // Pegs at 30% in from each edge (20% of itemW from centre)
    final offset = itemW * 0.17;
    for (final pegCx in [cx - offset, cx + offset]) {
      final pegRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(pegCx, ropeY + pegH / 2), width: pegW, height: pegH),
        const Radius.circular(3),
      );
      canvas.drawRRect(pegRect, Paint()..color = const Color(0xFF6D4C41));
      canvas.drawRRect(
        pegRect,
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RopePainter old) =>
      old.ropeY != ropeY || old.pegXs != pegXs || old.itemW != itemW;
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual clothing item widget
// ─────────────────────────────────────────────────────────────────────────────

class _ClothingItemWidget extends StatelessWidget {
  final ClothingItem item;
  final double width;
  final bool isCurrent;
  final bool isPast;
  final ClothesLineState gameState;

  const _ClothingItemWidget({
    required this.item,
    required this.width,
    required this.isCurrent,
    required this.isPast,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final svg = Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: SizedBox(
        width: width,
        child: ClothingSvgWidget(
          assetPath: item.assetPath,
          colourName: item.colour,
        ),
      ),
    );

    return svg;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour answer button — level 2 character_id style
// ─────────────────────────────────────────────────────────────────────────────

class _ColourButton extends StatelessWidget {
  final String colourName;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ColourButton({
    required this.colourName,
    required this.isCorrect,
    required this.isWrong,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColour;
    final Color borderColour;

    if (isCorrect) {
      bgColour = AppColors.success;
      borderColour = AppColors.success;
    } else if (isWrong) {
      bgColour = AppColors.accentRed;
      borderColour = AppColors.accentRed;
    } else {
      bgColour = Colors.white;
      borderColour = AppColors.catrinBlue;
    }

    final scale = (isCorrect || isWrong) ? 1.1 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bgColour,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(color: borderColour, width: 2),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: borderColour.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isDisabled && !isCorrect && !isWrong ? 0.5 : 1.0,
            child: const {'green', 'blue', 'pink', 'purple', 'red', 'brown', 'white'}
                    .contains(colourName)
                ? _BslColourRiveButton(key: ValueKey(colourName), colourName: colourName)
                : Image.asset(
                    'assets/images/colours_BSL/$colourName.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        colourName[0].toUpperCase() +
                            colourName.substring(1),
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 2 clothes-line view — conveyor belt
// ─────────────────────────────────────────────────────────────────────────────

class _L2ClothesLineView extends StatelessWidget {
  final List<_L2Item> items;
  final ClothesLineState gameState;

  const _L2ClothesLineView({
    required this.items,
    required this.gameState,
  });

  static const double _slotFraction = 0.28;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final itemW = w * _slotFraction * 0.84;
      const ropeY = 48.0;
      const pegH = 22.0;
      const stringH = 0.0;

      // Only pass peg x-positions for items that are on-screen.
      final visiblePegXs = items
          .where((it) => it.xNorm > -0.15 && it.xNorm < 1.15)
          .map((it) => it.xNorm * w)
          .toList();

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: _RopePainter(
              ropeY: ropeY,
              pegXs: visiblePegXs,
              pegH: pegH,
              itemW: itemW,
            ),
          ),
          // Render items back-to-front (left items behind right items).
          for (final item in items)
            Positioned(
              key: ObjectKey(item),
              left: item.xNorm * w - itemW / 2,
              top: ropeY + pegH + stringH,
              child: _ClothingItemWidget(
                item: item.clothingItem,
                width: itemW,
                isCurrent: item.isTarget,
                isPast: false,
                gameState: item.isTarget
                    ? gameState
                    : ClothesLineState.playing,
              ),
            ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rive-animated BSL colour widget (green, blue, pink, purple)
// ─────────────────────────────────────────────────────────────────────────────

class _BslColourRiveButton extends StatefulWidget {
  const _BslColourRiveButton({super.key, required this.colourName});

  final String colourName;

  @override
  State<_BslColourRiveButton> createState() => _BslColourRiveButtonState();
}

class _BslColourRiveButtonState extends State<_BslColourRiveButton> {
  late final FileLoader _fileLoader;
  TriggerInput? _playTrigger;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/images/colours_BSL/${widget.colourName}.riv',
      riveFactory: Factory.flutter,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fileLoader.dispose();
    super.dispose();
  }

  void _onLoaded(RiveLoaded state) {
    // ignore: deprecated_member_use
    _playTrigger = state.controller.stateMachine
        .trigger('play_${widget.colourName}');
    _triggerAnimation();
    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _triggerAnimation(),
    );
  }

  void _triggerAnimation() {
    _playTrigger?.fire();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _fileLoader,
      artboardSelector: ArtboardSelector.byDefault(),
      stateMachineSelector: StateMachineSelector.byName(
          '${widget.colourName}_state_machine'),
      onLoaded: _onLoaded,
      builder: (context, state) => switch (state) {
        RiveLoading() => const SizedBox.shrink(),
        RiveFailed() => Center(
            child: Text(
              widget.colourName[0].toUpperCase() +
                  widget.colourName.substring(1),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        RiveLoaded() => RiveWidget(
            controller: state.controller,
            fit: Fit.contain,
          ),
      },
    );
  }
}
