import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Width of the gradient stroke drawn around all button variants.
const double _strokeWidth = 4.0;

/// Default label font size — [AppSizes.fontSizeLarge] plus 2px so button
/// text reads larger than other uses of that shared size token.
const double _defaultFontSize = AppSizes.fontSizeLarge + 2;

/// Shared base for every child-friendly button in the app: a solid fill
/// wrapped in a gradient stroke, sized for small fingers.
///
/// Subclasses only supply their default fill colour and gradient/text-stroke
/// colours via [defaultBackgroundColor], [gradientColors], and
/// [textStrokeColor] — [build] and the rest of the button chrome are shared.
abstract class MasterButton extends StatelessWidget {
  /// The button label text.
  final String label;

  /// Optional secondary line shown beneath [label].
  final String? sublabel;

  /// Optional small description line shown beneath [sublabel].
  final String? description;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Background color override. Defaults to [defaultBackgroundColor].
  final Color? backgroundColor;

  /// Text/icon color override.
  /// Defaults to [AppColors.buttonText].
  final Color? foregroundColor;

  /// Whether to expand to fill available width.
  final bool expanded;

  /// Overrides the label's font size. Defaults to [AppSizes.fontSizeLarge] + 2.
  final double? fontSize;

  /// When true, renders just [icon] (no label text) — [label] is still used
  /// as the button's accessibility label.
  final bool iconOnly;

  /// Overrides the button's internal content padding. Defaults to
  /// [AppSizes.paddingLarge] horizontal, [AppSizes.paddingMedium] vertical.
  final EdgeInsetsGeometry? padding;

  const MasterButton({
    super.key,
    required this.label,
    this.sublabel,
    this.description,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.expanded = false,
    this.fontSize,
    this.iconOnly = false,
    this.padding,
  });

  /// Fill colour used when [backgroundColor] isn't supplied.
  Color get defaultBackgroundColor;

  /// Gradient stroke colours, top to bottom.
  List<Color> get gradientColors;

  /// Label stroke/drop-shadow colour.
  Color get textStrokeColor;

  @override
  Widget build(BuildContext context) {
    return _GradientStrokeButton(
      label: label,
      sublabel: sublabel,
      description: description,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor ?? defaultBackgroundColor,
      gradientColors: gradientColors,
      textStrokeColor: textStrokeColor,
      foregroundColor: foregroundColor,
      expanded: expanded,
      fontSize: fontSize,
      iconOnly: iconOnly,
      padding: padding,
    );
  }
}

/// A child-friendly primary button with a green fill and a gradient stroke.
///
/// Features:
/// - Large tap target for small fingers
/// - Rounded corners
/// - 8px gradient stroke (#12E557 → #0A7F30)
/// - Optional icon
/// - Customizable colors
///
/// Usage:
/// ```dart
/// PrimaryButton(
///   label: 'Play Again',
///   onPressed: () => resetGame(),
///   icon: Icons.replay,
/// )
/// ```
class PrimaryButton extends MasterButton {
  const PrimaryButton({
    super.key,
    required super.label,
    super.sublabel,
    super.description,
    required super.onPressed,
    super.icon,
    super.backgroundColor,
    super.foregroundColor,
    super.expanded,
    super.fontSize,
    super.iconOnly,
    super.padding,
  });

  @override
  Color get defaultBackgroundColor => AppColors.buttonPrimaryGreen;

  @override
  List<Color> get gradientColors => const [
        AppColors.buttonPrimaryStrokeStart,
        AppColors.buttonPrimaryStrokeEnd,
      ];

  @override
  Color get textStrokeColor => AppColors.buttonPrimaryTextStroke;
}

/// A child-friendly secondary button with an Abi pink fill and a gradient
/// stroke.
///
/// Features:
/// - Large tap target for small fingers
/// - Rounded corners
/// - 8px gradient stroke (#C6004F → #FF297E)
/// - Optional icon
/// - Customizable colors
///
/// Usage:
/// ```dart
/// SecondaryButton(
///   label: 'Back',
///   onPressed: () => Navigator.pop(context),
///   icon: Icons.arrow_back,
/// )
/// ```
class SecondaryButton extends MasterButton {
  const SecondaryButton({
    super.key,
    required super.label,
    super.sublabel,
    super.description,
    required super.onPressed,
    super.icon,
    super.backgroundColor,
    super.foregroundColor,
    super.expanded,
    super.fontSize,
    super.iconOnly,
    super.padding,
  });

  @override
  Color get defaultBackgroundColor => AppColors.abiPink;

  @override
  List<Color> get gradientColors => const [
        AppColors.buttonSecondaryStrokeStart,
        AppColors.buttonSecondaryStrokeEnd,
      ];

  @override
  Color get textStrokeColor => AppColors.buttonSecondaryTextStroke;
}

/// A child-friendly tertiary button with a Catrin blue fill and a gradient
/// stroke.
///
/// Features:
/// - Large tap target for small fingers
/// - Rounded corners
/// - 8px gradient stroke (#DAF4FF → #87CEEB)
/// - Optional icon
/// - Customizable colors
///
/// Usage:
/// ```dart
/// TertiaryButton(
///   label: 'Change Level',
///   onPressed: () => Navigator.pop(context),
///   icon: Icons.grid_view,
/// )
/// ```
class TertiaryButton extends MasterButton {
  const TertiaryButton({
    super.key,
    required super.label,
    super.sublabel,
    super.description,
    required super.onPressed,
    super.icon,
    super.backgroundColor,
    super.foregroundColor,
    super.expanded,
    super.fontSize,
    super.iconOnly,
    super.padding,
  });

  @override
  Color get defaultBackgroundColor => AppColors.bslBlue;

  @override
  List<Color> get gradientColors => const [
        AppColors.buttonTertiaryStrokeStart,
        AppColors.buttonTertiaryStrokeEnd,
      ];

  @override
  Color get textStrokeColor => AppColors.buttonTertiaryTextStroke;
}

/// A child-friendly warning button with a red fill and a gradient stroke —
/// for destructive actions like deleting an account.
///
/// Features:
/// - Large tap target for small fingers
/// - Rounded corners
/// - 8px gradient stroke (#FF6B6B → #B71C1C)
/// - Optional icon
/// - Customizable colors
///
/// Usage:
/// ```dart
/// WarningButton(
///   label: 'Delete Account',
///   onPressed: () => confirmDelete(),
///   icon: Icons.delete_forever,
/// )
/// ```
class WarningButton extends MasterButton {
  const WarningButton({
    super.key,
    required super.label,
    super.sublabel,
    super.description,
    required super.onPressed,
    super.icon,
    super.backgroundColor,
    super.foregroundColor,
    super.expanded,
    super.fontSize,
    super.iconOnly,
    super.padding,
  });

  @override
  Color get defaultBackgroundColor => AppColors.accentRed;

  @override
  List<Color> get gradientColors => const [
        AppColors.buttonWarningStrokeStart,
        AppColors.buttonWarningStrokeEnd,
      ];

  @override
  Color get textStrokeColor => AppColors.buttonWarningTextStroke;
}

/// Shared implementation behind every [MasterButton] subclass.
///
/// Draws the button inside a container filled with a horizontal
/// [LinearGradient] and padded by [_strokeWidth], producing a gradient
/// stroke around the solid button fill.
class _GradientStrokeButton extends StatelessWidget {
  /// Width of the solid drop shadow drawn behind the label text.
  static const Offset _textShadowOffset = Offset(1, 3);

  final String label;
  final String? sublabel;
  final String? description;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final Color textStrokeColor;
  final Color? foregroundColor;
  final bool expanded;
  final double? fontSize;
  final bool iconOnly;
  final EdgeInsetsGeometry? padding;

  const _GradientStrokeButton({
    required this.label,
    this.sublabel,
    this.description,
    required this.onPressed,
    required this.backgroundColor,
    required this.gradientColors,
    required this.textStrokeColor,
    this.icon,
    this.foregroundColor,
    this.expanded = false,
    this.fontSize,
    this.iconOnly = false,
    this.padding,
  });

  /// Renders [label] as a solid fill over a white-stroked outline, with a
  /// [textStrokeColor] solid drop shadow behind it — the same stroke-behind-
  /// fill trick used for the "Well Done!" heading in [GameSuccessOverlay].
  Widget _strokedLabel(double fontSize) {
    final base = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.white,
            shadows: [
              Shadow(color: textStrokeColor, offset: _textShadowOffset),
            ],
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: base.copyWith(color: foregroundColor ?? AppColors.buttonText),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? AppColors.buttonText,
        elevation: 0,
        minimumSize: Size(
          expanded ? double.infinity : AppSizes.minTapTarget,
          AppSizes.buttonHeight,
        ),
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: AppSizes.paddingMedium,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
        child: iconOnly && icon != null
            ? Icon(
                icon,
                size: AppSizes.iconMedium,
                shadows: [Shadow(color: textStrokeColor, offset: _textShadowOffset)],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: AppSizes.iconMedium,
                          shadows: [
                            Shadow(color: textStrokeColor, offset: _textShadowOffset),
                          ],
                        ),
                        const SizedBox(width: AppSizes.spacingSmall),
                      ],
                      Flexible(
                        child: _strokedLabel(fontSize ?? _defaultFontSize),
                      ),
                    ],
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: AppSizes.spacingXSmall),
                    Text(
                      sublabel!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: AppSizes.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor ?? AppColors.buttonText,
                      ),
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: AppSizes.spacingXSmall),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: AppSizes.fontSizeSmall,
                        color: (foregroundColor ?? AppColors.buttonText)
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
    );

    final stroked = Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppSizes.borderRadiusLarge + _strokeWidth),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_strokeWidth),
      child: button,
    );

    final sized = expanded ? SizedBox(width: double.infinity, child: stroked) : stroked;

    return iconOnly ? Semantics(label: label, child: sized) : sized;
  }
}
