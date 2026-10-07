import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/choose_character_grid.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Character detail screen: the chosen character's name as the heading
/// (back arrow to its left), a large portrait in the centre, and a button
/// row — pink Change Player (back to pick-a-player) and green Choose
/// (into the zoo's choose-a-level screen).
class ZooPlayerScreen extends StatefulWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  /// Which character this screen shows ([CharacterThumb.id]).
  final String characterId;

  const ZooPlayerScreen({
    super.key,
    this.locale = 'en',
    required this.characterId,
  });

  @override
  State<ZooPlayerScreen> createState() => _ZooPlayerScreenState();
}

class _ZooPlayerScreenState extends State<ZooPlayerScreen> {
  late final Future<CharacterThumb?> _character = _findCharacter();

  String get locale => widget.locale;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CharacterThumb?>(
      future: _character,
      builder: (context, snapshot) {
        final character = snapshot.data;
        if (character == null) {
          return const ZooBackgroundScaffold(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildScreen(context, character);
      },
    );
  }

  /// The character for [characterId], falling back to Abi — and then the
  /// first character — if it no longer exists (e.g. an old saved pick).
  Future<CharacterThumb?> _findCharacter() async =>
      await CharacterThumb.find(widget.characterId) ??
      await CharacterThumb.find('abi') ??
      (await CharacterThumb.loadAll()).firstOrNull;

  Widget _buildScreen(BuildContext context, CharacterThumb character) {
    final localizer = AppLocalizations(locale: locale);

    return ZooBackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Heading row: back arrow left, character name centred.
            Stack(
              alignment: Alignment.center,
              children: [
                ZooHeading(character.name),
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
            // Full portrait straight on the background, falling back to
            // the framed thumbnail while art is still to follow.
            Expanded(
              child: Center(
                child: Image.asset(
                  character.fullAssetPath ?? character.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SecondaryButton(
                  label: localizer('zoo.change_player'),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.zooPickPlayer,
                    arguments: locale,
                  ),
                ),
                const SizedBox(width: 20),
                PrimaryButton(
                  label: localizer('zoo.choose'),
                  onPressed: () {
                    context.read<SettingsProvider>().setLastZooCharacter(
                      character.id,
                    );
                    Navigator.pushNamed(
                      context,
                      AppRoutes.zooLevels,
                      arguments: {'locale': locale, 'character': character.id},
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
