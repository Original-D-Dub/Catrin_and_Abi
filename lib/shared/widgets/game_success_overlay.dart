import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/services/audio_service.dart';
import '../../core/tts_helper.dart';
import '../services/auth_provider.dart';
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
/// - [Play Again] — full width green button
/// - [Next Level] — full width pink button (hidden when [onNextLevel] is null)
/// - [Change Level] — white text link with grid_view icon
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

  // ── audio ─────────────────────────────────────────────────────────────────
  /// Game identifier used to look up a custom success sound in [AudioService].
  /// When null, "Well Done!" is spoken via TTS.
  final String? gameId;

  // ── change-level button style ─────────────────────────────────────────────
  /// When true, renders [onChangeLevel] as a full [ElevatedButton] instead of
  /// the default underlined text link. Use together with a custom [changeLevelLabel]
  /// and [changeLevelIcon]. When [onNextLevel] is also set the two buttons are
  /// shown side by side on screens wider than 600 px and stacked on narrower ones.
  final bool changeLevelIsButton;
  final String changeLevelLabel;
  final IconData changeLevelIcon;

  const GameSuccessOverlay({
    super.key,
    this.onPlayAgain,
    required this.onChangeLevel,
    this.onNextLevel,
    this.scoreStyle = SuccessScoreStyle.none,
    this.score,
    this.customScoreLine,
    this.showPersonalBest = false,
    this.isNewPersonalBest = false,
    this.personalBest,
    this.personalBestSuffix = '',
    this.imageAsset,
    this.backgroundImage,
    this.extraContent,
    this.gameId,
    this.changeLevelIsButton = false,
    this.changeLevelLabel = 'Change Level',
    this.changeLevelIcon = Icons.grid_view,
  });

  @override
  State<GameSuccessOverlay> createState() => _GameSuccessOverlayState();
}

class _GameSuccessOverlayState extends State<GameSuccessOverlay> {
  static const Color _gold = Color(0xFFFFC73A);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _pink = Color(0xFFEE009B);
  static const Color _darkBlue = Color(0xFF002D97);

  /// Controls whether extraContent is visible (delayed 5 s when backgroundImage is set).
  bool _showExtraContent = false;
  Timer? _extraContentTimer;

  @override
  void initState() {
    super.initState();
    AudioService.playSuccess(widget.gameId ?? '');
    if (widget.backgroundImage != null && widget.extraContent != null) {
      _extraContentTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showExtraContent = true);
      });
    } else {
      _showExtraContent = true;
    }
  }

  @override
  void dispose() {
    _extraContentTimer?.cancel();
    super.dispose();
  }

  String get _headingText =>
      (widget.score != null && widget.score! < 3) ? 'Play Again' : 'Well Done!';

  String? get _scoreLine {
    switch (widget.scoreStyle) {
      case SuccessScoreStyle.youScored:
        return 'You scored ${widget.score}';
      case SuccessScoreStyle.youMatched:
        return 'You matched ${widget.score}';
      case SuccessScoreStyle.got10Correct:
        return 'You got 10 correct';
      case SuccessScoreStyle.custom:
        return widget.customScoreLine;
      case SuccessScoreStyle.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.backgroundImage != null
          ? BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.backgroundImage!),
                fit: BoxFit.cover,
              ),
            )
          : const BoxDecoration(color: Color(0xFF002D97)),
      child: SafeArea(
        child: Column(
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
                      child: Center(
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.backgroundImage != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // Dark-blue 2 px stroke behind the white fill
                              Text(
                                _headingText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'LuckiestGuy',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 4
                                    ..color = _darkBlue,
                                ),
                              ),
                              Text(
                                _headingText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'LuckiestGuy',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _headingText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'LuckiestGuy',
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),

            // ── Score sub-line ──────────────────────────────────────────
            if (_scoreLine != null) ...[
              const SizedBox(height: AppSizes.spacingMedium),
              Text(
                _scoreLine!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: widget.backgroundImage != null ? _darkBlue : _gold,
                ),
              ),
            ],

            // ── Sign-in link (backgroundImage mode only, below score) ───
            if (widget.backgroundImage != null &&
                context.watch<AuthProvider>().isAnonymous) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.linkAccount),
                child: const Text(
                  'Sign in to save your changes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 16,
                    color: _darkBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: _darkBlue,
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
                            onTap: () => setState(() => _showExtraContent = false),
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
                                            () => _showExtraContent = false),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: _darkBlue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 18),
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
                      : const SizedBox.shrink()),
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
                      // Personal best badge
                      if (widget.showPersonalBest && widget.isNewPersonalBest) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingLarge,
                            vertical: AppSizes.spacingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Personal Best! ${widget.personalBest}${widget.personalBestSuffix}',
                                style: const TextStyle(
                                  fontFamily: 'ComicRelief',
                                  fontSize: AppSizes.fontSizeBody,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                      ],

                      // Extra content — only here when no backgroundImage;
                      // otherwise it lives in the Expanded centre slot above.
                      if (widget.extraContent != null &&
                          widget.backgroundImage == null) ...[
                        widget.extraContent!,
                        const SizedBox(height: AppSizes.spacingMedium),
                      ],

                      // Sign-in banner
                      if (context.watch<AuthProvider>().isAnonymous &&
                          widget.backgroundImage == null)
                        const SignInBannerButton(),
                      if (context.watch<AuthProvider>().isAnonymous)
                        const SizedBox(height: AppSizes.spacingMedium),

                      // Play Again — hidden when onPlayAgain is null
                      if (widget.onPlayAgain != null) ...[
                        ElevatedButton.icon(
                          onPressed: widget.onPlayAgain,
                          icon: const Icon(Icons.replay),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                      ],

                      // Buttons — responsive layout when changeLevelIsButton is true
                      if (widget.changeLevelIsButton) ...[
                        Builder(builder: (context) {
                          final isWide = MediaQuery.of(context).size.width > 600;
                          final homeBtn = ElevatedButton.icon(
                            onPressed: widget.onChangeLevel,
                            icon: Icon(widget.changeLevelIcon),
                            label: Text(widget.changeLevelLabel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                          final nextBtn = widget.onNextLevel != null
                              ? ElevatedButton.icon(
                                  onPressed: widget.onNextLevel,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Next Level'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pink,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'ComicRelief',
                                      fontSize: AppSizes.fontSizeLarge,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null;

                          if (nextBtn == null) return homeBtn;

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: homeBtn),
                                const SizedBox(width: AppSizes.spacingMedium),
                                Expanded(child: nextBtn),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                homeBtn,
                                const SizedBox(height: AppSizes.spacingMedium),
                                nextBtn,
                              ],
                            );
                          }
                        }),
                        const SizedBox(height: AppSizes.spacingSmall),
                      ] else ...[
                        // Next Level
                        if (widget.onNextLevel != null) ...[
                          ElevatedButton.icon(
                            onPressed: widget.onNextLevel,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next Level'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pink,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingMedium),
                        ],

                        // Change Level link
                        TextButton.icon(
                          onPressed: widget.onChangeLevel,
                          icon: Icon(widget.changeLevelIcon, color: Colors.white),
                          label: Text(
                            widget.changeLevelLabel,
                            style: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: AppSizes.fontSizeBody,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  const BingoSuccessOverlay({
    super.key,
    required this.onPlayAgain,
    required this.onChangeLevel,
    this.onNextLevel,
  });

  @override
  State<BingoSuccessOverlay> createState() => _BingoSuccessOverlayState();
}

class _BingoSuccessOverlayState extends State<BingoSuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _starController;
  late final Animation<double> _pulseAnimation;

  FlutterTts? _tts;

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
    _speakBingo();
  }

  Future<void> _speakBingo() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      await _tts!.speak('Bingo!');
    } catch (e) {
      debugPrint('BingoSuccessOverlay TTS failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starController.dispose();
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                          horizontal: AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (context.watch<AuthProvider>().isAnonymous) ...[
                            const SignInBannerButton(),
                            const SizedBox(height: AppSizes.spacingMedium),
                          ],

                          ElevatedButton.icon(
                            onPressed: widget.onPlayAgain,
                            icon: const Icon(Icons.replay),
                            label: const Text('Play Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSizes.borderRadiusLarge),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (widget.onNextLevel != null) ...[
                            const SizedBox(height: AppSizes.spacingMedium),
                            ElevatedButton.icon(
                              onPressed: widget.onNextLevel,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next Level'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEE009B),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.borderRadiusLarge),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'ComicRelief',
                                  fontSize: AppSizes.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSizes.spacingMedium),
                          TextButton.icon(
                            onPressed: widget.onChangeLevel,
                            icon: const Icon(Icons.grid_view, color: Colors.white),
                            label: const Text(
                              'Change Level',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeBody,
                                color: Colors.white,
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
    AppColors.accentPurple
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_letters.length, (i) {
        return Text(
          _letters[i],
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: _colors[i],
            shadows: [
              // White outer stroke simulation via layered shadows
              const Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(4, 0), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(-4, 0), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(0, 4), blurRadius: 0),
              const Shadow(color: Colors.white, offset: Offset(0, -4), blurRadius: 0),
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
  const _StarData({required this.x, required this.y, required this.size, required this.phase});
}
