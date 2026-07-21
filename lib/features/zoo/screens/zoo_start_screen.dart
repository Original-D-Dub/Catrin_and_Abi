import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Entry screen for the zoo game: heading, intro instructions, centre
/// image, and a green Play button that opens the pick-a-player screen.
class ZooStartScreen extends StatefulWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  const ZooStartScreen({super.key, this.locale = 'en'});

  @override
  State<ZooStartScreen> createState() => _ZooStartScreenState();
}

class _ZooStartScreenState extends State<ZooStartScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playIntro('zoo', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);

    return ZooBackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ZooHeading(localizer('zoo.start.title')),
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
            const SizedBox(height: 12),
            Text(
              localizer('zoo.start.intro'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/games/zoo/animals.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ZooActionButton(
              label: localizer('general.play'),
              color: AppColors.schoolGreen,
              onPressed: () {
                final lastCharacter =
                    context.read<SettingsProvider>().lastZooCharacter;
                if (lastCharacter != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.zooPlayer,
                    arguments: {
                      'locale': widget.locale,
                      'character': lastCharacter,
                    },
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.zooPickPlayer,
                    arguments: widget.locale,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
