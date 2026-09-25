import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/game_filters.dart';
import '../models/animal_model.dart';

/// Loads Letter Bingo reward animals from Supabase.
///
/// BSL rewards live in `bsl_bingo_rewards`, which stores the letter
/// indirectly via `letter_id` referencing `bsl_bingo_letters`; IAC rewards
/// live in `iac_bingo_rewards`, which stores the letter directly in a
/// `letter` column (FK'd to `iac_bingo_letters.letter`, the Welsh alphabet
/// incl. digraphs) rather than via an id join. Images: `Animals` Storage
/// bucket for BSL, `Anifeiliaid` for IAC — both public.
class BingoRewardsService {
  static const _storageBaseUrl =
      'https://dczagvdllqhzbiqljzfi.supabase.co/storage/v1/object/public';
  static const _placeholderFile = 'placeholder.png';

  static String _tableFor(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? 'iac_bingo_rewards' : 'bsl_bingo_rewards';

  static String _bucketFor(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? 'Anifeiliaid' : 'Animals';

  Future<List<Animal>> fetchRewards(SignSystem signSystem) async {
    final bucket = _bucketFor(signSystem);
    final isIac = signSystem == SignSystem.iac;
    try {
      final rows = await Supabase.instance.client
          .from(_tableFor(signSystem))
          .select(isIac ? 'id, name, image, letter' : 'id, name, image, bsl_bingo_letters(letter)')
          as List<dynamic>;

      return rows
          .map((row) => _toAnimal(row as Map<String, dynamic>, bucket, isIac))
          .whereType<Animal>()
          .toList();
    } catch (e) {
      debugPrint('BingoRewardsService: failed to load rewards — $e');
      return [];
    }
  }

  Animal? _toAnimal(Map<String, dynamic> row, String bucket, bool isIac) {
    final letter = isIac
        ? row['letter'] as String?
        : (row['bsl_bingo_letters'] as Map<String, dynamic>?)?['letter']
            as String?;
    final name = row['name'] as String?;
    final id = row['id'] as String?;
    if (id == null || letter == null || letter.isEmpty ||
        name == null || name.isEmpty) {
      return null;
    }

    final imageFile = (row['image'] as String?)?.trim();
    final fileName =
        (imageFile == null || imageFile.isEmpty) ? _placeholderFile : imageFile;

    return Animal(
      id: id,
      letter: letter.toUpperCase(),
      name: name,
      imageUrl: '$_storageBaseUrl/$bucket/$fileName',
      placeholderUrl: '$_storageBaseUrl/$bucket/$_placeholderFile',
    );
  }
}
