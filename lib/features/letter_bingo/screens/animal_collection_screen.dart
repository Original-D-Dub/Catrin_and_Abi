import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../models/animal_model.dart';
import '../models/letter_bingo_level.dart';
import '../providers/bingo_collection_provider.dart';

class AnimalCollectionScreen extends StatefulWidget {
  /// When non-null, the "Play Again" button pops this screen and calls back.
  final VoidCallback? onPlayAgain;

  /// UI locale ('en' or 'cy') used for all displayed text.
  final String locale;

  /// Sign system whose reward set (and Storage bucket) to load.
  final SignSystem signSystem;

  const AnimalCollectionScreen({
    super.key,
    this.onPlayAgain,
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
  });

  @override
  State<AnimalCollectionScreen> createState() => _AnimalCollectionScreenState();
}

class _AnimalCollectionScreenState extends State<AnimalCollectionScreen> {
  @override
  void initState() {
    super.initState();
    // Safety-net fetch: normally already preloaded when the bingo game was
    // entered (see routes.dart), so this is a no-op in the common case —
    // see BingoCollectionProvider.preload's dedup logic.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BingoCollectionProvider>().preload(
            signSystem: widget.signSystem,
            playerId: context.read<AuthProvider>().userId,
          );
    });
  }

  /// Letters shown in the grid, in alphabetical order.
  ///
  /// BSL always shows the full English alphabet (a–z), matching an
  /// undiscovered-animal tile for every letter. IAC shows only the Welsh
  /// letters that actually have a reward in `iac_bingo_rewards` — not every
  /// Welsh letter is used as an animal's first letter, so the full 29-letter
  /// alphabet would otherwise include tiles that could never be collected.
  List<String> _gridLetters(Map<String, Animal> animalsByLetter) {
    if (widget.signSystem == SignSystem.iac) {
      return LetterBingoLevel.iacLevel5.availableLetters
          .where(animalsByLetter.containsKey)
          .toList();
    }
    return List.generate(
      26,
      (i) => String.fromCharCode('a'.codeUnitAt(0) + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final playerId = context.watch<AuthProvider>().userId;
    final bingoCollection = context.watch<BingoCollectionProvider>();
    final loading = playerId != null &&
        (!bingoCollection.isRewardsLoaded(widget.signSystem) ||
            !bingoCollection.isCollectedLoaded(playerId));
    final animalsByLetter = <String, Animal>{
      for (final animal in bingoCollection.rewardsFor(widget.signSystem))
        animal.letter.toLowerCase(): animal,
    };
    final collected =
        playerId == null ? const <String>{} : bingoCollection.collectedLetters;
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
                scoreLabel: localizer('letter_bingo.cards_label'),
                scoreValue: '${collected.length}',
                showLevel: false,
                centerContent: Center(
                  child: Text(
                    localizer('letter_bingo.animals_header'),
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: loading
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
                        final gridLetters = _gridLetters(animalsByLetter);
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
                          itemCount: gridLetters.length,
                          itemBuilder: (context, index) {
                            final letter = gridLetters[index];
                            final isCollected = collected.contains(letter);
                            return _AnimalTile(
                              letter: letter,
                              animal: isCollected
                                  ? animalsByLetter[letter]
                                  : null,
                              localizer: localizer,
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
                            child: PrimaryButton(
                              label: localizer('general.play_again'),
                              icon: Icons.replay,
                              expanded: true,
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onPlayAgain?.call();
                              },
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
  final AppLocalizations localizer;

  const _AnimalTile({
    required this.letter,
    required this.animal,
    required this.localizer,
  });

  void _showOverlay(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: const Color(0xFF002D97).withValues(alpha: 0.85),
      barrierDismissible: true,
      barrierLabel: localizer('general.close'),
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
                    child: Image.network(
                      animal!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.network(
                        animal!.placeholderUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEEEEEE),
                          child: const Icon(Icons.pets,
                              size: 80, color: Colors.grey),
                        ),
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
                          fontFamily: 'Quicksand',
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
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
                      child: Image.network(
                        animal!.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => Image.network(
                          animal!.placeholderUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.pets,
                                size: 40, color: Colors.grey),
                          ),
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
                              fontFamily: 'Quicksand',
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w600,
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
