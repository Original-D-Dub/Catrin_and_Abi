import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/letter_quest_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_header_bar.dart';

/// Top HUD overlay for the Letter Quest game.
///
/// Displays a [GameHeaderBar] with:
/// - Back button (left)
/// - Words collected score circle (centre-left)
/// - Level number (right)
class GameHud extends StatelessWidget {
  final int levelNumber;

  /// UI language for the score label ('en' or 'cy').
  final String locale;

  const GameHud({super.key, required this.levelNumber, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: GameHeaderBar(
              onBack: () => Navigator.of(context).pop(),
              scoreLabel: localizer('general.words'),
              scoreValue: '${provider.wordsCompleted}',
              levelNumber: levelNumber,
            ),
          ),
        );
      },
    );
  }
}
