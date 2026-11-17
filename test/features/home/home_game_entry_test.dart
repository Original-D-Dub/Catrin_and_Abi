import 'dart:io';

import 'package:catrin_abi_bsl/core/constants/game_filters.dart';
import 'package:catrin_abi_bsl/features/home/models/home_game_entry.dart';
import 'package:catrin_abi_bsl/shared/services/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _allAges = {AgeGroup.years1to3, AgeGroup.years3to5, AgeGroup.years5plus};

HomeGameEntry _entry(String id, {GameCategory? category}) => homeGameEntry(
      route: '/games/$id',
      titleKey: '$id.title',
      category: category ?? GameCategory.alphabet,
      ageGroups: _allAges,
    );

void main() {
  group('visibleGames', () {
    final sudoku = _entry('sudoku', category: GameCategory.numeracy);
    final zoo = _entry('zoo', category: GameCategory.vocabulary);
    final games = [sudoku, zoo];

    test('toggle on with an empty hide list shows everything', () {
      final visible = visibleGames(
        games,
        category: GameCategory.all,
        ageGroup: AgeGroup.all,
        hideListedGames: true,
        hiddenGameIds: {},
      );
      expect(visible, containsAll([sudoku, zoo]));
    });

    test('shows everything when the hide toggle is off even if listed', () {
      final visible = visibleGames(
        games,
        category: GameCategory.all,
        ageGroup: AgeGroup.all,
        hideListedGames: false,
        hiddenGameIds: {'sudoku'},
      );
      expect(visible, containsAll([sudoku, zoo]));
    });

    test(
        'toggle on hides listed games regardless of category/age settings '
        '(overrides all other settings)', () {
      final visible = visibleGames(
        games,
        category: GameCategory.all,
        ageGroup: AgeGroup.all,
        hideListedGames: true,
        hiddenGameIds: {'sudoku'},
      );
      expect(visible, [zoo]);
    });

    test('toggle on hides games even when filters would show them', () {
      final visible = visibleGames(
        games,
        category: GameCategory.vocabulary,
        ageGroup: AgeGroup.years1to3,
        hideListedGames: true,
        hiddenGameIds: {'zoo'},
      );
      expect(visible, isEmpty);
    });

    test('still applies the category and age-group filters to other games',
        () {
      final visible = visibleGames(
        games,
        category: GameCategory.vocabulary,
        ageGroup: AgeGroup.years5plus,
        hideListedGames: true,
        hiddenGameIds: {'sudoku'},
      );
      expect(visible, [zoo]);
    });

    test('matches on explicit gameId when titleKey differs from it', () {
      // gameId is an escape hatch for tiles that deviate from the
      // '<gameId>.title' convention — hidden-game matching must honour it.
      final legacy = homeGameEntry(
        route: '/games/legacy',
        titleKey: 'legacy_name.title',
        category: GameCategory.numeracy,
        ageGroups: _allAges,
        gameId: 'legacy_id',
      );
      final visible = visibleGames(
        [legacy],
        category: GameCategory.all,
        ageGroup: AgeGroup.all,
        hideListedGames: true,
        hiddenGameIds: {'legacy_id'},
      );
      expect(visible, isEmpty);
    });
  });

  group('SettingsProvider.parseHiddenGamesJson', () {
    test('parses the shipped object format', () {
      final ids = SettingsProvider.parseHiddenGamesJson(
        '{"hidden_games": ["zoo", "sudoku"]}',
      );
      expect(ids, {'zoo', 'sudoku'});
    });

    test('accepts a bare JSON array too', () {
      final ids = SettingsProvider.parseHiddenGamesJson('["zoo"]');
      expect(ids, {'zoo'});
    });

    test('malformed JSON yields an empty set', () {
      expect(SettingsProvider.parseHiddenGamesJson('not json'), isEmpty);
    });

    test('non-string entries and other shapes yield an empty set', () {
      expect(
        SettingsProvider.parseHiddenGamesJson('{"hidden_games": [1, 2]}'),
        isEmpty,
      );
      expect(SettingsProvider.parseHiddenGamesJson('{"other": []}'), isEmpty);
    });
  });

  test('shipped hidden_games.json parses and lists the expected games',
      () async {
    // flutter test runs from the package root.
    final raw =
        await File('assets/data/hidden_games.json').readAsString();
    final ids = SettingsProvider.parseHiddenGamesJson(raw);
    expect(
      ids,
      {
        'bsl_number_builder',
        'bsl_sprint',
        'character_id',
        'clothes_line',
        'colouring',
        'letter_quest',
        'more_or_less',
        'school_explorer',
        'sudoku',
        'word_whirl',
        'zoo',
      },
    );
  });
}
