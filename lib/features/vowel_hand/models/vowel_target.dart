import 'package:flutter/material.dart';

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

  /// Minimum hit target radius (diameter 80px for easier touch targets)
  static const double minHitRadius = 40.0;

  /// Game duration in seconds
  static const int gameDurationSeconds = 60;

  /// Duration to show pointer after touch release (milliseconds)
  static const int pointerLingerDuration = 400;

  /// All vowels used in the game
  static const List<String> vowels = ['a', 'e', 'i', 'o', 'u'];

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
      normalizedPosition: Offset(0.31, 0.12),
      hitRadius: minHitRadius,
    ),
    // Middle finger tip - 'i' (tallest finger)
    VowelTarget(
      id: 3,
      vowel: 'i',
      normalizedPosition: Offset(0.55, 0.05),
      hitRadius: minHitRadius,
    ),
    // Ring finger tip - 'o'
    VowelTarget(
      id: 4,
      vowel: 'o',
      normalizedPosition: Offset(0.79, 0.13),
      hitRadius: minHitRadius,
    ),
    // Little finger tip - 'u' (rightmost)
    VowelTarget(
      id: 5,
      vowel: 'u',
      normalizedPosition: Offset(0.95, 0.34),
      hitRadius: minHitRadius,
    ),
  ];
}

/// Game levels for the BSL Vowels (vowel hand) game.
///
/// - **Vowel Match (Level 1)**: The original gameplay. A vowel letter is shown
///   at the bottom of the screen, and the player taps the corresponding
///   fingertip on the BSL hand.
///
/// - **Vowel Words (Level 2)**: A 3-letter CVC word is shown with the middle
///   vowel replaced by an underscore (e.g., "c_t"). The player must tap the
///   correct fingertip to identify the missing vowel.
enum VowelHandLevel {
  /// Level 1: Match the vowel shown to the correct fingertip
  vowelMatch(
    number: 1,
    name: 'Vowel Match',
    description: 'Tap the right fingertip!',
  ),

  /// Level 2: Find the missing vowel in a CVC word
  vowelWords(
    number: 2,
    name: 'Vowel Words',
    description: 'Find the missing vowel!',
  );

  /// The level number (1 or 2)
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
}
