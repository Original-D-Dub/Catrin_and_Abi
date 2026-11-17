import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/collection_screen.dart';
import '../../profile/models/profile_catalog.dart';

/// Shows a short [message] (e.g. why a chest can't be opened yet).
Future<void> showBadgeMapMessage(
  BuildContext context, {
  required String message,
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
    pageBuilder: (context, _, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xFF063A98), offset: Offset(1, 3))],
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

/// Shows a badge won from a treasure chest on the ages 1–3 level map: the
/// heading over the badge and its name, with a button to collect. Mirrors
/// Bubble Shooter's chest-card dialog.
Future<void> showBadgeAwardDialog(
  BuildContext context, {
  required ProfileBadge badge,
  required String heading,
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
    pageBuilder: (context, _, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xFF063A98), offset: Offset(1, 3))],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.color,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(badge.emoji,
                    style: const TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 14),
              Text(
                localizer(badge.labelKey),
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.catrinBlue,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: localizer('vowel_hand.chest_collect'),
                icon: Icons.check,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
