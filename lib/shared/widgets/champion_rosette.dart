import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import 'button.dart';

/// The Champion Mode rosette image.
const String kChampionRosetteAsset = 'assets/images/champion-rosette.png';

/// Width of [ChampionRosette] — 80px, well over 44px so it's an easy
/// target for a long press. The rosette image is 246×321, so it's about
/// 104px tall.
const double kChampionRosetteWidth = 80;

/// Size of [ChampionRosette] before it's turned by
/// [kChampionRosetteRotation].
const Size kChampionRosetteSize = Size(
  kChampionRosetteWidth,
  kChampionRosetteWidth * 321 / 246,
);

/// The rosette's tilt on a level-select title: 25° counter-clockwise.
const double kChampionRosetteRotation = -25 * math.pi / 180;

/// Where a level-select title's last letter touches the rosette, relative
/// to the centre of the tilted rosette (screen axes, y down): the lower-left
/// edge of its main circle, 45° round from the bottom, so the ribbon hangs
/// down to the right of the letter. See [TitleWithBadge].
final Offset kChampionRosetteTouchPoint = () {
  final size = kChampionRosetteSize;
  // The main circle in the 246×321 image: centred 120px down, filling
  // the width (radius trimmed so the letter meets solid gold, not the
  // gaps in the ruffled edge).
  final circleCentre = Offset(0, size.height * (120 / 321 - 0.5));
  final radius = size.width * 0.48;
  // Turn the circle's centre with the tilt (counter-clockwise when
  // negative, as in Transform.rotate).
  final a = kChampionRosetteRotation;
  final turnedCentre = Offset(
    circleCentre.dx * math.cos(a) - circleCentre.dy * math.sin(a),
    circleCentre.dx * math.sin(a) + circleCentre.dy * math.cos(a),
  );
  return turnedCentre +
      Offset(-radius * math.sin(math.pi / 4), radius * math.cos(math.pi / 4));
}();

/// Greyscale filter for the rosette while Champion Mode is switched off.
const ColorFilter _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// A game's Champion Mode badge, perched on the last letter of the
/// level-select title (see [TitleWithBadge]) once Champion Mode is
/// unlocked — the caller hides it until then.
///
/// Replaces the old Champion/Normal toggle. Champion Mode is on once
/// unlocked; a long press switches it off (the rosette greys out) and a
/// second long press switches it back on, each showing a modal that says
/// which way it went. The game's provider keeps the "off" choice for the
/// rest of the app session.
///
/// Shared by every game with a Champion Mode (BSL Maths, Bubble Pop, Card
/// Match, Counting).
class ChampionRosette extends StatelessWidget {
  /// Whether Champion Mode is currently on.
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppLocalizations localizer;

  const ChampionRosette({
    super.key,
    required this.value,
    required this.onChanged,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: localizer(
        value ? 'champion_mode.rosette_on' : 'champion_mode.rosette_off',
      ),
      child: GestureDetector(
        onLongPress: () {
          final next = !value;
          onChanged(next);
          _showChampionModeMessage(context, on: next, localizer: localizer);
        },
        child: _RosetteImage(on: value, height: kChampionRosetteSize.height),
      ),
    );
  }
}

class _RosetteImage extends StatelessWidget {
  final bool on;
  final double height;

  const _RosetteImage({required this.on, required this.height});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(kChampionRosetteAsset, height: height);
    if (on) return image;
    return Opacity(
      opacity: 0.6,
      child: ColorFiltered(colorFilter: _greyscale, child: image),
    );
  }
}

/// Shows the "Champion Mode off/on" modal over a full-screen 75% black
/// overlay after a long press on [ChampionRosette].
Future<void> _showChampionModeMessage(
  BuildContext context, {
  required bool on,
  required AppLocalizations localizer,
}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    barrierDismissible: true,
    barrierLabel: localizer('general.close'),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, _) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RosetteImage(on: on, height: 160),
            const SizedBox(height: 20),
            Text(
              localizer(
                on ? 'champion_mode.turned_on' : 'champion_mode.turned_off',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: localizer('general.close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
