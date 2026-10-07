import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Data for a single level button in [LevelSelectScreen].
class LevelSelectItem {
  /// Level number shown as "Level N" unless [displayLabel] is provided.
  final int number;

  /// Optional level name shown below the number / display label.
  final String? name;

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
    this.name,
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
  AppColors.accentDarkGreen,
  AppColors.accentOrange,
  AppColors.accentPurple,
  AppColors.accentLimeGreen,
];

/// Returns a colour from [kLevelSelectColors] for the given 0-based index.
Color levelColor(int index) =>
    kLevelSelectColors[index % kLevelSelectColors.length];

/// Shared level-selection screen used by all games.
///
/// Renders:
/// - Optional [aboveTitle] widget (e.g. one/two-player tabs)
/// - "Choose a Level" title
/// - Optional [aboveSubtitle] widget (e.g. a mode toggle)
/// - Optional [subtitle] line
/// - 2-column grid of coloured [LevelSelectItem] buttons
///
/// Each button shows "Level N", the level name, and an optional description.
class LevelSelectScreen extends StatelessWidget {
  /// Optional subtitle shown below the title (and below [aboveSubtitle]).
  final String? subtitle;

  /// Optional widget shown below the title and above [subtitle].
  final Widget? aboveSubtitle;

  /// Optional widget shown at the very top, above the title.
  final Widget? aboveTitle;

  /// Ordered list of levels to display.
  final List<LevelSelectItem> levels;

  /// Optional headers inserted mid-grid, splitting [levels] into groups.
  ///
  /// Key is the 0-based index in [levels] the header appears immediately
  /// before, starting a new row — e.g. `{5: 'Subtraction with BSL'}` inserts
  /// a header before the 6th level (index 5). Each group before/after a
  /// break gets its own grid, so its own responsive column count and
  /// trailing logo filler.
  final Map<int, String> sectionBreaks;

  /// UI language for the title and "Level" prefix ('en' or 'cy').
  final String locale;

  const LevelSelectScreen({
    super.key,
    this.subtitle,
    this.aboveSubtitle,
    this.aboveTitle,
    required this.levels,
    this.sectionBreaks = const {},
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (aboveTitle != null) ...[
              aboveTitle!,
              const SizedBox(height: AppSizes.spacingMedium),
            ],

            // Title
            Text(
              localizer('level_select.title'),
              style: AppTheme.title.copyWith(
                fontSize: AppSizes.fontSizeTitle,
                color: AppColors.textPrimary,
              ),
            ),

            if (aboveSubtitle != null) ...[
              const SizedBox(height: AppSizes.spacingMedium),
              aboveSubtitle!,
            ],

            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.spacingSmall),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons, split into groups at each section break
            ..._buildLevelGroups(localizer),
          ],
        ),
      ),
    );
  }

  /// Splits [levels] into groups at each [sectionBreaks] index, rendering a
  /// header before each group after the first.
  List<Widget> _buildLevelGroups(AppLocalizations localizer) {
    final breakIndices =
        sectionBreaks.keys.where((i) => i > 0 && i < levels.length).toList()
          ..sort();

    final widgets = <Widget>[];
    var start = 0;
    for (final index in breakIndices) {
      widgets.add(_buildGrid(levels.sublist(start, index), localizer));
      widgets.add(const SizedBox(height: AppSizes.spacingLarge));
      widgets.add(_buildSectionHeader(sectionBreaks[index]!));
      widgets.add(const SizedBox(height: AppSizes.spacingMedium));
      start = index;
    }
    widgets.add(_buildGrid(levels.sublist(start), localizer));
    return widgets;
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Quicksand',
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds a responsive grid for one group of levels, padded with a
  /// trailing logo image if the group doesn't fill its last row.
  Widget _buildGrid(
    List<LevelSelectItem> groupLevels,
    AppLocalizations localizer,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
        final List<Widget> children = groupLevels
            .map((item) => _buildButton(item, localizer))
            .toList();
        if (children.length % crossAxisCount != 0) {
          children.add(
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              child: Image.asset(
                'assets/logos/english/Catrin_Abi_Logo_Eng_600x600.png',
                fit: BoxFit.contain,
              ),
            ),
          );
        }
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.spacingMedium,
          crossAxisSpacing: AppSizes.spacingMedium,
          childAspectRatio: 1.3,
          children: children,
        );
      },
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
              fontFamily: 'Quicksand',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.name != null) ...[
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              item.name!,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: AppSizes.fontSizeBody,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (item.description != null) ...[
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              item.description!,
              style: TextStyle(
                fontFamily: 'Quicksand',
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
