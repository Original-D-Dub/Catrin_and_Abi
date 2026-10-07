import 'package:catrin_abi_bsl/shared/widgets/choose_character_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterThumb.nameFromPath', () {
    test('uses the file name up to the first underscore, capitalised', () {
      expect(
        CharacterThumb.nameFromPath('assets/images/characters/abi_thumb.png'),
        'Abi',
      );
      expect(
        CharacterThumb.nameFromPath(
          'assets/images/characters/jamjam_thumb.png',
        ),
        'Jamjam',
      );
      expect(
        CharacterThumb.nameFromPath(
          'assets/images/characters/elsie_lois_thumb.png',
        ),
        'Elsie',
      );
    });
  });

  testWidgets('loadAll finds every *_thumb.png in the characters folder', (
    tester,
  ) async {
    final thumbs = await CharacterThumb.loadAll();
    expect(thumbs, isNotEmpty);
    expect(thumbs.every((t) => t.assetPath.endsWith('_thumb.png')), isTrue);
    expect(thumbs.map((t) => t.name), contains('Abi'));
  });

  testWidgets('loadAll pairs thumbnails with full-size art ignoring case', (
    tester,
  ) async {
    final thumbs = {for (final t in await CharacterThumb.loadAll()) t.name: t};
    expect(thumbs['Abi']!.fullAssetPath, 'assets/images/characters/Abi.png');
    expect(
      thumbs['Jamjam']!.fullAssetPath,
      'assets/images/characters/JamJam.png',
    );
    // elsie_lois_thumb.png → "Elsie", but the art is Elsie-loise.png.
    expect(thumbs['Elsie']!.fullAssetPath, isNull);
  });

  testWidgets('find looks a character up by its lower-case id', (tester) async {
    final jamjam = await CharacterThumb.find('jamjam');
    expect(jamjam?.name, 'Jamjam');
    expect(jamjam?.id, 'jamjam');
    // The ids the zoo saved before the grid existed still resolve.
    for (final id in ['abi', 'catrin', 'ruby', 'osian']) {
      expect(await CharacterThumb.find(id), isNotNull, reason: id);
    }
    expect(await CharacterThumb.find('player5'), isNull);
  });
}
