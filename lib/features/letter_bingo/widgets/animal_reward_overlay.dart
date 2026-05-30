import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/audio_service.dart';
import '../models/animal_model.dart';
import '../services/animal_collection_service.dart';

/// Full-screen reward overlay shown after a logged-in player wins a round.
///
/// Sequence:
/// 1. Dark scrim + animal card slide up and fade in.
/// 2. Animal is auto-saved to the collection and its name spoken via TTS.
/// 3. "See your collection" button and "Skip" link fade in after a delay.
/// 4. Tapping the background or Skip calls [onComplete].
class AnimalRewardOverlay extends StatefulWidget {
  final Animal animal;
  final int levelNumber;
  final String playerId;
  final VoidCallback onComplete;

  const AnimalRewardOverlay({
    super.key,
    required this.animal,
    required this.levelNumber,
    required this.playerId,
    required this.onComplete,
  });

  @override
  State<AnimalRewardOverlay> createState() => _AnimalRewardOverlayState();
}

class _AnimalRewardOverlayState extends State<AnimalRewardOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  late final AnimationController _buttonCtrl;
  late final Animation<double> _buttonFade;

  final _collectionService = AnimalCollectionService();
  bool _done = false;

  /// null = still checking; true = brand-new animal; false = already owned
  bool? _isNew;

  @override
  void initState() {
    super.initState();

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

    // Check newness concurrently with the entry animation (check runs first,
    // save happens after the animation so there is no race condition).
    _checkIfNew();

    _entryCtrl.forward().then((_) {
      if (!mounted) return;
      // Auto-save to collection (fire-and-forget; failure is non-fatal)
      _collectionService
          .addToCollection(
            playerId: widget.playerId,
            animal: widget.animal,
            levelNumber: widget.levelNumber,
          )
          .catchError((_) {});
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) AudioService.speak(widget.animal.name);
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _buttonCtrl.forward();
      });
    });
  }

  Future<void> _checkIfNew() async {
    try {
      final collected = await _collectionService.fetchCollection(
          playerId: widget.playerId);
      if (mounted) {
        setState(() {
          _isNew = !collected.contains(widget.animal.letter.toLowerCase());
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isNew = true);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  void _skip() {
    if (_done) return;
    _done = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      child: Container(
        color: const Color(0xFF002D97).withValues(alpha: 0.92),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    fontSize: 32,
                    color: Color(0xFFFFC73A),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _AnimalCard(animal: widget.animal),
                ),
              ),

              const SizedBox(height: 32),

              FadeTransition(
                opacity: _buttonFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.animalCollection),
                    icon: const Icon(Icons.grid_view),
                    label: const Text('See your collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.abiPink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              FadeTransition(
                opacity: _buttonFade,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 14,
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                    ),
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
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.asset(
              animal.image,
              width: 220,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 220,
                height: 200,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
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
