import 'package:flutter/material.dart';

/// A collectable sports card, won from treasure chests on the Bubble
/// Shooter level map. [id] matches the `sport_id` values allowed in the
/// `sports_collection` Supabase table.
enum SportCard {
  football('football', Icons.sports_soccer, Color(0xFF2E9E4F)),
  netball('netball', Icons.sports_basketball, Color(0xFFE6542E)),
  rugby('rugby', Icons.sports_rugby, Color(0xFF8B5A2B)),
  hockey('hockey', Icons.sports_hockey, Color(0xFF3979A7)),
  sprinting('sprinting', Icons.directions_run, Color(0xFFD6336C)),
  swimming('swimming', Icons.pool, Color(0xFF1AA6C9));

  const SportCard(this.id, this.icon, this.colour);

  final String id;

  /// Icon on the placeholder card art.
  final IconData icon;

  /// Felt colour of the placeholder card art.
  final Color colour;

  /// Translation key for the sport's name.
  String get nameKey => 'sports.$id';

  /// Where real artwork for this card goes. When the file isn't there the
  /// felt placeholder (icon on [colour]) is shown instead.
  String get imageAsset => 'assets/images/sports_cards/$id.png';

  static SportCard? fromId(String id) {
    for (final card in values) {
      if (card.id == id) return card;
    }
    return null;
  }
}
