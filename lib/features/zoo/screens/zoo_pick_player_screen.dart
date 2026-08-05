import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../models/zoo_character.dart';
import '../widgets/zoo_framed_box.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Character selection screen for the zoo game: a responsive 2 x 3 grid of
/// framed character portraits with names underneath. Tapping a character
/// opens the player screen ([AppRoutes.zooPlayer]) for that character.
class ZooPickPlayerScreen extends StatefulWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  const ZooPickPlayerScreen({super.key, this.locale = 'en'});

  @override
  State<ZooPickPlayerScreen> createState() => _ZooPickPlayerScreenState();
}

class _ZooPickPlayerScreenState extends State<ZooPickPlayerScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playTitle('zoo_pick_player', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final localizer = AppLocalizations(locale: locale);

    return ZooBackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ZooHeading(localizer('zoo.pick_player.title')),
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 2 columns portrait, 3 columns landscape (2 x 3 grid
                      // either way round).
                      final crossAxisCount =
                          constraints.maxWidth < 600 ? 2 : 3;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        // Square image plus the name row below it.
                        childAspectRatio: 0.8,
                        children: [
                          for (final character in ZooCharacter.all)
                            _CharacterTile(
                              character: character,
                              localizer: localizer,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.zooPlayer,
                                arguments: {
                                  'locale': locale,
                                  'character': character.id,
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One grid cell: square framed portrait with the character name below.
class _CharacterTile extends StatelessWidget {
  final ZooCharacter character;
  final AppLocalizations localizer;
  final VoidCallback onTap;

  const _CharacterTile({
    required this.character,
    required this.localizer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ZooFramedBox(
                child: character.thumbAsset != null
                    ? Image.asset(character.thumbAsset!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizer(character.nameKey),
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
