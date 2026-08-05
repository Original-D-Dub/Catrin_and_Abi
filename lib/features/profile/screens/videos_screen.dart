import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../models/video_catalog.dart';

/// BSL video library — moved off the main profile page into its own screen,
/// reached via the "Videos" menu item.
class VideosScreen extends StatelessWidget {
  final String locale;

  const VideosScreen({super.key, this.locale = 'en'});

  /// Tablet vs mobile is decided by shortest-side, independent of rotation
  /// (matches `enclosure_walk_layout.dart`'s convention elsewhere in the app).
  static const double _kTabletBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(locale: locale);
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.shortestSide >= _kTabletBreakpoint;
    final isLandscape = mq.orientation == Orientation.landscape;

    // Mobile portrait: full width. Tablet portrait: 2 columns.
    // Landscape: 2 columns on mobile, 3 on tablet.
    final int columns = isLandscape ? (isTablet ? 3 : 2) : (isTablet ? 2 : 1);

    // Breakpoint here is screen width (not the shortest-side tablet check
    // above): <600px wide vs >600px wide, regardless of device type or
    // orientation.
    final bool isWideScreen = mq.size.width > _kTabletBreakpoint;
    final double tileHeight = isWideScreen ? 150 : 120;
    final double titleFontSize = isTablet ? 24 : 18;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1250),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('profile.videos_title'),
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSizes.spacingMedium;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final video in bslVideoCatalog)
                    SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: _VideoTile(
                        video: video,
                        title: t(video.titleKey),
                        titleFontSize: titleFontSize,
                        watchedLabel: t('profile.video.watched'),
                        notWatchedLabel: t('profile.video.not_watched'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final BslVideoTile video;
  final String title;
  final double titleFontSize;
  final String watchedLabel;
  final String notWatchedLabel;

  const _VideoTile({
    required this.video,
    required this.title,
    required this.titleFontSize,
    required this.watchedLabel,
    required this.notWatchedLabel,
  });

  String get _durationLabel {
    final minutes = video.duration.inMinutes;
    final seconds = video.duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: video.placeholderColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (video.backgroundImagePath != null)
            Positioned.fill(
              child: Image.asset(video.backgroundImagePath!, fit: BoxFit.cover),
            ),
          // Scrim so the overlaid text stays legible over any background image.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 100,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _durationLabel,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      video.watched ? Icons.check_circle : Icons.play_circle_outline,
                      size: 14,
                      color: video.watched ? const Color(0xFF69F0AE) : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video.watched ? watchedLabel : notWatchedLabel,
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
