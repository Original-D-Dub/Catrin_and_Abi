// A/B test duplicate of lib/features/colouring/. To remove this variant,
// delete lib/features/colouring2/ and grep the repo for "colouring2" to find
// the route, home tile, translation keys, and GameIds entry.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/circular_video_container.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/colouring_page.dart';
import '../providers/colouring2_provider.dart';
import '../widgets/colour_palette.dart';
import '../widgets/colouring_canvas.dart';

class Colouring2Screen extends StatefulWidget {
  const Colouring2Screen({super.key});

  @override
  State<Colouring2Screen> createState() => _Colouring2ScreenState();
}

class _Colouring2ScreenState extends State<Colouring2Screen> {
  static const double _kCircleSize = 200.0;
  static const double _kButtonSize = 36.0;
  static const double _kTabletScale = 1.5;
  static const double _kTabletBreakpoint = 600.0;

  // ── Colour → BSL video name (free-colour mode) ────────────────────────────
  static final Map<Color, String> _videoName = {
    AppColors.lightPink:      'pink',
    AppColors.accentRed:      'red',
    AppColors.accentOrange:   'orange',
    AppColors.accentYellow:   'yellow',
    AppColors.accentNavyBlue: 'blue',
    AppColors.schoolGreen:    'green',
    AppColors.accentPurple:   'purple',
    Colors.brown:             'brown',
    AppColors.lightGrey:      'grey',
    Color(0xFFFFFFFF):        'white',
    Color(0xFF000000):        'black',
  };

  static const Set<String> _availableVideos = {
    'red', 'orange', 'yellow', 'blue', 'green', 'purple',
    'pink', 'brown', 'grey', 'white', 'black',
  };

  static String? _videoPath(Color colour) {
    final name = _videoName[colour];
    if (name == null || !_availableVideos.contains(name)) return null;
    return 'assets/colours_video/$name.mov';
  }

  static String _label(Color colour) {
    final name = _videoName[colour];
    if (name == null) return 'Miss Angela';
    return name[0].toUpperCase() + name.substring(1);
  }

  double _scale(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kTabletBreakpoint
          ? _kTabletScale
          : 1.0;

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    return Consumer<Colouring2Provider>(
      builder: (context, provider, child) {
        if (provider.showLevelSelect) return _buildLevelSelect(provider);
        if (provider.currentLevel == ColouringLevel.bslColours) {
          return _buildLevel1(provider, scale);
        }
        return _buildFreeColour(provider, scale);
      },
    );
  }

  // ── Level select ──────────────────────────────────────────────────────────

  Widget _buildLevelSelect(Colouring2Provider provider) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GameAppBar(
        title: AppLocalizations.of(context)('colouring2.title'),
        onBack: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LevelSelectScreen(
            levels: ColouringLevel.values.map((level) => LevelSelectItem(
              number: level.number,
              name: level.name,
              description: level.description,
              color: levelColor(level.number - 1),
              onTap: () => provider.startLevel(level),
            )).toList(),
          ),
        ),
      ),
    );
  }

  // ── Level 1: BSL Colours ──────────────────────────────────────────────────

  Widget _buildLevel1(Colouring2Provider provider, double scale) {
    final target = provider.currentBslColour;
    final videoPath = 'assets/colours_video/${target.videoName}.mov';

    // Two rows of 4 from bslColourList
    final l1Rows = [
      bslColourList.take(4).map((c) => c.colour).toList(),
      bslColourList.skip(4).map((c) => c.colour).toList(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    GameHeaderBar(
                      onBack: provider.showLevelSelection,
                      scoreValue: '${provider.score}',
                      levelNumber: ColouringLevel.bslColours.number,
                      centerContent: const Center(
                        child: Text(
                          'BSL Colours',
                          style: TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Canvas
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSmall, vertical: AppSizes.paddingMedium),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.headerBackgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.headerBorderDark, width: 2),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.headerBorderDark, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildCanvasArea(provider),
                          ),
                        ),
                      ),
                    ),

                    // Wrong-guess message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: provider.wrongGuessMessage != null
                          ? _WrongGuessMessage(
                              key: ValueKey(provider.wrongGuessMessage),
                              message: provider.wrongGuessMessage!,
                            )
                          : const SizedBox(height: 0),
                    ),

                    // Palette — Level 1 colours only
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSizes.paddingSmall,
                          top: 6,
                          bottom: 8,
                        ),
                        child: ColourPalette(
                          colourRows: l1Rows,
                          selectedColour: provider.selectedColour,
                          onColourSelected: provider.selectColour,
                          buttonSize: _kButtonSize * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Video circle — target colour, auto-plays on advance
              Positioned(
                bottom: -50,
                right: -20,
                child: CircularVideoContainer(
                  key: ValueKey(provider.colourChangeGeneration),
                  size: _kCircleSize * scale,
                  videoAssetPath: videoPath,
                  label: target.name,
                  autoPlay: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Level 2: Free colour ──────────────────────────────────────────────────

  Widget _buildFreeColour(Colouring2Provider provider, double scale) {
    if (provider.showImageGrid) {
      return _buildImageSelectionScreen(provider);
    }
    return _buildFreeColourCanvas(provider, scale);
  }

  Widget _buildImageSelectionScreen(Colouring2Provider provider) {
    final pages = ColouringPage.allPages();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: provider.showLevelSelection,
        ),
        title: const Text(
          'Choose a picture',
          style: TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return _ThumbnailCard(
                  page: page,
                  onTap: () => provider.selectImageFromGrid(page),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeColourCanvas(Colouring2Provider provider, double scale) {
    final videoPath = _videoPath(provider.selectedColour);
    final label = _label(provider.selectedColour);

    final mapped = Colouring2Provider.paletteColourRows
        .expand((row) => row)
        .where(_videoName.containsKey)
        .toList();
    final paletteRows = <List<Color>>[
      mapped.take(5).toList(),
      if (mapped.length > 5) mapped.skip(5).toList(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    GameHeaderBar(
                      onBack: provider.returnToImageGrid,
                      showScore: false,
                      levelNumber: ColouringLevel.freeColour.number,
                      centerContent: Center(
                        child: Text(
                          provider.currentPage?.name ?? 'Colouring',
                          style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSmall, vertical: AppSizes.paddingMedium),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.headerBackgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.headerBorderDark, width: 2),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.headerBorderDark, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildCanvasArea(provider),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSizes.paddingSmall,
                          top: 8,
                          bottom: 8,
                        ),
                        child: ColourPalette(
                          colourRows: paletteRows,
                          selectedColour: provider.selectedColour,
                          onColourSelected: provider.selectColour,
                          buttonSize: _kButtonSize * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -50,
                right: -20,
                child: CircularVideoContainer(
                  size: _kCircleSize * scale,
                  videoAssetPath: videoPath,
                  label: label,
                  autoPlay: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared canvas area ────────────────────────────────────────────────────

  Widget _buildCanvasArea(Colouring2Provider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.abiPink),
      );
    }
    if (!provider.isReady || provider.originalImage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported,
                size: AppSizes.iconXLarge, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.spacingMedium),
            const Text('No image loaded',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontSizeBody)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: ColouringCanvas(
        image: provider.originalImage!,
        onTap: (point, displaySize) => provider.fillAtPoint(
          point: point,
          imageSize: Size(
            provider.imageWidth.toDouble(),
            provider.imageHeight.toDouble(),
          ),
          displaySize: displaySize,
        ),
      ),
    );
  }

}

// ── Image thumbnail card ──────────────────────────────────────────────────────

class _ThumbnailCard extends StatelessWidget {
  final ColouringPage page;
  final VoidCallback onTap;

  const _ThumbnailCard({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.asset(page.imagePath, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                page.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wrong-guess message banner ────────────────────────────────────────────────

class _WrongGuessMessage extends StatelessWidget {
  final String message;
  const _WrongGuessMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAreYouSure = message == 'Are you sure?';
    final colour = isAreYouSure ? AppColors.accentOrange : AppColors.accentRed;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAreYouSure ? Icons.help_outline : Icons.refresh,
            color: colour,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}
