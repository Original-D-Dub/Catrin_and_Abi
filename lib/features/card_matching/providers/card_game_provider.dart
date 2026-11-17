import 'package:flutter/foundation.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/services/game_instructions_service.dart';
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

  /// Levels available for the current sign system — the two-player tablet
  /// set when two players share a tablet.
  List<GameLevel> get levels => _usesTwoPlayerTabletLevels
      ? GameLevel.twoPlayerTabletForSignSystem(_signSystem)
      : GameLevel.forSignSystem(_signSystem);

  bool get _usesTwoPlayerTabletLevels => _isTwoPlayer && isTabletDevice;

  /// Game id whose recorded level-name clips match [levels] — the
  /// two-player tablet set has its own (`card_matching_2player_*`).
  String get levelNameAudioId =>
      _usesTwoPlayerTabletLevels ? 'card_matching_2player' : 'card_matching';

  /// Whether the game is running on a tablet. Set by the screen from the
  /// screen size; only affects which [levels] two-player mode offers.
  bool isTabletDevice = false;

  // ─────────────────────────────────────────
  // Champion Mode
  // ─────────────────────────────────────────

  /// Champion Mode unlocks once every level in the sign system's level
  /// list has been played — each has a recorded personal best. Gameplay
  /// is unchanged; every card's colour-coded pair border is replaced with
  /// white (invisible against the card face), so matches must be found from the signs and
  /// letters alone.
  bool _isChampionModeUnlocked = false;
  bool get isChampionModeUnlocked => _isChampionModeUnlocked;

  /// Whether Champion Mode is switched on (only ever true once unlocked).
  bool _championMode = false;
  bool get championMode => _championMode;

  /// True while the "Champion Mode Unlocked!" banner should show: Champion
  /// Mode is unlocked but this player hasn't yet dismissed the banner (see
  /// [_championBannerSeenId]). Cleared by
  /// [dismissChampionModeUnlockedBanner].
  bool _justUnlockedChampionMode = false;
  bool get justUnlockedChampionMode => _justUnlockedChampionMode;

  final GameInstructionsService _instructionsService =
      GameInstructionsService();

  /// Seen-flag id recording that this player has dismissed the unlock
  /// banner for this sign system. Stored per player rather than tied to
  /// the unlocking game, so a player who unlocked Champion Mode before the
  /// banner existed — or whose unlock was first spotted on opening the game
  /// rather than straight after their last level — still sees it once.
  String get _championBannerSeenId => '${_statsGameId}_champion_unlocked';

  /// Clears [justUnlockedChampionMode] once the unlock banner has been
  /// shown and dismissed, and remembers that so it isn't shown again.
  void dismissChampionModeUnlockedBanner() {
    _justUnlockedChampionMode = false;
    _instructionsService.markInstructionsSeen(_championBannerSeenId);
    notifyListeners();
  }

  /// Set when the player long-presses the Champion rosette to switch
  /// Champion Mode off. Static so it lasts for the rest of the app session
  /// (every new provider starts with Champion Mode off), then resets — once
  /// unlocked, Champion Mode is on by default.
  static bool _championModeOffThisSession = false;

  /// Enables or disables Champion Mode for the rest of this app session
  /// (see [_championModeOffThisSession]). No-ops if not yet unlocked.
  void setChampionMode(bool value) {
    if (!_isChampionModeUnlocked) return;
    _championMode = value;
    _championModeOffThisSession = !value;
    notifyListeners();
  }

  /// The `player_stats` game id this sign system's results record under.
  String get _statsGameId => _signSystem == SignSystem.iac
      ? GameIds.welshCardMatching
      : GameIds.cardMatching;

  /// Unlocks Champion Mode once every level in the sign system's level
  /// list has been played — each has a recorded personal best — and sets
  /// it on. Only ever raises [isChampionModeUnlocked], never lowers it:
  /// guest play isn't persisted by [GameStatsService] (it no-ops for
  /// anonymous users), so this check always comes back empty for guests —
  /// if it were allowed to clear the flag, a guest who just unlocked
  /// Champion Mode by playing in this session would see it re-locked the
  /// moment they returned to level select.
  ///
  /// On unlocking, raises [justUnlockedChampionMode] if this player hasn't
  /// dismissed the unlock banner before.
  Future<void> _refreshChampionModeUnlock() async {
    if (_isChampionModeUnlocked) return;
    final bests = await Future.wait([
      for (final level in GameLevel.forSignSystem(_signSystem))
        _statsService.getPersonalBest('${_statsGameId}_${level.levelNumber}'),
    ]);
    if (_isChampionModeUnlocked || !bests.every((best) => best != null)) {
      return;
    }
    final bannerSeen =
        await _instructionsService.hasSeenInstructions(_championBannerSeenId);
    _isChampionModeUnlocked = true;
    _championMode = !_championModeOffThisSession;
    _justUnlockedChampionMode = !bannerSeen;
    notifyListeners();
  }

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

  /// Most Champion Mode hints a player can use in one game.
  static const int maxHints = 3;

  /// Champion Mode hints used so far this game. Recorded with the result so
  /// the scores page can show how many hints a personal best used.
  int _hintsUsed = 0;
  int get hintsUsed => _hintsUsed;
  int get hintsRemaining => maxHints - _hintsUsed;

  /// Whether one card is turned over and the player hasn't flipped a second
  /// card yet — the moment a hint can reveal its pair.
  bool get isAwaitingSecondCard =>
      _firstSelection != null && _secondSelection == null;

  /// Whether the Champion Mode hint button is enabled: a card is waiting
  /// for its partner and the player has hints left.
  bool get canShowHint =>
      _championMode && isAwaitingSecondCard && hintsRemaining > 0;

  /// Spends one hint. Returns false (spending nothing) if [canShowHint] is
  /// false.
  bool useHint() {
    if (!canShowHint) return false;
    _hintsUsed++;
    notifyListeners();
    return true;
  }

  /// The card that matches [firstSelection], for the Champion Mode hint.
  CardModel? get hintPair {
    final first = _firstSelection;
    if (first == null) return null;
    for (final card in _cards) {
      if (card.pairId == first.pairId && card.id != first.id) return card;
    }
    return null;
  }

  /// Whether we're currently processing a match check  /// Prevents rapid tapping during the delay
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
  /// cards, and whoever makes a pair scores it and goes again. Chosen on the level-select
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
    _refreshChampionModeUnlock();
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
    _hintsUsed = 0;
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
    _refreshChampionModeUnlock();
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

    // Finding a pair earns another turn; a miss passes play to the other
    // player.
    if (_isTwoPlayer && !isMatch && !_hasWon) {
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
            hints: _hintsUsed,
          )
          .then((result) {
        _lastResult = result;
        // This play may have been the last unplayed level — re-check the
        // Champion Mode unlock.
        _refreshChampionModeUnlock();
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
