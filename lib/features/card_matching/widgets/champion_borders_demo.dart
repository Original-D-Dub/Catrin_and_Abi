import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import '../../bsl_maths/widgets/champion_mode_explainer.dart';

/// Champion Mode demo for card matching: a face-up letter + sign pair
/// whose colour-coded border fades to white, as it does on every card in
/// Champion Mode (see [GameCard]).
class ChampionBordersDemo extends StatefulWidget {
  final SignSystem signSystem;

  const ChampionBordersDemo({super.key, this.signSystem = SignSystem.bsl});

  @override
  State<ChampionBordersDemo> createState() => _ChampionBordersDemoState();
}

class _ChampionBordersDemoState extends State<ChampionBordersDemo>
    with SingleTickerProviderStateMixin, ChampionDemoLoop {
  static const String _letter = 'a';
  static const double _cardWidth = 110;
  static const double _cardHeight = 140;

  final Color _pairColor = AppColors.vowelPairColors[_letter]!;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final border = Color.lerp(
          _pairColor,
          AppColors.accentWhite,
          championDemoFade(loop.value),
        )!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(
              border,
              SignLetterImage(letter: _letter),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            _buildCard(
              border,
              Center(
                child: FittedBox(
                  child: Text(
                    _letter,
                    style: TextStyle(
                      fontFamily: 'OpenDyslexic',
                      fontSize: AppSizes.fontSizeCardLetter,
                      fontWeight: FontWeight.bold,
                      color: _pairColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A face-up card styled like [GameCard]'s front.
  Widget _buildCard(Color border, Widget child) {
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: border, width: AppSizes.cardBorderWidth),
      ),
      child: child,
    );
  }
}
