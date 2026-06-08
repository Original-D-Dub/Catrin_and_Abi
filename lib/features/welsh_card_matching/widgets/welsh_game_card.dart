import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_constants.dart';
import '../../../shared/widgets/welsh_alphabet_svg.dart';
import '../../card_matching/models/card_model.dart';

/// Flip card widget for the Welsh card matching game.
///
/// Identical in behaviour to GameCard but renders WelshAlphabetSvg on the
/// sign side, which loads from assets/wyddor_iac_svg/ and supports digraphs.
class WelshGameCard extends StatefulWidget {
  final CardModel card;
  final VoidCallback onTap;

  const WelshGameCard({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  State<WelshGameCard> createState() => _WelshGameCardState();
}

class _WelshGameCardState extends State<WelshGameCard> {
  late GlobalKey<FlipCardState> _cardKey;

  @override
  void initState() {
    super.initState();
    _cardKey = GlobalKey<FlipCardState>();
  }

  @override
  void didUpdateWidget(WelshGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final flipCardState = _cardKey.currentState;
    if (flipCardState != null) {
      final isFront = flipCardState.isFront;
      final shouldBeFlipped = widget.card.isFlipped;
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
      flipOnTouch: false,
      direction: FlipDirection.HORIZONTAL,
      speed: GameConstants.cardFlipDurationMs,
      front: _buildCardBack(),
      back: _buildCardFront(),
    );
  }

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
            ? WelshAlphabetSvg(letter: widget.card.value)
            : _buildLetterContent(),
      ),
    );
  }

  Widget _buildLetterContent() {
    return FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        child: Text(
          widget.card.value,
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
