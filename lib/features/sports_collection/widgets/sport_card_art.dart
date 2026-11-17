import 'package:flutter/material.dart';

import '../../../shared/widgets/button.dart';
import '../models/sport_card.dart';

/// Artwork for a sports card: the image at [SportCard.imageAsset] when one
/// has been added, otherwise a felt placeholder — the sport's icon on a
/// stitched felt patch in its colour.
class SportCardArt extends StatelessWidget {
  final SportCard card;

  /// Corner radius of the placeholder's felt patch.
  final double radius;

  const SportCardArt(this.card, {super.key, this.radius = 0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      card.imageAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    final hsl = HSLColor.fromColor(card.colour);
    final dark = hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
        .toColor();
    return FeltPanel(
      radius: radius,
      stitchColour: dark,
      gradient: ButtonFill(
        Color.lerp(card.colour, Colors.white, 0.3)!,
        card.colour,
        dark,
      ).gradient,
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          card.icon,
          size: constraints.biggest.shortestSide * 0.55,
          color: Colors.white,
          shadows: [Shadow(color: dark, offset: const Offset(1, 3))],
        ),
      ),
    );
  }
}
