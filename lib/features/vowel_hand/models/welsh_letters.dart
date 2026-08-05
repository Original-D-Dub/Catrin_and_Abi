/// Consonant digraphs that count as a single letter in the Welsh alphabet.
/// None of these contain a vowel character, so they never need to be
/// checked against [welshVowels].
const List<String> welshDigraphs = [
  'ch', 'dd', 'ff', 'ng', 'll', 'ph', 'rh', 'th',
];

/// Maps a circumflex ("to bach") vowel to its base vowel letter.
const Map<String, String> _welshCircumflexVowels = {
  'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u', 'ŵ': 'w', 'ŷ': 'y',
};

/// The seven Welsh vowels.
const Set<String> welshVowels = {'a', 'e', 'i', 'o', 'u', 'w', 'y'};

/// One letter of a Welsh word as split out by [splitWelshLetters]: either a
/// single character, or one of the eight consonant digraphs in
/// [welshDigraphs], which count as a single letter in the Welsh alphabet.
class WelshLetter {
  /// The letter's raw text, preserving original case/diacritics (1-2 chars).
  final String text;

  /// The base vowel ('a'/'e'/'i'/'o'/'u'/'w'/'y', with any circumflex
  /// stripped) if this letter is a vowel, otherwise null.
  final String? vowel;

  const WelshLetter(this.text, this.vowel);
}

/// Splits [word] into Welsh letter units.
///
/// Consonant digraphs (ch, dd, ff, ng, ll, ph, rh, th) are kept together as
/// a single unit so they're never split apart — blanking half a digraph
/// removes a consonant, not a vowel, and makes the word un-guessable.
/// Vowels are recognised as a/e/i/o/u/w/y, including their circumflex
/// ("to bach") forms (â/ê/î/ô/û/ŵ/ŷ), which are normalised to the base
/// letter so they match the vowel fingertip/badge the player taps.
List<WelshLetter> splitWelshLetters(String word) {
  final letters = <WelshLetter>[];
  final lower = word.toLowerCase();
  int i = 0;
  while (i < word.length) {
    if (i + 1 < word.length &&
        welshDigraphs.contains(lower.substring(i, i + 2))) {
      letters.add(WelshLetter(word.substring(i, i + 2), null));
      i += 2;
      continue;
    }
    final lowerChar = lower[i];
    final base = _welshCircumflexVowels[lowerChar] ?? lowerChar;
    letters.add(
        WelshLetter(word[i], welshVowels.contains(base) ? base : null));
    i += 1;
  }
  return letters;
}
