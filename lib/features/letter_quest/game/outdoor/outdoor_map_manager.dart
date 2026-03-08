import 'dart:math';

import 'package:flame/components.dart';

import '../../models/letter_quest_word.dart';
import '../../providers/letter_quest_provider.dart';
import '../letter_collectible.dart';
import 'boundary_component.dart';
import 'bush_component.dart';
import 'outdoor_map_data.dart';
import 'outdoor_map_generator.dart';
import 'outdoor_terrain_component.dart';
import 'rock_component.dart';
import 'tree_component.dart';
import 'water_component.dart';

/// Manages the outdoor map terrain and letter placement for Level 4.
///
/// Analogous to [RoomManager] for Level 3 but operates on a
/// procedurally generated outdoor map instead of pre-defined rooms.
///
/// Responsibilities:
/// - Generates the outdoor map via [OutdoorMapGenerator]
/// - Builds all terrain components (ground, water, obstacles, boundary)
/// - Places correct and distractor letters at random walkable positions
/// - Clears and replaces letters when advancing to the next word
class OutdoorMapManager {
  /// Reference to the game provider for word/state access
  final LetterQuestProvider provider;

  /// The Flame world to add components to
  final World gameWorld;

  /// The generated map data
  late OutdoorMapData mapData;

  /// Currently active letter collectibles (tracked for cleanup)
  final List<LetterCollectible> _activeLetters = [];

  /// Random number generator
  final Random _random = Random();

  /// All consonants used as distractors
  static const String _consonants = 'bcdfghjklmnpqrstvwxyz';

  /// Number of distractor letters to place per word
  static const int _distractorCount = 7;

  /// Creates the outdoor map manager.
  OutdoorMapManager({
    required this.provider,
    required this.gameWorld,
  });

  /// The player's starting position on the generated map.
  Vector2 get playerStartPosition => mapData.playerStart;

  /// Generates the outdoor map and adds all terrain components to the world.
  ///
  /// Call this once during game setup. The generated [mapData] is stored
  /// for letter placement and can be regenerated on replay.
  void generateMap() {
    mapData = OutdoorMapGenerator.generate(random: _random);
    _buildTerrain();
  }

  /// Regenerates the map with a new random layout.
  ///
  /// Used when the player taps "Play Again" after victory.
  /// Removes existing terrain components and generates fresh ones.
  /// Uses a fresh Random instance to ensure a different map each time.
  void regenerateMap() {
    // Remove all children from the world (terrain + obstacles + letters)
    gameWorld.removeAll(gameWorld.children.toList());

    // Clear active letters list
    _activeLetters.clear();

    // Generate new map with a fresh random seed
    mapData = OutdoorMapGenerator.generate(random: Random());
    _buildTerrain();
  }

  /// Builds all terrain components from the generated map data.
  void _buildTerrain() {
    // 1. Terrain canvas (grass, lake, streams, bridges)
    gameWorld.add(OutdoorTerrainComponent(mapData: mapData));

    // 2. Water collision segments
    _addWaterCollision();

    // 3. Boundary collision walls
    BoundaryBuilder.buildBoundary(
      world: gameWorld,
      mapData: mapData,
    );

    // 4. Trees (solid obstacles)
    for (int i = 0; i < mapData.treePositions.length; i++) {
      gameWorld.add(TreeComponent(
        position: mapData.treePositions[i].clone(),
        colorSeed: i,
      ));
    }

    // 5. Rocks (solid obstacles)
    for (int i = 0; i < mapData.rockPositions.length; i++) {
      gameWorld.add(RockComponent(
        position: mapData.rockPositions[i].clone(),
        colorSeed: i,
      ));
    }

    // 6. Bushes (decorative, no collision)
    for (int i = 0; i < mapData.bushPositions.length; i++) {
      gameWorld.add(BushComponent(
        position: mapData.bushPositions[i].clone(),
        colorSeed: i,
      ));
    }
  }

  /// Adds water collision segments for all water grid cells.
  ///
  /// Iterates the generation grid and creates a [WaterComponent] for
  /// each water-type cell. Bridge cells are skipped, which creates
  /// the walkable gaps at bridge crossings.
  void _addWaterCollision() {
    for (int row = 0; row < mapData.gridRows; row++) {
      for (int col = 0; col < mapData.gridCols; col++) {
        if (mapData.grid[row][col] == CellType.water) {
          gameWorld.add(WaterComponent(
            position: Vector2(
              col * mapData.cellSize,
              row * mapData.cellSize,
            ),
            size: Vector2.all(mapData.cellSize),
          ));
        }
      }
    }
  }

  // -------------------------
  // Letter placement
  // -------------------------

  /// Places letters for the current word randomly across the map.
  ///
  /// The 3 correct letters are placed at random candidate positions.
  /// [_distractorCount] distractor consonants (not in the current word)
  /// are scattered at other candidate positions.
  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final candidates = List<Vector2>.from(mapData.letterCandidatePositions)
      ..shuffle(_random);

    if (candidates.isEmpty) return;

    int candidateIdx = 0;

    // Place the 3 correct letters
    for (int i = 0; i < word.word.length && candidateIdx < candidates.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: candidates[candidateIdx].clone(),
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
      candidateIdx++;
    }

    // Place distractor letters
    _placeDistractors(word, candidates, candidateIdx);
  }

  /// Places distractor letters at remaining candidate positions.
  void _placeDistractors(
    LetterQuestWord word,
    List<Vector2> candidates,
    int startIdx,
  ) {
    final wordLetters = word.uniqueLetters;

    // Get consonants not in the current word
    final availableDistractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    int distractorIdx = 0;
    int candidateIdx = startIdx;

    for (int i = 0;
        i < _distractorCount && candidateIdx < candidates.length;
        i++) {
      if (distractorIdx >= availableDistractors.length) {
        distractorIdx = 0;
      }

      final letter = LetterCollectible(
        letter: availableDistractors[distractorIdx],
        position: candidates[candidateIdx].clone(),
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
      distractorIdx++;
      candidateIdx++;
    }
  }

  /// Removes all current letter collectibles and places new ones
  /// for the next word.
  void clearAndReplaceLetters() {
    for (final letter in _activeLetters) {
      if (letter.isMounted) {
        letter.removeFromParent();
      }
    }
    _activeLetters.clear();

    placeLettersForCurrentWord();
  }
}
