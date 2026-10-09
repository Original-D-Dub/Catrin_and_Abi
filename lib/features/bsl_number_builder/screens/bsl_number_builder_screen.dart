import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/bsl_till.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/rotate_device_overlay.dart';
import '../models/belt_item_images.dart';
import '../models/number_builder_game.dart';
import '../models/number_builder_level.dart';
import '../widgets/belt_item.dart';
import '../widgets/coin_burst.dart';
import '../widgets/coin_counter.dart';
import '../widgets/conveyor_belt.dart';
import '../widgets/factory_background.dart';

enum _ItemPhase { arriving, waiting, correct, leaving }

/// BSL Number Builder: priced items ride a conveyor belt from the left edge
/// into view, and the player rings each price up on the BSL till.
///
/// Opens on a level select ([numberBuilderLevels]); each level is a set
/// number of items. The game itself is landscape only — in portrait a
/// [RotateDeviceOverlay] replaces the scene.
class BslNumberBuilderScreen extends StatefulWidget {
  final String locale;

  /// Level number to start straight into, skipping the level select.
  final int? startLevel;

  /// Seeds the game's randomness; for tests.
  final Random? random;

  const BslNumberBuilderScreen({
    super.key,
    this.locale = 'en',
    this.startLevel,
    this.random,
  });

  @override
  State<BslNumberBuilderScreen> createState() => _BslNumberBuilderScreenState();
}

class _BslNumberBuilderScreenState extends State<BslNumberBuilderScreen>
    with SingleTickerProviderStateMixin {
  static const double _beltTop = 0.45;
  static const double _beltBottom = 0.71;

  /// Fraction of the belt's height where items rest: on the dark belt
  /// surface, just above the front rail.
  static const double _itemRestY = 0.4;

  /// Gap between the screen's left edge and the belt's.
  static const double _beltLeft = 0;

  /// Most of the screen width the till may take on squarer (tablet)
  /// screens.
  static const double _tillMaxWidth = 0.566;

  /// Shortest side below which the screen is treated as a phone.
  static const double _phoneBreakpoint = 600;

  static const Duration _arriveDuration = Duration(milliseconds: 1400);
  static const Duration _leaveDuration = Duration(milliseconds: 800);
  static const Duration _tickDuration = Duration(milliseconds: 900);

  /// The level being played; null while choosing one.
  NumberBuilderLevel? _level;
  late NumberBuilderGame _game;
  bool _levelComplete = false;

  /// Bumped whenever a level starts or is left, so callbacks from the
  /// previous run can tell they're stale.
  int _session = 0;

  late final AnimationController _move;
  _ItemPhase _phase = _ItemPhase.arriving;
  int? _display;

  late final _itemImages = beltItemImages(widget.locale);
  late final _imageRandom = widget.random ?? Random();
  String? _itemImage;
  Timer? _tickTimer;

  /// Counts down a timed level, once its first item is ready.
  Timer? _clock;
  int _secondsLeft = 0;

  final _sceneKey = GlobalKey();
  final _tillKey = GlobalKey();
  final _counterCoinKey = GlobalKey();

  /// Coins shown on the counter. Lags behind the game's total while coins
  /// are flying up to it.
  int _bankedCoins = 0;

  /// The in-flight coin burst, if any. A new key per burst restarts it.
  CoinBurst? _burst;
  int _burstId = 0;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this);
    if (widget.startLevel case final number?) {
      _startLevel(numberBuilderLevels[number - 1]);
    }
  }

  void _startLevel(NumberBuilderLevel level) {
    _stopTimers();
    _session++;
    _level = level;
    _levelComplete = false;
    _secondsLeft = level.timeLimit?.inSeconds ?? 0;
    _game = NumberBuilderGame(
      prices: level.pricesFrom(BslTillLayout.standard.values),
      tagStyle: level.tagStyle,
      itemCount: level.itemCount,
      priceWeights: level.priceWeights,
      random: widget.random,
    );
    _bankedCoins = 0;
    _burst = null;
    _game.nextItem();
    _pickImage();
    _arrive();
  }

  void _pickImage() {
    _itemImage = pickBeltItemImage(
      _itemImages,
      _imageRandom,
      previous: _itemImage,
    );
  }

  void _showLevelSelect() {
    _stopTimers();
    _move.stop();
    setState(() {
      _session++;
      _level = null;
      _burst = null;
    });
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _clock?.cancel();
    _clock = null;
  }

  @override
  void dispose() {
    _stopTimers();
    _move.dispose();
    super.dispose();
  }

  void _startClockIfTimed() {
    if (_level?.timeLimit == null || _clock != null) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _endLevel();
    });
  }

  /// Ends the level and shows the coin total.
  void _endLevel() {
    _clock?.cancel();
    setState(() => _levelComplete = true);
  }

  void _arrive() {
    final session = _session;
    setState(() {
      _phase = _ItemPhase.arriving;
      _display = null;
    });
    _move.duration = _arriveDuration;
    _move.forward(from: 0).then((_) {
      if (mounted && session == _session) {
        setState(() => _phase = _ItemPhase.waiting);
        _startClockIfTimed();
      }
    });
  }

  void _leave() {
    final session = _session;
    setState(() => _phase = _ItemPhase.leaving);
    _move.duration = _leaveDuration;
    _move.forward(from: 0).then((_) {
      if (!mounted || session != _session || _levelComplete) return;
      _game.nextItem();
      _pickImage();
      _arrive();
    });
  }

  void _onKeyPressed(int value) {
    final correct = _game.submit(value);
    setState(() {
      _display = value;
      if (correct) {
        _phase = _ItemPhase.correct;
        _payOut(value);
      } else {
        _burst = null;
        _bankedCoins = _game.coins;
      }
    });
    if (!correct) return;
    if (_game.isComplete) _endLevel();
    _tickTimer = Timer(_tickDuration, _leave);
  }

  /// Sends [amount] coins flying from the till's LCD up to the counter,
  /// which counts up to the new total as they land.
  void _payOut(int amount) {
    final total = _game.coins;
    final from = _localCentre(
      _tillKey,
      fraction: BslTillLayout.standard.lcdCentreFraction,
    );
    final to = _localCentre(_counterCoinKey);
    if (from == null || to == null || MediaQuery.disableAnimationsOf(context)) {
      _bankedCoins = total;
      return;
    }
    final id = ++_burstId;
    _burst = CoinBurst(
      key: ValueKey(id),
      from: from,
      to: to,
      count: amount,
      onFirstLanded: () {
        if (mounted && _burstId == id) setState(() => _bankedCoins = total);
      },
      onDone: () {
        if (mounted && _burstId == id) setState(() => _burst = null);
      },
    );
  }

  /// The point at [fraction] of [key]'s widget (its centre by default), in
  /// the scene stack's coordinates.
  Offset? _localCentre(
    GlobalKey key, {
    Offset fraction = const Offset(0.5, 0.5),
  }) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final scene = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || scene == null) return null;
    final point = Offset(
      box.size.width * fraction.dx,
      box.size.height * fraction.dy,
    );
    return scene.globalToLocal(box.localToGlobal(point));
  }

  @override
  Widget build(BuildContext context) {
    if (_level == null) return _buildLevelSelect(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return RotateDeviceOverlay(
              locale: widget.locale,
              onBack: _showLevelSelect,
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: _buildScene(context)),
              if (_levelComplete) Positioned.fill(child: _buildSuccess()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLevelSelect(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GameAppBar(
        title: localizer('bsl_number_builder.title'),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/backgrounds/math-background-1080x1920.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LevelSelectScreen(
            subtitle: localizer('bsl_number_builder.subtitle'),
            locale: widget.locale,
            levels: [
              for (final (i, level) in numberBuilderLevels.indexed)
                LevelSelectItem(
                  number: level.number,
                  name: localizer(level.nameKey),
                  color: levelColor(i),
                  onTap: () => setState(() => _startLevel(level)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final level = _level!;
    final hasNext = level.number < numberBuilderLevels.length;
    final localizer = AppLocalizations(locale: widget.locale);
    return GameSuccessOverlay(
      locale: widget.locale,
      scoreStyle: SuccessScoreStyle.none,
      score: _game.coins,
      extraContent: _CoinTotal(
        coins: _game.coins,
        before: localizer('bsl_number_builder.you_collected'),
        after: localizer(
          _game.coins == 1
              ? 'bsl_number_builder.coin'
              : 'bsl_number_builder.coins',
        ),
      ),
      // Show the total big and centred in the overlay's middle slot.
      centerExtraContent: true,
      onPlayAgain: () => setState(() => _startLevel(level)),
      onNextLevel: hasNext
          ? () => setState(() => _startLevel(numberBuilderLevels[level.number]))
          : null,
      onChangeLevel: _showLevelSelect,
    );
  }

  Widget _buildScene(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Till fills the screen height, capped so it never takes more than
        // ~57% of the width on squarer landscape screens (tablets).
        const layout = BslTillLayout.standard;
        final tillWidth = min(h * layout.aspectRatio, w * _tillMaxWidth);
        final tillHeight = tillWidth / layout.aspectRatio;
        // Pushed right, part of its dark background off-screen, so the till
        // body's right edge lines up with the coin counter's.
        final counterInset =
            MediaQuery.paddingOf(context).right + AppSizes.spacingSmall;
        final tillRight =
            counterInset -
            tillWidth * (1 - layout.bodyRight / layout.canvas.width);
        final tillLeft = w - tillRight - tillWidth;
        final isPhone =
            MediaQuery.sizeOf(context).shortestSide < _phoneBreakpoint;
        final tillTop = isPhone
            // Lowered so the screen's bottom edge cuts the drawer keyhole
            // in half, freeing up height.
            ? h - tillHeight * layout.keyholeY / layout.canvas.height
            : h * 0.04;
        final beltTopY = h * _beltTop;
        final beltHeight = h * (_beltBottom - _beltTop);

        final boxSize = h * 0.2;
        final itemWidth = BeltItem.widthFor(boxSize);
        final itemHeight = BeltItem.heightFor(boxSize);
        // Where the till's dark background starts hiding the belt.
        final visibleBeltRight =
            tillLeft + tillWidth * layout.opaqueFromX / layout.canvas.width;
        final centreX = visibleBeltRight / 2 - itemWidth / 2;

        return Stack(
          key: _sceneKey,
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: FactoryBackground(
                beltTop: _beltTop,
                beltBottom: _beltBottom,
              ),
            ),
            // Belt runs from just right of the left edge to behind the middle
            // of the till.
            Positioned(
              left: _beltLeft,
              top: beltTopY,
              height: beltHeight,
              width: tillLeft + tillWidth * 0.5 - _beltLeft,
              child: const ConveyorBelt(),
            ),
            AnimatedBuilder(
              animation: _move,
              builder: (context, child) => Positioned(
                left: _itemX(
                  start: -itemWidth,
                  centre: centreX,
                  exit: visibleBeltRight + tillWidth * 0.2,
                ),
                top: beltTopY + beltHeight * _itemRestY - itemHeight,
                child: child!,
              ),
              child: BeltItem(
                boxSize: boxSize,
                image: _itemImage!,
                price: _game.price!,
                tagShowsSign: _game.tagShowsSign,
              ),
            ),
            Positioned(
              right: tillRight,
              top: tillTop,
              width: tillWidth,
              child: BslTill(
                key: _tillKey,
                display: _display?.toString(),
                showNumbers: _game.tagShowsSign,
                showTick: _phase == _ItemPhase.correct,
                enabled: _phase == _ItemPhase.waiting && !_levelComplete,
                onKeyPressed: _onKeyPressed,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingSmall),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _showLevelSelect,
                        icon: const BackArrowIcon(size: 40),
                      ),
                      const SizedBox(width: AppSizes.spacingSmall),
                      _ItemProgress(
                        done: _game.itemsDone,
                        total: _level!.itemCount,
                      ),
                      if (_level!.timeLimit != null) ...[
                        const SizedBox(width: AppSizes.spacingSmall),
                        _Countdown(secondsLeft: _secondsLeft),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingSmall),
                  child: CoinCounter(
                    coins: _bankedCoins,
                    coinKey: _counterCoinKey,
                  ),
                ),
              ),
            ),
            if (_burst case final burst?) Positioned.fill(child: burst),
          ],
        );
      },
    );
  }

  double _itemX({
    required double start,
    required double centre,
    required double exit,
  }) {
    final t = _move.value;
    return switch (_phase) {
      _ItemPhase.arriving => lerpDouble(
        start,
        centre,
        Curves.easeOutCubic.transform(t),
      )!,
      _ItemPhase.leaving => lerpDouble(
        centre,
        exit,
        Curves.easeInCubic.transform(t),
      )!,
      _ItemPhase.waiting || _ItemPhase.correct => centre,
    };
  }
}

/// Pill showing how many of the level's items have been rung up, out of
/// [total] when the level has a target.
class _ItemProgress extends StatelessWidget {
  final int done;
  final int? total;

  const _ItemProgress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: total == null ? '$done items' : '$done of $total items',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_rounded, color: Color(0xFFD29D62)),
            const SizedBox(width: 8),
            Text(
              total == null ? '$done' : '$done / $total',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill counting down a timed level's seconds; turns red near the end.
class _Countdown extends StatelessWidget {
  final int secondsLeft;

  const _Countdown({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final s = max(secondsLeft, 0);
    final urgent = s <= 10;
    final colour = urgent ? const Color(0xFFFF5A4E) : Colors.white;
    return Semantics(
      label: '$s seconds left',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colour, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, color: colour),
            const SizedBox(width: 8),
            Text(
              '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: colour,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The success overlay's total on one line: [before], a big gold coin and
/// the number, then [after] — e.g. "You collected (coin) 12 coins". The
/// coin and number have a dark amber outline and matching drop shadow.
class _CoinTotal extends StatelessWidget {
  final int coins;
  final String before;
  final String after;

  const _CoinTotal({
    required this.coins,
    required this.before,
    required this.after,
  });

  /// Deep amber-brown: dark enough to frame the gold, softer than black.
  static const Color _outline = Color(0xFF5C3A00);

  /// Dark blue of the overlay's own score line.
  static const Color _labelBlue = Color(0xFF002D97);

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: AppSizes.fontSizeTitle,
    fontWeight: FontWeight.w600,
  );

  /// Dark blue text with a stroke of the same blue, which thickens the
  /// letters, as on the overlay's score line.
  static Widget _label(String text) => Stack(
    children: [
      Text(
        text,
        style: _labelStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..color = _labelBlue,
        ),
      ),
      Text(text, style: _labelStyle.copyWith(color: _labelBlue)),
    ],
  );

  static const TextStyle _numberStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w700,
    fontSize: 44,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    // Shrinks rather than overflows on short landscape phones.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(before),
          const SizedBox(width: AppSizes.spacingMedium),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoldCoin(size: 56, outlineColor: _outline),
              const SizedBox(width: 14),
              // Padding leaves room for the outline and shadow, which paint
              // outside the text's own box.
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      '$coins',
                      style: _numberStyle.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3.5
                          ..strokeJoin = StrokeJoin.round
                          ..color = _outline,
                        shadows: const [
                          Shadow(
                            color: _outline,
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$coins',
                      style: _numberStyle.copyWith(
                        color: const Color(0xFFFFC73A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          _label(after),
        ],
      ),
    );
  }
}
