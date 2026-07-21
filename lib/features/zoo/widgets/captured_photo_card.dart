import 'package:flutter/material.dart';

/// Polaroid-style card shown after a correct picture in any zoo quiz
/// level: the animal's photo with its name as the caption. Until the
/// real photos land, a coloured placeholder with a paw icon stands in.
class CapturedPhotoCard extends StatelessWidget {
  static const Color _placeholderColor = Color(0xFF7FBF6A);

  final String photoAssetPath;
  final String animalName;

  const CapturedPhotoCard({
    super.key,
    required this.photoAssetPath,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 220,
                height: 165,
                child: Image.asset(
                  photoAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: _placeholderColor,
                    child: const Icon(Icons.pets, color: Colors.white70, size: 64),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              animalName,
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
