import 'package:flutter/material.dart';

/// Scatters [photos] (small polaroid cards, e.g. [MiniPhotoCard]) around
/// the centre of its bounds with fixed, hand-tuned offsets and rotations —
/// used on the zoo quiz's success screen to show off everything the
/// player photographed that playthrough, like a tossed pile of snapshots.
class ScatteredPhotoGallery extends StatelessWidget {
  final List<Widget> photos;

  const ScatteredPhotoGallery({super.key, required this.photos});

  /// Scatter offsets from centre, and matching tilt angles (radians) —
  /// cycled through if there are more photos than entries.
  static const List<Offset> _offsets = [
    Offset(-110, -50),
    Offset(100, -76),
    Offset(-30, 84),
    Offset(140, 40),
    Offset(-140, 40),
    Offset(20, -110),
  ];
  static const List<double> _rotations = [-0.15, 0.18, -0.09, 0.20, -0.20, 0.12];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: 520,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < photos.length; i++)
            Transform.translate(
              offset: _offsets[i % _offsets.length],
              child: Transform.rotate(
                angle: _rotations[i % _rotations.length],
                child: photos[i],
              ),
            ),
        ],
      ),
    );
  }
}

/// A small polaroid-style photo card for [ScatteredPhotoGallery] — the
/// same visual language as [CapturedPhotoCard]'s in-game reveal, shrunk
/// down so several fit scattered on the success screen at once.
class MiniPhotoCard extends StatelessWidget {
  static const Color _placeholderColor = Color(0xFF7FBF6A);

  final String photoAssetPath;
  final String animalName;

  const MiniPhotoCard({
    super.key,
    required this.photoAssetPath,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 180,
              height: 136,
              child: Image.asset(
                photoAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: _placeholderColor,
                  child: const Icon(Icons.pets, color: Colors.white70, size: 56),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            animalName,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
