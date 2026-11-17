import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/cached_asset_image.dart';
import '../models/animal_model.dart';

/// Shared reward card showing a collected animal's picture and name.
///
/// Used by both the BINGO celebration and the standalone reward overlay so
/// the "collector card" styling lives in one place. Pass [onTap] to make it
/// interactive (the celebration uses it to replay the animal's recorded
/// name); the card is then exposed to screen readers as a button labelled
/// with the animal's name.
class AnimalCard extends StatelessWidget {
  final Animal animal;

  /// When non-null the card is tappable and announced as a button.
  final VoidCallback? onTap;

  static const double cardWidth = 220;
  static const double imageHeight = 200;

  static const Color _background = AppColors.accentYellow;
  static const Color _border = AppColors.accentOrange;

  /// When true the name strip gets the primary buttons' felt texture.
  final bool feltName;

  const AnimalCard({
    super.key,
    required this.animal,
    this.onTap,
    this.feltName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: animal.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
            border: Border.all(color: _border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: ColoredBox(
                    color: Colors.white,
                    child: CachedAssetImage(
                      url: animal.imageUrl,
                      width: cardWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      semanticLabel: animal.name,
                      errorBuilder: (_, _, _) => CachedAssetImage(
                        url: animal.placeholderUrl,
                        width: cardWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        semanticLabel: animal.name,
                        errorBuilder: (_, _, _) => Container(
                          width: cardWidth,
                          height: imageHeight,
                          color: AppColors.background,
                          child: const Icon(
                            Icons.pets,
                            size: 80,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(19),
                  ),
                  child: ColoredBox(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        if (feltName)
                          const Positioned.fill(child: FuzzTexture()),
                        _name(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _name() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingMedium),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              animal.name,
              style: AppTheme.heading.copyWith(
                fontSize: AppSizes.fontSizeHeading,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = AppColors.celebrationNavy,
              ),
            ),
            Text(
              animal.name,
              style: AppTheme.heading.copyWith(
                fontSize: AppSizes.fontSizeHeading,
                color: AppColors.celebrationNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
