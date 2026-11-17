import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import '../models/card_model.dart';
import '../../../core/theme/digraph_letter_spacing.dart';

/// A flip card widget for the matching game.
///
/// Displays either a BSL sign image or a letter, with a colored border
/// indicating the pair. Uses flip_card package for animations.
///
/// In Champion Mode ([championMode]) the border is white, matching the
/// card face, so there is no visible border; letters keep their pair
/// colour and gameplay is unchanged.
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

  /// Which sign-asset family to render for [CardType.bslSign] cards.
  final SignSystem signSystem;

  /// Whether Champion Mode is on: every card's colour-coded pair border
  /// becomes white (invisible against the white face).
  final bool championMode;

  const GameCard({
    super.key,
    required this.card,
    required this.onTap,
    this.signSystem = SignSystem.bsl,
    this.championMode = false,
  });

  /// The front-face border colour: the pair's colour, or white (blending
  /// into the white face, so no visible border) in Champion Mode.
  Color get _frontBorderColor =>
      championMode ? AppColors.accentWhite : card.pairColor;

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
      // Letters get more breathing room than signs, whose artwork
      // already has space around the hand.
      padding: EdgeInsets.all(widget.card.type == CardType.bslSign ? 4 : 16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: widget._frontBorderColor,
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
      child: widget.card.type == CardType.bslSign
          ? _buildBslSignContent()
          : _buildLetterContent(),
    );
  }

  /// Builds the BSL sign image content.
  ///
  /// Deliberately has no [Center]/[FittedBox] of its own. [FlipCard]'s
  /// Stack uses `StackFit.passthrough`, so the card's tight constraints
  /// reach this Container; its `padding` deflates its tight constraints (the card's actual rendered
  /// size) by a fixed inset and passes the rest straight through to
  /// [SignLetterImage], whose underlying Image fills exactly that box
  /// and scales the artwork via its own `BoxFit.contain` — so the
  /// sign grows and shrinks directly with the card's size. A [Center] here
  /// would loosen those constraints, which only ever shrinks an oversized
  /// sign and never grows an undersized one.
  Widget _buildBslSignContent() {
    return SignLetterImage(letter: widget.card.value);
  }

  /// Builds the letter text content.
  ///
  /// Like [_buildBslSignContent], this has no [Center] around it: the
  /// [FittedBox] receives the card's tight constraints (minus the padding),
  /// fills that box and scales the letter up or down with `BoxFit.contain`
  /// (centred by FittedBox's default alignment). A [Center] would loosen
  /// the constraints, letting FittedBox shrink to the text's natural size
  /// so the letter could never grow past [AppSizes.fontSizeCardLetter].
  /// The letter keeps its pair colour in Champion Mode too — only the
  /// border loses the colour coding.
  Widget _buildLetterContent() {
    return FittedBox(
      fit: BoxFit.contain,
      child: Text(
        widget.card.value.toLowerCase(),
        style: digraphAwareStyle(
          widget.card.value.toLowerCase(),
          TextStyle(
            fontFamily: 'OpenDyslexic',
            fontSize: AppSizes.fontSizeCardLetter,
            fontWeight: FontWeight.bold,
            color: widget.card.pairColor,
          ),
        ),
      ),
    );
  }
}
