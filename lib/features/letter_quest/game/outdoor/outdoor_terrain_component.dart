import 'dart:ui';

import 'package:flame/components.dart';

import 'outdoor_map_data.dart';

/// Renders the outdoor terrain as a single large canvas component.
///
/// Draws layers in order:
/// 1. Green grass background
/// 2. Blue lake polygon
/// 3. Blue stream paths (thick stroked lines)
/// 4. Brown bridge rectangles with plank texture
///
/// This is a single component rather than individual tiles for
/// performance — the camera culling in Flame ensures only the
/// visible portion is rendered each frame.
class OutdoorTerrainComponent extends PositionComponent {
  /// The generated map data containing all terrain geometry
  final OutdoorMapData mapData;

  // -------------------------
  // Colour constants
  // -------------------------

  /// Light grass green
  static const Color _grassColor = Color(0xFF8BC34A);

  /// Darker grass variation for texture
  static const Color _grassDarkColor = Color(0xFF7CB342);

  /// Lake/stream water colour
  static const Color _waterColor = Color(0xFF42A5F5);

  /// Water edge stroke colour
  static const Color _waterEdgeColor = Color(0xFF1E88E5);

  /// Bridge wood colour
  static const Color _bridgeColor = Color(0xFF795548);

  /// Bridge plank line colour
  static const Color _bridgePlankColor = Color(0xFF5D4037);

  // -------------------------
  // Pre-built paints
  // -------------------------

  late final Paint _grassPaint;
  late final Paint _waterFillPaint;
  late final Paint _waterStrokePaint;
  late final Paint _bridgePaint;
  late final Paint _bridgePlankPaint;

  /// Creates the terrain renderer.
  OutdoorTerrainComponent({required this.mapData})
      : super(
          size: Vector2(mapData.worldWidth, mapData.worldHeight),
        );

  @override
  Future<void> onLoad() async {
    _grassPaint = Paint()..color = _grassColor;
    _waterFillPaint = Paint()..color = _waterColor;
    _waterStrokePaint = Paint()
      ..color = _waterEdgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    _bridgePaint = Paint()..color = _bridgeColor;
    _bridgePlankPaint = Paint()
      ..color = _bridgePlankColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  @override
  void render(Canvas canvas) {
    // 1. Grass background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapData.worldWidth, mapData.worldHeight),
      _grassPaint,
    );

    // 2. Grass texture (subtle darker patches)
    _renderGrassTexture(canvas);

    // 3. Lake
    _renderLake(canvas);

    // 4. Streams
    _renderStreams(canvas);

    // 5. Bridges
    _renderBridges(canvas);
  }

  /// Renders subtle grass texture using a grid of slightly varied rectangles.
  void _renderGrassTexture(Canvas canvas) {
    final darkPaint = Paint()..color = _grassDarkColor.withValues(alpha: 0.3);
    const spacing = 128.0;

    // Render a grid of small dark patches for texture
    for (double x = 0; x < mapData.worldWidth; x += spacing) {
      for (double y = 0; y < mapData.worldHeight; y += spacing) {
        // Checkerboard-like pattern
        final ix = (x / spacing).floor();
        final iy = (y / spacing).floor();
        if ((ix + iy) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, spacing, spacing),
            darkPaint,
          );
        }
      }
    }
  }

  /// Renders the lake as a filled polygon with stroke border.
  void _renderLake(Canvas canvas) {
    if (mapData.lakePoints.isEmpty) return;

    final lakePath = Path();
    lakePath.moveTo(mapData.lakePoints.first.x, mapData.lakePoints.first.y);
    for (int i = 1; i < mapData.lakePoints.length; i++) {
      lakePath.lineTo(mapData.lakePoints[i].x, mapData.lakePoints[i].y);
    }
    lakePath.close();

    canvas.drawPath(lakePath, _waterFillPaint);
    canvas.drawPath(lakePath, _waterStrokePaint);
  }

  /// Renders streams as thick stroked paths.
  void _renderStreams(Canvas canvas) {
    final streamPaint = Paint()
      ..color = _waterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = mapData.cellSize * 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stream in mapData.streamPaths) {
      if (stream.length < 2) continue;

      final streamPath = Path();
      streamPath.moveTo(stream.first.x, stream.first.y);
      for (int i = 1; i < stream.length; i++) {
        streamPath.lineTo(stream[i].x, stream[i].y);
      }

      canvas.drawPath(streamPath, streamPaint);
    }
  }

  /// Renders bridges as brown rectangles with plank lines.
  void _renderBridges(Canvas canvas) {
    for (final bridge in mapData.bridges) {
      final halfW =
          bridge.isHorizontal ? bridge.length / 2 : bridge.width / 2;
      final halfH =
          bridge.isHorizontal ? bridge.width / 2 : bridge.length / 2;

      final rect = Rect.fromCenter(
        center: Offset(bridge.position.x, bridge.position.y),
        width: halfW * 2,
        height: halfH * 2,
      );

      // Bridge base
      canvas.drawRect(rect, _bridgePaint);

      // Plank lines
      if (bridge.isHorizontal) {
        // Vertical plank lines across a horizontal bridge
        for (double x = rect.left + 16; x < rect.right; x += 24) {
          canvas.drawLine(
            Offset(x, rect.top),
            Offset(x, rect.bottom),
            _bridgePlankPaint,
          );
        }
      } else {
        // Horizontal plank lines across a vertical bridge
        for (double y = rect.top + 16; y < rect.bottom; y += 24) {
          canvas.drawLine(
            Offset(rect.left, y),
            Offset(rect.right, y),
            _bridgePlankPaint,
          );
        }
      }
    }
  }
}
