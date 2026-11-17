import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/cached_asset_image.dart';
import '../../../shared/widgets/collection_screen.dart';
import '../models/animal_model.dart';
import '../models/letter_bingo_level.dart';
import '../providers/bingo_collection_provider.dart';
import '../widgets/bingo_celebration.dart' show bingoOverlayGradient;

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
    return List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i));
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final playerId = context.watch<AuthProvider>().userId;
    final bingoCollection = context.watch<BingoCollectionProvider>();
    final loading =
        playerId != null &&
        (!bingoCollection.isRewardsLoaded(widget.signSystem) ||
            !bingoCollection.isCollectedLoaded(playerId));
    final animalsByLetter = <String, Animal>{
      for (final animal in bingoCollection.rewardsFor(widget.signSystem))
        animal.letter.toLowerCase(): animal,
    };
    final collected = playerId == null
        ? const <String>{}
        : bingoCollection.collectedLetters;

    return CollectionScreen(
      locale: widget.locale,
      title: localizer('letter_bingo.animals_header'),
      countLabel: localizer('letter_bingo.cards_label'),
      loading: loading,
      onPlayAgain: widget.onPlayAgain,
      overlayGradient: bingoOverlayGradient,
      items: [
        for (final letter in _gridLetters(animalsByLetter))
          if (collected.contains(letter) && animalsByLetter[letter] != null)
            CollectionItem(
              id: letter,
              name: animalsByLetter[letter]!.name,
              collected: true,
              artBuilder: (_) => _AnimalArt(animalsByLetter[letter]!),
            )
          else
            CollectionItem(
              id: letter,
              name: letter,
              collected: false,
              placeholder: letter,
              artBuilder: (_) => const SizedBox.shrink(),
            ),
      ],
    );
  }
}

/// An animal's reward picture, falling back to the sign system's
/// placeholder image and then a paw icon.
class _AnimalArt extends StatelessWidget {
  final Animal animal;

  const _AnimalArt(this.animal);

  @override
  Widget build(BuildContext context) {
    return CachedAssetImage(
      url: animal.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      semanticLabel: animal.name,
      errorBuilder: (_, _, _) => CachedAssetImage(
        url: animal.placeholderUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFEEEEEE),
          child: const Icon(Icons.pets, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}
