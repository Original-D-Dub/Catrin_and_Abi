import 'dart:math';

import 'package:catrin_abi_bsl/features/bubble_shooter/models/bubble_shooter_models.dart';
import 'package:catrin_abi_bsl/features/sports_collection/models/sport_card.dart';
import 'package:catrin_abi_bsl/features/sports_collection/providers/sports_collection_provider.dart';
import 'package:catrin_abi_bsl/features/sports_collection/services/sports_collection_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the Supabase table.
class _FakeService extends SportsCollectionService {
  _FakeService([Map<String, SportCard>? rows]) : rows = {...?rows};

  final Map<String, SportCard> rows;
  int fetches = 0;

  @override
  Future<Map<String, SportCard>> fetchCollection(
      {required String playerId}) async {
    fetches++;
    return {...rows};
  }

  @override
  Future<void> addToCollection({
    required String playerId,
    required SportCard card,
    required String source,
  }) async {
    rows[source] = card;
  }
}

void main() {
  test('every fifth level is a chest', () {
    final chests = [
      for (final l in BubbleShooterLevels.all)
        if (BubbleShooterLevels.isChestLevel(l.number)) l.number,
    ];
    expect(chests, [5, 10, 15, 20, 25, 30, 35, 40]);
    expect(BubbleShooterLevels.chestSource(5), 'bubble_shooter_chest_5');
  });

  test('a chest gives a new card once, and saves it', () async {
    final service = _FakeService();
    final p = SportsCollectionProvider(service: service, random: Random(1));
    final card = await p.openChest(playerId: 'p', source: 'chest_5');
    expect(card, isNotNull);
    expect(p.isChestOpened('chest_5'), isTrue);
    expect(p.cardFromChest('chest_5'), card);
    expect(service.rows, {'chest_5': card});
    // Opening the same chest again gives nothing.
    expect(await p.openChest(playerId: 'p', source: 'chest_5'), isNull);
    expect(p.collected, {card});
  });

  test('chests only give cards the player does not have yet', () async {
    for (var seed = 0; seed < 20; seed++) {
      final p = SportsCollectionProvider(
          service: _FakeService(), random: Random(seed));
      final won = <SportCard>[];
      for (var i = 0; i < SportCard.values.length; i++) {
        won.add((await p.openChest(playerId: 'p', source: 'chest_$i'))!);
      }
      expect(won.toSet(), SportCard.values.toSet(), reason: 'seed $seed');
      // Nothing left to give.
      expect(await p.openChest(playerId: 'p', source: 'extra'), isNull);
    }
  });

  test('loads saved cards once per player', () async {
    final service = _FakeService({'bubble_shooter_chest_5': SportCard.rugby});
    final p = SportsCollectionProvider(service: service);
    await p.load('p');
    await p.load('p');
    expect(service.fetches, 1);
    expect(p.isLoaded('p'), isTrue);
    expect(p.isChestOpened('bubble_shooter_chest_5'), isTrue);
    final card = await p.openChest(playerId: 'p', source: 'other');
    expect(card, isNot(SportCard.rugby));
  });
}
