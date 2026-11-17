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

  /// Whether Champion Mode is on: every card gets the same dark blue
  /// border instead of its colour-coded pair border.
  final bool championMode;

  /// Height available for the play area on phones, where the grid sits in
  /// a scroll view and so can't measure its own height via [LayoutBuilder].
  /// Passed down by the caller from the unscrolled layout. Used to pick the
  /// column count and card size so the whole board fits without scrolling
  /// (see [_bestFittingColumns]); if omitted, cards just fill the width.
  final double? availableHeight;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.levelNumber,
    this.signSystem = SignSystem.bsl,
    this.locale = 'en',
    this.availableHeight,
    this.championMode = false,
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
        // Narrower than the available width when the cards are shrunk to
        // fit the height; the grid is then centred.
        double? gridWidth;

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
          // Bigger boards (e.g. the two-player tablet levels) that don't
          // fit the layout above get the grid with the largest cards.
          if (cards.length > crossAxisCount * targetRows) {
            (crossAxisCount, targetRows) = _bestFillingGrid(
              constraints.biggest,
              cards.length,
            );
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
          final preferredColumns =
              constraints.maxWidth < 600 && levelNumber <= 2 ? 3 : 4;
          (crossAxisCount, gridWidth) = _bestFittingColumns(
            availableWidth: constraints.maxWidth,
            availableHeight: availableHeight,
            cardCount: cards.length,
            preferredColumns: preferredColumns,
          );
          childAspectRatio = 0.8;
          shrinkWrap = true;
          physics = const NeverScrollableScrollPhysics();
        }

        final cardWidgets = cards.map<Widget>((card) {
          return GameCard(
            card: card,
            onTap: () => onCardTap(card.id),
            signSystem: signSystem,
            championMode: championMode,
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

        final grid = GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.cardGridSpacing,
          mainAxisSpacing: AppSizes.cardGridSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: shrinkWrap,
          physics: physics,
          children: cardWidgets,
        );
        if (gridWidth == null) return grid;
        return Center(child: SizedBox(width: gridWidth, child: grid));
      },
    );
  }

  /// The (columns, rows) grid of 2–6 rows that holds [cardCount] cards in
  /// [size] with the largest card, measured as the biggest card at the
  /// usual 0.8 aspect ratio that fits in one cell.
  (int, int) _bestFillingGrid(Size size, int cardCount) {
    var best = (cardCount, 1);
    var bestCardWidth = 0.0;
    for (var rows = 2; rows <= 6; rows++) {
      final columns = (cardCount / rows).ceil();
      final cellWidth =
          (size.width - (columns - 1) * AppSizes.cardGridSpacing) / columns;
      final cellHeight =
          (size.height - (rows - 1) * AppSizes.cardGridSpacing) / rows;
      final cardWidth = cellWidth < cellHeight * 0.8
          ? cellWidth
          : cellHeight * 0.8;
      if (cardWidth > bestCardWidth) {
        bestCardWidth = cardWidth;
        best = (columns, rows);
      }
    }
    return best;
  }

  /// The column count and grid width that fit all [cardCount] cards (at the
  /// 0.8 aspect ratio) within [availableWidth] × [availableHeight] with the
  /// largest card, so the whole board is visible without scrolling.
  ///
  /// Starts at [preferredColumns] — fewer columns means bigger cards — and
  /// tries up to three more, since more columns means fewer rows when the
  /// board is height-limited. Each card is the smaller of the width that
  /// fills a row and the width whose rows fill the height; when the height
  /// is the limit, the returned grid width is narrower than
  /// [availableWidth]. Without [availableHeight] the grid just fills the
  /// width at [preferredColumns] (grid width null).
  (int, double?) _bestFittingColumns({
    required double availableWidth,
    required double? availableHeight,
    required int cardCount,
    required int preferredColumns,
  }) {
    if (availableHeight == null) return (preferredColumns, null);

    var bestColumns = preferredColumns;
    var bestCardWidth = 0.0;
    for (var columns = preferredColumns;
        columns <= preferredColumns + 3;
        columns++) {
      final rows = (cardCount / columns).ceil();
      final widthFit =
          (availableWidth - (columns - 1) * AppSizes.cardGridSpacing) /
              columns;
      final heightFit = (availableHeight -
              (rows - 1) * AppSizes.cardGridSpacing) /
          rows *
          0.8; // matches childAspectRatio = 0.8
      final cardWidth = widthFit < heightFit ? widthFit : heightFit;
      if (cardWidth > bestCardWidth) {
        bestCardWidth = cardWidth;
        bestColumns = columns;
      }
    }

    final fullWidthCard =
        (availableWidth - (bestColumns - 1) * AppSizes.cardGridSpacing) /
            bestColumns;
    if (bestCardWidth >= fullWidthCard) return (bestColumns, null);
    // Floored so rounding can't tip the grid a fraction of a pixel too tall.
    final gridWidth = bestCardWidth.floorToDouble() * bestColumns +
        (bestColumns - 1) * AppSizes.cardGridSpacing;
    return (bestColumns, gridWidth);
  }
}
