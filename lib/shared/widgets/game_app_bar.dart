import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../services/audio_service.dart';

/// Transparent AppBar used on game screens.
///
/// Renders a transparent, zero-elevation AppBar with a white back arrow and
/// a centred ComicRelief title — the standard style across all game screens.
class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const GameAppBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.accentWhite,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.accentWhite),
        onPressed: () {
          AudioService.stopAll();
          onBack();
        },
      ),
    );
  }
}
