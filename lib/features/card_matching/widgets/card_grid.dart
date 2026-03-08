import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/card_model.dart';
import 'game_card.dart';

/// A responsive grid layout for game cards.
///
/// Arranges cards in a grid that adapts to screen size.
/// Uses Wrap for flexible layout on different devices.
///
/// Usage:
/// ```dart
/// CardGrid(
///   cards: provider.cards,
///   onCardTap: (cardId) => provider.selectCard(cardId: cardId),
/// )
/// ```
class CardGrid extends StatelessWidget {
  /// The list of cards to display
  final List<CardModel> cards;

  /// Callback when a card is tapped
  final void Function(String cardId) onCardTap;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /// 4 columns below 600px, 5 columns at 600px and above
        final crossAxisCount = constraints.maxWidth < 600 ? 4 : 5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.cardGridSpacing,
          mainAxisSpacing: AppSizes.cardGridSpacing,
          childAspectRatio: 0.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards.map((card) {
            return GameCard(
              card: card,
              onTap: () => onCardTap(card.id),
            );
          }).toList(),
        );
      },
    );
  }
}
