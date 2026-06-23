import 'package:flame/components.dart';

/// A desk that Pero can walk under but Gary cannot.
///
/// [PlayerComponent] ignores collision with this entirely.
/// [GaryComponent] always collides with it.
/// Renders above the player (priority 2) so Pero appears to pass underneath.
class DeskComponent extends PositionComponent {
  DeskComponent({required super.position, required super.size})
      : super(priority: 2);
}
