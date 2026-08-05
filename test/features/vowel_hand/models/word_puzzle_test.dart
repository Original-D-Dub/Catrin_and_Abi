import 'package:catrin_abi_bsl/features/vowel_hand/models/word_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordPuzzle (English, default alphabet)', () {
    test('blanks the single vowel and reconstructs correctly', () {
      final puzzle = WordPuzzle(word: 'cat');
      expect(puzzle.vowel, 'a');
      expect(puzzle.displayWord, 'c_t');
      expect(puzzle.displayWithLetter(letter: 'a'), 'cat');
      expect(puzzle.displayWithLetter(letter: 'o'), 'cot');
    });

    // Regression test: the Welsh alphabet fix below (treating w/y as
    // vowels) must not apply to English words, where w/y are consonants —
    // otherwise these words have their leading 'w' blanked instead of
    // their real vowel, making them un-guessable (no fingertip/badge for a
    // 'w' vowel exists in BSL). CCVC/CVCC English words fetched from
    // Supabase go through this same path.
    for (final entry in {'wag': 'a', 'wig': 'i', 'win': 'i', 'wet': 'e', 'twig': 'i'}
        .entries) {
      test('"${entry.key}" blanks its real vowel, not the leading w', () {
        final puzzle = WordPuzzle(word: entry.key);
        expect(puzzle.vowel, entry.value);
      });
    }
  });

  group('WordPuzzle (Welsh alphabet, digraph-aware)', () {
    // Regression test: these words previously had their vowel identified
    // by a positional fallback (raw character index 1) whenever no plain
    // a/e/i/o/u was found. That fallback landed inside a leading consonant
    // digraph (dr/tr) or digraph (ll/rh) for these words, blanking a
    // consonant instead of the vowel and making them un-guessable.
    for (final word in ['drwg', 'drws', 'trwm', 'llyfr', 'rhy']) {
      test('"$word" blanks the vowel, not a consonant digraph', () {
        final puzzle = WordPuzzle(word: word, useWelshAlphabet: true);
        expect('aeiouwy'.contains(puzzle.vowel), isTrue,
            reason: 'vowel "${puzzle.vowel}" is not a real vowel');
        expect(
            puzzle.displayWithLetter(letter: puzzle.vowel).toLowerCase(),
            word.toLowerCase());
      });
    }

    test('recognises w/y as vowels', () {
      final puzzle = WordPuzzle(word: 'dwr', useWelshAlphabet: true);
      expect(puzzle.vowel, 'w');
      expect(puzzle.displayWord, 'd_r');
    });

    test('keeps a consonant digraph intact as one unit', () {
      final puzzle = WordPuzzle(word: 'bach', useWelshAlphabet: true);
      expect(puzzle.vowel, 'a');
      expect(puzzle.displayWord, 'b_ch');
    });

    test('normalises a circumflex vowel to its base letter', () {
      final puzzle = WordPuzzle(word: 'tân', useWelshAlphabet: true);
      expect(puzzle.vowel, 'a');
    });
  });
}
