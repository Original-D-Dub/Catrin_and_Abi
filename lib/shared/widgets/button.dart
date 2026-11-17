import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Texture blended over every button's fill (below the label).
const String _fuzzTexture = 'assets/images/button fuzz.png';

/// Opacity of [_fuzzTexture] over the button fill.
const double _fuzzOpacity = 0.67;

/// Extra height every button gets on top of its content padding and the
/// shared [AppSizes.buttonHeight] minimum, split evenly above and below.
const double _extraHeight = 8.0;

/// Distance of the dashed "stitching" line inside the button's edge.
const double _stitchInset = 8.0;

/// Default label font size — [AppSizes.fontSizeLarge] plus 2px so button
/// text reads larger than other uses of that shared size token.
const double _defaultFontSize = AppSizes.fontSizeLarge + 2;

/// Solid drop shadow behind the label and icon.
const Offset _defaultTextShadowOffset = Offset(1, 3);

/// Shared base for every child-friendly button in the app: a felt patch
/// with a vertical gradient fill, fuzz texture and stitched edge, sized for
/// small fingers.
///
/// The fill runs [ButtonFill.start] at the top, [ButtonFill.middle] from
/// 10% to 90% of the height, then [ButtonFill.end] at the bottom.
/// Subclasses only supply [fill] and [textStrokeColor].
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

  /// Solid fill override, used instead of the [fill] gradient.
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

  /// Overrides the label and icon drop-shadow offset. Defaults to
  /// `Offset(1, 3)`.
  final Offset? textShadowOffset;

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
    this.textShadowOffset,
  });

  /// Gradient fill colours.
  ButtonFill get fill;

  /// Label/icon drop-shadow and stitching colour.
  Color get textStrokeColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.borderRadiusLarge);
    final textColour = foregroundColor ?? AppColors.buttonText;
    final shadows = [
      Shadow(
        color: textStrokeColor,
        offset: textShadowOffset ?? _defaultTextShadowOffset,
      ),
    ];

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // The gradient fill is painted in backgroundBuilder instead.
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: textColour,
        elevation: 0,
        minimumSize: Size(
          expanded ? double.infinity : AppSizes.minTapTarget,
          AppSizes.buttonHeight + _extraHeight,
        ),
        padding:
            (padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingMedium,
                    ))
                .add(const EdgeInsets.symmetric(vertical: _extraHeight / 2)),
        shape: RoundedRectangleBorder(borderRadius: radius),
        // Fill, fuzz texture and stitching, behind the label/icon.
        backgroundBuilder: (context, states, child) => FeltPanel(
          gradient: backgroundColor == null ? fill.gradient : null,
          stitchColour: textStrokeColor,
          radius: AppSizes.borderRadiusLarge,
          child: child,
        ),
      ),
      child: iconOnly && icon != null
          ? Icon(icon, size: AppSizes.iconMedium, shadows: shadows)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppSizes.iconMedium, shadows: shadows),
                      const SizedBox(width: AppSizes.spacingSmall),
                    ],
                    Flexible(
                      child: _strokedLabel(
                        fontSize ?? _defaultFontSize,
                        textColour,
                        shadows,
                      ),
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
                      color: textColour,
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
                      color: textColour.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
    );

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: button,
    );

    final sized = expanded
        ? SizedBox(width: double.infinity, child: shadowed)
        : shadowed;

    return iconOnly ? Semantics(label: label, child: sized) : sized;
  }

  /// Renders [label] as a solid fill over a white-stroked outline, with a
  /// solid drop shadow behind it — the same stroke-behind-fill trick used
  /// for the "Well Done!" heading in [GameSuccessOverlay].
  Widget _strokedLabel(double size, Color colour, List<Shadow> shadows) {
    final base = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: size,
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
            shadows: shadows,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: base.copyWith(color: colour),
        ),
      ],
    );
  }
}

/// A felt patch: an optional [gradient] fill, the fuzz texture (or
/// [texture], when given) and a stitched edge in [stitchColour], with
/// [child] centred on top. The
/// backdrop of every [MasterButton]; also usable for any felt-style panel
/// (e.g. collectable card art, the game header bar).
class FeltPanel extends StatelessWidget {
  final Gradient? gradient;
  final Color stitchColour;
  final double radius;
  final Widget? child;

  /// Texture blended over the fill, clipped to the panel's rounded shape.
  /// Defaults to [FuzzTexture].
  final Widget? texture;

  const FeltPanel({
    super.key,
    this.gradient,
    required this.stitchColour,
    this.radius = AppSizes.borderRadiusLarge,
    this.texture,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // Centred so the child stays in the middle when the panel is larger
    // than it (e.g. a button stretched full width) — the Stack's default
    // top-start alignment would pin it to the top-left corner.
    return Stack(
      alignment: Alignment.center,
      children: [
        if (gradient != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: gradient,
              ),
            ),
          ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: borderRadius,
            child: texture ?? const FuzzTexture(),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StitchPainter(colour: stitchColour, radius: radius),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

/// A button's vertical gradient fill: [start] at the top, [middle] from 10%
/// to 90% of the height, [end] at the bottom.
class ButtonFill {
  final Color start;
  final Color middle;
  final Color end;

  const ButtonFill(this.start, this.middle, this.end);

  /// A fill built around any [middle] colour, lightening it for [start]
  /// and darkening it for [end] by roughly the same HSL lightness steps
  /// the named button fills use (about +15% and −11%).
  factory ButtonFill.fromColour(Color middle) => ButtonFill(
    _shiftLightness(middle, 0.15),
    middle,
    _shiftLightness(middle, -0.11),
  );

  /// A dark shade of [colour] for stitching and text shadows, about as far
  /// below it (−21% lightness) as the named buttons' text stroke colours.
  static Color strokeFor(Color colour) => _shiftLightness(colour, -0.21);

  static Color _shiftLightness(Color colour, double delta) {
    final hsl = HSLColor.fromColor(colour);
    return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
  }

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [start, middle, middle, end],
    stops: const [0.0, 0.1, 0.9, 1.0],
  );
}

/// A child-friendly primary button with a green felt fill.
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
    super.textShadowOffset,
  });

  @override
  ButtonFill get fill => const ButtonFill(
    AppColors.buttonPrimaryGradStart,
    AppColors.buttonPrimaryGrad1,
    AppColors.buttonPrimaryGradEnd,
  );

  @override
  Color get textStrokeColor => AppColors.buttonPrimaryTextStroke;
}

/// Formerly a borderless variant of [PrimaryButton]; now that no button has
/// a border the two are identical.
typedef Primary2Button = PrimaryButton;

/// A child-friendly secondary button with an Abi pink felt fill.
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
    super.textShadowOffset,
  });

  @override
  ButtonFill get fill => const ButtonFill(
    AppColors.buttonSecondaryGradStart,
    AppColors.abiPink,
    AppColors.buttonSecondaryGradEnd,
  );

  @override
  Color get textStrokeColor => AppColors.buttonSecondaryTextStroke;
}

/// A child-friendly tertiary button with a blue felt fill.
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
    super.textShadowOffset,
  });

  @override
  ButtonFill get fill => const ButtonFill(
    AppColors.buttonTertiaryGradStart,
    AppColors.buttonTertiaryGrad1,
    AppColors.buttonTertiaryGradEnd,
  );

  @override
  Color get textStrokeColor => AppColors.buttonTertiaryTextStroke;
}

/// A child-friendly warning button with a red felt fill — for destructive
/// actions like deleting an account.
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
    super.textShadowOffset,
  });

  @override
  ButtonFill get fill => const ButtonFill(
    AppColors.buttonWarningGradStart,
    AppColors.accentRed,
    AppColors.buttonWarningGradEnd,
  );

  @override
  Color get textStrokeColor => AppColors.buttonWarningTextStroke;
}

/// Dashed rounded-rectangle line [_stitchInset] inside the edges of the
/// area it paints, following the fill's corner radius ([radius]), so the
/// button reads as a stitched felt patch.
class _StitchPainter extends CustomPainter {
  _StitchPainter({required this.colour, required this.radius});

  final Color colour;
  final double radius;

  static const double _dash = 4.0;
  static const double _gap = 6.0;
  static const double _width = 1.5;
  static const double _opacity = 0.7;

  /// Offset and colour of the stitches' drop shadow (drawn above them).
  static const Offset _shadowOffset = Offset(0, -1);
  static const Color _shadowColour = Color(0x4D000000); // black, 30%

  /// Blur radius of the stitches' drop shadow, as for a [BoxShadow].
  static const double _shadowBlur = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stitchInset);
    if (rect.width <= 0 || rect.height <= 0) return;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular((radius - _stitchInset).clamp(0.0, radius)),
        ),
      );
    final dashes = Path();
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        dashes.addPath(metric.extractPath(d, d + _dash), Offset.zero);
      }
    }
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      dashes.shift(_shadowOffset),
      stroke(_shadowColour)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(_shadowBlur),
        ),
    );
    canvas.drawPath(
      dashes,
      stroke(colour.withValues(alpha: colour.a * _opacity)),
    );
  }

  @override
  bool shouldRepaint(_StitchPainter old) =>
      old.colour != colour || old.radius != radius;
}

/// Paints [_fuzzTexture] over whatever is beneath it (the button's fill)
/// with [BlendMode.overlay] at [_fuzzOpacity], scaled to cover the button.
/// Also usable outside buttons to give any fill the same felt look.
class FuzzTexture extends StatelessWidget {
  const FuzzTexture({super.key});

  @override
  Widget build(BuildContext context) {
    return FuzzTextureBuilder(
      builder: (context, image) {
        if (image == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(painter: _FuzzTexturePainter(image)),
        );
      },
    );
  }
}

/// Loads [_fuzzTexture] and hands it to [builder] once decoded (null until
/// then), for callers that paint the felt texture themselves — e.g. via
/// [fuzzTextPaint].
class FuzzTextureBuilder extends StatefulWidget {
  const FuzzTextureBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ui.Image? image) builder;

  @override
  State<FuzzTextureBuilder> createState() => _FuzzTextureBuilderState();
}

/// A text foreground paint that blends [image] (from [FuzzTextureBuilder])
/// over glyphs drawn beneath it with the same blend and opacity as
/// [FuzzTexture], so stacking a text run in this paint over the same run in
/// a solid colour gives it the felt look, clipped exactly to the glyphs.
///
/// The texture is tiled in the canvas's local space at [scale] (1 = native
/// pixel size).
Paint fuzzTextPaint(ui.Image image, {double scale = 1}) {
  return Paint()
    ..blendMode = BlendMode.overlay
    ..color = Color.fromRGBO(0, 0, 0, _fuzzOpacity)
    ..filterQuality = FilterQuality.medium
    ..shader = ImageShader(
      image,
      TileMode.mirror,
      TileMode.mirror,
      Matrix4.diagonal3Values(scale, scale, 1).storage,
    );
}

class _FuzzTextureBuilderState extends State<FuzzTextureBuilder> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) {
      if (!mounted) return;
      setState(() {
        _image?.dispose();
        _image = info;
      });
    },
    onError: (error, _) => debugPrint('Button texture failed to load: $error'),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      _fuzzTexture,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _image?.image);
}

class _FuzzTexturePainter extends CustomPainter {
  _FuzzTexturePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.cover,
      blendMode: BlendMode.overlay,
      opacity: _fuzzOpacity,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_FuzzTexturePainter oldDelegate) =>
      oldDelegate.image != image;
}
