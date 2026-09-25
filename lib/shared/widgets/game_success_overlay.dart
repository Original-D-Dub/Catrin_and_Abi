import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/audio_service.dart';
import '../services/auth_provider.dart';
import 'back_arrow_icon.dart';
import 'button.dart';
import 'falling_confetti_layer.dart';
import 'sign_in_banner_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Score line variants
// ─────────────────────────────────────────────────────────────────────────────

/// How the score sub-line is phrased.
enum SuccessScoreStyle {
  /// "You scored {{score}}" – used by vowel_hand, bubble_pop, bsl_maths L5
  youScored,

  /// "You matched {{score}}" – used by card_matching
  youMatched,

  /// "You got 10 correct" – used by bsl_maths L1-4, character_id
  got10Correct,

  /// Custom string passed directly via [customScoreLine]
  custom,

  /// No score sub-line
  none,
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// Shared full-screen success overlay used across all games.
///
/// Layout (top→bottom, full screen, dark scrim):
/// - "Well Done!" heading — bold white, ComicRelief, top of card
/// - Score sub-line — gold (#FFC73A)
/// - Personal best badge (optional, shown when [showPersonalBest] && result is PB)
/// - Sign-in banner (shown automatically for anonymous users)
/// - [extraContent] — arbitrary widget slot (e.g. Letter Quest word list)
/// - [Play Again] — full width green button (hidden when [onPlayAgain] is null)
/// - [Next Level] — full width pink button (hidden when [onNextLevel] is null)
///
/// The back arrow in the top-left corner (wired to [onChangeLevel]) is the
/// way back to the level select.
///
/// Plays a success sound on first display via [AudioService.playSuccess].
/// Pass [gameId] matching [GameIds] to use a game-specific custom sound, or
/// drop an MP3 at `assets/audio/{gameId}/success.mp3` and register it in
/// [AudioService._configs].
class GameSuccessOverlay extends StatefulWidget {
  // ── required callbacks ──────────────────────────────────────────────────
  /// When null the Play Again button is hidden entirely.
  final VoidCallback? onPlayAgain;
  final VoidCallback onChangeLevel;

  // ── optional callbacks ──────────────────────────────────────────────────
  /// When non-null the pink "Next Level" button is shown.
  final VoidCallback? onNextLevel;

  // ── score display ───────────────────────────────────────────────────────
  final SuccessScoreStyle scoreStyle;
  final int? score;

  /// Used when [scoreStyle] is [SuccessScoreStyle.custom].
  final String? customScoreLine;

  // ── spoken score readout ─────────────────────────────────────────────────
  /// When [scoreAudioNumber] is non-null, plays [scoreAudioPrefix] (a bare
  /// speech-file name), then the recorded number, then [scoreAudioSuffix],
  /// once the success chime finishes — see [AudioService.playCountResult].
  final String? scoreAudioPrefix;
  final int? scoreAudioNumber;
  final String? scoreAudioSuffix;

  // ── personal best ────────────────────────────────────────────────────────
  final bool showPersonalBest;
  final bool isNewPersonalBest;
  final int? personalBest;

  /// Optional unit appended to the personal best number in the badge,
  /// e.g. ' moves' → "Personal Best! 12 moves".
  final String personalBestSuffix;

  // ── success image ─────────────────────────────────────────────────────────
  /// Optional asset path for a character/celebration image shown in the
  /// middle of the overlay.
  final String? imageAsset;

  // ── background image ──────────────────────────────────────────────────────
  /// Optional full-screen background image. When provided the solid colour
  /// is replaced and [extraContent] moves into the expanded centre slot so
  /// the buttons stay pinned to the bottom.
  final String? backgroundImage;

  // ── extra content (e.g. word list for Letter Quest) ──────────────────────
  final Widget? extraContent;

  /// When true (and no [backgroundImage]/[imageAsset]), [extraContent] is
  /// shown centred in the main image slot instead of below the personal
  /// best badge — e.g. Number Race's podium.
  final bool centerExtraContent;

  // ── audio ─────────────────────────────────────────────────────────────────
  /// Game identifier used to look up a custom success sound in [AudioService].
  /// When null, "Well Done!" is spoken via TTS.
  final String? gameId;

  // ── localization ─────────────────────────────────────────────────────────
  /// UI locale ('en' or 'cy') used for all displayed text.
  final String locale;

  const GameSuccessOverlay({
    super.key,
    this.onPlayAgain,
    required this.onChangeLevel,
    this.onNextLevel,
    this.scoreStyle = SuccessScoreStyle.none,
    this.score,
    this.customScoreLine,
    this.scoreAudioPrefix,
    this.scoreAudioNumber,
    this.scoreAudioSuffix,
    this.showPersonalBest = false,
    this.isNewPersonalBest = false,
    this.personalBest,
    this.personalBestSuffix = '',
    this.imageAsset,
    this.backgroundImage,
    this.extraContent,
    this.centerExtraContent = false,
    this.gameId,
    this.locale = 'en',
  });

  @override
  State<GameSuccessOverlay> createState() => _GameSuccessOverlayState();
}

class _GameSuccessOverlayState extends State<GameSuccessOverlay>
    with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFC73A);
  static const Color _goldLight = Color(0xFFFFE08A);
  static const Color _orange = Color(0xFFFF6F00);
  static const Color _pbTextColor = Color(0xE6000000); // black @ 0.9 opacity
  static const Color _pink = Color(0xFFEE009B);
  static const Color _darkBlue = Color(0xFF002D97);

  /// Controls whether extraContent is visible (delayed 5 s when backgroundImage is set).
  bool _showExtraContent = false;
  Timer? _extraContentTimer;

  /// Controls whether the overlay itself has appeared yet (delayed on mount
  /// so the player's last in-game action/animation isn't cut off).
  bool _visible = false;
  Timer? _entryTimer;

  static const Duration _entryDelay = Duration(milliseconds: 1500);

  // ── personal-best celebration (only allocated when isNewPersonalBest) ────
  AnimationController? _pbPulseController;
  Animation<double>? _pbPulseAnimation;

  // ── sign-in link pulse (only allocated when the link is shown) ───────────
  AnimationController? _signInPulseController;
  Animation<double>? _signInPulseAnimation;
  AnimationController? _sparkleController;
  List<_StarData> _sparkleStars = const [];
  final List<ConfettiController> _fireworkControllers = [];
  final List<Timer> _fireworkTimers = [];
  static const List<double> _fireworkXFractions = [0.22, 0.5, 0.78];

  bool get _celebratePersonalBest =>
      widget.showPersonalBest && widget.isNewPersonalBest;

  static List<_StarData> _buildSparkleStars() {
    final rng = Random();
    return List.generate(7, (_) {
      return _StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 14.0 + rng.nextDouble() * 18,
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    Future<void> audioChain = AudioService.playSuccess(
      widget.gameId ?? '',
      locale: widget.locale,
      messageName: _successAudioName(),
    );

    // Spoken score readout (e.g. "You did it in 42 moves!") once the
    // success chime finishes.
    if (widget.scoreAudioNumber != null) {
      audioChain = audioChain.then((_) {
        if (!mounted) return null;
        return AudioService.playCountResult(
          widget.scoreAudioPrefix ?? '',
          widget.scoreAudioNumber!,
          widget.scoreAudioSuffix ?? '',
          locale: widget.locale,
        );
      });
    }

    // Gentle pulse on the underlined "Sign in to save" link (background
    // image mode only — the banner button pulses itself). Only allocated
    // when the player is anonymous so the link is actually rendered.
    if (widget.backgroundImage != null &&
        context.read<AuthProvider>().isAnonymous) {
      _signInPulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
      _signInPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
          parent: _signInPulseController!,
          curve: Curves.easeInOut,
        ),
      );
      // Read the link aloud once the success chime (and score readout, if
      // any) finishes.
      audioChain.then((_) {
        if (mounted) {
          AudioService.playSpeechMp3('sign_in_to_save', locale: widget.locale);
        }
      });
    }

    if (_celebratePersonalBest) _startPersonalBestCelebration();

    _entryTimer = Timer(_entryDelay, () {
      if (!mounted) return;
      setState(() => _visible = true);
      if (_celebratePersonalBest) _fireFireworks();
    });
    if (widget.backgroundImage != null && widget.extraContent != null) {
      _extraContentTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showExtraContent = true);
      });
    } else {
      _showExtraContent = true;
    }
  }

  @override
  void didUpdateWidget(covariant GameSuccessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The personal-best result (isNewPersonalBest) is often unknown at
    // mount time — callers fetch it asynchronously (e.g. after a
    // recordGameResult call) and rebuild this overlay once it arrives. When
    // that happens after initState already ran with isNewPersonalBest still
    // false, the celebration controllers were never created; start them now
    // so the badge doesn't end up frozen on a stopped animation.
    if (_celebratePersonalBest && _pbPulseController == null) {
      _startPersonalBestCelebration();
      if (_visible) _fireFireworks();
    }
  }

  /// Creates the pulse/sparkle/firework controllers and starts the
  /// continuously-repeating ones (pulse, sparkle). Safe to call more than
  /// once — a no-op after the first successful call.
  void _startPersonalBestCelebration() {
    if (_pbPulseController != null) return;

    // Double pulse (two quick beats) every 3 s, then hold flat until the
    // next cycle — a single continuous reverse-repeat was too subtle to
    // read as a "pulse" at only 10% scale.
    _pbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pbPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2200),
    ]).animate(_pbPulseController!);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sparkleStars = _buildSparkleStars();

    for (var i = 0; i < _fireworkXFractions.length; i++) {
      _fireworkControllers.add(
        ConfettiController(duration: const Duration(milliseconds: 800)),
      );
    }
  }

  /// Fires the staggered firework bursts. Only meaningful once the overlay
  /// is visible and [_startPersonalBestCelebration] has run.
  void _fireFireworks() {
    for (var i = 0; i < _fireworkControllers.length; i++) {
      _fireworkTimers.add(
        Timer(Duration(milliseconds: i * 250), () {
          if (mounted) _fireworkControllers[i].play();
        }),
      );
    }
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _extraContentTimer?.cancel();
    _signInPulseController?.dispose();
    _pbPulseController?.dispose();
    _sparkleController?.dispose();
    for (final controller in _fireworkControllers) {
      controller.dispose();
    }
    for (final timer in _fireworkTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  String _headingText(AppLocalizations localizer) =>
      (widget.score != null && widget.score! < 3)
      ? localizer('general.play_again')
      : localizer('general.welldone');

  /// Bare `general_`-prefixed clip name (see [AudioService.playSuccess]) for
  /// the spoken message that opens the overlay's audio, picked in the same
  /// priority a personal best takes over a plain win: a new personal best
  /// speaks `'personal_best'`; otherwise a good score (the same condition
  /// [_headingText] uses for "Well Done!") speaks `'congratulations'`; a low
  /// score (which shows "Play Again" instead) speaks `'well_done'`.
  String _successAudioName() {
    if (_celebratePersonalBest) return 'personal_best';
    if (widget.score != null && widget.score! < 3) return 'well_done';
    return 'congratulations';
  }

  /// Shared size for every trophy layer in the badge stack — matches the
  /// original (unchanged) top icon, so all layers line up on the same
  /// centre point instead of needing different offsets per size.
  static const double _pbIconSize = 30;

  /// Renders [icon] as stroke-only outline text, using the same
  /// Paint-stroke trick as the "Well Done!" heading above — Material icons
  /// are just glyphs in the MaterialIcons font, so a stroked [Text] gives an
  /// outlined icon where a plain [Icon] (fill-only) cannot.
  ///
  /// Wrapped in the same `SizedBox(size, size) > Center` structure [Icon]
  /// uses internally, so its glyph lines up exactly with a plain [Icon] of
  /// the same [size] rather than being sized to the raw text metrics.
  Widget _strokedIcon(
    IconData icon, {
    required double size,
    required Color color,
    required double strokeWidth,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: size,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = color,
          ),
        ),
      ),
    );
  }

  Widget _personalBestBadge(AppLocalizations localizer) {
    final pill = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _goldLight,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
        border: Border.all(color: _orange, width: 3),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.spacingMedium + 4,
        ),
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(color: _orange, width: 2),
        ),
        child: Text(
          localizer('general.personal_best'),
          textAlign: TextAlign.center,
          style: AppTheme.celebration.copyWith(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: _pbTextColor,
          ),
        ),
      ),
    );

    // All layers share [_pbIconSize] and the same top offset, so they sit
    // centred on exactly the same point, straddling the pill's top edge.
    const top = -_pbIconSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Bottom layer: orange-outlined trophy behind the whole pill, with
        // a thick 12px outer border so it peeks out around the pill's edges.
        Positioned(
          top: top,
          child: _strokedIcon(
            Icons.emoji_events,
            size: _pbIconSize,
            color: _orange,
            strokeWidth: 12,
          ),
        ),
        pill,
        // Middle layer: gold trophy with its own 8px orange outline, sitting
        // in front of the pill.
        Positioned(
          top: top,
          child: _strokedIcon(
            Icons.emoji_events,
            size: _pbIconSize,
            color: _orange,
            strokeWidth: 8,
          ),
        ),
        const Positioned(
          top: top,
          child: Icon(Icons.emoji_events, color: _gold, size: _pbIconSize),
        ),
        // Top layer: unchanged.
        const Positioned(
          top: top,
          child: Icon(
            Icons.emoji_events,
            color: _pbTextColor,
            size: _pbIconSize,
          ),
        ),
      ],
    );
  }

  String? _scoreLine(AppLocalizations localizer) {
    switch (widget.scoreStyle) {
      case SuccessScoreStyle.youScored:
        return localizer(
          'general.you_scored',
        ).replaceAll('{score}', '${widget.score}');
      case SuccessScoreStyle.youMatched:
        return localizer(
          'general.you_matched',
        ).replaceAll('{score}', '${widget.score}');
      case SuccessScoreStyle.got10Correct:
        return localizer('general.got_10_correct');
      case SuccessScoreStyle.custom:
        return widget.customScoreLine;
      case SuccessScoreStyle.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final headingText = _headingText(localizer);
    final scoreLine = _scoreLine(localizer);
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: _buildContent(context, localizer, headingText, scoreLine),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations localizer,
    String headingText,
    String? scoreLine,
  ) {
    final content = Container(
      decoration: widget.backgroundImage != null
          ? BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.backgroundImage!),
                fit: BoxFit.cover,
              ),
            )
          : BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF94E0FF).withValues(alpha: 0.93),
                  const Color(0xFF00A8F3).withValues(alpha: 0.93),
                ],
              ),
            ),
      child: SafeArea(
        child: Stack(
          children: [
            const FallingConfettiLayer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Heading row: back arrow | "Well Done!" | balance spacer ──
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.paddingLarge),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onChangeLevel,
                        child: const SizedBox(
                          width: 72,
                          height: 72,
                          child: Center(child: BackArrowIcon(size: 48)),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dark-blue 2 px stroke + solid drop shadow
                            // (2 px right, 4 px down) behind the white fill.
                            Text(
                              headingText,
                              textAlign: TextAlign.center,
                              style: AppTheme.celebration.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = _darkBlue,
                                shadows: const [
                                  Shadow(
                                    color: _darkBlue,
                                    offset: Offset(2, 4),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              headingText,
                              textAlign: TextAlign.center,
                              style: AppTheme.celebration.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 72),
                    ],
                  ),
                ),

                // ── Score sub-line ──────────────────────────────────────────
                if (scoreLine != null) ...[
                  const SizedBox(height: AppSizes.spacingMedium),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Stroke + white drop shadow, behind the solid fill.
                      Text(
                        scoreLine,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: AppSizes.fontSizeTitle,
                          fontWeight: FontWeight.w600,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 1
                            ..color = _darkBlue,
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        scoreLine,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: AppSizes.fontSizeTitle,
                          fontWeight: FontWeight.w600,
                          color: _darkBlue,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Sign-in link (backgroundImage mode only, below score) ───
                if (widget.backgroundImage != null &&
                    context.watch<AuthProvider>().isAnonymous) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.profile,
                      arguments: widget.locale,
                    ),
                    child: ScaleTransition(
                      scale:
                          _signInPulseAnimation ??
                          const AlwaysStoppedAnimation<double>(1.0),
                      child: Text(
                        localizer('general.sign_in_to_save'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 14,
                          color: _darkBlue,
                          decoration: TextDecoration.underline,
                          decorationColor: _darkBlue,
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Centre slot — image, or extraContent when backgroundImage
                // is set (pins buttons to bottom of screen)
                Expanded(
                  child: widget.backgroundImage != null
                      ? (widget.extraContent != null
                            ? AnimatedOpacity(
                                opacity: _showExtraContent ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 600),
                                // Full-area tap detector — tapping outside the box dismisses it
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showExtraContent = false),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.paddingLarge,
                                        vertical: AppSizes.spacingMedium,
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Box content — absorbs taps so they don't reach the outer dismisser
                                          GestureDetector(
                                            onTap: () {},
                                            child: widget.extraContent!,
                                          ),
                                          // Close button — top-right corner of the box
                                          Positioned(
                                            top: -14,
                                            right: -14,
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _showExtraContent = false,
                                              ),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: const BoxDecoration(
                                                  color: _darkBlue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink())
                      : (widget.imageAsset != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingLarge,
                                  vertical: AppSizes.spacingMedium,
                                ),
                                child: Image.asset(
                                  widget.imageAsset!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : (widget.centerExtraContent &&
                                      widget.extraContent != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSizes.paddingLarge,
                                          vertical: AppSizes.spacingMedium,
                                        ),
                                        child: widget.extraContent!,
                                      ),
                                    )
                                  : const SizedBox.shrink())),
                ),

                // ── Bottom elements ─────────────────────────────────────────
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Personal best badge — double border like GameHeaderBar,
                          // pulsing 10% in size when it's a new personal best.
                          //
                          // Taken out of the stretched Column flow: a hidden
                          // same-size placeholder reserves the layout space, while
                          // the real badge is absolutely positioned over it via
                          // Align/Positioned so ScaleTransition can freely pulse
                          // without the CrossAxisAlignment.stretch width lock or
                          // any clipping restricting it.
                          if (widget.showPersonalBest &&
                              widget.isNewPersonalBest) ...[
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Visibility(
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  visible: false,
                                  child: _personalBestBadge(localizer),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ScaleTransition(
                                      scale:
                                          _pbPulseAnimation ??
                                          const AlwaysStoppedAnimation<double>(
                                            1.0,
                                          ),
                                      child: _personalBestBadge(localizer),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.spacingMedium),
                          ],

                          // Extra content — only here when no backgroundImage and
                          // not already shown in the Expanded centre slot above.
                          if (widget.extraContent != null &&
                              widget.backgroundImage == null &&
                              !widget.centerExtraContent) ...[
                            widget.extraContent!,
                            const SizedBox(height: AppSizes.spacingMedium),
                          ],

                          // Sign-in banner — 14 px label; pulses itself.
                          if (context.watch<AuthProvider>().isAnonymous &&
                              widget.backgroundImage == null)
                            SignInBannerButton(locale: widget.locale),
                          if (context.watch<AuthProvider>().isAnonymous)
                            const SizedBox(height: AppSizes.spacingMedium),

                          // Buttons — same layout as the Letter Bingo
                          // celebration: Play Again full width, then Next
                          // Level full width below it. The header's back
                          // arrow is the way back to the level select.
                          if (widget.onPlayAgain != null) ...[
                            PrimaryButton(
                              label: localizer('general.play_again'),
                              icon: Icons.replay,
                              expanded: true,
                              onPressed: widget.onPlayAgain,
                            ),
                            const SizedBox(height: AppSizes.spacingMedium),
                          ],
                          if (widget.onNextLevel != null)
                            SecondaryButton(
                              label: localizer('general.next_level'),
                              expanded: true,
                              onPressed: widget.onNextLevel,
                            ),
                          const SizedBox(height: AppSizes.spacingSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!_celebratePersonalBest) return content;

    return Stack(
      children: [
        content,
        IgnorePointer(child: _buildSparkleLayer(context)),
        IgnorePointer(child: _buildFireworksLayer(context)),
      ],
    );
  }

  /// Twinkling gold stars scattered over the top half of the screen.
  Widget _buildSparkleLayer(BuildContext context) {
    final controller = _sparkleController;
    if (controller == null) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    return Stack(
      children: _sparkleStars.map((s) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, _) {
            final t = (controller.value + s.phase) % 1.0;
            final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : 2 - t * 2)).clamp(
              0.15,
              1.0,
            );
            return Positioned(
              left: s.x * size.width - s.size / 2,
              top: s.y * size.height * 0.5,
              child: Opacity(
                opacity: opacity,
                child: Icon(Icons.star, color: _gold, size: s.size),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// Staggered firework-style confetti bursts, fired once when the
  /// personal-best badge appears.
  Widget _buildFireworksLayer(BuildContext context) {
    if (_fireworkControllers.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(_fireworkControllers.length, (i) {
        return Positioned(
          left: size.width * _fireworkXFractions[i],
          top: size.height * 0.16,
          child: ConfettiWidget(
            confettiController: _fireworkControllers[i],
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 18,
            maxBlastForce: 12,
            minBlastForce: 5,
            gravity: 0.25,
            colors: const [_gold, _orange, Colors.white, _pink],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Letter Bingo variant — BINGO text with stars, no "Well Done!"
// ─────────────────────────────────────────────────────────────────────────────

/// The Letter Bingo celebration overlay.
///
/// Shows multicoloured "BINGO" letters with a white outer stroke,
/// animated gold stars, and the standard action buttons.
class BingoSuccessOverlay extends StatefulWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onChangeLevel;
  final VoidCallback? onNextLevel;

  /// UI locale ('en' or 'cy') used for all displayed text.
  final String locale;

  const BingoSuccessOverlay({
    super.key,
    required this.onPlayAgain,
    required this.onChangeLevel,
    this.onNextLevel,
    this.locale = 'en',
  });

  @override
  State<BingoSuccessOverlay> createState() => _BingoSuccessOverlayState();
}

class _BingoSuccessOverlayState extends State<BingoSuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _starController;
  late final Animation<double> _pulseAnimation;

  // Random positions for stars — fixed per instance
  final List<_StarData> _stars = _buildStars();

  static List<_StarData> _buildStars() {
    final rng = Random();
    return List.generate(8, (_) {
      return _StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.6, // keep stars in top 60% of screen
        size: 18.0 + rng.nextDouble() * 24, // 18–42 px
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    AudioService.hapticSuccess();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final localizer = AppLocalizations(locale: widget.locale);
    return Container(
      color: const Color(0xFF002D97).withValues(alpha: 0.88),
      child: SafeArea(
        child: Stack(
          children: [
            // ── flashing gold stars ──────────────────────────────────────
            ..._stars.map((s) {
              return AnimatedBuilder(
                animation: _starController,
                builder: (_, child) {
                  final t = ((_starController.value + s.phase) % 1.0);
                  final opacity = (0.4 + 0.6 * (t < 0.5 ? t * 2 : 2 - t * 2))
                      .clamp(0.2, 1.0);
                  return Positioned(
                    left: s.x * size.width - s.size / 2,
                    top: s.y * size.height * 0.6,
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        Icons.star,
                        color: const Color(0xFFFFC73A),
                        size: s.size,
                      ),
                    ),
                  );
                },
              );
            }),

            // ── BINGO text + buttons ─────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pulsing BINGO
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: const _BingoText(),
                ),
                const SizedBox(height: 32),

                // Buttons
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (context.watch<AuthProvider>().isAnonymous) ...[
                            SignInBannerButton(locale: widget.locale),
                            const SizedBox(height: AppSizes.spacingMedium),
                          ],

                          Builder(
                            builder: (context) {
                              final isLandscape =
                                  MediaQuery.of(context).orientation ==
                                  Orientation.landscape;

                              final playAgainBtn = PrimaryButton(
                                label: localizer('general.play_again'),
                                icon: Icons.replay,
                                expanded: true,
                                onPressed: widget.onPlayAgain,
                              );

                              final nextLevelBtn = widget.onNextLevel != null
                                  ? SecondaryButton(
                                      label: localizer('general.next_level'),
                                      icon: Icons.arrow_forward,
                                      expanded: true,
                                      onPressed: widget.onNextLevel,
                                    )
                                  : null;

                              if (nextLevelBtn != null && isLandscape) {
                                return Row(
                                  children: [
                                    Expanded(child: playAgainBtn),
                                    const SizedBox(
                                      width: AppSizes.spacingMedium,
                                    ),
                                    Expanded(child: nextLevelBtn),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  playAgainBtn,
                                  if (nextLevelBtn != null) ...[
                                    const SizedBox(
                                      height: AppSizes.spacingMedium,
                                    ),
                                    nextLevelBtn,
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: AppSizes.spacingMedium),
                          Center(
                            child: TertiaryButton(
                              label: localizer('general.change_level'),
                              icon: Icons.grid_view,
                              onPressed: widget.onChangeLevel,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingLarge,
                                vertical: AppSizes.paddingSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BingoText extends StatelessWidget {
  const _BingoText();

  static const _letters = ['B', 'I', 'N', 'G', 'O'];
  static const _colors = [
    AppColors.accentRed,
    AppColors.catrinBlue,
    AppColors.accentLimeGreen,
    AppColors.accentOrange,
    AppColors.accentPurple,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_letters.length, (i) {
        return Text(
          _letters[i],
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 80,
            fontWeight: FontWeight.w600,
            color: _colors[i],
            shadows: [
              // White outer stroke simulation via layered shadows
              const Shadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(2, -2),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(-2, 2),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(4, 0),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(-4, 0),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.white,
                offset: Offset(0, -4),
                blurRadius: 0,
              ),
              // Black drop shadow for depth
              // const Shadow(color: Colors.black38, offset: Offset(4, 4), blurRadius: 8),
            ],
          ),
        );
      }),
    );
  }
}

class _StarData {
  final double x;
  final double y;
  final double size;
  final double phase;
  const _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
  });
}
