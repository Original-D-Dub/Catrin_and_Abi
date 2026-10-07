import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/choose_character_grid.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Character selection screen for the zoo game: a [ChooseCharacterGrid] of
/// every character thumbnail with names underneath. Tapping a character
/// opens the player screen ([AppRoutes.zooPlayer]) for that character.
class ZooPickPlayerScreen extends StatelessWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  const ZooPickPlayerScreen({super.key, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    return ZooBackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ZooHeading(
                  localizer('zoo.pick_player.title'),
                  letterSpacingFactor: 0.18,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const BackArrowIcon(size: 32),
                    tooltip: localizer('general.back'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ChooseCharacterGrid(
                padding: const EdgeInsets.symmetric(vertical: 16),
                // White with a shadow to stay readable over the photo.
                labelStyle: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                onSelected: (character) => Navigator.pushNamed(
                  context,
                  AppRoutes.zooPlayer,
                  arguments: {'locale': locale, 'character': character.id},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
