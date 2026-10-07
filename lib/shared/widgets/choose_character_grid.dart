import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// A character found in `assets/images/characters/` as `<name>_thumb.png`.
class CharacterThumb {
  /// Display name: the file name up to the first underscore, capitalised
  /// (e.g. `jamjam_thumb.png` → "Jamjam").
  final String name;

  /// Full asset path to the thumbnail image.
  final String assetPath;

  /// Full-size character art (`<Name>.png` in the same folder, matched
  /// ignoring case), or null when there isn't any yet.
  final String? fullAssetPath;

  const CharacterThumb({
    required this.name,
    required this.assetPath,
    this.fullAssetPath,
  });

  /// Stable lower-case identifier (e.g. "jamjam"), used where a character
  /// is passed around or saved by id — route arguments, saved settings.
  String get id => name.toLowerCase();

  static Future<List<CharacterThumb>>? _all;

  /// The character with [id], or null if there's no such thumbnail.
  static Future<CharacterThumb?> find(String id) async {
    for (final thumb in await (_all ??= loadAll())) {
      if (thumb.id == id) return thumb;
    }
    return null;
  }

  static const _directory = 'assets/images/characters/';
  static const _suffix = '_thumb.png';

  /// Every `*_thumb.png` in the characters directory, sorted by name. Read
  /// from the asset manifest, so dropping a new thumbnail into the folder is
  /// all that's needed to add a character.
  static Future<List<CharacterThumb>> loadAll([AssetBundle? bundle]) async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );
    final characterAssets = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith(_directory) &&
              !path.substring(_directory.length).contains('/'),
        )
        .toList();
    // Lower-cased "<name>.png" → actual path, for finding full-size art.
    final fullArt = {
      for (final path in characterAssets)
        if (path.endsWith('.png') && !path.endsWith(_suffix))
          path.substring(_directory.length).toLowerCase(): path,
    };
    final thumbs =
        characterAssets.where((path) => path.endsWith(_suffix)).map((path) {
          final name = nameFromPath(path);
          return CharacterThumb(
            name: name,
            assetPath: path,
            fullAssetPath: fullArt['${name.toLowerCase()}.png'],
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return thumbs;
  }

  /// "assets/images/characters/elsie_lois_thumb.png" → "Elsie".
  static String nameFromPath(String path) {
    final fileName = path.split('/').last;
    final raw = fileName.split('_').first;
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

/// "Choose your character" grid: every `*_thumb.png` thumbnail in
/// `assets/images/characters/`, each labelled with its character name.
/// 2 columns on devices under 600px wide, 3 columns otherwise.
///
/// [disabledNames] are faded and can't be picked (e.g. a character another
/// player has already taken).
class ChooseCharacterGrid extends StatefulWidget {
  final ValueChanged<CharacterThumb> onSelected;
  final Set<String> disabledNames;
  final EdgeInsetsGeometry padding;

  /// Style for the name under each thumbnail; defaults to dark Quicksand.
  final TextStyle? labelStyle;

  const ChooseCharacterGrid({
    super.key,
    required this.onSelected,
    this.disabledNames = const {},
    this.padding = const EdgeInsets.all(AppSizes.paddingLarge),
    this.labelStyle,
  });

  @override
  State<ChooseCharacterGrid> createState() => _ChooseCharacterGridState();
}

class _ChooseCharacterGridState extends State<ChooseCharacterGrid> {
  late final Future<List<CharacterThumb>> _thumbs = CharacterThumb.loadAll();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width < 600 ? 2 : 3;

    return FutureBuilder<List<CharacterThumb>>(
      future: _thumbs,
      builder: (context, snapshot) {
        final thumbs = snapshot.data;
        if (thumbs == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return GridView.builder(
          padding: widget.padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSizes.spacingMedium,
            crossAxisSpacing: AppSizes.spacingMedium,
            // Square thumbnail plus the name label below it.
            childAspectRatio: 0.8,
          ),
          itemCount: thumbs.length,
          itemBuilder: (context, index) {
            final thumb = thumbs[index];
            return _CharacterThumbTile(
              thumb: thumb,
              isDisabled: widget.disabledNames.contains(thumb.name),
              labelStyle: widget.labelStyle,
              onTap: () => widget.onSelected(thumb),
            );
          },
        );
      },
    );
  }
}

/// One grid cell: square thumbnail with the character name below, with a
/// white circle filling the inside of the gold frame behind the character.
class _CharacterThumbTile extends StatelessWidget {
  // Every thumbnail is a 300px square with the same gold frame, centred at
  // (150, 148). Its opening has a radius of ~96–101 and its ornate outer edge
  // comes no closer than ~129.5, so a radius-127 circle fills the whole frame
  // (including gaps in the scrollwork) without showing past it.
  static const double _thumbSize = 300;
  static const double _frameCentreX = 150;
  static const double _frameCentreY = 148;
  static const double _circleRadius = 127;

  /// The circle's diameter as a fraction of the thumbnail's width.
  static const double _circleFactor = _circleRadius * 2 / _thumbSize;

  /// Places the circle so its centre lands on the frame's centre, in
  /// [Alignment] terms (-1…1 across the space left beside the circle).
  static const Alignment _circleAlignment = Alignment(
    (_frameCentreX - _circleRadius) / (_thumbSize - _circleRadius * 2) * 2 - 1,
    (_frameCentreY - _circleRadius) / (_thumbSize - _circleRadius * 2) * 2 - 1,
  );

  static const TextStyle _defaultLabelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  final CharacterThumb thumb;
  final bool isDisabled;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  const _CharacterThumbTile({
    required this.thumb,
    required this.isDisabled,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: thumb.name,
      excludeSemantics: true,
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1.0,
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  // Circle and image share one square and are both sized as
                  // fractions of it, so they scale together at any tile size.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Align(
                        alignment: _circleAlignment,
                        child: FractionallySizedBox(
                          widthFactor: _circleFactor,
                          heightFactor: _circleFactor,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Image.asset(thumb.assetPath, fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                thumb.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle ?? _defaultLabelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
