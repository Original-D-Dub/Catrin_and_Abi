import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../models/zoo_character.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Character detail screen: the chosen character's name as the heading
/// (back arrow to its left), a large portrait in the centre, and a button
/// row — pink Change Player (back to pick-a-player) and green Choose
/// (into the zoo's choose-a-level screen).
class ZooPlayerScreen extends StatelessWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  /// Which character this screen shows ([ZooCharacter.id]).
  final String characterId;

  const ZooPlayerScreen({
    super.key,
    this.locale = 'en',
    required this.characterId,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);
    final character = ZooCharacter.byId(characterId);

    return ZooBackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Heading row: back arrow left, character name centred.
            Stack(
              alignment: Alignment.center,
              children: [
                ZooHeading(localizer(character.nameKey)),
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
            const SizedBox(height: 16),
            // Full portrait (<id>.png) straight on the background, falling
            // back to the square thumb and then a placeholder icon while
            // art is still to follow.
            Expanded(
              child: Center(
                child: Image.asset(
                  character.fullAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => character.thumbAsset != null
                      ? Image.asset(
                          character.thumbAsset!,
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          Icons.person,
                          size: 120,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ZooActionButton(
                  label: localizer('zoo.change_player'),
                  color: AppColors.abiPink,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.zooPickPlayer,
                    arguments: locale,
                  ),
                ),
                const SizedBox(width: 20),
                ZooActionButton(
                  label: localizer('zoo.choose'),
                  color: AppColors.schoolGreen,
                  onPressed: () {
                    context
                        .read<SettingsProvider>()
                        .setLastZooCharacter(character.id);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.zooLevels,
                      arguments: {
                        'locale': locale,
                        'character': character.id,
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
