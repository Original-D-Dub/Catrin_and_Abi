import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// A child-friendly primary button with consistent styling.
///
/// Features:
/// - Large tap target for small fingers
/// - Rounded corners
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
class PrimaryButton extends StatelessWidget {
  /// The button label text.
  final String label;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Background color override.
  /// Defaults to [AppColors.buttonPrimary].
  final Color? backgroundColor;

  /// Text/icon color override.
  /// Defaults to [AppColors.buttonText].
  final Color? foregroundColor;

  /// Whether to expand to fill available width.
  final bool expanded;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
        foregroundColor: foregroundColor ?? AppColors.buttonText,
        minimumSize: Size(
          expanded ? double.infinity : AppSizes.minTapTarget,
          AppSizes.buttonHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMedium),
            const SizedBox(width: AppSizes.spacingSmall),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
