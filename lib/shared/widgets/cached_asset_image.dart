import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_asset_service.dart';

/// Displays [url], preferring an already-downloaded disk-cached copy (see
/// [ImageAssetService]) so artwork preloaded ahead of time — e.g. while a
/// player is mid-game — paints instantly instead of re-fetching over the
/// network. Falls back to [Image.network] while the disk cache is still
/// populating, and to [errorBuilder] if the fetch fails outright.
class CachedAssetImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final ImageErrorWidgetBuilder? errorBuilder;

  const CachedAssetImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.semanticLabel,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: ImageAssetService.resolveLocalFile(url),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return Image.network(
            url,
            fit: fit,
            width: width,
            height: height,
            semanticLabel: semanticLabel,
            errorBuilder: errorBuilder,
          );
        }
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          semanticLabel: semanticLabel,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
