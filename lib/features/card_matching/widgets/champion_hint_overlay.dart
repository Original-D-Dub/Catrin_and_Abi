import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import '../../../shared/widgets/button.dart';
import '../models/card_model.dart';
import '../../../core/theme/digraph_letter_spacing.dart';

/// Champion Mode hint: dims the board and shows the card the player has
/// just turned over beside its pair, face-up with their colour-coded pair
/// border restored. Tapping anywhere, or the dismiss button, closes it.
class ChampionHintOverlay extends StatelessWidget {
  /// The card the player has just turned over.
  final CardModel card;

  /// The card that matches [card].
  final CardModel pair;

  final SignSystem signSystem;
  final String title;
  final String dismissLabel;
  final VoidCallback onDismiss;

  const ChampionHintOverlay({
    super.key,
    required this.card,
    required this.pair,
    required this.signSystem,
    required this.title,
    required this.dismissLabel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final cardWidth = isWideScreen ? 160.0 : 120.0;
    // Matches the 0.8 aspect ratio the board uses on phones.
    final cardHeight = cardWidth / 0.8;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCard(card, cardWidth, cardHeight),
                    const SizedBox(width: AppSizes.spacingMedium),
                    _buildCard(pair, cardWidth, cardHeight),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingLarge),
                SecondaryButton(
                  label: dismissLabel,
                  icon: Icons.thumb_up,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A face-up card styled like [GameCard]'s front, with its pair border.
  Widget _buildCard(CardModel card, double width, double height) {
    return Container(
      width: width,
      height: height,
      // Letters get more breathing room than signs, whose artwork
      // already has space around the hand.
      padding: EdgeInsets.all(card.type == CardType.bslSign ? 4 : 16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: card.pairColor,
          width: AppSizes.cardBorderWidth,
        ),
      ),
      child: card.type == CardType.bslSign
          ? SignLetterImage(letter: card.value)
          : FittedBox(
              child: Text(
                card.value.toLowerCase(),
                style: digraphAwareStyle(
                  card.value.toLowerCase(),
                  TextStyle(
                    fontFamily: 'OpenDyslexic',
                    fontSize: AppSizes.fontSizeCardLetter,
                    fontWeight: FontWeight.bold,
                    color: card.pairColor,
                  ),
                ),
              ),
            ),
    );
  }
}
