import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';
import '../../vowel_hand/models/welsh_letters.dart';

/// Shows [word] fingerspelled, one hand-shape per letter, in [signSystem]'s
/// alphabet — BSL spells the English word letter by letter, IAC spells the
/// Welsh word with its digraphs (ch, dd, ll...) kept as single signs.
///
/// Spaces become small gaps; characters with no sign (apostrophes,
/// hyphens) are skipped.
class FingerspelledWord extends StatelessWidget {
  final String word;
  final SignSystem signSystem;
  final double signSize;

  const FingerspelledWord({
    super.key,
    required this.word,
    required this.signSystem,
    this.signSize = 48,
  });

  static const Set<String> _iacLetters = {
    'a',
    'b',
    'c',
    'ch',
    'd',
    'dd',
    'e',
    'f',
    'ff',
    'g',
    'h',
    'i',
    'j',
    'l',
    'll',
    'm',
    'n',
    'ng',
    'o',
    'p',
    'ph',
    'r',
    'rh',
    's',
    't',
    'th',
    'u',
    'w',
    'y',
  };

  static const Map<String, String> _stripCircumflex = {
    'â': 'a',
    'ê': 'e',
    'î': 'i',
    'ô': 'o',
    'û': 'u',
    'ŵ': 'w',
    'ŷ': 'y',
  };

  /// Splits [word] into sign letters, with `' '` marking word breaks.
  static List<String> lettersFor(String word, SignSystem signSystem) {
    final out = <String>[];
    for (final part in word.toLowerCase().split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      if (out.isNotEmpty) out.add(' ');
      if (signSystem == SignSystem.iac) {
        for (final l in splitWelshLetters(part)) {
          final text = l.text.toLowerCase();
          final base = _stripCircumflex[text] ?? text;
          if (_iacLetters.contains(base)) out.add(base);
        }
      } else {
        for (final ch in part.split('')) {
          if (RegExp('[a-z]').hasMatch(ch)) out.add(ch);
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final letters = lettersFor(word, signSystem);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final letter in letters)
            if (letter == ' ')
              SizedBox(width: signSize * 0.4)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: signSize,
                      height: signSize,
                      child: BslAlphabetSvg(
                        letter: letter,
                        signSystem: signSystem,
                      ),
                    ),
                    Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
