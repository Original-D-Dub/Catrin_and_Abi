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

  /// Height available for the play area on phones, where the grid sits in
  /// a scroll view and so can't measure its own height via [LayoutBuilder].
  /// Passed down by the caller from the unscrolled layout. Used only to
  /// decide between a 3- and 4-column layout on levels 1-2; if omitted, that
  /// decision falls back to 4 columns.
  final double? availableHeight;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.levelNumber,
    this.signSystem = SignSystem.bsl,
    this.locale = 'en',
    this.availableHeight,
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
          if (constraints.maxWidth < 600) {
            crossAxisCount = levelNumber <= 2
                ? _bestColumnCount(
                    availableWidth: constraints.maxWidth,
                    availableHeight: availableHeight,
                    cardCount: cards.length,
                    preferredColumns: 3,
                    fallbackColumns: 4,
                  )
                : 4;
          } else {
            crossAxisCount = _bestColumnCount(
              availableWidth: constraints.maxWidth,
              availableHeight: availableHeight,
              cardCount: cards.length,
              preferredColumns: 4,
              fallbackColumns: 5,
            );
          }
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

  /// Fewer columns means bigger cards, a better use of space. Use
  /// [preferredColumns] when the extra rows it produces still fit within
  /// [availableHeight] (so every card stays visible without scrolling);
  /// otherwise fall back to [fallbackColumns].
  int _bestColumnCount({
    required double availableWidth,
    required double? availableHeight,
    required int cardCount,
    required int preferredColumns,
    required int fallbackColumns,
  }) {
    if (availableHeight == null) return fallbackColumns;

    double gridHeightFor(int columns) {
      final cardWidth = (availableWidth -
              (columns - 1) * AppSizes.cardGridSpacing) /
          columns;
      final cardHeight = cardWidth / 0.8; // matches childAspectRatio = 0.8
      final rows = (cardCount / columns).ceil();
      return rows * cardHeight + (rows - 1) * AppSizes.cardGridSpacing;
    }

    return gridHeightFor(preferredColumns) <= availableHeight
        ? preferredColumns
        : fallbackColumns;
  }
}
