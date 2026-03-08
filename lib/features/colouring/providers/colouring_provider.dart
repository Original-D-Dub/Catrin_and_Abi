import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../models/colouring_page.dart';

/// Manages all state for the colouring game.
///
/// Responsibilities:
/// - Load and manage the colouring page image
/// - Track pixel colours for flood-fill operations
/// - Handle colour selection from palette
/// - Perform flood-fill algorithm when user taps
/// - Protect black outline pixels from being filled
///
/// Usage:
/// ```dart
/// final provider = ColouringProvider();
/// await provider.loadPage(ColouringPage.abi());
/// provider.selectColour(Colors.red);
/// provider.fillAtPoint(Offset(100, 100));
/// ```
class ColouringProvider extends ChangeNotifier {
  /// Row 1: Primary painting colours
  static const List<Color> paletteRow1 = [
    AppColors.accentRed,
    AppColors.accentOrange,
    AppColors.accentYellow,
    AppColors.accentLimeGreen,
    AppColors.schoolGreen,
    AppColors.catrinBlue,
    AppColors.accentNavyBlue,
    AppColors.accentPurple,
    AppColors.abiPink,
    AppColors.peroJacket,
    AppColors.connectorGold,
    AppColors.peroFur,
    Colors.white,
  ];

  /// Row 2: Character/detail colours (brown, skin, greys)
  static const List<Color> paletteRow2 = [
    AppColors.catrinHair,
    AppColors.skinColour,
    AppColors.lightGrey,
    AppColors.darkGrey,
  ];

  /// Both rows combined for the palette widget
  static const List<List<Color>> paletteColourRows = [
    paletteRow1,
    paletteRow2,
  ];

  /// Tolerance for flood-fill colour matching (0-255)
  /// Higher values fill more similar colours
  static const int _colourTolerance = 32;

  /// Threshold below which a pixel is considered part of the black outline.
  ///
  /// Pixels where R, G, and B are all below this value are treated as
  /// outline and cannot be selected or filled with colour.
  static const int _outlineThreshold = 50;

  /// The currently loaded colouring page
  ColouringPage? _currentPage;
  ColouringPage? get currentPage => _currentPage;

  /// The original image loaded from assets
  ui.Image? _originalImage;
  ui.Image? get originalImage => _originalImage;

  /// Pixel data for the current image (RGBA format)
  ByteData? _pixelData;

  /// Width of the current image
  int _imageWidth = 0;
  int get imageWidth => _imageWidth;

  /// Height of the current image
  int _imageHeight = 0;
  int get imageHeight => _imageHeight;

  /// Currently selected colour for painting
  Color _selectedColour = paletteRow1.first;
  Color get selectedColour => _selectedColour;

  /// Whether an image is currently loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Whether the provider has a loaded image ready for colouring
  bool get isReady => _originalImage != null && _pixelData != null;

  /// Loads a colouring page and prepares it for colouring.
  ///
  /// [page] The colouring page configuration to load.
  ///
  /// Throws [Exception] if the image fails to load.
  Future<void> loadPage(ColouringPage page) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load the image from assets
      final ByteData data = await rootBundle.load(page.imagePath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      _originalImage = frameInfo.image;
      _imageWidth = _originalImage!.width;
      _imageHeight = _originalImage!.height;

      // Extract pixel data for flood-fill operations
      _pixelData = await _originalImage!.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      _currentPage = page;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to load colouring page: $e');
    }
  }

  /// Selects a colour from the palette.
  ///
  /// [colour] The colour to use for filling.
  void selectColour(Color colour) {
    _selectedColour = colour;
    notifyListeners();
  }

  /// Performs a flood-fill operation at the given point.
  ///
  /// [point] The tap position in image coordinates.
  /// [imageSize] The size of the displayed image (for coordinate conversion).
  /// [displaySize] The size of the display area.
  ///
  /// Returns true if the fill was performed, false otherwise.
  /// Returns false if the tapped pixel is part of the black outline.
  Future<bool> fillAtPoint({
    required Offset point,
    required Size imageSize,
    required Size displaySize,
  }) async {
    if (!isReady || _pixelData == null) return false;

    // Convert display coordinates to image coordinates
    final double scaleX = _imageWidth / displaySize.width;
    final double scaleY = _imageHeight / displaySize.height;

    final int x = (point.dx * scaleX).round().clamp(0, _imageWidth - 1);
    final int y = (point.dy * scaleY).round().clamp(0, _imageHeight - 1);

    // Get the colour at the tap point
    final Color targetColour = _getPixelColour(x, y);

    // Don't fill if tapping on the black outline
    if (_isOutlineColour(targetColour)) {
      return false;
    }

    // Don't fill if tapping on the same colour
    if (_coloursMatch(targetColour, _selectedColour, tolerance: 5)) {
      return false;
    }

    // Perform flood-fill
    await _floodFill(x, y, targetColour, _selectedColour);

    // Rebuild the image from modified pixel data
    await _rebuildImage();

    notifyListeners();
    return true;
  }

  /// Gets the colour of a pixel at the given coordinates.
  Color _getPixelColour(int x, int y) {
    if (_pixelData == null) return Colors.transparent;

    final int index = (y * _imageWidth + x) * 4;
    if (index < 0 || index + 3 >= _pixelData!.lengthInBytes) {
      return Colors.transparent;
    }

    final int r = _pixelData!.getUint8(index);
    final int g = _pixelData!.getUint8(index + 1);
    final int b = _pixelData!.getUint8(index + 2);
    final int a = _pixelData!.getUint8(index + 3);

    return Color.fromARGB(a, r, g, b);
  }

  /// Sets the colour of a pixel at the given coordinates.
  void _setPixelColour(int x, int y, Color colour) {
    if (_pixelData == null) return;

    final int index = (y * _imageWidth + x) * 4;
    if (index < 0 || index + 3 >= _pixelData!.lengthInBytes) return;

    // Convert ByteData to Uint8List for modification
    final Uint8List pixels = _pixelData!.buffer.asUint8List();
    pixels[index] = (colour.r * 255.0).round().clamp(0, 255);
    pixels[index + 1] = (colour.g * 255.0).round().clamp(0, 255);
    pixels[index + 2] = (colour.b * 255.0).round().clamp(0, 255);
    pixels[index + 3] = (colour.a * 255.0).round().clamp(0, 255);
  }

  /// Gets red component as int (0-255)
  int _redInt(Color c) => (c.r * 255.0).round().clamp(0, 255);

  /// Gets green component as int (0-255)
  int _greenInt(Color c) => (c.g * 255.0).round().clamp(0, 255);

  /// Gets blue component as int (0-255)
  int _blueInt(Color c) => (c.b * 255.0).round().clamp(0, 255);

  /// Checks if two colours match within the tolerance.
  bool _coloursMatch(Color a, Color b, {int tolerance = _colourTolerance}) {
    return (_redInt(a) - _redInt(b)).abs() <= tolerance &&
        (_greenInt(a) - _greenInt(b)).abs() <= tolerance &&
        (_blueInt(a) - _blueInt(b)).abs() <= tolerance;
  }

  /// Checks if a colour is part of the black outline.
  ///
  /// A pixel is considered outline if all RGB components are
  /// below [_outlineThreshold] (very dark/black).
  bool _isOutlineColour(Color colour) {
    return _redInt(colour) < _outlineThreshold &&
        _greenInt(colour) < _outlineThreshold &&
        _blueInt(colour) < _outlineThreshold;
  }

  /// Performs flood-fill algorithm using a queue-based approach.
  ///
  /// Skips pixels that are part of the black outline, treating them
  /// as impassable barriers.
  ///
  /// [startX], [startY] Starting coordinates.
  /// [targetColour] The colour being replaced.
  /// [fillColour] The colour to fill with.
  Future<void> _floodFill(
    int startX,
    int startY,
    Color targetColour,
    Color fillColour,
  ) async {
    // Use a set to track visited pixels
    final Set<int> visited = <int>{};
    final Queue<int> queue = Queue<int>();

    // Encode position as single int for efficiency
    int encode(int x, int y) => y * _imageWidth + x;

    queue.add(encode(startX, startY));

    while (queue.isNotEmpty) {
      final int pos = queue.removeFirst();
      final int x = pos % _imageWidth;
      final int y = pos ~/ _imageWidth;

      // Skip if already visited
      if (visited.contains(pos)) continue;
      visited.add(pos);

      // Check bounds
      if (x < 0 || x >= _imageWidth || y < 0 || y >= _imageHeight) continue;

      // Check if pixel matches target colour
      final Color currentColour = _getPixelColour(x, y);

      // Skip outline pixels - they act as barriers
      if (_isOutlineColour(currentColour)) continue;

      if (!_coloursMatch(currentColour, targetColour)) continue;

      // Fill this pixel
      _setPixelColour(x, y, fillColour);

      // Add adjacent pixels to queue (4-connected)
      if (x > 0) queue.add(encode(x - 1, y));
      if (x < _imageWidth - 1) queue.add(encode(x + 1, y));
      if (y > 0) queue.add(encode(x, y - 1));
      if (y < _imageHeight - 1) queue.add(encode(x, y + 1));
    }
  }

  /// Rebuilds the ui.Image from the modified pixel data.
  Future<void> _rebuildImage() async {
    if (_pixelData == null) return;

    final Uint8List pixels = _pixelData!.buffer.asUint8List();

    // Create image from raw pixels using decodeImageFromPixels
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _imageWidth,
      _imageHeight,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        completer.complete(image);
      },
    );
    _originalImage = await completer.future;
  }

  /// Resets the current page to its original state.
  Future<void> resetPage() async {
    if (_currentPage != null) {
      await loadPage(_currentPage!);
    }
  }

  @override
  void dispose() {
    _originalImage?.dispose();
    super.dispose();
  }
}
