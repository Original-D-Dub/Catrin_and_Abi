import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';

/// Data for a single level button in [LevelSelectScreen].
class LevelSelectItem {
  /// Level number shown as "Level N" unless [displayLabel] is provided.
  final int number;

  /// Level name shown below the number / display label.
  final String name;

  /// Optional smaller description shown below the name.
  final String? description;

  /// When set, replaces the default "Level N" heading on the button.
  final String? displayLabel;

  /// Button background colour. Ignored when [isLocked] is true.
  final Color color;

  /// Called when the button is tapped. Null disables the button.
  final VoidCallback? onTap;

  /// When true the button is greyed out and shows a lock icon.
  final bool isLocked;

  const LevelSelectItem({
    required this.number,
    required this.name,
    this.description,
    this.displayLabel,
    required this.color,
    this.onTap,
    this.isLocked = false,
  });
}

/// Standard colour palette that cycles across level buttons.
///
/// Use [levelColor] to pick a colour by level index (0-based).
const List<Color> kLevelSelectColors = [
  AppColors.abiPink,
  AppColors.accentNavyBlue,
  AppColors.accentLimeGreen,
  AppColors.accentOrange,
  AppColors.accentPurple,
  AppColors.catrinBlue,
];

/// Returns a colour from [kLevelSelectColors] for the given 0-based index.
Color levelColor(int index) => kLevelSelectColors[index % kLevelSelectColors.length];

/// Shared level-selection screen used by all games.
///
/// Renders:
/// - "Choose a Level" title
/// - Optional [subtitle] line
/// - 2-column grid of coloured [LevelSelectItem] buttons
///
/// Each button shows "Level N", the level name, and an optional description.
class LevelSelectScreen extends StatelessWidget {
  /// Optional subtitle shown below the title.
  final String? subtitle;

  /// Ordered list of levels to display.
  final List<LevelSelectItem> levels;

  const LevelSelectScreen({
    super.key,
    this.subtitle,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              localizer('level_select.title'),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.spacingSmall),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeBody,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons in responsive grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSizes.spacingMedium,
                  crossAxisSpacing: AppSizes.spacingMedium,
                  childAspectRatio: 1.3,
                  children: levels.map((item) => _buildButton(item, localizer)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(LevelSelectItem item, AppLocalizations localizer) {
    final color = item.isLocked ? AppColors.textSecondary : item.color;
    return ElevatedButton(
      onPressed: item.isLocked ? null : item.onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        elevation: item.isLocked ? 0 : 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.isLocked) ...[
            const Icon(Icons.lock, size: AppSizes.iconSmall),
            const SizedBox(height: AppSizes.spacingXSmall),
          ],
          Text(
            item.displayLabel ??
                '${localizer('level_select.level_prefix')} ${item.number}',
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            item.name,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeBody,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.description != null) ...[
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              item.description!,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeSmall,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
