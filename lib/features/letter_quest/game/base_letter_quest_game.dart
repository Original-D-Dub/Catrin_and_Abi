import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_svg/flame_svg.dart';

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

  /// Pre-loaded sign-language alphabet SVGs keyed by lowercase letter
  /// (or digraph for IAC, e.g. 'ch', 'dd').
  final Map<String, Svg> signSvgs = {};

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

  /// Loads sign-language alphabet SVGs into [signSvgs].
  ///
  /// Reads each SVG as a raw string, replaces CSS class selectors with
  /// inline fill/stroke attributes (flutter_svg doesn't reliably resolve
  /// CSS class rules), then creates the flame Svg from the modified string.
  ///
  /// Uses BSL (`bsl_alphabet_svg/`) or IAC (`wyddor_iac_svg/`) directory
  /// based on [provider.signSystem].
  Future<void> loadSignSvgs() async {
    final isIac = provider.signSystem == SignSystem.iac;
    final dir = isIac ? 'wyddor_iac_svg' : 'bsl_alphabet_svg';
    final keys = isIac ? _iacKeys : _bslKeys;

    // Read all SVG strings first (fast I/O), then compile in parallel
    // to avoid blocking the UI thread with 26 sequential compilations.
    final strings = <String, String>{};
    for (final key in keys) {
      var svgString = await Flame.assets.readFile('$dir/$key.svg');
      strings[key] = _applyInlineStyles(svgString);
    }
    final entries = await Future.wait(
      strings.entries.map((e) async =>
          MapEntry(e.key, await Svg.loadFromString(e.value))),
    );
    for (final entry in entries) {
      signSvgs[entry.key] = entry.value;
    }
  }

  static String _applyInlineStyles(String svg) {
    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-1"'),
      'fill="#ffd8bf" stroke="#000" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="cls-2"'),
      'fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round"',
    );
    svg = svg.replaceAll(
      RegExp(r'\bclass="dash"'),
      'fill="none" stroke="#000" stroke-dasharray="2 2"',
    );
    return svg;
  }
}
