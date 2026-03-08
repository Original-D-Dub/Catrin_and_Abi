import 'package:flame/game.dart';

import '../providers/letter_quest_provider.dart';

/// Abstract base class shared by both indoor (Level 3) and outdoor (Level 4)
/// Letter Quest games.
///
/// Provides the [provider] getter that [PlayerComponent] and
/// [LetterCollectible] access via `HasGameReference<BaseLetterQuestGame>`.
///
/// Both concrete game classes extend this so that shared components
/// can reference either game without knowing which level is active.
abstract class BaseLetterQuestGame extends FlameGame
    with HasCollisionDetection {
  /// The game state provider (words, collection tracking, phases).
  LetterQuestProvider get provider;
}
