import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/paper_texture_overlay.dart';
import '../../../shared/widgets/torn_paper_panel.dart';
import '../../../shared/widgets/treasure_chest.dart';
import '../../sports_collection/models/sport_card.dart';
import '../../sports_collection/widgets/sport_card_art.dart';

/// Shown when a Bubble Shooter level is finished: the points on a strip of
/// torn paper, fireworks bursting behind it, and a
/// Next button along the bottom that returns to the level map.
///
/// On a chest level ([openChest] set), after [chestDelay] the points give
/// way to a treasure chest shaking in the middle of the screen. Tapping it
/// opens it: the card it gives pops up amid fireworks as the chest fades,
/// and only then does Next appear.
class LevelCompleteModal extends StatefulWidget {
  final int score;
  final String locale;
  final VoidCallback onNext;

  /// Opens this level's chest, returning the card won (null if there's
  /// nothing to give after all). Null when the level has no chest to open.
  final Future<SportCard?> Function()? openChest;

  const LevelCompleteModal({
    super.key,
    required this.score,
    required this.onNext,
    this.locale = 'en',
    this.openChest,
  });

  /// How long the points show before the chest appears.
  static const Duration chestDelay = Duration(seconds: 4);

  static const Color purple = Color(0xFF8E44EC);

  @override
  State<LevelCompleteModal> createState() => _LevelCompleteModalState();
}

enum _Phase { score, chest, opening, card }

class _LevelCompleteModalState extends State<LevelCompleteModal>
    with TickerProviderStateMixin {
  /// Firework launch points, as fractions of the screen.
  static const _bursts = [
    Alignment(-0.6, -0.65),
    Alignment(0.55, -0.75),
    Alignment(0.0, -0.9),
    // Beside the chest, clear of the "Tap the chest!" text below it.
    Alignment(-0.65, -0.15),
    Alignment(0.6, 0.25),
  ];
  static const _colours = [
    Color(0xFFFFD54A),
    Color(0xFFFF7AB8),
    Color(0xFF8E44EC),
    Color(0xFF5FBBE1),
    Colors.white,
  ];

  final _random = Random();

  late final List<ConfettiController> _fireworks = [
    for (var i = 0; i < _bursts.length; i++)
      ConfettiController(duration: const Duration(milliseconds: 500)),
  ];
  Timer? _timer;
  int _next = 0;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();

  /// Shakes the waiting chest: a rattle, then a pause, on repeat.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// The chest opening: lid up, card rising out, chest fading away.
  late final AnimationController _reveal =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..addStatusListener((_) {
        // Next appears once the card has landed.
        if (mounted) setState(() {});
      });

  _Phase _phase = _Phase.score;
  SportCard? _card;
  Timer? _chestTimer;

  /// Captured once: the chest is opened during this modal, and the caller
  /// stops offering one as soon as it is.
  late final Future<SportCard?> Function()? _openChest = widget.openChest;

  bool get _showNext =>
      (_phase == _Phase.card && _reveal.isCompleted) ||
      (_phase == _Phase.score && _openChest == null);

  @override
  void initState() {
    super.initState();
    AudioService.playSuccess('bubble_shooter', locale: widget.locale);
    if (_openChest != null) {
      _chestTimer = Timer(LevelCompleteModal.chestDelay, () {
        if (!mounted) return;
        setState(() => _phase = _Phase.chest);
        if (!MediaQuery.of(context).disableAnimations) _shake.repeat();
      });
    }
    // A burst every 0.45s from a random launch point, until Next.
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted || MediaQuery.of(context).disableAnimations) return;
      _fireworks[_next].play();
      _next =
          (_next + 1 + _random.nextInt(_fireworks.length - 1)) %
          _fireworks.length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chestTimer?.cancel();
    for (final f in _fireworks) {
      f.dispose();
    }
    _pop.dispose();
    _shake.dispose();
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _onChestTapped() async {
    if (_phase != _Phase.chest) return;
    setState(() => _phase = _Phase.opening);
    _shake.stop();
    final card = await _openChest!();
    if (!mounted) return;
    if (card == null) {
      // Nothing to give after all: back to the points, with Next.
      setState(() => _phase = _Phase.score);
      return;
    }
    setState(() {
      _card = card;
      _phase = _Phase.card;
    });
    AudioService.playCorrect('bubble_shooter');
    if (!MediaQuery.of(context).disableAnimations) {
      for (final f in _fireworks) {
        f.play();
      }
    }
    _reveal.forward();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Material(
      color: const Color(0xCC1E0B3A),
      child: Stack(
        children: [
          const Positioned.fill(child: PaperTextureOverlay()),
          for (var i = 0; i < _bursts.length; i++)
            Align(
              alignment: _bursts[i],
              child: ConfettiWidget(
                confettiController: _fireworks[i],
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 22,
                maxBlastForce: 16,
                minBlastForce: 6,
                gravity: 0.18,
                emissionFrequency: 0.5,
                colors: _colours,
                minimumSize: const Size(6, 6),
                maximumSize: const Size(9, 9),
                // Round sparks rather than confetti strips.
                createParticlePath: (size) =>
                    Path()..addOval(Offset.zero & size),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: switch (_phase) {
                        _Phase.score => ScaleTransition(
                          key: const ValueKey('score'),
                          scale: CurvedAnimation(
                            parent: _pop,
                            curve: Curves.easeOutBack,
                          ),
                          child: _scoreCard(localizer),
                        ),
                        _Phase.chest || _Phase.opening => KeyedSubtree(
                          key: const ValueKey('chest'),
                          child: _waitingChest(localizer),
                        ),
                        _Phase.card => KeyedSubtree(
                          key: const ValueKey('card'),
                          child: _cardReveal(localizer),
                        ),
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    // Space kept so nothing jumps when Next appears.
                    child: AnimatedOpacity(
                      opacity: _showNext ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showNext,
                        child: ExcludeSemantics(
                          excluding: !_showNext,
                          child: PrimaryButton(
                            label: localizer('general.next'),
                            icon: Icons.arrow_forward,
                            expanded: true,
                            onPressed: widget.onNext,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _chestSize = 220;

  /// Dark blue of the stroke and drop shadow on the shared success page's
  /// heading (see `GameSuccessOverlay`).
  static const Color _darkBlue = Color(0xFF002D97);

  /// Sits behind headings so they stay readable over the fireworks.
  Widget _textBackdrop(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  /// White heading with a dark purple drop shadow, over the dark backdrop.
  Widget _heading(String text) => _textBackdrop(
    Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        shadows: [Shadow(color: Color(0xFF4A148C), offset: Offset(1, 3))],
      ),
    ),
  );

  /// The "Treasure chest!" heading, styled like the shared success page's
  /// heading: white OpenDyslexic with a dark-blue 2 px stroke and a solid
  /// drop shadow (2 px right, 4 px down).
  Widget _chestTitle(String text) {
    final style = AppTheme.celebrationAt(
      34,
    ).copyWith(fontWeight: FontWeight.bold);
    return _textBackdrop(
      Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = _darkBlue,
              shadows: const [Shadow(color: _darkBlue, offset: Offset(2, 4))],
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// The chest, shaking as if about to burst open, waiting to be tapped.
  Widget _waitingChest(AppLocalizations localizer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chestTitle(localizer('bubble_shooter.chest_title')),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: localizer('bubble_shooter.chest_tap'),
          child: GestureDetector(
            onTap: _onChestTapped,
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                // Rattle for the first half of each cycle, then rest.
                final v = _shake.value;
                final rattle = v < 0.5 ? sin(v * 2 * pi * 8) * (0.5 - v) : 0.0;
                return Transform.rotate(
                  angle: rattle * 0.22,
                  child: Transform.scale(
                    scale: 1 + rattle.abs() * 0.12,
                    child: child,
                  ),
                );
              },
              child: CustomPaint(
                size: const Size.square(_chestSize),
                painter: TreasureChestPainter(ChestState.ready),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _heading(localizer('bubble_shooter.chest_tap')),
      ],
    );
  }

  /// The chest opening and fading away as the won card rises out of it.
  Widget _cardReveal(AppLocalizations localizer) {
    final card = _card!;
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final t = _reveal.value;
        final cardT = Curves.easeOutBack.transform(
          // The lid pops open first, then the card rises out.
          ((t - 0.3) / 0.7).clamp(0.0, 1.0),
        );
        final chestFade =
            1 - Curves.easeIn.transform(((t - 0.4) / 0.6).clamp(0.0, 1.0));
        return SizedBox(
          width: 300,
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                child: Opacity(
                  opacity: chestFade,
                  child: CustomPaint(
                    size: const Size.square(_chestSize),
                    painter: TreasureChestPainter(ChestState.opened),
                  ),
                ),
              ),
              // Rises from inside the chest to the middle, growing.
              Positioned(
                top: lerpDouble(220, 0, cardT),
                child: Opacity(
                  opacity: ((t - 0.3) / 0.15).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: lerpDouble(0.25, 1, cardT),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _heading(localizer('bubble_shooter.chest_won')),
                        const SizedBox(height: 12),
                        _sportCard(card, localizer),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sportCard(SportCard card, AppLocalizations localizer) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LevelCompleteModal.purple, width: 6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(aspectRatio: 1, child: SportCardArt(card)),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              localizer(card.nameKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A148C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(AppLocalizations localizer) {
    const ink = Color(0xFF4A148C);
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingLarge),
      child: TornPaperPanel(child: _scoreContent(localizer, ink)),
    );
  }

  Widget _scoreContent(AppLocalizations localizer, Color ink) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shrinks to fit on one line rather than wrapping (the Welsh is
          // longer).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              localizer('general.welldone'),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTheme.celebrationAt(
                30,
              ).copyWith(color: LevelCompleteModal.purple),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '${widget.score} ${localizer('bubble_shooter.points')}',
            excludeSemantics: true,
            child: Column(
              children: [
                Text(
                  '${widget.score}',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: ink,
                  ),
                ),
                Text(
                  localizer('bubble_shooter.points'),
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
