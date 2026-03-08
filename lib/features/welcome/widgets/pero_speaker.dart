import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/widgets/character_image.dart';
import 'speech_bubble.dart';

/// Displays Pero's introduction with timed image swap and delayed speech bubble.
///
/// Sequence:
/// 1. Shows Pero profile image immediately
/// 2. After 1 second, shows "Woof!" speech bubble
/// 3. After 2 seconds, instantly swaps to default (with jacket) image
///
/// Both images use an identical fixed-size container so the swap
/// looks like Pero turning his head.
class PeroSpeaker extends StatefulWidget {
  final double characterHeight;

  const PeroSpeaker({
    super.key,
    this.characterHeight = AppSizes.characterHeightWelcome,
  });

  @override
  State<PeroSpeaker> createState() => _PeroSpeakerState();
}

class _PeroSpeakerState extends State<PeroSpeaker> {
  bool _showSpeechBubble = false;
  bool _showDefaultImage = false;
  Timer? _speechTimer;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    _speechTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showSpeechBubble = true);
    });
    _imageTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showDefaultImage = true);
    });
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final characterFlex = screenWidth < 600 ? 0.35 : 0.3;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          final characterWidth = availableWidth * characterFlex;
          final effectiveHeight = availableHeight.isFinite
              ? availableHeight.clamp(0.0, widget.characterHeight)
              : widget.characterHeight;

          return SizedBox(
            height: effectiveHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fixed-size container so both images occupy the same space
                SizedBox(
                  width: characterWidth,
                  height: effectiveHeight,
                  child: CharacterImage(
                    assetPath: _showDefaultImage
                        ? AssetPaths.peroDefault
                        : AssetPaths.peroProfile,
                    fit: BoxFit.contain,
                    semanticLabel: 'Pero the hearing dog',
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                // Speech bubble with fade-in
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showSpeechBubble ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const SpeechBubble(
                      text: 'Woof!',
                      pointDirection: PointDirection.left,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
