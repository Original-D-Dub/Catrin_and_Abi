import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Downloads and disk-caches reward-collection artwork so it's already
/// available locally by the time a player opens their collection screen,
/// instead of paying a network fetch delay right when they're excited to
/// see what they've won.
///
/// Generic over plain image URLs (not tied to any one game's reward model),
/// so any collection — the Letter Bingo animal set today, and whichever
/// reward collections other games add later — can call [preload] with its
/// own image URLs.
class ImageAssetService {
  ImageAssetService._();

  /// Returns the local, on-disk cached copy of [url], downloading it first
  /// if this is the first time it's been requested.
  static Future<File> resolveLocalFile(String url) {
    return DefaultCacheManager().getSingleFile(url);
  }

  /// Kicks off background downloads for [urls] so they're already cached to
  /// disk by the time the player reaches the screen that displays them.
  /// Failures (e.g. no network) are swallowed — display simply falls back
  /// to fetching on demand.
  static void preload(Iterable<String> urls) {
    for (final url in urls) {
      unawaited(_preloadOne(url));
    }
  }

  static Future<void> _preloadOne(String url) async {
    try {
      await resolveLocalFile(url);
    } catch (_) {
      // No network / fetch failed — the widget falls back to Image.network.
    }
  }
}
