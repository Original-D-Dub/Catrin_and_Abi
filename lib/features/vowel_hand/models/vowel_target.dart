import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';

/// Represents a fingertip target area for a vowel in the BSL hand game.
///
/// Each vowel (a, e, i, o, u) maps to a fingertip on the open hand image.
/// The hit area is a polygon tracing the fingertip from the tip down to the
/// first knuckle, in normalized (0-1) image coordinates so it scales and
/// moves with the displayed hand.
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

  /// Outline of the fingertip (tip to first knuckle) as normalized
  /// coordinates (0.0 - 1.0) relative to the hand image dimensions.
  final List<Offset> outline;

  const VowelTarget({
    required this.id,
    required this.vowel,
    required this.outline,
  });

  /// How far the rounded tip bulges past the straight cut across it, as a
  /// fraction of that cut's length (the Bézier control-arm length). 0.25
  /// keeps the curve on the fingertip's edge in open_hand_left.png for all
  /// five fingers.
  static const double _tipCurve = 0.25;

  /// As [_tipCurve], for the rounded base across the knuckle. Kept lower
  /// because the base is much wider than the tip: 0.15 keeps the curve on
  /// each finger without spilling into the gaps between them or onto a
  /// neighbouring target.
  static const double _baseCurve = 0.15;

  /// Returns the fingertip outline scaled to a hand displayed at [handSize].
  ///
  /// The traced outlines jump straight across the very tip of each finger
  /// (their longest edge) and close with a straight line across the
  /// knuckle. Both are drawn as curves that carry on from the finger's
  /// sides instead, giving a rounded tip and base. Hit testing and the hint
  /// flash both use this path, so they match.
  Path pathForSize(Size handSize) {
    final points = [
      for (final p in outline) Offset(p.dx * handSize.width, p.dy * handSize.height),
    ];

    // The tip is the longest edge between consecutive points, ignoring the
    // closing edge across the knuckle and the end edges, which lack a
    // neighbour on one side to take a direction from.
    var tip = -1;
    var tipLength = 0.0;
    for (var i = 1; i < points.length - 2; i++) {
      final length = (points[i + 1] - points[i]).distance;
      if (length > tipLength) {
        tip = i;
        tipLength = length;
      }
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      if (i - 1 == tip) {
        _curveTo(path, points[i - 2], points[i - 1], points[i], points[i + 1],
            _tipCurve);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    // Rounded base: from the last point back round to the first.
    _curveTo(path, points[points.length - 2], points.last, points.first,
        points[1], _baseCurve);
    return path..close();
  }

  /// Adds a curve from [a] to [b] to [path] whose control points continue
  /// the outline's direction past each end ([aPrev]→[a] and [bNext]→[b]),
  /// so it bulges outward smoothly. [curve] is the control-arm length as a
  /// fraction of the distance from [a] to [b].
  static void _curveTo(
    Path path,
    Offset aPrev,
    Offset a,
    Offset b,
    Offset bNext,
    double curve,
  ) {
    final length = (b - a).distance;
    final c1 = a + _unit(a - aPrev) * length * curve;
    final c2 = b + _unit(b - bNext) * length * curve;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
  }

  static Offset _unit(Offset o) => o.distance == 0 ? Offset.zero : o / o.distance;

  /// Checks if [touchPoint] (in hand-local coordinates) is within the
  /// fingertip outline for a hand displayed at [handSize].
  bool containsPoint(Offset touchPoint, Size handSize) {
    return pathForSize(handSize).contains(touchPoint);
  }
}

/// Constants for the vowel hand game.
///
/// Contains the target positions derived from the PNG image.
/// open_hand_left.png is 823 x 1120 pixels.
class VowelHandConstants {
  VowelHandConstants._();

  /// Pixel width of the open hand image
  static const double imageWidth = 823;

  /// Pixel height of the open hand image
  static const double imageHeight = 1120;

  /// Curved bottom edge of the ribbed cuff, left to right, in normalized
  /// (0-1) image coordinates. Traced from where the cuff's vertical ribbing
  /// ends; used to clip off the sleeve below it.
  static const List<Offset> cuffBottomEdge = [
    Offset(0.115, 0.808), Offset(0.146, 0.819), Offset(0.170, 0.828),
    Offset(0.194, 0.833), Offset(0.219, 0.838), Offset(0.243, 0.842),
    Offset(0.267, 0.844), Offset(0.292, 0.847), Offset(0.316, 0.849),
    Offset(0.340, 0.851), Offset(0.365, 0.852), Offset(0.389, 0.852),
    Offset(0.413, 0.851), Offset(0.437, 0.850), Offset(0.462, 0.848),
    Offset(0.486, 0.844), Offset(0.510, 0.838), Offset(0.535, 0.829),
    Offset(0.559, 0.820),
  ];

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

  /// Fingertip target outlines (normalized 0-1 coordinates).
  /// For a LEFT hand as seen by the player looking at their own palm:
  /// - Thumb is on the LEFT side of the screen
  /// - Little finger is on the RIGHT side of the screen
  ///
  /// Outlines traced from the open_hand_left.png alpha channel, following
  /// each finger's edge from the tip down to the first knuckle:
  /// - Thumb tip (a): leftmost, lower position
  /// - Index tip (e): top-left finger (tallest)
  /// - Middle tip (i): top-center finger
  /// - Ring tip (o): top-right of center
  /// - Little tip (u): rightmost finger
  static const List<VowelTarget> targets = [
    // Thumb tip - 'a' (leftmost, lower position)
    VowelTarget(
      id: 1,
      vowel: 'a',
      outline: [
        Offset(0.074, 0.34), Offset(0.077, 0.331), Offset(0.08, 0.323),
        Offset(0.082, 0.315), Offset(0.083, 0.307), Offset(0.085, 0.299),
        Offset(0.086, 0.291), Offset(0.084, 0.283), Offset(0.085, 0.275),
        Offset(0.083, 0.267), Offset(0.083, 0.259), Offset(0.082, 0.251),
        Offset(0.079, 0.243), Offset(0.076, 0.235), Offset(0.076, 0.227),
        Offset(0.079, 0.218), Offset(0.084, 0.21), Offset(0.094, 0.201),
        Offset(0.114, 0.192), Offset(0.163, 0.189), Offset(0.184, 0.196),
        Offset(0.195, 0.204), Offset(0.204, 0.211), Offset(0.212, 0.219),
        Offset(0.217, 0.227), Offset(0.22, 0.234), Offset(0.222, 0.242),
        Offset(0.224, 0.25), Offset(0.226, 0.258), Offset(0.229, 0.266),
        Offset(0.23, 0.274), Offset(0.231, 0.282), Offset(0.232, 0.29),
        Offset(0.234, 0.298), Offset(0.234, 0.306), Offset(0.233, 0.314),
        Offset(0.234, 0.322), Offset(0.233, 0.33),
      ],
    ),
    // Index finger tip - 'e'
    VowelTarget(
      id: 2,
      vowel: 'e',
      outline: [
        Offset(0.389, 0.15), Offset(0.393, 0.142), Offset(0.398, 0.135),
        Offset(0.403, 0.128), Offset(0.408, 0.121), Offset(0.413, 0.113),
        Offset(0.417, 0.106), Offset(0.422, 0.098), Offset(0.427, 0.091),
        Offset(0.432, 0.084), Offset(0.436, 0.077), Offset(0.442, 0.069),
        Offset(0.447, 0.062), Offset(0.453, 0.055), Offset(0.461, 0.049),
        Offset(0.468, 0.042), Offset(0.478, 0.036), Offset(0.487, 0.03),
        Offset(0.498, 0.024), Offset(0.518, 0.02), Offset(0.554, 0.035),
        Offset(0.557, 0.044), Offset(0.557, 0.052), Offset(0.558, 0.061),
        Offset(0.558, 0.069), Offset(0.558, 0.078), Offset(0.556, 0.086),
        Offset(0.555, 0.094), Offset(0.552, 0.102), Offset(0.548, 0.109),
        Offset(0.545, 0.117), Offset(0.54, 0.124), Offset(0.537, 0.132),
        Offset(0.533, 0.14), Offset(0.529, 0.147), Offset(0.525, 0.155),
        Offset(0.521, 0.162), Offset(0.518, 0.17), Offset(0.514, 0.177),
      ],
    ),
    // Middle finger tip - 'i'
    VowelTarget(
      id: 3,
      vowel: 'i',
      outline: [
        Offset(0.577, 0.15), Offset(0.583, 0.143), Offset(0.588, 0.135),
        Offset(0.593, 0.128), Offset(0.598, 0.121), Offset(0.602, 0.114),
        Offset(0.608, 0.107), Offset(0.613, 0.1), Offset(0.618, 0.093),
        Offset(0.625, 0.086), Offset(0.63, 0.079), Offset(0.634, 0.072),
        Offset(0.639, 0.064), Offset(0.645, 0.057), Offset(0.651, 0.051),
        Offset(0.658, 0.044), Offset(0.668, 0.039), Offset(0.678, 0.033),
        Offset(0.69, 0.028), Offset(0.706, 0.025), Offset(0.765, 0.05),
        Offset(0.766, 0.059), Offset(0.765, 0.068), Offset(0.763, 0.076),
        Offset(0.761, 0.084), Offset(0.758, 0.092), Offset(0.754, 0.1),
        Offset(0.75, 0.107), Offset(0.746, 0.114), Offset(0.742, 0.122),
        Offset(0.737, 0.129), Offset(0.731, 0.136), Offset(0.726, 0.143),
        Offset(0.721, 0.15), Offset(0.717, 0.158), Offset(0.712, 0.165),
        Offset(0.707, 0.172), Offset(0.701, 0.179), Offset(0.697, 0.186),
      ],
    ),
    // Ring finger tip - 'o'
    VowelTarget(
      id: 4,
      vowel: 'o',
      outline: [
        Offset(0.7, 0.226), Offset(0.706, 0.219), Offset(0.711, 0.212),
        Offset(0.717, 0.205), Offset(0.723, 0.199), Offset(0.731, 0.193),
        Offset(0.737, 0.186), Offset(0.743, 0.179), Offset(0.75, 0.173),
        Offset(0.759, 0.167), Offset(0.765, 0.161), Offset(0.773, 0.155),
        Offset(0.782, 0.149), Offset(0.788, 0.142), Offset(0.798, 0.137),
        Offset(0.808, 0.132), Offset(0.819, 0.127), Offset(0.831, 0.123),
        Offset(0.893, 0.142), Offset(0.894, 0.152), Offset(0.893, 0.16),
        Offset(0.894, 0.17), Offset(0.89, 0.178), Offset(0.886, 0.185),
        Offset(0.881, 0.192), Offset(0.877, 0.2), Offset(0.872, 0.207),
        Offset(0.866, 0.214), Offset(0.861, 0.221), Offset(0.854, 0.227),
        Offset(0.849, 0.234), Offset(0.842, 0.24), Offset(0.837, 0.248),
        Offset(0.831, 0.254), Offset(0.825, 0.261), Offset(0.819, 0.268),
      ],
    ),
    // Little finger tip - 'u' (rightmost)
    VowelTarget(
      id: 5,
      vowel: 'u',
      outline: [
        Offset(0.762, 0.391), Offset(0.771, 0.386), Offset(0.778, 0.379),
        Offset(0.786, 0.373), Offset(0.794, 0.366), Offset(0.803, 0.36),
        Offset(0.811, 0.355), Offset(0.82, 0.349), Offset(0.829, 0.344),
        Offset(0.838, 0.339), Offset(0.846, 0.334), Offset(0.854, 0.326),
        Offset(0.862, 0.321), Offset(0.872, 0.316), Offset(0.883, 0.315),
        Offset(0.895, 0.316), Offset(0.909, 0.318), Offset(0.923, 0.322),
        Offset(0.941, 0.331), Offset(0.959, 0.361), Offset(0.954, 0.373),
        Offset(0.946, 0.378), Offset(0.937, 0.384), Offset(0.928, 0.389),
        Offset(0.92, 0.395), Offset(0.912, 0.401), Offset(0.904, 0.409),
        Offset(0.896, 0.415), Offset(0.889, 0.422), Offset(0.88, 0.428),
        Offset(0.872, 0.434), Offset(0.863, 0.439), Offset(0.855, 0.445),
        Offset(0.846, 0.451), Offset(0.838, 0.457), Offset(0.828, 0.461),
        Offset(0.819, 0.466), Offset(0.81, 0.471),
      ],
    ),
  ];

  /// Returns the fingertip target containing [point] (hand-local
  /// coordinates) for a hand displayed at [handSize], or null if none.
  static VowelTarget? targetAt(Offset point, Size handSize) {
    for (final target in targets) {
      if (target.containsPoint(point, handSize)) return target;
    }
    return null;
  }
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
  ),

  /// Ages 1–3, Level 1: a, e and i, each called twice in random order. The
  /// correct fingertip flashes red as a hint; no timer.
  toddlerAei(
    number: 1,
    name: 'First Vowels',
    description: 'a, e, i',
  ),

  /// Ages 1–3, Level 2: all five fingertip vowels, each called twice, with
  /// the same red hint flash; no timer. Also the warm-up Level 1 for ages
  /// 3–5 and 5+.
  toddlerVowels(
    number: 2,
    name: 'Five Vowels',
    description: 'a, e, i, o, u',
  ),

  /// Ages 1–3, Level 3: as Level 2, plus the w and y badges (called four
  /// times each) for IAC. BSL has no w/y, so it gets a shorter hint flash
  /// instead.
  toddlerChallenge(
    number: 3,
    name: 'Vowel Challenge',
    description: 'Quicker hints',
  ),

  /// Ages 1–3, Level 4: 15 random calls from every vowel for the sign
  /// system (including w and y for IAC), with no hint flash; no timer.
  toddlerAll(
    number: 4,
    name: 'All Vowels',
    description: 'No hints',
  ),

  /// Ages 1–3, Level 5: the same five words in the same order every game
  /// (the fixed list in `VowelHandProvider._toddlerFiveWords`), untimed and
  /// ending after 5 words. A wrong guess can be retried, so every round
  /// ends on 5 points.
  toddlerFiveWords(
    number: 5,
    name: 'Five Words',
    description: 'bed, dog, cat, sun, win',
  ),

  /// Ages 1–3, Level 6: the same ten words every game (the fixed list in
  /// `VowelHandProvider._toddlerTenWords`), shuffled into a new random
  /// order each game; untimed and ending after 10 words.
  toddlerTenWords(
    number: 6,
    name: 'Ten Words',
    description: 'The same words, mixed up',
  ),

  /// Ages 1–3, Level 7: the Vowel Words puzzle (missing vowel in a short
  /// word) with words drawn at random from the word pools, untimed and
  /// ending after 10 words. A wrong guess can be retried, so every round
  /// ends on 10 points.
  toddlerWords(
    number: 7,
    name: 'Small Words',
    description: 'Missing vowel',
  );

  /// The level number — for the toddler levels this matches their position
  /// in the ages 1–3 level list, so it keys their translations and stats
  /// the same way they are displayed. (The main levels number 1–6
  /// separately, under their own stats ids.)
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

  /// Whether the correct fingertip/badge flashes red as a hint (ages 1–3,
  /// Levels 1–3).
  bool get hasHint =>
      this == toddlerAei || this == toddlerVowels || this == toddlerChallenge;

  /// Whether this is an ages 1–3 level that calls a fixed number of letters
  /// (Levels 1–4).
  bool get isToddlerMatch => hasHint || this == toddlerAll;

  /// Whether this is one of the untimed ages 1–3 levels.
  bool get isToddler => isToddlerMatch || isToddlerWordLevel;

  /// Whether play is "tap the fingertip for the letter shown" rather than
  /// a word puzzle.
  bool get isVowelMatch => this == vowelMatch || isToddlerMatch;

  /// Whether this is one of the ages 1–3 missing-vowel word levels —
  /// [toddlerWords] and its two fixed-list siblings.
  bool get isToddlerWordLevel => this == toddlerWords || isFixedWords;

  /// Whether this level plays a fixed word list — the same words every
  /// game ([toddlerFiveWords] in a fixed order, [toddlerTenWords] shuffled)
  /// — rather than drawing words at random from a pool.
  bool get isFixedWords =>
      this == toddlerFiveWords || this == toddlerTenWords;

  /// Whether this is the short-word (CVC) missing-vowel puzzle whose words
  /// are drawn from a pool (the local CVC list or Supabase).
  bool get isShortWords => this == vowelWords || this == toddlerWords;

  /// Whether this is one of the word-count-based multi-vowel levels (5 & 6).
  bool get isMultiVowel => this == vowelWordsMulti || this == noMistakes;

  /// Whether this level runs against the countdown timer.
  bool get isTimed => !isToddler && !isMultiVowel;

  /// Returns the main (ages 3+) levels available for the given sign system.
  ///
  /// IAC has Vowel Match, Vowel Words (Welsh CVC/VCC/CCV words), a third
  /// level reusing the `ccvc` slot for the remaining `Geiriau` patterns not
  /// used by Vowel Words, and the two multi-vowel word levels (using the
  /// Welsh multi-vowel word list). Only the CVCC level is BSL/English-only.
  /// The Learn BSL trail indexes into this list by level number.
  static List<VowelHandLevel> forSignSystem(SignSystem signSystem) {
    return signSystem == SignSystem.iac
        ? const [
            VowelHandLevel.vowelMatch,
            VowelHandLevel.vowelWords,
            VowelHandLevel.ccvc,
            VowelHandLevel.vowelWordsMulti,
            VowelHandLevel.noMistakes,
          ]
        : const [
            VowelHandLevel.vowelMatch,
            VowelHandLevel.vowelWords,
            VowelHandLevel.ccvc,
            VowelHandLevel.cvcc,
            VowelHandLevel.vowelWordsMulti,
            VowelHandLevel.noMistakes,
          ];
  }

  /// Returns the levels offered on level select for [ageGroup].
  ///
  /// - 1–3 years: the seven untimed toddler levels — letter levels, the
  ///   three Small Words variants (fixed five words in a fixed order, the
  ///   ten words shuffled, then fully random) — then the timed CCVC word
  ///   level as an eighth step up.
  /// - 3–5 years: a warm-up [toddlerVowels] level, then [toddlerAll]
  ///   (15 vowel calls, no hints), then up to the consonant-cluster word
  ///   levels.
  /// - 5+ years: the same tutorial, then the timed Vowel Match and short
  ///   words, then the cluster levels through to No Mistakes.
  /// - All ages: the same tutorial, then every main level.
  ///
  /// Levels other than the toddler ones are drawn from [forSignSystem], so
  /// IAC still never gets the CVCC level.
  static List<VowelHandLevel> forAgeGroup(
    SignSystem signSystem,
    AgeGroup ageGroup,
  ) {
    if (ageGroup == AgeGroup.years1to3) {
      return const [
        toddlerAei,
        toddlerVowels,
        toddlerChallenge,
        toddlerAll,
        toddlerFiveWords,
        toddlerTenWords,
        toddlerWords,
        ccvc,
      ];
    }
    final levels = forSignSystem(signSystem);
    final allowed = switch (ageGroup) {
      AgeGroup.years3to5 => const {vowelMatch, vowelWords, ccvc, cvcc},
      AgeGroup.years5plus => const {
          vowelMatch,
          vowelWords,
          ccvc,
          cvcc,
          vowelWordsMulti,
          noMistakes,
        },
      _ => levels.toSet(),
    };
    return [
      // Every list except the ages 1–3 one leads with the tutorial level
      // (named "Tutorial" on level select — see the warm-up naming in the
      // screen).
      if (ageGroup == AgeGroup.years3to5 ||
          ageGroup == AgeGroup.years5plus ||
          ageGroup == AgeGroup.all)
        toddlerVowels,
      // Ages 3–5 Level 2: 15 vowel calls with no hints — the same gameplay
      // as the ages 1–3 Level 4.
      if (ageGroup == AgeGroup.years3to5) toddlerAll,
      ...levels.where(allowed.contains),
    ];
  }
}
