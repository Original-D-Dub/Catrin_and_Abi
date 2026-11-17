import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/collection_screen.dart';

/// The symbol cards won from More or Less's treasure chests.
enum SymbolCard {
  moreThan('>', 'more_or_less.card.more_than'),
  lessThan('<', 'more_or_less.card.less_than'),

  /// Placeholder until level 12's prize is decided.
  mystery('?', 'more_or_less.card.coming_soon');

  /// The symbol as shown on the card.
  final String symbol;

  /// Translation key for the caption under the symbol.
  final String nameKey;

  const SymbolCard(this.symbol, this.nameKey);

  /// The card in the chest at [level], or null if it isn't a chest level.
  static SymbolCard? forLevel(int level) => switch (level) {
    4 => SymbolCard.moreThan,
    8 => SymbolCard.lessThan,
    12 => SymbolCard.mystery,
    _ => null,
  };

  static bool isChestLevel(int level) => forLevel(level) != null;
}

/// A playing card showing [card]'s symbol with its name underneath.
class SymbolCardView extends StatelessWidget {
  static const Color _navy = Color(0xFF002D97);
  static const Color _gold = Color(0xFFF5B400);

  final SymbolCard card;
  final AppLocalizations localizer;

  const SymbolCardView({
    super.key,
    required this.card,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    final name = localizer(card.nameKey);
    return Semantics(
      label: name,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold, width: 6),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        card.symbol,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 160,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                FittedBox(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the card just won from a chest: a heading, the [card] and a
/// button to collect it, over the soft blue collection backdrop, as Bubble
/// Shooter's chest popups do.
Future<void> showSymbolCardWon(
  BuildContext context, {
  required SymbolCard card,
  required AppLocalizations localizer,
}) {
  return showGeneralDialog(
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
    pageBuilder: (context, _, _) {
      final width = MediaQuery.sizeOf(context).width * 0.6;
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizer('more_or_less.chest_won'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0xFF063A98), offset: Offset(1, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: width.clamp(160.0, 280.0),
                    child: SymbolCardView(card: card, localizer: localizer),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: localizer('bubble_shooter.chest_collect'),
                    icon: Icons.check,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
