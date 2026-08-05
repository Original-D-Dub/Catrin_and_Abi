import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/back_arrow_icon.dart';

/// Player scores — reached via the "Score" menu item.
///
/// Placeholder for now: just the heading and a back arrow, per spec. Fill
/// this in once there's a real per-game score summary to show.
class ScoresScreen extends StatelessWidget {
  final String locale;

  const ScoresScreen({super.key, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(locale: locale);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1250),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('profile.scores_title'),
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
