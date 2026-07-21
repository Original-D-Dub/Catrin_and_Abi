import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../models/colouring_page.dart';

// ── Levels ────────────────────────────────────────────────────────────────────

enum ColouringLevel {
  bslColours(number: 1, name: 'BSL Colours',
      description: 'Tap the colour Miss Angela signs'),
  freeColour(number: 2, name: 'Colour a Picture',
      description: 'Choose a picture and colour it in');

  final int number;
  final String name;
  final String description;
  const ColouringLevel({required this.number, required this.name,
      required this.description});
}

// ── BSL colour list ───────────────────────────────────────────────────────────

typedef BslColour = ({Color colour, String name, String videoName});

const List<BslColour> bslColourList = [
  (colour: AppColors.accentRed,    name: 'Red',    videoName: 'red'),
  (colour: AppColors.accentOrange, name: 'Orange', videoName: 'orange'),
  (colour: AppColors.accentYellow, name: 'Yellow', videoName: 'yellow'),
  (colour: AppColors.schoolGreen,  name: 'Green',  videoName: 'green'),
  (colour: AppColors.catrinBlue,   name: 'Blue',   videoName: 'blue'),
  (colour: AppColors.accentPurple, name: 'Purple', videoName: 'purple'),
  (colour: AppColors.abiPink,      name: 'Pink',   videoName: 'pink'),
  (colour: Colors.white,           name: 'White',  videoName: 'white'),
];

// ── Provider ──────────────────────────────────────────────────────────────────

class Colouring2Provider extends ChangeNotifier {
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

  /// Row 2: Character/detail colours
  static const List<Color> paletteRow2 = [
    AppColors.catrinHair,
    AppColors.skinColour,
    AppColors.lightGrey,
    AppColors.darkGrey,
  ];

  static const List<List<Color>> paletteColourRows = [paletteRow1, paletteRow2];

  static const int _colourTolerance = 32;
  static const int _outlineThreshold = 50;

  // ── Level select ─────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  ColouringLevel _currentLevel = ColouringLevel.bslColours;
  ColouringLevel get currentLevel => _currentLevel;

  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  void startLevel(ColouringLevel level) {
    _currentLevel = level;
    _showLevelSelect = false;
    _score = 0;
    _bslColourIndex = 0;
    _colourChangeGeneration = 0;
    _lastGuessCorrect = null;
    _wrongGuessCount = 0;
    _selectedColour = paletteRow1.first;
    if (level == ColouringLevel.freeColour) _showImageGrid = true;
    notifyListeners();
    if (level == ColouringLevel.bslColours) {
      loadPage(ColouringPage.abi());
    }
  }

  // ── Level 2: image selection ──────────────────────────────────────────────────

  /// Whether the Level 2 image grid is showing (vs. the canvas).
  bool _showImageGrid = true;
  bool get showImageGrid => _showImageGrid;

  void selectImageFromGrid(ColouringPage page) {
    _showImageGrid = false;
    loadPage(page);
  }

  void returnToImageGrid() {
    _showImageGrid = true;
    notifyListeners();
  }

  // ── Level 1: BSL Colours game ─────────────────────────────────────────────────

  int _score = 0;
  int get score => _score;

  int _bslColourIndex = 0;
  BslColour get currentBslColour => bslColourList[_bslColourIndex];

  /// Increments each time the target colour advances so the video widget
  /// replays even when the same colour cycles around again.
  int _colourChangeGeneration = 0;
  int get colourChangeGeneration => _colourChangeGeneration;

  /// null = no guess yet, true = last guess correct, false = wrong
  bool? _lastGuessCorrect;
  bool? get lastGuessCorrect => _lastGuessCorrect;

  /// 0 = no wrong guess, 1 = "Are you sure?", 2+ = "Try again"
  int _wrongGuessCount = 0;
  int get wrongGuessCount => _wrongGuessCount;

  String? get wrongGuessMessage {
    if (_wrongGuessCount == 1) return 'Are you sure?';
    if (_wrongGuessCount >= 2) return 'Try again';
    return null;
  }

  void nextBslColour() {
    _bslColourIndex = (_bslColourIndex + 1) % bslColourList.length;
    _lastGuessCorrect = null;
    _wrongGuessCount = 0;
    _colourChangeGeneration++;
    notifyListeners();
  }

  // ── Slot machine ──────────────────────────────────────────────────────────────

  bool _isSlotSpinning = false;
  bool get isSlotSpinning => _isSlotSpinning;

  int _slotPageIndex = 0;
  int get slotPageIndex => _slotPageIndex;

  Timer? _slotTimer;

  /// Starts the slot-machine image cycle and loads the winning page when done.
  void startSlotMachine() {
    if (_isSlotSpinning) return;
    _isSlotSpinning = true;
    notifyListeners();

    final pages = ColouringPage.allPages();
    // Intervals in ms: fast then progressively slower
    const intervals = [80, 100, 130, 180, 260, 380, 560, 820, 1200];
    int step = 0;

    void spin() {
      _slotPageIndex = (_slotPageIndex + 1) % pages.length;
      notifyListeners();

      if (step < intervals.length - 1) {
        step++;
        _slotTimer = Timer(Duration(milliseconds: intervals[step]), spin);
      } else {
        _isSlotSpinning = false;
        loadPage(pages[_slotPageIndex]);
      }
    }

    _slotTimer = Timer(Duration(milliseconds: intervals[0]), spin);
  }

  // ── Canvas state ──────────────────────────────────────────────────────────────

  ColouringPage? _currentPage;
  ColouringPage? get currentPage => _currentPage;

  ui.Image? _originalImage;
  ui.Image? get originalImage => _originalImage;

  ByteData? _pixelData;

  int _imageWidth = 0;
  int get imageWidth => _imageWidth;

  int _imageHeight = 0;
  int get imageHeight => _imageHeight;

  Color _selectedColour = paletteRow1.first;
  Color get selectedColour => _selectedColour;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isReady => _originalImage != null && _pixelData != null;

  Future<void> loadPage(ColouringPage page) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ByteData data = await rootBundle.load(page.imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      _originalImage = frameInfo.image;
      _imageWidth = _originalImage!.width;
      _imageHeight = _originalImage!.height;
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

  void selectColour(Color colour) {
    _selectedColour = colour;
    if (_currentLevel == ColouringLevel.bslColours) {
      if (_coloursMatch(colour, currentBslColour.colour, tolerance: 8)) {
        _wrongGuessCount = 0;
      } else {
        _wrongGuessCount++;
      }
    }
    notifyListeners();
  }

  Future<bool> fillAtPoint({
    required Offset point,
    required Size imageSize,
    required Size displaySize,
  }) async {
    if (!isReady || _pixelData == null) return false;

    final double scaleX = _imageWidth / displaySize.width;
    final double scaleY = _imageHeight / displaySize.height;

    final int x = (point.dx * scaleX).round().clamp(0, _imageWidth - 1);
    final int y = (point.dy * scaleY).round().clamp(0, _imageHeight - 1);

    final Color targetColour = _getPixelColour(x, y);
    if (_isOutlineColour(targetColour)) return false;
    if (_coloursMatch(targetColour, _selectedColour, tolerance: 5)) return false;

    await _floodFill(x, y, targetColour, _selectedColour);
    await _rebuildImage();

    // Level 1: award a point when the correct colour is used on the canvas.
    if (_currentLevel == ColouringLevel.bslColours &&
        _coloursMatch(_selectedColour, currentBslColour.colour, tolerance: 8)) {
      _score++;
      _wrongGuessCount = 0;
      _bslColourIndex = (_bslColourIndex + 1) % bslColourList.length;
      _colourChangeGeneration++;
    }

    notifyListeners();
    return true;
  }

  Color _getPixelColour(int x, int y) {
    if (_pixelData == null) return Colors.transparent;
    final int index = (y * _imageWidth + x) * 4;
    if (index < 0 || index + 3 >= _pixelData!.lengthInBytes) return Colors.transparent;
    return Color.fromARGB(
      _pixelData!.getUint8(index + 3),
      _pixelData!.getUint8(index),
      _pixelData!.getUint8(index + 1),
      _pixelData!.getUint8(index + 2),
    );
  }

  void _setPixelColour(int x, int y, Color colour) {
    if (_pixelData == null) return;
    final int index = (y * _imageWidth + x) * 4;
    if (index < 0 || index + 3 >= _pixelData!.lengthInBytes) return;
    final Uint8List pixels = _pixelData!.buffer.asUint8List();
    pixels[index]     = (colour.r * 255.0).round().clamp(0, 255);
    pixels[index + 1] = (colour.g * 255.0).round().clamp(0, 255);
    pixels[index + 2] = (colour.b * 255.0).round().clamp(0, 255);
    pixels[index + 3] = (colour.a * 255.0).round().clamp(0, 255);
  }

  int _redInt(Color c)   => (c.r * 255.0).round().clamp(0, 255);
  int _greenInt(Color c) => (c.g * 255.0).round().clamp(0, 255);
  int _blueInt(Color c)  => (c.b * 255.0).round().clamp(0, 255);

  bool _coloursMatch(Color a, Color b, {int tolerance = _colourTolerance}) =>
      (_redInt(a) - _redInt(b)).abs() <= tolerance &&
      (_greenInt(a) - _greenInt(b)).abs() <= tolerance &&
      (_blueInt(a) - _blueInt(b)).abs() <= tolerance;

  bool _isOutlineColour(Color colour) =>
      _redInt(colour) < _outlineThreshold &&
      _greenInt(colour) < _outlineThreshold &&
      _blueInt(colour) < _outlineThreshold;

  Future<void> _floodFill(int startX, int startY, Color targetColour, Color fillColour) async {
    final Set<int> visited = <int>{};
    final Queue<int> queue = Queue<int>();
    int encode(int x, int y) => y * _imageWidth + x;
    queue.add(encode(startX, startY));

    while (queue.isNotEmpty) {
      final int pos = queue.removeFirst();
      if (visited.contains(pos)) continue;
      visited.add(pos);

      final int x = pos % _imageWidth;
      final int y = pos ~/ _imageWidth;
      if (x < 0 || x >= _imageWidth || y < 0 || y >= _imageHeight) continue;

      final Color c = _getPixelColour(x, y);
      if (_isOutlineColour(c)) continue;
      if (!_coloursMatch(c, targetColour)) continue;

      _setPixelColour(x, y, fillColour);
      if (x > 0)              queue.add(encode(x - 1, y));
      if (x < _imageWidth - 1) queue.add(encode(x + 1, y));
      if (y > 0)              queue.add(encode(x, y - 1));
      if (y < _imageHeight - 1) queue.add(encode(x, y + 1));
    }
  }

  Future<void> _rebuildImage() async {
    if (_pixelData == null) return;
    final Uint8List pixels = _pixelData!.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, _imageWidth, _imageHeight,
        ui.PixelFormat.rgba8888, completer.complete);
    _originalImage = await completer.future;
  }

  Future<void> resetPage() async {
    if (_currentPage != null) await loadPage(_currentPage!);
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    _originalImage?.dispose();
    super.dispose();
  }
}
