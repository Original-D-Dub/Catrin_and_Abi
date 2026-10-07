import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// One-player / two-player tabs shown at the top of the Card Match level
/// select, styled to match [ChampionModeToggle]'s [SegmentedButton] look.
class PlayerModeTabs extends StatelessWidget {
  final bool isTwoPlayer;
  final ValueChanged<bool> onChanged;
  final AppLocalizations localizer;

  const PlayerModeTabs({
    super.key,
    required this.isTwoPlayer,
    required this.onChanged,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.person),
          label: Text(localizer('card_matching.one_player')),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.people),
          label: Text(localizer('card_matching.two_players')),
        ),
      ],
      selected: {isTwoPlayer},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.4),
        foregroundColor: AppColors.textPrimary,
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: AppColors.accentPurple,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
