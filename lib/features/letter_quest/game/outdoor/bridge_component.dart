import 'package:flame/components.dart';

/// Purely visual bridge component — no collision hitbox.
///
/// Bridges are rendered by [OutdoorTerrainComponent] in the terrain
/// canvas layer. This component exists only as a positional marker
/// in the world for potential future interactions (e.g., sound effects
/// when crossing).
///
/// The player walks through freely because there is no hitbox.
/// Water collision segments are not placed at bridge grid cells,
/// which is what actually allows crossing.
class BridgeComponent extends PositionComponent {
  /// Creates a bridge marker at the given position.
  BridgeComponent({
    required super.position,
    required super.size,
  });
}
