import 'package:flutter/foundation.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/services/game_stats_service.dart';
import '../../../shared/widgets/choose_character_grid.dart';
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
  final CardGameService _gameService = CardGameService();
  final GameStatsService _statsService = GameStatsService();

  /// The sign system (BSL or IAC) this game instance uses.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

  /// Levels available for the current sign system.
  List<GameLevel> get levels => GameLevel.forSignSystem(_signSystem);

  /// The current game level configuration
  late GameLevel _level;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;
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

  /// Called after each match check with `true` for a match, `false` for a mismatch.
  /// Set by the screen to play correct/wrong audio without coupling the provider to audio.
  Function(bool isMatch)? onAnswerResult;

  /// Called the moment the player flips the second card of a pair-matching
  /// attempt, before the match result is known. Set by the screen to
  /// permanently dismiss the instruction bubble — by this point the player
  /// has shown they know how to play.
  VoidCallback? onSecondCardFlipped;

  /// Called once, with [_moveCount], the moment the level is won. Set by the
  /// screen when launched from the "Learn BSL trail" so it can mark the
  /// trail node completed without coupling the provider to trail state.
  Function(int score)? onLevelComplete;

  /// Number of successful matches made
  int _matchCount = 0;
  int get matchCount => _matchCount;

  /// Total number of card-pair attempts (flipping two cards), regardless of
  /// whether they matched. This is the score metric — fewer moves is better.
  int _moveCount = 0;
  int get moveCount => _moveCount;

  /// Total number of pairs in the level
  int get totalPairs => _level.totalPairs;

  /// Whether this is a two-player game — players take turns flipping two
  /// cards, and whoever makes a pair scores it. Chosen on the level-select
  /// tabs (players then pick characters before choosing a level); uses the
  /// same levels as one-player.
  bool _isTwoPlayer = false;
  bool get isTwoPlayer => _isTwoPlayer;

  /// Whose turn it is in a two-player game: 1 or 2.
  int _currentPlayer = 1;
  int get currentPlayer => _currentPlayer;

  /// Pairs found by each player in a two-player game.
  int _player1Score = 0;
  int get player1Score => _player1Score;
  int _player2Score = 0;
  int get player2Score => _player2Score;

  /// Characters chosen by each player for a two-player game. Kept across
  /// Play Again / Next Level so players only pick once per session.
  CharacterThumb? _player1Character;
  CharacterThumb? get player1Character => _player1Character;
  CharacterThumb? _player2Character;
  CharacterThumb? get player2Character => _player2Character;

  /// Which player (1 or 2) is currently choosing a character, or null when
  /// the character select isn't showing.
  int? _pickingPlayer;
  int? get pickingPlayer => _pickingPlayer;

  /// The winning player (1 or 2) of a finished two-player game, or null for
  /// a draw.
  int? get twoPlayerWinner {
    if (_player1Score == _player2Score) return null;
    return _player1Score > _player2Score ? 1 : 2;
  }

  /// Creates the provider and initializes the first level for [signSystem].
  ///
  /// [initialLevelNumber], when set, skips level-select and starts directly
  /// at that level — used when launched from the "Learn BSL trail".
  CardGameProvider({SignSystem signSystem = SignSystem.bsl, int? initialLevelNumber})
      : _signSystem = signSystem {
    _initializeGame(GameLevel.forSignSystem(_signSystem).first);
    if (initialLevelNumber != null) {
      startLevel(levels[initialLevelNumber - 1]);
    }
  }

  /// Initializes a new game with the specified level.
  void _initializeGame(GameLevel level) {
    _level = level;
    _cards = _gameService.generateCardsForLevel(
      level: _level,
      signSystem: _signSystem,
    );
    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    _hasWon = false;
    _matchCount = 0;
    _moveCount = 0;
    _currentPlayer = 1;
    _player1Score = 0;
    _player2Score = 0;
  }

  /// Records [character] for the player currently choosing, then moves on to
  /// player 2. Once player 2 has chosen, the character select closes and the
  /// level select shows again for the players to pick a level.
  void pickCharacter(CharacterThumb character) {
    if (_pickingPlayer == 1) {
      _player1Character = character;
      _pickingPlayer = 2;
    } else {
      _player2Character = character;
      _pickingPlayer = null;
    }
    notifyListeners();
  }

  /// Steps back from the character select: player 2 → player 1 → level
  /// select in one-player mode (the players never finished choosing).
  void backFromCharacterSelect() {
    if (_pickingPlayer == 2) {
      _pickingPlayer = 1;
    } else {
      _pickingPlayer = null;
      _isTwoPlayer = false;
    }
    notifyListeners();
  }

  /// Switches between one-player and two-player mode (from the level-select
  /// tabs). Switching to two-player opens the character select for player 1;
  /// the level is chosen afterwards.
  void setTwoPlayer(bool value) {
    if (_isTwoPlayer == value) return;
    _isTwoPlayer = value;
    _pickingPlayer = value ? 1 : null;
    notifyListeners();
  }

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    _pickingPlayer = null;
    notifyListeners();
  }

  /// Starts a game with the specified level.
  void startLevel(GameLevel level) {
    _showLevelSelect = false;
    _pickingPlayer = null;
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
      onSecondCardFlipped?.call();
      await _checkForMatch();
    }
  }

  /// Checks if the two selected cards match.
  Future<void> _checkForMatch() async {
    if (_firstSelection == null || _secondSelection == null) return;

    _moveCount++; // every two-card attempt counts as one move
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

    // Players alternate after every two-card attempt, match or not.
    if (_isTwoPlayer && !_hasWon) {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    }

    // Clear selections
    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    notifyListeners();
  }

  /// Handles a successful match.
  void _handleMatch() {
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isMatched = true;
      }
    }
    _matchCount++;
    if (_isTwoPlayer) {
      if (_currentPlayer == 1) {
        _player1Score++;
      } else {
        _player2Score++;
      }
    }
    onAnswerResult?.call(true);
    _checkWinCondition();
  }

  /// Handles a failed match - flips cards back.
  void _handleMismatch() {
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isFlipped = false;
      }
    }
    onAnswerResult?.call(false);
  }

  /// Checks if all pairs have been matched.
  void _checkWinCondition() {
    _hasWon = _gameService.checkWinCondition(
      matchCount: _matchCount,
      totalPairs: totalPairs,
    );
    // Two-player games aren't a personal score, so they don't feed stats,
    // personal bests or the trail.
    if (_hasWon && !_isTwoPlayer) {
      _lastResult = null;
      onLevelComplete?.call(_moveCount);
      final gameId = _signSystem == SignSystem.iac
          ? GameIds.welshCardMatching
          : GameIds.cardMatching;
      _statsService
          .recordGameResult(
            gameId,
            _moveCount,
            level: _level.levelNumber,
            higherIsBetter: false,
          )
          .then((result) {
        _lastResult = result;
        notifyListeners();
      });
    }
  }

  /// Resets the game to initial state with reshuffled cards.
  void resetGame() {
    _initializeGame(_level);
    notifyListeners();
  }
}
