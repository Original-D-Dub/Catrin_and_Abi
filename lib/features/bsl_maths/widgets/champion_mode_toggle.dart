import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// On/off toggle for BSL Maths Champion Mode (BSL numbers with no numeral
/// labels on the keyboard), styled to match [SignSystemToggle]'s
/// [SegmentedButton] look.
///
/// Only ever shown once Champion Mode is unlocked — the caller hides this
/// widget entirely until then.
class ChampionModeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppLocalizations localizer;

  const ChampionModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          localizer('bsl_maths.champion_mode.label'),
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(localizer('bsl_maths.champion_mode.off')),
            ),
            ButtonSegment(
              value: true,
              label: Text(localizer('bsl_maths.champion_mode.on')),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.4),
            foregroundColor: AppColors.textPrimary,
            selectedBackgroundColor: Colors.white,
            selectedForegroundColor: AppColors.accentPurple,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
            textStyle: const TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
