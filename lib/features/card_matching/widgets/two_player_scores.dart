import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Both players' scores for a two-player Card Match game, shown in the
/// centre of the [GameHeaderBar] as each character's name followed by
/// their score. The player whose turn it is gets a solid
/// white chip; the other is faded.
class TwoPlayerScores extends StatelessWidget {
  final int player1Score;
  final int player2Score;

  /// Character names shown ahead of each score.
  final String player1Name;
  final String player2Name;

  /// Whose turn it is: 1 or 2.
  final int currentPlayer;

  const TwoPlayerScores({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.player1Name,
    required this.player2Name,
    required this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlayerChip(
            label: player1Name,
            score: player1Score,
            color: AppColors.abiPink,
            isActive: currentPlayer == 1,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlayerChip(
            label: player2Name,
            score: player2Score,
            color: AppColors.accentNavyBlue,
            isActive: currentPlayer == 2,
          ),
        ),
      ],
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isActive;

  const _PlayerChip({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: isActive ? color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
