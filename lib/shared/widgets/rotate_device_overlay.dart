import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import 'back_arrow_icon.dart';

/// Full-screen prompt asking the player to turn their device to landscape.
///
/// Show it in place of (or over) a landscape-only game while the device is
/// in portrait. [onBack] lets the player leave without rotating.
class RotateDeviceOverlay extends StatelessWidget {
  final String locale;
  final VoidCallback onBack;

  const RotateDeviceOverlay({
    super.key,
    required this.locale,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.screen_rotation,
                      color: Colors.white,
                      size: 96,
                    ),
                    const SizedBox(height: AppSizes.spacingLarge),
                    Text(
                      localizer('general.rotate_to_landscape'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: AppSizes.fontSizeTitle,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSizes.spacingSmall,
              left: AppSizes.spacingSmall,
              child: IconButton(
                onPressed: onBack,
                icon: const BackArrowIcon(size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
