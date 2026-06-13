import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../models/card_model.dart';
import 'game_card.dart';

class CardGrid extends StatelessWidget {
  final List<CardModel> cards;
  final void Function(String cardId) onCardTap;
  final int levelNumber;
  final SignSystem signSystem;
  final String locale;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.levelNumber,
    this.signSystem = SignSystem.bsl,
    this.locale = 'en',
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
        int targetRows = 0;

        if (isTabletLandscape) {
          if (signSystem == SignSystem.iac) {
            crossAxisCount = levelNumber <= 1 ? 7 : 8;
            targetRows = 2;
          } else if (levelNumber <= 2) {
            crossAxisCount = 5;
            targetRows = 2;
          } else {
            crossAxisCount = 7;
            targetRows = 3;
          }
          final cardWidth = (constraints.maxWidth -
                  (crossAxisCount - 1) * AppSizes.cardGridSpacing) /
              crossAxisCount;
          final cardHeight = (constraints.maxHeight -
                  (targetRows - 1) * AppSizes.cardGridSpacing) /
              targetRows;
          childAspectRatio = cardWidth / cardHeight;
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
            signSystem: signSystem,
          );
        }).toList();

        if (isTabletLandscape) {
          final logoAsset = locale == 'cy'
              ? 'assets/logos/welsh/catacabi_font_colour_cym.png'
              : 'assets/logos/english/Catrin_Abi_Logo_Eng_600x600.png';
          final totalSlots = crossAxisCount * targetRows;
          final emptySlots = totalSlots - cards.length;
          for (int i = 0; i < emptySlots; i++) {
            cardWidgets.add(
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
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
