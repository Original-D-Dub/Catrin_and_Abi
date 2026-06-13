import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';
import '../models/letter_bingo_level.dart';

/// A square tile displaying a hand sign or the revealed letter.
///
/// **Unrevealed state**: hand sign image (BSL or IAC, per [signSystem])
/// inside a coloured border with rounded corners. Responsive sizing:
/// - **< 600px**: 4px border, 8px radius, 4px inner padding
/// - **>= 600px**: 6px border, 16px radius, 8px inner padding
///
/// **Revealed state**: The letter (or Welsh digraph) in large bold text on
/// a white background.
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= _wideBreakpoint;

    final borderWidth = isWide ? 6.0 : 4.0;
    final borderRadius = isWide ? 16.0 : 8.0;
    final innerPadding = isWide ? 8.0 : 4.0;

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
                innerPadding: innerPadding,
              )
            : _buildUnrevealedTile(
                borderWidth: borderWidth,
                borderRadius: borderRadius,
                innerPadding: innerPadding,
              ),
      ),
    );
  }

  /// Builds the unrevealed tile — BSL hand sign with coloured border.
  Widget _buildUnrevealedTile({
    required double borderWidth,
    required double borderRadius,
    required double innerPadding,
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
          border: Border.all(
            color: tileColor,
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: innerPadding,
              vertical: innerPadding * 3,
            ),
            child: BslAlphabetSvg(
              letter: tile.letter,
              signSystem: signSystem,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the revealed tile showing the letter.
  Widget _buildRevealedTile({
    required double borderWidth,
    required double borderRadius,
    required double innerPadding,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        key: const ValueKey('revealed'),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: tileColor,
            width: borderWidth,
          ),
        ),
        child: Center(
          child: Text(
            tile.letter.toLowerCase(),
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: tile.letter.length > 1 ? 32 : 48,
              fontWeight: FontWeight.w900,
              color: tileColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns a distinct bright colour for a tile based on its index.
///
/// Cycles through the brand accent colours to give each tile
/// a unique, vibrant appearance.
///
/// Parameters:
/// - [index]: The tile index (0-based)
Color tileColorForIndex(int index) {
  const colors = [
    AppColors.accentRed,
    AppColors.accentNavyBlue,
    AppColors.accentLimeGreen,
    AppColors.accentOrange,
    AppColors.accentPurple,
    AppColors.abiPink,
    AppColors.catrinBlue,
    AppColors.connectorGold,
    AppColors.schoolGreen,
  ];
  return colors[index % colors.length];
}
