import 'character_part.dart';

/// Represents a mixed-up character created from parts of different characters.
///
/// The identity of the mixed character is determined by whose head is used.
class MixedCharacter {
  /// The name of the character (from whoever provided the head)
  final String identityName;

  /// The head part (determines identity)
  final CharacterPart head;

  /// The torso part (can be from any character)
  final CharacterPart torso;

  /// The legs part (can be from any character)
  final CharacterPart legs;

  /// The feet part (can be from any character)
  final CharacterPart feet;

  /// Name of the character who provided the head
  final String headSource;

  /// Name of the character who provided the torso
  final String torsoSource;

  /// Name of the character who provided the legs
  final String legsSource;

  /// Name of the character who provided the feet
  final String feetSource;

  const MixedCharacter({
    required this.identityName,
    required this.head,
    required this.torso,
    required this.legs,
    required this.feet,
    required this.headSource,
    required this.torsoSource,
    required this.legsSource,
    required this.feetSource,
  });

  /// Returns all parts as a list (top to bottom).
  List<CharacterPart> get allParts => [head, torso, legs, feet];

  /// Returns all source names for debugging.
  List<String> get allSources => [headSource, torsoSource, legsSource, feetSource];
}
