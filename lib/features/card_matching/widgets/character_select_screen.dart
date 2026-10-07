import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/choose_character_grid.dart';

/// Two-player Card Match character select, shown once per player: a
/// [ChooseCharacterGrid] of every character thumbnail. [takenCharacter]
/// (player 1's pick, on player 2's screen) is faded and can't be chosen, so
/// both players never share a character.
class CharacterSelectScreen extends StatelessWidget {
  /// Which player (1 or 2) is choosing.
  final int player;

  final CharacterThumb? takenCharacter;
  final ValueChanged<CharacterThumb> onPick;
  final VoidCallback onBack;
  final AppLocalizations localizer;

  const CharacterSelectScreen({
    super.key,
    required this.player,
    this.takenCharacter,
    required this.onPick,
    required this.onBack,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = player == 1
        ? AppColors.abiPink
        : AppColors.accentNavyBlue;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingSmall,
            AppSizes.paddingSmall,
            AppSizes.paddingSmall,
            0,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const BackArrowIcon(size: 32),
                tooltip: localizer('general.back'),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  localizer('card_matching.player$player'),
                  textAlign: TextAlign.center,
                  style: AppTheme.title.copyWith(
                    fontSize: AppSizes.fontSizeTitle,
                    color: playerColor,
                  ),
                ),
              ),
              // Balances the back button so the title stays centred.
              const SizedBox(width: 48),
            ],
          ),
        ),
        Text(
          localizer('card_matching.choose_character'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ChooseCharacterGrid(
                disabledNames: {
                  if (takenCharacter != null) takenCharacter!.name,
                },
                onSelected: onPick,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
