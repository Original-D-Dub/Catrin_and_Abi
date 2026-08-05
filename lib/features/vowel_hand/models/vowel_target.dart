import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';

/// Represents a fingertip target area for a vowel in the BSL hand game.
///
/// Each vowel (a, e, i, o, u) maps to a specific fingertip position on
/// the open hand SVG. The position is relative to the SVG viewBox coordinates
/// and the hitRadius determines the touch detection area.
///
/// Fingertip mapping (left hand, player looking at own palm - thumb on LEFT):
/// - Thumb tip (LEFT side): 'a'
/// - Index finger tip: 'e'
/// - Middle finger tip (center, tallest): 'i'
/// - Ring finger tip: 'o'
/// - Little finger tip (RIGHT side): 'u'
class VowelTarget {
  /// Unique identifier for this target (1-5)
  final int id;

  /// The lowercase vowel character this target represents
  final String vowel;

  /// Position of the fingertip center relative to the SVG viewBox
  /// These are normalized coordinates (0.0 - 1.0) relative to viewBox dimensions
  final Offset normalizedPosition;

  /// The radius of the hit detection area in logical pixels
  /// Minimum 40px (diameter 80px) for easier touch targets
  final double hitRadius;

  const VowelTarget({
    required this.id,
    required this.vowel,
    required this.normalizedPosition,
    this.hitRadius = 40.0,
  });

  /// Checks if a touch point is within the hit target area.
  ///
  /// [touchPoint] is the touch position in the same coordinate space
  /// as the target position (after coordinate transformation).
  /// [scaledRadius] is the hit radius scaled to the current display size.
  bool containsPoint({
    required Offset touchPoint,
    required Offset scaledPosition,
    required double scaledRadius,
  }) {
    final distance = (touchPoint - scaledPosition).distance;
    return distance <= scaledRadius;
  }
}

/// Constants for the vowel hand game.
///
/// Contains the target positions derived from the SVG coordinates.
/// The open hand-left.svg has viewBox="0 0 695.94 726.2"
class VowelHandConstants {
  VowelHandConstants._();

  /// SVG viewBox width for the open hand image
  static const double svgViewBoxWidth = 695.94;

  /// SVG viewBox height for the open hand image
  static const double svgViewBoxHeight = 726.2;

  /// Minimum hit target radius (diameter 96 for easier touch targets)
  static const double minHitRadius = 56.0;

  /// Game duration in seconds
  static const int gameDurationSeconds = 60;

  /// Duration to show pointer after touch release (milliseconds)
  static const int pointerLingerDuration = 400;

  /// All vowels used in the game (BSL — fingertip targets only)
  static const List<String> vowels = ['a', 'e', 'i', 'o', 'u'];

  /// All Welsh vowels (IAC). Includes 'w' and 'y', which have no fingertip
  /// target and are matched via on-screen badges instead.
  static const List<String> iacVowels = ['a', 'e', 'i', 'o', 'u', 'w', 'y'];

  /// Returns the vowels to cycle through for the given sign system.
  static List<String> vowelsForSignSystem(SignSystem signSystem) {
    return signSystem == SignSystem.iac ? iacVowels : vowels;
  }

  /// Fingertip target positions (normalized 0-1 coordinates).
  /// For a LEFT hand as seen by the player looking at their own palm:
  /// - Thumb is on the LEFT side of the screen
  /// - Little finger is on the RIGHT side of the screen
  ///
  /// Coordinates derived from the open hand-left.svg path data:
  /// - Thumb tip (a): leftmost, lower position
  /// - Index tip (e): top-left finger
  /// - Middle tip (i): top-center finger (tallest)
  /// - Ring tip (o): top-right of center
  /// - Little tip (u): rightmost finger
  static const List<VowelTarget> targets = [
    // Thumb tip - 'a' (leftmost, lower position)
    VowelTarget(
      id: 1,
      vowel: 'a',
      normalizedPosition: Offset(0.08, 0.55),
      hitRadius: minHitRadius,
    ),
    // Index finger tip - 'e'
    VowelTarget(
      id: 2,
      vowel: 'e',
      normalizedPosition: Offset(0.32, 0.14),
      hitRadius: minHitRadius,
    ),
    // Middle finger tip - 'i' (tallest finger)
    VowelTarget(
      id: 3,
      vowel: 'i',
      normalizedPosition: Offset(0.57, 0.08),
      hitRadius: minHitRadius,
    ),
    // Ring finger tip - 'o'
    VowelTarget(
      id: 4,
      vowel: 'o',
      normalizedPosition: Offset(0.77, 0.16),
      hitRadius: minHitRadius,
    ),
    // Little finger tip - 'u' (rightmost)
    VowelTarget(
      id: 5,
      vowel: 'u',
      normalizedPosition: Offset(0.95, 0.36),
      hitRadius: minHitRadius,
    ),
  ];
}

/// Game levels for the BSL Vowels (vowel hand) game.
enum VowelHandLevel {
  /// Level 1: Match the vowel shown to the correct fingertip
  vowelMatch(
    number: 1,
    name: 'Vowel Match',
    description: 'Tap the fingertips',
  ),

  /// Level 2: Find the missing vowel in a CVC word
  vowelWords(
    number: 2,
    name: 'Vowel Words',
    description: 'Missing vowel',
  ),

  /// Level 3: Find the missing vowel in a CCVC word (e.g. fr_g)
  ccvc(
    number: 3,
    name: 'CCVC Words',
    description: 'Consonant cluster + vowel',
  ),

  /// Level 4: Find the missing vowel in a CVCC word (e.g. f_st)
  cvcc(
    number: 4,
    name: 'CVCC Words',
    description: 'Vowel + consonant cluster',
  ),

  /// Level 5: Find every vowel in a word — all vowels are blanked at once
  /// and must be revealed one vowel-character at a time.
  vowelWordsMulti(
    number: 5,
    name: 'All Vowels',
    description: 'Find every vowel in the word',
  ),

  /// Level 6: Same puzzle as Level 5, but a word only scores if guessed
  /// with no mistakes; points scale with word length.
  noMistakes(
    number: 6,
    name: 'No Mistakes',
    description: 'More points for longer words',
  );

  /// The level number (1–6)
  final int number;

  /// Display name for the level
  final String name;

  /// Short description shown on level select
  final String description;

  const VowelHandLevel({
    required this.number,
    required this.name,
    required this.description,
  });

  /// Returns the levels available for the given sign system.
  ///
  /// IAC has Vowel Match, Vowel Words (Welsh CVC/VCC/CCV words), a third
  /// level reusing the `ccvc` slot for the remaining `Geiriau` patterns not
  /// used by Vowel Words, and the two multi-vowel word levels (using the
  /// Welsh multi-vowel word list). Only the CVCC level is BSL/English-only.
  static List<VowelHandLevel> forSignSystem(SignSystem signSystem) {
    return signSystem == SignSystem.iac
        ? const [
            VowelHandLevel.vowelMatch,
            VowelHandLevel.vowelWords,
            VowelHandLevel.ccvc,
            VowelHandLevel.vowelWordsMulti,
            VowelHandLevel.noMistakes,
          ]
        : VowelHandLevel.values;
  }
}
