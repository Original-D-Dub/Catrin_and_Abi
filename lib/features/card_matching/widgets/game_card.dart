import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_constants.dart';
import '../models/card_model.dart';

/// A flip card widget for the matching game.
///
/// Displays either a BSL sign image or a letter, with a colored border
/// indicating the pair. Uses flip_card package for animations.
///
/// Usage:
/// ```dart
/// GameCard(
///   card: cardModel,
///   onTap: () => provider.selectCard(cardId: cardModel.id),
/// )
/// ```
class GameCard extends StatefulWidget {
  /// The card data to display
  final CardModel card;

  /// Callback when card is tapped
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  /// Controller for the flip animation
  late GlobalKey<FlipCardState> _cardKey;

  @override
  void initState() {
    super.initState();
    _cardKey = GlobalKey<FlipCardState>();
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync flip state with model
    final flipCardState = _cardKey.currentState;
    if (flipCardState != null) {
      final isFront = flipCardState.isFront;
      final shouldBeFlipped = widget.card.isFlipped;

      // If state doesn't match, toggle the card
      if (isFront && shouldBeFlipped) {
        flipCardState.toggleCard();
      } else if (!isFront && !shouldBeFlipped) {
        flipCardState.toggleCard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      key: _cardKey,
      flipOnTouch: false, // We control flipping via onTap
      direction: FlipDirection.HORIZONTAL,
      speed: GameConstants.cardFlipDurationMs,
      front: _buildCardBack(),
      back: _buildCardFront(),
      onFlipDone: (isFront) {
        // Card flip completed
      },
    );
  }

  /// Builds the back of the card (face-down state).
  Widget _buildCardBack() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          image: const DecorationImage(
            image: AssetImage('assets/games/card_matching/Card-back-9.jpg'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Icon(
              Icons.question_mark,
              color: AppColors.accentWhite.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the front of the card (face-up state).
  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: widget.card.pairColor,
          width: AppSizes.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: widget.card.type == CardType.bslSign
            ? _buildBslSignContent()
            : _buildLetterContent(),
      ),
    );
  }

  /// Builds the BSL sign image content.
  ///
  /// Uses [Padding] to give the image breathing room, then
  /// fills the remaining space so signs scale with card size.
  Widget _buildBslSignContent() {
    if (widget.card.imagePath == null) {
      return const Icon(Icons.image_not_supported);
    }

    return Image.asset(
      widget.card.imagePath!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading BSL image: $error');
        return const Icon(Icons.image_not_supported);
      },
    );
  }

  /// Builds the letter text content.
  ///
  /// Uses [FittedBox] so the letter scales with the card size
  /// instead of being a fixed font size.
  Widget _buildLetterContent() {
    return FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        child: Text(
          widget.card.value.toLowerCase(),
          style: TextStyle(
            fontSize: AppSizes.fontSizeCardLetter,
            fontWeight: FontWeight.bold,
            color: widget.card.pairColor,
          ),
        ),
      ),
    );
  }
}
