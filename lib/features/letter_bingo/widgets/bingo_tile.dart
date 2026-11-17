import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import '../models/letter_bingo_level.dart';
import '../../../core/theme/digraph_letter_spacing.dart';

/// A square tile displaying a hand sign or the revealed letter.
///
/// **Unrevealed state**: hand sign image (BSL or IAC, per [signSystem])
/// inside a coloured border with rounded corners, with no padding so the
/// sign is as large as the tile allows. Responsive sizing:
/// - **Devices < 600px** (shortest side — phones, in either orientation):
///   4px border, 8px radius
/// - **Devices >= 600px** (tablets): 6px border, 16px radius
///
/// **Revealed state**: The letter (or Welsh digraph) in bold text on a white
/// background, scaled to fill the tile (4px inner padding).
///
/// Both states scale with the tile like the card-match [GameCard]: the
/// content gets the tile's tight constraints and a `BoxFit.contain` fit,
/// with no [Center] to loosen them (which would stop it growing).
///
/// Uses [AnimatedSwitcher] for a smooth transition between states.
///
/// Parameters:
/// - [tile]: The [BingoTile] data (letter, reveal state)
/// - [onTap]: Called when the tile is tapped (null if not interactive)
/// - [tileColor]: The accent colour for the tile border
/// - [signSystem]: Which hand-sign family to display (BSL or IAC)
class BingoTileWidget extends StatelessWidget {
  /// The tile data to display
  final BingoTile tile;

  /// Callback when the tile is tapped
  final VoidCallback? onTap;

  /// Accent colour for the tile border
  final Color tileColor;

  /// Sign system used for the unrevealed hand-sign image (BSL or IAC).
  final SignSystem signSystem;

  /// Screen width breakpoint for responsive sizing
  static const double _wideBreakpoint = 600;

  const BingoTileWidget({
    super.key,
    required this.tile,
    required this.onTap,
    required this.tileColor,
    this.signSystem = SignSystem.bsl,
  });

  @override
  Widget build(BuildContext context) {
    // Shortest side, not width: a landscape phone is wider than 600px but
    // should still get the phone-sized 4px border.
    final isWide = MediaQuery.sizeOf(context).shortestSide >= _wideBreakpoint;

    final borderWidth = isWide ? 6.0 : 4.0;
    final borderRadius = isWide ? 16.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: tile.isRevealed
            ? _buildRevealedTile(
                borderWidth: borderWidth,
                borderRadius: borderRadius,
              )
            : _buildUnrevealedTile(
                borderWidth: borderWidth,
                borderRadius: borderRadius,
              ),
      ),
    );
  }

  /// Builds the unrevealed tile — BSL hand sign with coloured border.
  Widget _buildUnrevealedTile({
    required double borderWidth,
    required double borderRadius,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        key: const ValueKey('unrevealed'),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: tileColor, width: borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: SignLetterImage(letter: tile.letter, fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// Builds the revealed tile showing the letter.
  Widget _buildRevealedTile({
    required double borderWidth,
    required double borderRadius,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        key: const ValueKey('revealed'),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: tileColor, width: borderWidth),
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            tile.letter.toLowerCase(),
            style: digraphAwareStyle(
              tile.letter.toLowerCase(),
              TextStyle(
                fontFamily: 'OpenDyslexic',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: tileColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns a distinct bright colour for a tile based on its index.
///
/// Cycles through [bingoTilePalette] to give each tile a unique, vibrant
/// appearance.
///
/// Parameters:
/// - [index]: The tile index (0-based)
Color tileColorForIndex(int index) =>
    bingoTilePalette[index % bingoTilePalette.length];

/// [colour] blended 50% towards white — a paler but still solid version,
/// for the parts of the player card outside the row being checked.
Color paleBingoColour(Color colour) => Color.lerp(colour, Colors.white, 0.5)!;

/// A blank bingo square: a solid block of [color] with no letter, shaped
/// like a [BingoTileWidget] (same responsive corner radius). Not tappable.
class BingoBlankTile extends StatelessWidget {
  final Color color;

  const BingoBlankTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).shortestSide >=
        BingoTileWidget._wideBreakpoint;
    return AspectRatio(
      aspectRatio: 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isWide ? 16.0 : 8.0),
        ),
      ),
    );
  }
}

/// A square on a multiplayer player card: the [tile]'s printed letter on a
/// white tile with a [tileColor] border and letter.
///
/// Marked ([BingoTile.isRevealed]), a bingo "dab" appears behind the
/// letter: an irregular, almost circular blob of [tileColor] at 40%
/// opacity, popping in with a small scale animation. Each tile's blob has
/// its own wobble, fixed for that tile so it doesn't change on rebuild.
///
/// [dimmed] (rows not being checked) draws the letter at 50% opacity and
/// the border 50% paler (blended towards white, so it stays solid); the
/// white tile and the dab stay as they are.
///
/// [showSign] (checking view, winning row) swaps the letter for its BSL/IAC
/// hand sign, with a quick fade, and hides the dab while it's shown.
class PlayerBingoTile extends StatelessWidget {
  final BingoTile tile;
  final Color tileColor;
  final VoidCallback? onTap;
  final bool dimmed;
  final bool showSign;

  const PlayerBingoTile({
    super.key,
    required this.tile,
    required this.tileColor,
    required this.onTap,
    this.dimmed = false,
    this.showSign = false,
  });

  static const double _dabOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).shortestSide >=
        BingoTileWidget._wideBreakpoint;
    final borderWidth = isWide ? 6.0 : 4.0;
    final borderRadius = isWide ? 16.0 : 8.0;
    final marked = tile.isRevealed;
    final letter = tile.letter.toLowerCase();

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: dimmed ? paleBingoColour(tileColor) : tileColor,
              width: borderWidth,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The dab, scaling in when marked and out when unmarked.
              TweenAnimationBuilder<double>(
                // Hidden while the sign is showing, so it doesn't sit
                // behind the hand shape.
                tween: Tween(end: marked && !showSign ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 250),
                curve: marked ? Curves.easeOutBack : Curves.easeIn,
                builder: (context, t, _) => t <= 0
                    ? const SizedBox.shrink()
                    : Transform.scale(
                        scale: t,
                        child: CustomPaint(
                          painter: _DabPainter(
                            color: tileColor.withValues(alpha: _dabOpacity),
                            seed: Object.hash(tile.letter, tile.row, tile.col),
                          ),
                        ),
                      ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showSign
                    ? Padding(
                        key: const ValueKey('sign'),
                        padding: const EdgeInsets.all(2),
                        child: SignLetterImage(letter: tile.letter),
                      )
                    : _buildLetter(letter),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetter(String letter) {
    return Padding(
      key: const ValueKey('letter'),
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          letter,
          style: digraphAwareStyle(
            letter,
            TextStyle(
              fontFamily: 'OpenDyslexic',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: tileColor.withValues(alpha: dimmed ? 0.5 : 1.0),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints an irregular, almost circular blob — like a bingo dabber's mark —
/// filling most of the tile. Points around a circle get a random radius
/// (from [seed], so the same tile always gets the same shape) and are
/// joined with a smooth closed curve.
class _DabPainter extends CustomPainter {
  final Color color;
  final int seed;

  const _DabPainter({required this.color, required this.seed});

  static const int _points = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final centre = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.42;
    final rotation = rng.nextDouble() * 2 * pi;

    final points = List.generate(_points, (i) {
      final angle = rotation + i * 2 * pi / _points;
      final r = baseRadius * (0.86 + rng.nextDouble() * 0.16);
      return centre + Offset(cos(angle), sin(angle)) * r;
    });

    // Closed Catmull-Rom spline through the points, as cubic Béziers.
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < _points; i++) {
      final p0 = points[(i - 1 + _points) % _points];
      final p1 = points[i];
      final p2 = points[(i + 1) % _points];
      final p3 = points[(i + 2) % _points];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DabPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.seed != seed;
}
