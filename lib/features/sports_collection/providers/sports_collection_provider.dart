import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/sport_card.dart';
import '../services/sports_collection_service.dart';

/// App-wide cache of the player's sports cards, shared by the Bubble
/// Shooter level map (treasure chests) and the sports collection screen.
///
/// Each chest is identified by a source id (e.g. `bubble_shooter_chest_5`)
/// and opens once per player, giving a random card the player doesn't have
/// yet.
class SportsCollectionProvider extends ChangeNotifier {
  SportsCollectionProvider({
    SportsCollectionService? service,
    Random? random,
  })  : _service = service ?? SportsCollectionService(),
        _random = random ?? Random();

  final SportsCollectionService _service;
  final Random _random;

  /// Cards collected, keyed by the chest each came from.
  Map<String, SportCard> _bySource = {};
  String? _loadedForPlayerId;
  Future<void>? _load;

  Set<SportCard> get collected => _bySource.values.toSet();

  bool isLoaded(String? playerId) =>
      playerId != null && _loadedForPlayerId == playerId;

  /// Whether the chest [source] has already been opened.
  bool isChestOpened(String source) => _bySource.containsKey(source);

  /// The card the chest [source] gave, if it's been opened.
  SportCard? cardFromChest(String source) => _bySource[source];

  /// Fetches the player's cards once per player. Safe to call repeatedly.
  Future<void> load(String playerId) {
    if (_loadedForPlayerId == playerId) return Future.value();
    return _load ??= () async {
      try {
        _bySource = await _service.fetchCollection(playerId: playerId);
        _loadedForPlayerId = playerId;
        notifyListeners();
      } catch (e) {
        debugPrint('SportsCollectionProvider load error: $e');
      } finally {
        _load = null;
      }
    }();
  }

  /// Opens the chest [source] for [playerId]: picks a random card the
  /// player doesn't have, records it and returns it. Returns null if the
  /// chest was already opened or every card is collected.
  ///
  /// The card shows straight away; saving it is best-effort, like the
  /// animal collection's saves.
  Future<SportCard?> openChest({
    required String playerId,
    required String source,
  }) async {
    await load(playerId);
    if (isChestOpened(source)) return null;
    final remaining =
        SportCard.values.where((c) => !collected.contains(c)).toList();
    if (remaining.isEmpty) return null;
    final card = remaining[_random.nextInt(remaining.length)];
    _bySource = {..._bySource, source: card};
    notifyListeners();
    try {
      await _service.addToCollection(
          playerId: playerId, card: card, source: source);
    } catch (e) {
      debugPrint('SportsCollectionProvider save error: $e');
    }
    return card;
  }
}
