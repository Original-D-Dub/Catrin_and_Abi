import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'button.dart';
import 'champion_rosette.dart';
import 'paper_texture_overlay.dart';

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

/// Shows [text] centred on a single line (shrunk to fit if it's too wide),
/// with a game's [ChampionRosette] as [badge] perched on its last letter:
/// the top of that letter (e.g. the "l" of "Choose a Level") touches the
/// rosette's main circle at [kChampionRosetteTouchPoint], and the ribbon
/// hangs down to the right of it.
///
/// The badge is absolutely positioned and never moves the text: it's drawn
/// in the nearest [Overlay] (see [OverlayPortal]), pinned to the text with
/// a [CompositedTransformFollower], so it takes up no layout space yet
/// still receives taps and long presses wherever it's drawn. Wrap the
/// screen in [Overlay.wrap] (with [Clip.none], so the badge is never cut
/// off) so the badge stays under anything stacked above that screen, like
/// a level transition fade.
///
/// Shows [text] alone when [badge] is null.
class TitleWithBadge extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Widget? badge;

  const TitleWithBadge({
    super.key,
    required this.text,
    required this.style,
    required this.badge,
  });

  @override
  State<TitleWithBadge> createState() => _TitleWithBadgeState();
}

class _TitleWithBadgeState extends State<TitleWithBadge> {
  /// Height of a lowercase ascender (the top of an "l") as a fraction of
  /// the font size — approximate for Quicksand, the title font.
  static const double _ascenderHeight = 0.72;

  final _link = LayerLink();
  final _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final style = widget.style;
    final textWidget = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
      ),
    );
    final badge = widget.badge;
    if (badge == null || text.isEmpty) return textWidget;

    // Bounding box of the badge once tilted.
    const rotation = kChampionRosetteRotation;
    final w = kChampionRosetteSize.width;
    final h = kChampionRosetteSize.height;
    final sinA = math.sin(rotation.abs());
    final cosA = math.cos(rotation.abs());
    final boxW = w * cosA + h * sinA;
    final boxH = w * sinA + h * cosA;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final lastBox = painter
            .getBoxesForSelection(
              TextSelection(
                baseOffset: text.length - 1,
                extentOffset: text.length,
              ),
            )
            .last;
        final baseline = painter.computeLineMetrics().last.baseline;
        final fontSize = scaler.scale(style.fontSize ?? 14);
        final textWidth = painter.width;
        painter.dispose();

        // Matches the FittedBox's shrink when the text is too wide.
        final scale = math.min(1.0, constraints.maxWidth / textWidth);
        final letterTop = (baseline - fontSize * _ascenderHeight) * scale;
        final letterCentre = (lastBox.left + lastBox.right) / 2 * scale;

        return OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(
                letterCentre - boxW / 2 - kChampionRosetteTouchPoint.dx,
                letterTop - boxH / 2 - kChampionRosetteTouchPoint.dy,
              ),
              child: SizedBox(
                width: boxW,
                height: boxH,
                child: Center(
                  child: Transform.rotate(
                    angle: rotation,
                    child: SizedBox(width: w, height: h, child: badge),
                  ),
                ),
              ),
            ),
          ),
          child: CompositedTransformTarget(link: _link, child: textWidget),
        );
      },
    );
  }
}

/// Shared level-selection screen used by all games.
///
/// Renders:
/// - Optional [aboveTitle] widget (e.g. one/two-player tabs)
/// - "Choose a Level" title on one line, with an optional [titleBadge] on
///   its last letter
/// - Optional [aboveSubtitle] widget (e.g. a mode toggle)
/// - Optional [subtitle] line
/// - Responsive grid (2–3 columns, or [tabletLandscapeColumns] on a
///   landscape tablet) of coloured [LevelSelectItem] buttons
///
/// Each button shows "Level N", the level name, and an optional description.
class LevelSelectScreen extends StatelessWidget {
  /// Optional subtitle shown below the title (and below [aboveSubtitle]).
  final String? subtitle;

  /// Optional widget shown below the title and above [subtitle].
  final Widget? aboveSubtitle;

  /// Optional widget shown at the very top, above the title.
  final Widget? aboveTitle;

  /// Optional badge perched on the title's last letter (e.g. the game's
  /// [ChampionRosette] once Champion Mode is unlocked) — see
  /// [TitleWithBadge].
  final Widget? titleBadge;

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

  /// When set, overrides the grid's column count on tablets (shortest side
  /// ≥ 600) held in landscape. Null keeps the default 2/3-column layout.
  final int? tabletLandscapeColumns;

  /// When set, always uses this many columns (on every device), with each
  /// column capped at [kFixedColumnMaxWidth] so a short row — e.g. two
  /// tiles side by side — doesn't stretch across a wide tablet. Takes
  /// priority over [tabletLandscapeColumns].
  final int? fixedColumns;

  static const double kFixedColumnMaxWidth = 300;

  const LevelSelectScreen({
    super.key,
    this.subtitle,
    this.aboveSubtitle,
    this.aboveTitle,
    this.titleBadge,
    required this.levels,
    this.sectionBreaks = const {},
    this.locale = 'en',
    this.tabletLandscapeColumns,
    this.fixedColumns,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    // Overlay.wrap gives [titleBadge] an overlay of this screen's own to
    // draw in — see [TitleWithBadge].
    return Overlay.wrap(
      clipBehavior: Clip.none,
      child: _buildContent(localizer),
    );
  }

  Widget _buildContent(AppLocalizations localizer) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (aboveTitle != null) ...[
              aboveTitle!,
              // The badge rises about 58px above the title text without
              // taking layout space, so leave room for it to clear the
              // widget above.
              SizedBox(
                height: titleBadge != null
                    ? kChampionRosetteWidth - AppSizes.spacingSmall
                    : AppSizes.spacingMedium,
              ),
            ],

            // Title
            TitleWithBadge(
              badge: titleBadge,
              text: localizer('level_select.title'),
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
        final mq = MediaQuery.of(context);
        final isTabletLandscape = mq.size.shortestSide >= 600 &&
            mq.orientation == Orientation.landscape;
        final crossAxisCount = fixedColumns ??
            (isTabletLandscape && tabletLandscapeColumns != null
                ? tabletLandscapeColumns!
                : constraints.maxWidth < 400
                    ? 2
                    : 3);
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
        final grid = GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.spacingMedium,
          crossAxisSpacing: AppSizes.spacingMedium,
          childAspectRatio: 1.3,
          children: children,
        );
        if (fixedColumns == null) return grid;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: fixedColumns! * kFixedColumnMaxWidth +
                  (fixedColumns! - 1) * AppSizes.spacingMedium,
            ),
            child: grid,
          ),
        );
      },
    );
  }

  /// Spreads tiles' texture windows across the paper image: golden-ratio
  /// steps give each index a distinct, well-separated (x, y) fraction.
  static Offset _textureOffsetFor(int index) {
    const phi = 0.6180339887;
    const phi2 = 0.7548776662;
    return Offset((0.31 + index * phi) % 1.0, (0.57 + index * phi2) % 1.0);
  }

  Widget _buildButton(LevelSelectItem item, AppLocalizations localizer) {
    final color = item.isLocked ? AppColors.textSecondary : item.color;
    final radius = BorderRadius.circular(AppSizes.borderRadiusMedium);
    final textureOffset = _textureOffsetFor(levels.indexOf(item));
    return ElevatedButton(
      onPressed: item.isLocked ? null : item.onTap,
      style: ElevatedButton.styleFrom(
        // The gradient fill is painted in backgroundBuilder instead.
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(borderRadius: radius),
        elevation: item.isLocked ? 0 : 2,
        // Felt-button look: gradient fill from the tile colour, paper
        // texture (native size, a different patch per tile) and stitched
        // edge, all beneath the label.
        backgroundBuilder: (context, states, child) => FeltPanel(
          gradient: ButtonFill.fromColour(color).gradient,
          stitchColour: ButtonFill.strokeFor(color),
          radius: AppSizes.borderRadiusMedium,
          texture: PaperTextureOverlay(textureOffset: textureOffset),
          child: child,
        ),
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
