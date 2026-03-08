import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// A clickable tile for an active game on the home screen.
///
/// Displays the game title and an optional image or icon.
/// Expands to fill its parent (designed to be used inside a GridView).
/// Tapping navigates to the game.
///
/// Usage:
/// ```dart
/// GameTile(
///   title: 'Card Matching',
///   imagePath: AssetPaths.someImage,
///   onTap: () => Navigator.pushNamed(context, AppRoutes.cardMatching),
/// )
/// ```
class GameTile extends StatelessWidget {
  /// The game title to display
  final String title;

  /// Optional asset path for the tile image
  final String? imagePath;

  /// Callback when tile is tapped
  final VoidCallback onTap;

  /// Optional icon to show if no image is provided
  final IconData? icon;

  const GameTile({
    super.key,
    required this.title,
    required this.onTap,
    this.imagePath,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        child: _buildImageOrIcon(),
      ),
    );
  }

  Widget _buildImageOrIcon() {
    if (imagePath != null) {
      return SizedBox.expand(
        child: Image.asset(
          imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultIcon();
          },
        ),
      );
    }
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Icon(
      icon ?? Icons.games,
      size: AppSizes.iconXLarge * 1.5,
      color: AppColors.abiPink,
    );
  }
}
