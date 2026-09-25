/// A single bingo reward animal loaded from Supabase (`bsl_bingo_rewards` for
/// BSL, `gwobrau_bingo_iac` for IAC — see `BingoRewardsService`).
class Animal {
  final String id;   // reward row id — used as reward_id when saved to a player inventory
  final String letter; // uppercase, e.g. 'C'
  final String name;   // e.g. 'Cat'
  final String imageUrl;       // resolved Supabase Storage public URL
  final String placeholderUrl; // fallback image URL when imageUrl fails to load

  const Animal({
    required this.id,
    required this.letter,
    required this.name,
    required this.imageUrl,
    required this.placeholderUrl,
  });
}
