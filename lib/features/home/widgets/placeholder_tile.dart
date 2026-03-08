import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// A greyed-out placeholder tile for games coming soon.
///
/// Shows a lock icon and "Coming Soon" message.
/// Non-interactive - tapping has no effect.
///
/// Usage:
/// ```dart
/// PlaceholderTile(
///   title: 'Bubble Pop',
///   comingSoonText: 'Coming Soon',
/// )
/// ```
class PlaceholderTile extends StatelessWidget {
  /// The game title to display
  final String title;

  /// Text to show indicating the game is not yet available
  final String comingSoonText;

  /// Optional asset path for a preview image
  final String? imagePath;

  const PlaceholderTile({
    super.key,
    required this.title,
    required this.comingSoonText,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      child: Container(
        width: AppSizes.gameTileWidth,
        height: AppSizes.gameTileHeight,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image or lock icon - fixed height instead of Expanded
            SizedBox(
              height: AppSizes.iconXLarge * 2,
              child: _buildImageOrLock(),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            // Title (greyed out)
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.spacingXSmall),
            // Coming soon badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: AppSizes.spacingXSmall,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
              ),
              child: Text(
                comingSoonText,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeBody - 4,
                  color: AppColors.accentWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOrLock() {
    if (imagePath != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Greyed-out preview image
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.grey,
              BlendMode.saturation,
            ),
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                imagePath!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildLockIcon();
                },
              ),
            ),
          ),
          // Lock overlay
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: AppSizes.iconLarge,
              color: AppColors.accentWhite,
            ),
          ),
        ],
      );
    }
    return _buildLockIcon();
  }

  Widget _buildLockIcon() {
    return Icon(
      Icons.lock_outline,
      size: AppSizes.iconXLarge * 1.5,
      color: Colors.grey.shade500,
    );
  }
}
