import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/dressed_character.dart';
import 'recoloured_clothing_svg.dart';

/// Displays a [DressedCharacter]: the body image with clothing layered on
/// top at template positions, scaled to fit the available space. SVG
/// clothing is recoloured to the colour it's being worn in.
class DressedCharacterDisplay extends StatelessWidget {
  final DressedCharacter character;

  const DressedCharacterDisplay({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final body = character.body;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(
          color: AppColors.catrinBlue.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.paddingSmall),
      child: Center(
        child: AspectRatio(
          aspectRatio: body.canvasSize.width / body.canvasSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / body.canvasSize.width;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      body.assetPath,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                  for (final worn in character.layers)
                    Positioned.fromRect(
                      rect: _scaleRect(
                        worn.item.bounds.shift(body.templateOffset),
                        scale,
                      ),
                      child: worn.item.isSvg
                          ? RecolouredClothingSvg(
                              assetPath: worn.item.assetPath,
                              colourName: worn.colour,
                            )
                          : Image.asset(
                              worn.item.assetPath,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Rect _scaleRect(Rect r, double scale) => Rect.fromLTWH(
        r.left * scale,
        r.top * scale,
        r.width * scale,
        r.height * scale,
      );
}
