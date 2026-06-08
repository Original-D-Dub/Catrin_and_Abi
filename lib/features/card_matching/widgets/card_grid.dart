import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/card_model.dart';
import 'game_card.dart';

class CardGrid extends StatelessWidget {
  final List<CardModel> cards;
  final void Function(String cardId) onCardTap;
  final int levelNumber;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTabletLandscape = screenWidth >= 768 &&
            MediaQuery.of(context).orientation == Orientation.landscape &&
            constraints.maxHeight.isFinite;

        int crossAxisCount;
        double childAspectRatio;
        bool shrinkWrap;
        ScrollPhysics? physics;

        if (isTabletLandscape) {
          if (levelNumber <= 2) {
            crossAxisCount = 5;
            const targetRows = 2;
            final cardWidth = (constraints.maxWidth -
                    (crossAxisCount - 1) * AppSizes.cardGridSpacing) /
                crossAxisCount;
            final cardHeight = (constraints.maxHeight -
                    (targetRows - 1) * AppSizes.cardGridSpacing) /
                targetRows;
            childAspectRatio = cardWidth / cardHeight;
          } else {
            crossAxisCount = 7;
            const targetRows = 3;
            final cardWidth = (constraints.maxWidth -
                    (crossAxisCount - 1) * AppSizes.cardGridSpacing) /
                crossAxisCount;
            final cardHeight = (constraints.maxHeight -
                    (targetRows - 1) * AppSizes.cardGridSpacing) /
                targetRows;
            childAspectRatio = cardWidth / cardHeight;
          }
          shrinkWrap = false;
          physics = null;
        } else {
          crossAxisCount = constraints.maxWidth < 600 ? 4 : 5;
          childAspectRatio = 0.8;
          shrinkWrap = true;
          physics = const NeverScrollableScrollPhysics();
        }

        final cardWidgets = cards.map<Widget>((card) {
          return GameCard(
            card: card,
            onTap: () => onCardTap(card.id),
          );
        }).toList();

        if (isTabletLandscape) {
          final targetRows = levelNumber <= 2 ? 2 : 3;
          final totalSlots = crossAxisCount * targetRows;
          final emptySlots = totalSlots - cards.length;
          for (int i = 0; i < emptySlots; i++) {
            cardWidgets.add(
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/logos/english/Catrin_Abi_Logo_Eng_600x600.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          }
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.cardGridSpacing,
          mainAxisSpacing: AppSizes.cardGridSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: shrinkWrap,
          physics: physics,
          children: cardWidgets,
        );
      },
    );
  }
}
