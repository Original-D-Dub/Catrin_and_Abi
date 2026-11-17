import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/collection_screen.dart';
import '../models/sport_card.dart';
import '../providers/sports_collection_provider.dart';
import '../widgets/sport_card_art.dart';

/// "My Sports Cards": every [SportCard], showing the ones the player has won
/// from Bubble Shooter treasure chests.
class SportsCollectionScreen extends StatefulWidget {
  /// UI locale ('en' or 'cy').
  final String locale;

  const SportsCollectionScreen({super.key, this.locale = 'en'});

  @override
  State<SportsCollectionScreen> createState() => _SportsCollectionScreenState();
}

class _SportsCollectionScreenState extends State<SportsCollectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playerId = context.read<AuthProvider>().userId;
      if (playerId != null) {
        context.read<SportsCollectionProvider>().load(playerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final playerId = context.watch<AuthProvider>().userId;
    final sports = context.watch<SportsCollectionProvider>();
    final collected =
        playerId == null ? const <SportCard>{} : sports.collected;

    return CollectionScreen(
      locale: widget.locale,
      title: localizer('sports.collection_title'),
      countLabel: localizer('letter_bingo.cards_label'),
      loading: playerId != null && !sports.isLoaded(playerId),
      items: [
        for (final card in SportCard.values)
          CollectionItem(
            id: card.id,
            name: localizer(card.nameKey),
            collected: collected.contains(card),
            placeholderIcon: card.icon,
            artBuilder: (_) => SportCardArt(card),
          ),
      ],
    );
  }
}
