import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// One-player / two-player tabs shown at the top of a level select (Card
/// Match, Letter Bingo), styled as a [SegmentedButton].
///
/// [onePlayerLabel] / [twoPlayerLabel] override the default "1 Player" /
/// "2 Players" text (e.g. Letter Bingo's "Multiplayer").
class PlayerModeTabs extends StatelessWidget {
  final bool isTwoPlayer;
  final ValueChanged<bool> onChanged;
  final AppLocalizations localizer;
  final String? onePlayerLabel;
  final String? twoPlayerLabel;

  const PlayerModeTabs({
    super.key,
    required this.isTwoPlayer,
    required this.onChanged,
    required this.localizer,
    this.onePlayerLabel,
    this.twoPlayerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.person),
          label: Text(onePlayerLabel ?? localizer('card_matching.one_player')),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.people),
          label: Text(twoPlayerLabel ?? localizer('card_matching.two_players')),
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
