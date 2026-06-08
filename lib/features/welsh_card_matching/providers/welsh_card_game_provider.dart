import 'package:flutter/foundation.dart';
import '../../../core/constants/game_constants.dart';
import '../../../shared/services/game_stats_service.dart';
import '../../card_matching/models/card_model.dart';
import '../models/welsh_game_level.dart';
import '../services/welsh_card_game_service.dart';

/// State management for the Welsh card matching game.
class WelshCardGameProvider extends ChangeNotifier {
  final WelshCardGameService _gameService = WelshCardGameService();
  final GameStatsService _statsService = GameStatsService();

  late WelshGameLevel _level;
  WelshGameLevel get level => _level;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  List<CardModel> _cards = [];
  List<CardModel> get cards => _cards;

  CardModel? _firstSelection;
  CardModel? get firstSelection => _firstSelection;

  CardModel? _secondSelection;
  CardModel? get secondSelection => _secondSelection;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _hasWon = false;
  bool get hasWon => _hasWon;

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  int _matchCount = 0;
  int get matchCount => _matchCount;

  int _moveCount = 0;
  int get moveCount => _moveCount;

  int get totalPairs => _level.totalPairs;

  Function(bool isMatch)? onAnswerResult;

  WelshCardGameProvider() {
    _initializeGame(WelshGameLevel.level1());
  }

  void _initializeGame(WelshGameLevel level) {
    _level = level;
    _cards = _gameService.generateCardsForLevel(level: _level);
    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    _hasWon = false;
    _matchCount = 0;
    _moveCount = 0;
  }

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startLevel(WelshGameLevel level) {
    _showLevelSelect = false;
    _initializeGame(level);
    notifyListeners();
  }

  Future<void> selectCard({required String cardId}) async {
    final cardIndex = _cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = _cards[cardIndex];
    if (card.isMatched || card.isFlipped || _isProcessing) return;

    _cards[cardIndex].isFlipped = true;
    notifyListeners();

    if (_firstSelection == null) {
      _firstSelection = _cards[cardIndex];
    } else if (_secondSelection == null) {
      _secondSelection = _cards[cardIndex];
      await _checkForMatch();
    }
  }

  Future<void> _checkForMatch() async {
    if (_firstSelection == null || _secondSelection == null) return;

    _moveCount++;
    _isProcessing = true;
    notifyListeners();

    final isMatch = _gameService.checkMatch(
      first: _firstSelection!,
      second: _secondSelection!,
    );

    if (isMatch) {
      _handleMatch();
    } else {
      await Future.delayed(
        const Duration(milliseconds: GameConstants.mismatchDelayMs),
      );
      _handleMismatch();
    }

    _firstSelection = null;
    _secondSelection = null;
    _isProcessing = false;
    notifyListeners();
  }

  void _handleMatch() {
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isMatched = true;
      }
    }
    _matchCount++;
    onAnswerResult?.call(true);
    _checkWinCondition();
  }

  void _handleMismatch() {
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].id == _firstSelection!.id ||
          _cards[i].id == _secondSelection!.id) {
        _cards[i].isFlipped = false;
      }
    }
    onAnswerResult?.call(false);
  }

  void _checkWinCondition() {
    _hasWon = _gameService.checkWinCondition(
      matchCount: _matchCount,
      totalPairs: totalPairs,
    );
    if (_hasWon) {
      _lastResult = null;
      _statsService
          .recordGameResult(
            GameIds.welshCardMatching,
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

  void resetGame() {
    _initializeGame(_level);
    notifyListeners();
  }
}
