import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Resolves BSL colour-sign videos that live in the "game-videos" Supabase
/// Storage bucket rather than the app bundle, caching each one to local
/// disk on first use so playback never has to buffer over the network
/// again.
class VideoAssetService {
  VideoAssetService._();

  static const _publicBaseUrl =
      'https://dczagvdllqhzbiqljzfi.supabase.co/storage/v1/object/public/game-videos';

  /// Legacy bundled-asset path prefixes that now live in Supabase Storage,
  /// mapped to their folder within the bucket.
  static const _remotePrefixes = {
    'assets/colours_video/': 'colours_video/',
    'assets/colours_video2/': 'colours_video2/',
  };

  static String? _remoteUrlFor(String assetPath) {
    for (final entry in _remotePrefixes.entries) {
      if (assetPath.startsWith(entry.key)) {
        return '$_publicBaseUrl/${entry.value}${assetPath.substring(entry.key.length)}';
      }
    }
    return null;
  }

  /// True if [assetPath] refers to a video now hosted in Supabase Storage
  /// rather than bundled with the app.
  static bool isRemote(String assetPath) => _remoteUrlFor(assetPath) != null;

  /// Returns the local, on-disk cached copy of [assetPath], downloading it
  /// first if this is the first time it's been requested. Only valid when
  /// [isRemote] is true for [assetPath].
  static Future<File> resolveLocalFile(String assetPath) {
    final url = _remoteUrlFor(assetPath);
    if (url == null) {
      throw ArgumentError('Not a remote video asset: $assetPath');
    }
    return DefaultCacheManager().getSingleFile(url);
  }

  /// Kicks off background downloads for [assetPaths] so they're already
  /// cached to disk by the time the player reaches them in-game. Failures
  /// (e.g. no network) are swallowed — playback simply falls back to
  /// downloading on demand.
  static void preload(Iterable<String> assetPaths) {
    for (final path in assetPaths) {
      if (!isRemote(path)) continue;
      unawaited(resolveLocalFile(path).catchError((_) => File(path)));
    }
  }
}
