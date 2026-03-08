import 'character_part.dart';

/// Represents a complete character with all body parts.
class GameCharacter {
  /// The name of this character
  final String characterName;

  /// The head part
  final CharacterPart head;

  /// The torso part
  final CharacterPart torso;

  /// The legs part
  final CharacterPart legs;

  /// The feet part
  final CharacterPart feet;

  const GameCharacter({
    required this.characterName,
    required this.head,
    required this.torso,
    required this.legs,
    required this.feet,
  });

  /// Creates a GameCharacter from JSON data.
  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'] as Map<String, dynamic>;
    return GameCharacter(
      characterName: json['character_name'] as String,
      head: CharacterPart.fromJson(parts['head'] as Map<String, dynamic>),
      torso: CharacterPart.fromJson(parts['torso'] as Map<String, dynamic>),
      legs: CharacterPart.fromJson(parts['legs'] as Map<String, dynamic>),
      feet: CharacterPart.fromJson(parts['feet'] as Map<String, dynamic>),
    );
  }

  /// Converts to JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'character_name': characterName,
      'parts': {
        'head': head.toJson(),
        'torso': torso.toJson(),
        'legs': legs.toJson(),
        'feet': feet.toJson(),
      },
    };
  }
}
