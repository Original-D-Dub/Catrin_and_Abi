import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/game.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/game_filters.dart';
import '../providers/letter_quest_provider.dart';

/// Abstract base class shared by all Letter Quest levels.
///
/// Provides the [provider] getter that [PlayerComponent] and
/// [LetterCollectible] access via `HasGameReference<BaseLetterQuestGame>`.
abstract class BaseLetterQuestGame extends FlameGame
    with HasCollisionDetection {
  /// The game state provider (words, collection tracking, phases).
  LetterQuestProvider get provider;

  static const double _breakpoint = 600.0;

  bool get isLargeScreen => size.x > _breakpoint;

  /// Camera zoom — zoomed out 20% on phones, full on tablets.
  double get mapZoom => isLargeScreen ? 1.0 : 0.8;

  /// Character scale — independent of map zoom.
  double get characterScale => isLargeScreen ? 1.0 : 1.0;

  /// Pre-loaded sign-language alphabet images keyed by lowercase letter
  /// (or digraph for IAC, e.g. 'ch', 'dd').
  final Map<String, ui.Image> signImages = {};

  /// BSL single-letter keys (a–z).
  static const _bslKeys = [
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
  ];

  /// IAC keys — Welsh alphabet including digraphs.
  static const _iacKeys = [
    'a','b','c','ch','d','dd','e','f','ff','g','h','i','j',
    'l','ll','m','n','ng','o','p','ph','r','rh','s','t','th',
    'u','w','y',
  ];

  /// Loads sign-language alphabet PNGs into [signImages].
  ///
  /// BSL and IAC share one image folder (`bsl_alphabet_png/`); the sign
  /// system only decides which letters are needed. A missing image is
  /// skipped so one absent letter doesn't stop the level loading.
  Future<void> loadSignImages() async {
    final keys =
        provider.signSystem == SignSystem.iac ? _iacKeys : _bslKeys;
    final loader = Images(prefix: '');
    final entries = await Future.wait(keys.map((key) async {
      try {
        return MapEntry(key, await loader.load(AssetPaths.signLetterPng(key)));
      } catch (_) {
        return null;
      }
    }));
    for (final entry in entries) {
      if (entry != null) signImages[entry.key] = entry.value;
    }
  }
}
