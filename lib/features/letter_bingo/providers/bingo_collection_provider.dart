import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/constants/game_filters.dart';
import '../models/animal_model.dart';
import '../services/animal_collection_service.dart';
import '../services/bingo_rewards_service.dart';
import '../services/iac_bingo_inventory_service.dart';

/// App-wide cache of Letter Bingo reward data — the animal list per sign
/// system, the player's already-collected letters, and the reward artwork
/// itself — shared between [LetterBingoProvider] (round-win reward
/// selection, the BINGO celebration card) and `AnimalCollectionScreen`
/// ("My Animals").
///
/// Without this, both screens independently re-fetched the same reward rows
/// and the player's collected-letters set from Supabase every time they
/// opened, and every reward image was downloaded fresh the moment it was
/// first displayed — a visible delay right when a child wins a round or
/// opens their collection. [preload] is instead kicked off the moment a
/// bingo game route is entered (see routes.dart), well before the first
/// round ends, so by the time the celebration or collection screen actually
/// needs the data it's already in memory and every image is already in
/// Flutter's image cache.
class BingoCollectionProvider extends ChangeNotifier {
  BingoCollectionProvider({
    BingoRewardsService? rewardsService,
    AnimalCollectionService? collectionService,
    IacBingoInventoryService? iacInventoryService,
  })  : _rewardsService = rewardsService ?? BingoRewardsService(),
        _collectionService = collectionService ?? AnimalCollectionService(),
        _iacInventoryService =
            iacInventoryService ?? IacBingoInventoryService();

  final BingoRewardsService _rewardsService;
  final AnimalCollectionService _collectionService;
  final IacBingoInventoryService _iacInventoryService;

  final Map<SignSystem, List<Animal>> _rewardsBySignSystem = {};
  final Map<SignSystem, Future<void>> _rewardsLoads = {};

  /// Lowercase letters the current player has collected. Not split by sign
  /// system — mirrors the shared `animal_collection` table, which records
  /// both BSL and IAC rewards together.
  Set<String> _collectedLetters = {};
  String? _collectedForPlayerId;
  Future<void>? _collectedLoad;

  /// Cached reward list for [signSystem]; empty until [preload] finishes.
  List<Animal> rewardsFor(SignSystem signSystem) =>
      List.unmodifiable(_rewardsBySignSystem[signSystem] ?? const []);

  Set<String> get collectedLetters => Set.unmodifiable(_collectedLetters);

  bool isRewardsLoaded(SignSystem signSystem) =>
      _rewardsBySignSystem.containsKey(signSystem);

  bool isCollectedLoaded(String? playerId) =>
      playerId != null && _collectedForPlayerId == playerId;

  /// Fetches (once per sign system / player) the reward list and the
  /// player's collected-letters set, and warms Flutter's image cache with
  /// every reward's artwork so it's ready before it's first displayed.
  /// Safe to call repeatedly — an in-flight or already-cached load is
  /// reused rather than re-fetched.
  Future<void> preload({
    required SignSystem signSystem,
    String? playerId,
  }) {
    return Future.wait([
      _loadRewards(signSystem),
      if (playerId != null) _loadCollected(playerId),
    ]);
  }

  Future<void> _loadRewards(SignSystem signSystem) {
    if (_rewardsBySignSystem.containsKey(signSystem)) return Future.value();
    return _rewardsLoads.putIfAbsent(signSystem, () async {
      final animals = await _rewardsService.fetchRewards(signSystem);
      _rewardsBySignSystem[signSystem] = animals;
      notifyListeners();
      // A Set, not a per-animal loop: every reward in a sign system shares
      // the same placeholderUrl, so this resolves each distinct image once
      // rather than redundantly re-resolving the placeholder per animal.
      final urls = <String>{
        for (final animal in animals) ...[animal.imageUrl, animal.placeholderUrl],
      };
      for (final url in urls) {
        _precache(url);
      }
    });
  }

  Future<void> _loadCollected(String playerId) {
    if (_collectedForPlayerId == playerId) return Future.value();
    return _collectedLoad ??= () async {
      try {
        _collectedLetters =
            await _collectionService.fetchCollection(playerId: playerId);
        _collectedForPlayerId = playerId;
        notifyListeners();
      } finally {
        _collectedLoad = null;
      }
    }();
  }

  /// Resolving a [NetworkImage] (even without a [BuildContext]) triggers the
  /// download and decode, populating Flutter's global image cache — any
  /// later `Image.network(url)` with the same URL then hits that cache
  /// instead of re-downloading.
  void _precache(String url) {
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) => stream.removeListener(listener),
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  /// Records that [animal] was just added to the player's collection —
  /// persists it to Supabase (`animal_collection`, plus
  /// `iac_bingo_player_inventory` for IAC) and updates the cached
  /// collected-letters set immediately, notifying listeners so every screen
  /// watching this provider (the collection grid, a future celebration)
  /// reflects the new animal right away rather than re-fetching.
  Future<void> markCollected({
    required Animal animal,
    required String playerId,
    required int levelNumber,
    required SignSystem signSystem,
  }) async {
    final letter = animal.letter.toLowerCase();
    if (!_collectedLetters.contains(letter)) {
      _collectedLetters = {..._collectedLetters, letter};
      _collectedForPlayerId = playerId;
      notifyListeners();
    }

    // Both writes are independent (different tables) — run them
    // concurrently rather than back-to-back so an IAC save doesn't pay
    // double the round-trip latency. Each is individually non-fatal: the
    // cached/UI state above already reflects the reward regardless of
    // whether persistence succeeds, matching this game's other saves.
    await Future.wait([
      _collectionService
          .addToCollection(
            playerId: playerId,
            animal: animal,
            levelNumber: levelNumber,
          )
          .catchError((_) {}),
      if (signSystem == SignSystem.iac)
        _iacInventoryService
            .addToInventory(userId: playerId, rewardId: animal.id)
            .catchError((_) {}),
    ]);
  }
}
