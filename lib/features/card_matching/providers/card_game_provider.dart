import 'package:flutter/foundation.dart';
import '../../../core/constants/game_constants.dart';
import '../models/card_model.dart';
import '../models/game_level.dart';
import '../services/card_game_service.dart';

/// Manages all state for the card matching game.
///
/// Responsibilities:
/// - Track all cards and their states (flipped, matched)
/// - Handle card selection logic (max 2 at a time)
/// - Check for matches and update state
/// - Detect win condition
/// - Support game reset
///
/// Usage:
/// ```dart
/// final provider = CardGameProvider();
/// provider.selectCard(cardId: 'bsl_a');
/// if (provider.hasWon) {
///   showCelebration();
/// }
/// ```
class CardGameProvider extends ChangeNotifier {
  /// The game service for pure logic operations
  final CardGameService _gameService = CardGameService();

  /// The current game level configuration
  late GameLevel _level;
  GameLevel get level => _level;

  /// All cards in the current game
  List<CardModel> _cards = [];
  List<CardModel> get cards => _cards;

  /// First card selected by the player
  CardModel? _firstSelection;
  CardModel? get firstSelection => _firstSelection;

  /// Second card selected by the player
  CardModel? _secondSelection;
  CardModel? get secondSelection => _secondSelection;

  /// Whether we're currently processing a match check
  /// Prevents rapid tapping during the delay
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Whether the player has won the game
  bool _hasWon = false;
  bool get hasWon => _hasWon;

  /// Whether to show the level selection screen
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// Number of successful matches made
  int _matchCount = 0;
  int get matchCount => _matchCount;

  /// Total number of pairs in the level
  int get totalPairs => _level.totalPairs;

  /// Creates the provider and initializes Level 1.
  CardGameProvider() {
    _initializeGame(GameLevel.level1());
  }

  /// Initializes a new game with the specified level.
  void _initializeGame(GameLevel level) {
    _level = level;
    _cards = _gameService.generateCardsForLevel(level: _level);
    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    _hasWon = false;
    _matchCount = 0;
  }

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  /// Starts a game with the specified level.
  void startLevel(GameLevel level) {
    _showLevelSelect = false;
    _initializeGame(level);
    notifyListeners();
  }

  /// Called when user taps a card.
  ///
  /// Handles flip logic, selection tracking, and match checking.
  ///
  /// [cardId] is the unique ID of the tapped card.
  Future<void> selectCard({required String cardId}) async {
    // Find the card
    final cardIndex = _cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = _cards[cardIndex];

    // Ignore if card is already matched
    if (card.isMatched) return;

    // Ignore if card is already flipped
    if (card.isFlipped) return;

    // Ignore if we're processing a previous match check
    if (_isProcessing) return;

    // Flip the card
    _cards[cardIndex].isFlipped = true;
    notifyListeners();

    // Handle selection
    if (_firstSelection == null) {
      // First card selected
      _firstSelection = _cards[cardIndex];
    } else if (_secondSelection == null) {
      // Second card selected
      _secondSelection = _cards[cardIndex];
      await _checkForMatch();
    }
  }

  /// Checks if the two selected cards match.
  Future<void> _checkForMatch() async {
    if (_firstSelection == null || _secondSelection == null) return;

    _isProcessing = true;
    notifyListeners();

    final isMatch = _gameService.checkMatch(
      first: _firstSelection!,
      second: _secondSelection!,
    );

    if (isMatch) {
      // Mark both cards as matched
      _handleMatch();
    } else {
      // Wait before flipping back
      await Future.delayed(
        const Duration(milliseconds: GameConstants.mismatchDelayMs),
      );
      _handleMismatch();
    }

    // Clear selections
    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    notifyListeners();
  }

  /// Handles a successful match.
  void _handleMatch() {
    // Find and mark both cards as matched
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isMatched = true;
      }
    }

    _matchCount++;

    // Check win condition
    _checkWinCondition();
  }

  /// Handles a failed match - flips cards back.
  void _handleMismatch() {
    // Flip both cards back
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isFlipped = false;
      }
    }
  }

  /// Checks if all pairs have been matched.
  void _checkWinCondition() {
    _hasWon = _gameService.checkWinCondition(
      matchCount: _matchCount,
      totalPairs: totalPairs,
    );
  }

  /// Resets the game to initial state with reshuffled cards.
  void resetGame() {
    _initializeGame(_level);
    notifyListeners();
  }
}
