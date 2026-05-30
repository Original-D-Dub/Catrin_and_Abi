import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../models/animal_model.dart';
import '../services/animal_collection_service.dart';

class AnimalCollectionScreen extends StatefulWidget {
  /// When non-null, the "Play Again" button pops this screen and calls back.
  final VoidCallback? onPlayAgain;

  const AnimalCollectionScreen({super.key, this.onPlayAgain});

  @override
  State<AnimalCollectionScreen> createState() => _AnimalCollectionScreenState();
}

class _AnimalCollectionScreenState extends State<AnimalCollectionScreen> {
  final _service = AnimalCollectionService();
  Map<String, Animal> _animalsByLetter = {};
  Set<String> _collected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final playerId = context.read<AuthProvider>().userId;
    if (playerId == null) {
      setState(() => _loading = false);
      return;
    }

    final jsonStr = await rootBundle.loadString('assets/data/animals.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    final byLetter = <String, Animal>{
      for (final e in list)
        (e['letter'] as String).toLowerCase():
            Animal.fromJson(e as Map<String, dynamic>),
    };

    final collected = await _service.fetchCollection(playerId: playerId);

    setState(() {
      _animalsByLetter = byLetter;
      _collected = collected;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              GameHeaderBar(
                onBack: () => Navigator.pop(context),
                scoreLabel: 'Cards',
                scoreValue: '${_collected.length}',
                showLevel: false,
                centerContent: const Center(
                  child: Text(
                    'Animals',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Stack(
                        children: [
                          LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width < 374
                            ? 2
                            : width < 600
                                ? 3
                                : 4;
                        return GridView.builder(
                          // bottom padding keeps last row above the floating button
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 84),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: 26,
                          itemBuilder: (context, index) {
                            final letter = String.fromCharCode(
                                'a'.codeUnitAt(0) + index);
                            final isCollected = _collected.contains(letter);
                            return _AnimalTile(
                              letter: letter,
                              animal: isCollected
                                  ? _animalsByLetter[letter]
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusLarge),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onPlayAgain?.call();
                              },
                              icon: const Icon(Icons.replay),
                              label: const Text('Play Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(
                                    color: Colors.white, width: 2.5),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  final String letter;
  final Animal? animal;

  const _AnimalTile({required this.letter, required this.animal});

  void _showOverlay(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: const Color(0xFF002D97).withValues(alpha: 0.85),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (context, _, _) {
        final width = MediaQuery.of(context).size.width * 0.75;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      animal!.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Icon(Icons.pets,
                            size: 80, color: Colors.grey),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 64,
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        animal!.name,
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D97),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collected = animal != null;
    final wide = MediaQuery.of(context).size.width > 600;
    final labelHeight = wide ? 48.0 : 24.0;
    final labelFontSize = wide ? 28.0 : 14.0;
    return GestureDetector(
      onTap: collected ? () => _showOverlay(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white.withValues(alpha: 0.55),
          child: collected
              ? Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        animal!.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEEEEEE),
                          child: const Icon(Icons.pets,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: labelHeight,
                      width: double.infinity,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            animal!.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF002D97),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002D97),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
