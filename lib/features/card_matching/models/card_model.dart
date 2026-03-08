import 'package:flutter/material.dart';

/// Type of card in the matching game.
enum CardType {
  /// Card showing a BSL hand sign image
  bslSign,

  /// Card showing a written letter
  letter,
}

/// Represents a single card in the matching game.
///
/// Cards come in two types:
/// - BSL sign cards (show hand sign image)
/// - Letter cards (show written letter)
///
/// Matching pairs share the same [pairId] and [pairColor].
///
/// Example:
/// ```dart
/// final bslCard = CardModel(
///   id: 'bsl_a',
///   type: CardType.bslSign,
///   value: 'a',
///   pairId: 'pair_a',
///   pairColor: Colors.red,
///   imagePath: 'assets/bsl_alphabet/A.png',
/// );
/// ```
class CardModel {
  /// Unique identifier for this card (e.g., 'bsl_a', 'letter_a')
  final String id;

  /// The type of card (BSL sign or letter)
  final CardType type;

  /// The letter this card represents ('a', 'e', 'i', 'o', 'u')
  final String value;

  /// Shared ID for matching pair (e.g., 'pair_a')
  /// Cards with the same pairId are a match.
  final String pairId;

  /// Color coding for this pair
  /// Matching cards share the same color for visual hint.
  final Color pairColor;

  /// Asset path for BSL sign cards
  /// Null for letter cards.
  final String? imagePath;

  /// Whether this card is currently face-up
  bool isFlipped;

  /// Whether this card has been successfully matched
  bool isMatched;

  /// Creates a card model.
  ///
  /// [id] must be unique across all cards in the game.
  /// [type] determines if this is a BSL sign or letter card.
  /// [value] is the letter this card represents.
  /// [pairId] links this card to its matching partner.
  /// [pairColor] provides color-coding for the pair.
  CardModel({
    required this.id,
    required this.type,
    required this.value,
    required this.pairId,
    required this.pairColor,
    this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  });

  /// Creates a copy of this card with optional field overrides.
  CardModel copyWith({
    String? id,
    CardType? type,
    String? value,
    String? pairId,
    Color? pairColor,
    String? imagePath,
    bool? isFlipped,
    bool? isMatched,
  }) {
    return CardModel(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      pairId: pairId ?? this.pairId,
      pairColor: pairColor ?? this.pairColor,
      imagePath: imagePath ?? this.imagePath,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  String toString() {
    return 'CardModel(id: $id, type: $type, value: $value, '
        'isFlipped: $isFlipped, isMatched: $isMatched)';
  }
}
