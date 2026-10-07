import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/game_filters.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../services/settings_provider.dart';

/// Full-width banner tile shown above the game grid on both home screens.
///
/// Reads [SettingsProvider.signSystem] the same way the vowel-hand game
/// tile does, showing "Learn BSL" or "Learn IAC" accordingly. Tapping it
/// opens the guided "Learn BSL trail" level-select screen.
class LearnSignSystemTile extends StatelessWidget {
  /// UI locale ('en' or 'cy') used to look up the localized label.
  final String locale;

  /// Height to render at — pass [gameGridTileHeight] so this matches the
  /// game tiles below it.
  final double height;

  const LearnSignSystemTile({
    super.key,
    required this.locale,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final localizer = AppLocalizations(locale: locale);
    final titleKey = settings.signSystem == SignSystem.iac
        ? 'home.learn_iac_tile'
        : 'home.learn_bsl_tile';
    final isWideDevice = MediaQuery.of(context).size.width > 600;
    final fontSize = isWideDevice
        ? AppSizes.fontSizeExtraExtraLarge
        : AppSizes.fontSizeExtraLarge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.learnBslTrail,
          arguments: locale,
        ),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/backgrounds/yellow_ brick_path.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Stroke sits centered on the glyph outline, so a 4px
                    // stroke reads as a ~2px border once the fill text on
                    // top covers its inner half.
                    Text(
                      localizer(titleKey),
                      style: AppTheme.celebrationAt(fontSize).copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 4
                          ..color = AppColors.bslBlueOutline,
                        shadows: const [
                          Shadow(
                            color: AppColors.bslBlueOutline,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      localizer(titleKey),
                      style: AppTheme.celebrationAt(
                        fontSize,
                      ).copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: AppSizes.spacingMedium,
                bottom: AppSizes.spacingMedium,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingMedium,
                    vertical: AppSizes.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.schoolGreen,
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusLarge,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localizer('home.learn_trail_start_here'),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: AppSizes.fontSizeLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
