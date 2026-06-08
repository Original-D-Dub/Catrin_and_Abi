import 'dart:math';
import '../../../core/constants/asset_paths.dart';
import '../../card_matching/models/card_model.dart';
import '../models/welsh_game_level.dart';

/// Stateless service for Welsh card matching game logic.
///
/// Identical in structure to CardGameService but uses Welsh SVG paths
/// and supports multi-character letter values (digraphs).
class WelshCardGameService {
  final Random _random = Random();

  List<CardModel> generateCardsForLevel({required WelshGameLevel level}) {
    final List<CardModel> cards = [];

    for (final letter in level.letters) {
      final pairId = 'pair_$letter';
      final color = level.getColorForLetter(letter);

      cards.add(CardModel(
        id: 'welsh_sign_$letter',
        type: CardType.bslSign,
        value: letter,
        pairId: pairId,
        pairColor: color,
        imagePath: AssetPaths.welshLetterSvg(letter),
      ));

      cards.add(CardModel(
        id: 'welsh_letter_$letter',
        type: CardType.letter,
        value: letter,
        pairId: pairId,
        pairColor: color,
      ));
    }

    return _shuffle(cards);
  }

  List<CardModel> _shuffle(List<CardModel> cards) {
    final shuffled = List<CardModel>.from(cards);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  bool checkMatch({required CardModel first, required CardModel second}) =>
      first.pairId == second.pairId;

  bool checkWinCondition({required int matchCount, required int totalPairs}) =>
      matchCount >= totalPairs;
}
