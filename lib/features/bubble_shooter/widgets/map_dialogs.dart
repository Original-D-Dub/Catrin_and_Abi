import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/collection_screen.dart';
import '../../sports_collection/models/sport_card.dart';
import '../../sports_collection/widgets/sport_card_art.dart';
import '../services/bubble_shooter_map_prefs.dart';

/// Shows a sports card won from (or found in) a treasure chest: [heading]
/// over the card's art and name, with a button to close.
Future<void> showChestCardDialog(
  BuildContext context, {
  required SportCard card,
  required String heading,
  required AppLocalizations localizer,
}) {
  return _showPopup(
    context,
    localizer: localizer,
    builder: (context) {
      final width = MediaQuery.sizeOf(context).width * 0.7;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _heading(heading),
          const SizedBox(height: 16),
          SizedBox(
            width: width.clamp(160.0, 320.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(aspectRatio: 1, child: SportCardArt(card)),
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      localizer(card.nameKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF002D97),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: localizer('bubble_shooter.chest_collect'),
            icon: Icons.check,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

/// Shows a short [message] (e.g. why a chest can't be opened yet).
Future<void> showMapMessage(
  BuildContext context, {
  required String message,
  required AppLocalizations localizer,
}) {
  return _showPopup(
    context,
    localizer: localizer,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(message),
        const SizedBox(height: 20),
        PrimaryButton(
          label: localizer('general.close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// Lets the player pick which [MapCharacter] stands on the level map.
Future<MapCharacter?> showCharacterPicker(
  BuildContext context, {
  required MapCharacter current,
  required AppLocalizations localizer,
}) {
  return _showPopup<MapCharacter>(
    context,
    localizer: localizer,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(localizer('card_matching.choose_character')),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final character in MapCharacter.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Semantics(
                  button: true,
                  selected: character == current,
                  label: character.name,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, character),
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: character == current
                                  ? const Color(0xFFF5B400)
                                  : Colors.white,
                              width: 6,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            character.thumbAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ExcludeSemantics(child: _heading(character.name)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

Widget _heading(String text) => Text(
  text,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [Shadow(color: Color(0xFF063A98), offset: Offset(1, 3))],
  ),
);

/// Pops [builder]'s content up over the soft blue collection backdrop.
Future<T?> _showPopup<T>(
  BuildContext context, {
  required AppLocalizations localizer,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: localizer('general.close'),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (context, animation, _, child) => Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: animation,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: defaultCollectionOverlayGradient,
                ),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
        ),
      ],
    ),
    pageBuilder: (context, _, _) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: builder(context),
        ),
      ),
    ),
  );
}
