import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/collection_screen.dart';

/// The big-number cards won from Number Race's treasure chests, each with
/// a (future) video of the number being signed.
enum BigNumber {
  thousand('1,000'),
  million('1,000,000'),
  billion('1,000,000,000');

  /// The number as shown on the card.
  final String digits;

  const BigNumber(this.digits);

  /// The card in the chest at [level], or null if it isn't a chest level.
  static BigNumber? forLevel(int level) => switch (level) {
    5 => BigNumber.thousand,
    9 => BigNumber.million,
    13 => BigNumber.billion,
    _ => null,
  };
}

/// A playing card showing [number] with a play badge. Tapping it opens
/// [showBigNumberVideo].
class BigNumberCard extends StatelessWidget {
  static const Color _navy = Color(0xFF002D97);
  static const Color _gold = Color(0xFFF5B400);

  final BigNumber number;
  final AppLocalizations localizer;

  const BigNumberCard({
    super.key,
    required this.number,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: localizer(
        'number_race.big_number.watch',
      ).replaceAll('{number}', number.digits),
      child: GestureDetector(
        onTap: () =>
            showBigNumberVideo(context, number: number, localizer: localizer),
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
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      child: ExcludeSemantics(
                        child: Text(
                          number.digits,
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _navy,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
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

/// Shows the card just won from a chest: a heading, the [number] card
/// (tap it to watch the sign) and a button to collect it.
Future<void> showBigNumberWon(
  BuildContext context, {
  required BigNumber number,
  required AppLocalizations localizer,
}) {
  return _showPopup(
    context,
    localizer: localizer,
    builder: (context) {
      final width = MediaQuery.sizeOf(context).width * 0.6;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _heading(localizer('number_race.chest_won')),
          const SizedBox(height: 16),
          SizedBox(
            width: width.clamp(160.0, 280.0),
            child: BigNumberCard(number: number, localizer: localizer),
          ),
          const SizedBox(height: 12),
          Text(
            localizer('number_race.big_number.tap_to_watch'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xFF063A98), offset: Offset(1, 2))],
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

/// Pops up a placeholder for the video of [number] being signed, with a
/// button to close.
Future<void> showBigNumberVideo(
  BuildContext context, {
  required BigNumber number,
  required AppLocalizations localizer,
}) {
  return _showPopup(
    context,
    localizer: localizer,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(number.digits),
        const SizedBox(height: 16),
        // Placeholder until the signing videos are recorded.
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B2440),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white70,
                  size: 72,
                ),
                const SizedBox(height: 8),
                Text(
                  localizer('number_race.big_number.video_soon'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: localizer('general.close'),
          onPressed: () => Navigator.pop(context),
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
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [Shadow(color: Color(0xFF063A98), offset: Offset(1, 3))],
  ),
);

/// Pops [builder]'s content up over the soft blue collection backdrop, as
/// Bubble Shooter's chest popups do.
Future<void> _showPopup(
  BuildContext context, {
  required AppLocalizations localizer,
  required WidgetBuilder builder,
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
    pageBuilder: (context, _, _) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}
