import 'package:flame/components.dart';

/// A bed that blocks Gary but lets Pero jump onto it.
///
/// [PlayerComponent] ignores collision with this while jumping.
/// [GaryComponent] always collides with it, so beds act as safe zones.
class BedComponent extends PositionComponent {
  BedComponent({required super.position, required super.size});
}
