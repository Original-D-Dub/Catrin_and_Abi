import 'dart:math';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/game_filters.dart';
import '../models/card_model.dart';
import '../models/game_level.dart';

/// Service containing pure game logic for card matching.
///
/// Responsibilities:
/// - Generate cards for a level
/// - Shuffle cards
/// - Check if two cards match
/// - Determine win condition
///
/// This service is stateless - all state is managed by [CardGameProvider].
class CardGameService {
  /// Random number generator for shuffling
  final Random _random = Random();

  /// Generates a shuffled list of cards for the given level.
  ///
  /// Creates two cards for each letter:
  /// - A sign card with the BSL/IAC hand sign image
  /// - A letter card with the written letter
  ///
  /// Both cards share the same pairId and color for matching.
  ///
  /// [level] contains the letters and colors for this level.
  /// [signSystem] selects which sign-asset family to load images from.
  /// Returns a shuffled list of [CardModel] objects.
  List<CardModel> generateCardsForLevel({
    required GameLevel level,
    required SignSystem signSystem,
  }) {
    final List<CardModel> cards = [];
    final isIac = signSystem == SignSystem.iac;

    for (final letter in level.letters) {
      final pairId = 'pair_$letter';
      final color = level.getColorForLetter(letter);

      // Create sign card
      cards.add(CardModel(
        id: '${isIac ? 'welsh_sign' : 'bsl'}_$letter',
        type: CardType.bslSign,
        value: letter,
        pairId: pairId,
        pairColor: color,
        imagePath: isIac
            ? AssetPaths.welshLetterSvg(letter)
            : AssetPaths.bslLetterSvg(letter),
      ));

      // Create letter card
      cards.add(CardModel(
        id: '${isIac ? 'welsh_letter' : 'letter'}_$letter',
        type: CardType.letter,
        value: letter,
        pairId: pairId,
        pairColor: color,
      ));
    }

    // Shuffle the cards using Fisher-Yates algorithm
    return _shuffleCards(cards);
  }

  /// Shuffles a list of cards using the Fisher-Yates algorithm.
  ///
  /// This provides a uniform random shuffle.
  List<CardModel> _shuffleCards(List<CardModel> cards) {
    final shuffled = List<CardModel>.from(cards);

    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    return shuffled;
  }

  /// Checks if two cards form a valid match.
  ///
  /// A match occurs when both cards have the same pairId.
  /// (One sign card and one letter card representing the same letter)
  ///
  /// [first] and [second] are the two cards to compare.
  /// Returns true if the cards match.
  bool checkMatch({
    required CardModel first,
    required CardModel second,
  }) {
    return first.pairId == second.pairId;
  }

  /// Checks if the game has been won.
  ///
  /// Win condition: All pairs have been matched.
  ///
  /// [matchCount] is the current number of successful matches.
  /// [totalPairs] is the total number of pairs in the level.
  /// Returns true if the game is won.
  bool checkWinCondition({
    required int matchCount,
    required int totalPairs,
  }) {
    return matchCount >= totalPairs;
  }
}
