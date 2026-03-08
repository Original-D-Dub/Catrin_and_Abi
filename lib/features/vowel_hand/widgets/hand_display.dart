import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/asset_paths.dart';
import '../models/vowel_target.dart';

/// Displays the open hand SVG with fingertip hit targets for vowel selection.
///
/// The widget renders the hand image and overlays green bordered circles
/// at each fingertip position to show the hit target areas.
///
/// The hand displays with fingers spread, showing the BSL vowel positions:
/// - Thumb: 'a'
/// - Index finger: 'e'
/// - Middle finger: 'i'
/// - Ring finger: 'o'
/// - Little finger: 'u'
class HandDisplay extends StatelessWidget {
  /// Callback when the widget size is determined
  final ValueChanged<Size>? onSizeChanged;

  const HandDisplay({
    super.key,
    this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the size maintaining aspect ratio
        final aspectRatio = VowelHandConstants.svgViewBoxWidth /
            VowelHandConstants.svgViewBoxHeight;

        double width = constraints.maxWidth;
        double height = width / aspectRatio;

        // If height exceeds available space, constrain by height instead
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * aspectRatio;
        }

        final size = Size(width, height);

        // Notify parent of size for coordinate calculations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSizeChanged?.call(size);
        });

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // The hand SVG image
              Positioned.fill(
                child: SvgPicture.asset(
                  AssetPaths.vowelHandOpen,
                  fit: BoxFit.contain,
                ),
              ),

              // Hit targets at each fingertip (invisible, for touch detection reference)
              // Uncomment below to show hit target outlines for debugging:
              // ...VowelHandConstants.targets.map((target) {
              //   final position = Offset(
              //     target.normalizedPosition.dx * width,
              //     target.normalizedPosition.dy * height,
              //   );
              //   return Positioned(
              //     left: position.dx - target.hitRadius,
              //     top: position.dy - target.hitRadius,
              //     child: Container(
              //       width: target.hitRadius * 2,
              //       height: target.hitRadius * 2,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: Colors.green,
              //           width: 2,
              //         ),
              //       ),
              //     ),
              //   );
              // }),
            ],
          ),
        );
      },
    );
  }
}
