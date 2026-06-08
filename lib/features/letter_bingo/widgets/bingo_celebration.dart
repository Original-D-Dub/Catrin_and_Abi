import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/animal_collection_screen.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/sign_in_banner_button.dart';
import '../models/animal_model.dart';
import '../services/animal_collection_service.dart';

/// Combined BINGO celebration screen.
///
/// Layout (top → bottom):
/// 1. Pulsing BINGO text with twinkling gold stars.
/// 2. Animal reward section (logged-in users only) — heading, card, and
///    "See your collection" button — slides in after a short delay.
/// 3. "Play Again" button.
/// 4. "Change Level" link.
class BingoCelebration extends StatefulWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onChangeLevel;

  /// Non-null only for logged-in users who earned a reward animal this round.
  final Animal? animal;
  final String? playerId;
  final int levelNumber;

  const BingoCelebration({
    super.key,
    required this.onPlayAgain,
    required this.onChangeLevel,
    this.animal,
    this.playerId,
    required this.levelNumber,
  });

  @override
  State<BingoCelebration> createState() => _BingoCelebrationState();
}

class _BingoCelebrationState extends State<BingoCelebration>
    with TickerProviderStateMixin {
  // BINGO pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Star twinkle
  late final AnimationController _starCtrl;

  // Animal card entry
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  // Button fade-in
  late final AnimationController _buttonCtrl;
  late final Animation<double> _buttonFade;

  final List<_StarData> _stars = _buildStars();

  final _collectionService = AnimalCollectionService();
  bool? _isNew;

  static List<_StarData> _buildStars() {
    final rng = Random();
    return List.generate(8, (_) => _StarData(
          x: rng.nextDouble(),
          y: rng.nextDouble() * 0.5,
          size: 18.0 + rng.nextDouble() * 24,
          phase: rng.nextDouble(),
        ));
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn),
    );

    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(_buttonCtrl);

    AudioService.hapticSuccess();
    _startAudioSequence();

    if (widget.animal != null && widget.playerId != null) {
      _checkIfNew();
      // Short pause so BINGO text registers before the card slides in
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _entryCtrl.forward().then((_) {
          if (!mounted) return;
          _collectionService
              .addToCollection(
                playerId: widget.playerId!,
                animal: widget.animal!,
                levelNumber: widget.levelNumber,
              )
              .catchError((_) {});
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) _buttonCtrl.forward();
          });
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _buttonCtrl.forward();
      });
    }
  }

  Future<void> _checkIfNew() async {
    try {
      final collected = await _collectionService.fetchCollection(
          playerId: widget.playerId!);
      if (mounted) {
        setState(() {
          _isNew = !collected.contains(widget.animal!.letter.toLowerCase());
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isNew = true);
    }
  }

  Future<void> _startAudioSequence() async {
    await AudioService.playMp3('speech files/bingo_bingo.mp3');
    if (!mounted || widget.animal == null) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (_isNew ?? false) {
      AudioService.playMp3('speech files/bingo_you_have_a_new_friend.mp3');
    } else {
      AudioService.playMp3('speech files/bingo_you_have_a_friend.mp3');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _starCtrl.dispose();
    _entryCtrl.dispose();
    _buttonCtrl.dispose();
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
            // Twinkling stars — non-interactive
            IgnorePointer(
              child: Stack(
                children: _stars.map((s) {
                  return AnimatedBuilder(
                    animation: _starCtrl,
                    builder: (_, _) {
                      final t = (_starCtrl.value + s.phase) % 1.0;
                      final opacity =
                          (0.4 + 0.6 * (t < 0.5 ? t * 2 : 2 - t * 2))
                              .clamp(0.2, 1.0);
                      return Positioned(
                        left: s.x * size.width - s.size / 2,
                        top: s.y * size.height * 0.5,
                        child: Opacity(
                          opacity: opacity,
                          child: Icon(Icons.star,
                              color: const Color(0xFFFFC73A), size: s.size),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            // Scrollable content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingLarge,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pulsing BINGO
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: const _BingoText(),
                        ),
                        const SizedBox(height: 24),

                        // ── Animal reward section ─────────────────────────
                        if (widget.animal != null) ...[
                          AnimatedOpacity(
                            opacity: _isNew != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              (_isNew ?? false)
                                  ? 'Congratulations!\nYou have a new friend.'
                                  : 'You have a friend!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'LuckiestGuy',
                                fontSize: 28,
                                color: Color(0xFFFFC73A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SlideTransition(
                              position: _slideAnim,
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: _AnimalCard(animal: widget.animal!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Sign-in banner (anonymous users) ─────────────
                        if (context.watch<AuthProvider>().isAnonymous) ...[
                          const SignInBannerButton(),
                          const SizedBox(height: AppSizes.spacingMedium),
                        ],

                        // ── See your collection ───────────────────────────
                        if (widget.animal != null) ...[
                          FadeTransition(
                            opacity: _buttonFade,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnimalCollectionScreen(
                                    onPlayAgain: widget.onPlayAgain,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.grid_view),
                              label: const Text('See your collection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.abiPink,
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
                          ),
                          const SizedBox(height: AppSizes.spacingMedium),
                        ],

                        // ── Play Again ────────────────────────────────────
                        FadeTransition(
                          opacity: _buttonFade,
                          child: ElevatedButton.icon(
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
                        ),

                        // ── Change Level ──────────────────────────────────
                        const SizedBox(height: AppSizes.spacingMedium),
                        FadeTransition(
                          opacity: _buttonFade,
                          child: TextButton.icon(
                            onPressed: widget.onChangeLevel,
                            icon: const Icon(Icons.grid_view,
                                color: Colors.white),
                            label: const Text(
                              'Change Level',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeBody,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

// ── Animal card ──────────────────────────────────────────────────────────────

class _AnimalCard extends StatelessWidget {
  final Animal animal;
  const _AnimalCard({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.asset(
              animal.image,
              width: 220,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 220,
                height: 200,
                color: const Color(0xFFEEEEEE),
                child:
                    const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              animal.name,
              style: const TextStyle(
                fontFamily: 'LuckiestGuy',
                fontSize: 28,
                color: Color(0xFF002D97),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BINGO text ────────────────────────────────────────────────────────────────

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
            fontFamily: 'ComicRelief',
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: _colors[i],
            shadows: const [
              Shadow(
                  color: Colors.white,
                  offset: Offset(-2, -2),
                  blurRadius: 0),
              Shadow(
                  color: Colors.white,
                  offset: Offset(2, -2),
                  blurRadius: 0),
              Shadow(
                  color: Colors.white,
                  offset: Offset(-2, 2),
                  blurRadius: 0),
              Shadow(
                  color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
              Shadow(
                  color: Colors.white, offset: Offset(4, 0), blurRadius: 0),
              Shadow(
                  color: Colors.white,
                  offset: Offset(-4, 0),
                  blurRadius: 0),
              Shadow(
                  color: Colors.white, offset: Offset(0, 4), blurRadius: 0),
              Shadow(
                  color: Colors.white,
                  offset: Offset(0, -4),
                  blurRadius: 0),
            ],
          ),
        );
      }),
    );
  }
}

// ── Star data ─────────────────────────────────────────────────────────────────

class _StarData {
  final double x;
  final double y;
  final double size;
  final double phase;
  const _StarData(
      {required this.x,
      required this.y,
      required this.size,
      required this.phase});
}
