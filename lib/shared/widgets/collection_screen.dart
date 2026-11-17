import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import 'button.dart';
import 'game_header_bar.dart';

/// One slot in a [CollectionScreen] grid.
///
/// Uncollected slots show [placeholder] (e.g. the animal's letter) or
/// [placeholderIcon]; collected ones show the artwork from [artBuilder] with
/// [name] underneath, and open a large view when tapped.
class CollectionItem {
  /// Stable identifier, e.g. the animal's letter or the sport's id.
  final String id;

  /// Display name shown under collected artwork.
  final String name;

  /// Whether the player has collected this item.
  final bool collected;

  /// Text shown on an uncollected slot.
  final String? placeholder;

  /// Icon shown on an uncollected slot when [placeholder] is null.
  final IconData? placeholderIcon;

  /// Builds the item's artwork, filling the box it's given.
  final Widget Function(BuildContext context) artBuilder;

  const CollectionItem({
    required this.id,
    required this.name,
    required this.collected,
    required this.artBuilder,
    this.placeholder,
    this.placeholderIcon,
  });
}

/// Default backdrop behind an item's enlarged view — the same soft blue as
/// the Letter Bingo success page.
final RadialGradient defaultCollectionOverlayGradient = RadialGradient(
  colors: [
    const Color(0xFF94E0FF).withValues(alpha: 0.88),
    const Color(0xFF00A8F3).withValues(alpha: 0.88),
  ],
);

/// Shared "my collection" screen: a header with the number collected, a
/// grid of [items] (collected ones show their art, the rest a placeholder),
/// and an optional floating "Play Again" button.
///
/// Used for Letter Bingo's animals and the Bubble Shooter's sports cards.
class CollectionScreen extends StatelessWidget {
  /// UI locale ('en' or 'cy').
  final String locale;

  /// Heading in the header bar (already translated).
  final String title;

  /// Label for the collected count in the header bar (already translated).
  final String countLabel;

  /// Every slot, in display order.
  final List<CollectionItem> items;

  /// Shows a spinner instead of the grid.
  final bool loading;

  /// When non-null, a floating "Play Again" button pops this screen and
  /// calls back.
  final VoidCallback? onPlayAgain;

  /// Backdrop behind an item's enlarged view.
  final Gradient? overlayGradient;

  /// Colour of item names and placeholders.
  static const Color _ink = Color(0xFF002D97);

  const CollectionScreen({
    super.key,
    this.locale = 'en',
    required this.title,
    required this.countLabel,
    required this.items,
    this.loading = false,
    this.onPlayAgain,
    this.overlayGradient,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);
    final collectedCount = items.where((i) => i.collected).length;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/backgrounds/felt-background.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              GameHeaderBar(
                onBack: () => Navigator.pop(context),
                scoreLabel: countLabel,
                scoreValue: '$collectedCount',
                showLevel: false,
                centerContent: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              // Held portrait with room for a full row of
                              // two square tiles: two big columns.
                              final portrait =
                                  MediaQuery.orientationOf(context) ==
                                  Orientation.portrait;
                              final twoColumnTile = (width - 12 * 2 - 8) / 2;
                              final crossAxisCount =
                                  width < 374 ||
                                      (portrait &&
                                          constraints.maxHeight >=
                                              twoColumnTile + 12 * 2)
                                  ? 2
                                  : width < 600
                                  ? 3
                                  : 4;
                              return GridView.builder(
                                // Bottom padding keeps the last row above
                                // the floating button.
                                padding: EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  onPlayAgain != null ? 84 : 12,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                itemCount: items.length,
                                itemBuilder: (context, index) => _ItemTile(
                                  item: items[index],
                                  localizer: localizer,
                                  overlayGradient:
                                      overlayGradient ??
                                      defaultCollectionOverlayGradient,
                                ),
                              );
                            },
                          ),
                          if (onPlayAgain != null)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: PrimaryButton(
                                    label: localizer('general.play_again'),
                                    icon: Icons.replay,
                                    expanded: true,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onPlayAgain!();
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final CollectionItem item;
  final AppLocalizations localizer;
  final Gradient overlayGradient;

  const _ItemTile({
    required this.item,
    required this.localizer,
    required this.overlayGradient,
  });

  void _showOverlay(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      // The barrier only takes a flat colour, so it is left transparent and
      // the gradient is painted in the transition instead.
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: localizer('general.close'),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            // Ignores taps so they still reach the barrier and dismiss.
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: animation,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: overlayGradient),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            ),
          ],
        );
      },
      pageBuilder: (context, _, _) {
        // Portrait: 75% of the screen width. Landscape: as tall as fits —
        // the square art plus the name bar fill the height between the
        // safe area and the dialog's vertical inset.
        const nameBarHeight = 64.0;
        const dialogVerticalInset = 24.0 * 2; // Dialog's default insetPadding
        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        final fullHeightArt =
            screen.height - safe.vertical - dialogVerticalInset - nameBarHeight;
        final width = fullHeightArt < screen.width * 0.75
            ? fullHeightArt
            : screen.width * 0.75;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(aspectRatio: 1, child: item.artBuilder(context)),
                  Container(
                    width: double.infinity,
                    height: nameBarHeight,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      // Shrinks long names on the narrower landscape card.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: CollectionScreen._ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;
    final labelHeight = wide ? 48.0 : 24.0;
    final labelFontSize = wide ? 28.0 : 14.0;
    return Semantics(
      button: item.collected,
      label: item.collected ? item.name : null,
      child: GestureDetector(
        onTap: item.collected ? () => _showOverlay(context) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          child: Container(
            color: Colors.white.withValues(alpha: 0.55),
            child: item.collected
                ? Column(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: item.artBuilder(context),
                        ),
                      ),
                      SizedBox(
                        height: labelHeight,
                        width: double.infinity,
                        child: ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              item.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w600,
                                color: CollectionScreen._ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: item.placeholder != null
                        ? Text(
                            item.placeholder!,
                            style: const TextStyle(
                              fontFamily: 'OpenDyslexic',
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: CollectionScreen._ink,
                            ),
                          )
                        : Icon(
                            item.placeholderIcon ?? Icons.help_outline,
                            size: 44,
                            color: CollectionScreen._ink.withValues(
                              alpha: 0.35,
                            ),
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}
