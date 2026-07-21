import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';

/// Placeholder interior screen for an enterable zoo building.
///
/// Opened from [ZooScreen]'s Enter button. [building] is the identifier
/// from the map's trigger zone (`aviary`, `reptile-house`, `aquarium`);
/// each will get its own activity content later. [signSystem] selects
/// BSL or IAC assets once those activities include sign content.
class ZooBuildingScreen extends StatelessWidget {
  final String building;
  final String locale;
  final SignSystem signSystem;

  const ZooBuildingScreen({
    super.key,
    required this.building,
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
  });

  static const _icons = {
    'aviary': Icons.flutter_dash,
    'reptile-house': Icons.pest_control,
    'aquarium': Icons.water,
  };

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);
    final titleKey = 'zoo.${building.replaceAll('-', '_')}';

    return Scaffold(
      backgroundColor: const Color(0xFFDFEDC6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B6231),
        foregroundColor: Colors.white,
        title: Text(localizer(titleKey)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[building] ?? Icons.help_outline,
              size: 96,
              color: const Color(0xFF3B6231),
            ),
            const SizedBox(height: 16),
            Text(
              localizer('zoo.coming_soon'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF3B6231),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
