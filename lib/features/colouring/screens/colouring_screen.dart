import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/colouring_page.dart';
import '../providers/colouring_provider.dart';
import '../widgets/colour_palette.dart';
import '../widgets/colouring_canvas.dart';

/// Main screen for the colouring game.
///
/// Displays:
/// - App bar with page selection menu
/// - Colouring canvas in the center
/// - Colour palette at the bottom
///
/// Uses [ColouringProvider] for state management including
/// flood-fill operations and colour selection.
class ColouringScreen extends StatefulWidget {
  const ColouringScreen({super.key});

  @override
  State<ColouringScreen> createState() => _ColouringScreenState();
}

class _ColouringScreenState extends State<ColouringScreen> {
  @override
  void initState() {
    super.initState();
    // Load the first colouring page when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPage();
    });
  }

  /// Loads the initial colouring page (Abi by default).
  Future<void> _loadInitialPage() async {
    try {
      await context.read<ColouringProvider>().loadPage(ColouringPage.abi());
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load colouring page');
      }
    }
  }

  /// Shows an error snackbar with the given message.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColouringProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              provider.currentPage?.name ?? 'Colouring',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              // Page selection menu
              PopupMenuButton<ColouringPage>(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onSelected: (page) => _loadPage(provider, page),
                itemBuilder: (context) => ColouringPage.allPages()
                    .map((page) => PopupMenuItem<ColouringPage>(
                          value: page,
                          child: Text(
                            page.name,
                            style: TextStyle(
                              fontWeight: page.id == provider.currentPage?.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Colouring canvas area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.headerBackgroundLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.headerBorderDark,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.headerBorderDark,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildCanvasArea(provider),
                        ),
                      ),
                    ),
                  ),

                  // Colour palette at bottom
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: ColourPalette(
                      colourRows: ColouringProvider.paletteColourRows,
                      selectedColour: provider.selectedColour,
                      onColourSelected: provider.selectColour,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the canvas area with loading and error states.
  Widget _buildCanvasArea(ColouringProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.abiPink,
        ),
      );
    }

    if (!provider.isReady || provider.originalImage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: AppSizes.iconXLarge,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            const Text(
              'No image loaded',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSizeBody,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: ColouringCanvas(
        image: provider.originalImage!,
        onTap: (point) => _handleCanvasTap(provider, point),
      ),
    );
  }

  /// Handles a tap on the canvas by performing flood-fill.
  Future<void> _handleCanvasTap(
    ColouringProvider provider,
    Offset point,
  ) async {
    try {
      // Get the display size from the canvas
      final displaySize = _getDisplaySize(provider);
      if (displaySize == null) return;

      await provider.fillAtPoint(
        point: point,
        imageSize: Size(
          provider.imageWidth.toDouble(),
          provider.imageHeight.toDouble(),
        ),
        displaySize: displaySize,
      );
    } catch (e) {
      debugPrint('Error during flood-fill: $e');
    }
  }

  /// Calculates the display size of the canvas.
  Size? _getDisplaySize(ColouringProvider provider) {
    if (!provider.isReady) return null;

    // Get available size (screen minus app bar and palette)
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        100; // Approximate palette height
    final availableWidth = screenSize.width - (AppSizes.paddingMedium * 2);

    // Calculate display size maintaining aspect ratio
    final imageAspectRatio = provider.imageWidth / provider.imageHeight;
    final constraintAspectRatio = availableWidth / availableHeight;

    double displayWidth;
    double displayHeight;

    if (imageAspectRatio > constraintAspectRatio) {
      displayWidth = availableWidth;
      displayHeight = availableWidth / imageAspectRatio;
    } else {
      displayHeight = availableHeight;
      displayWidth = availableHeight * imageAspectRatio;
    }

    return Size(displayWidth, displayHeight);
  }

  /// Loads a new colouring page.
  Future<void> _loadPage(ColouringProvider provider, ColouringPage page) async {
    try {
      await provider.loadPage(page);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load ${page.name}');
      }
    }
  }

  /// Navigates back to the home screen.
  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }
}
