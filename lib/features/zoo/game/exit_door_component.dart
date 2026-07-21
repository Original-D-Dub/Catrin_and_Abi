import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;

/// The exit door at the end of an enclosure walk, set into the rock wall
/// after the last window with an "Exit" sign above it.
///
/// Tapping the door calls [onTapped] — the screen navigates back to the
/// zoo map. The stopped player also turns to face it, like they do at the
/// enclosure windows.
class ExitDoorComponent extends PositionComponent with TapCallbacks {
  /// Already-localized sign text ("Exit" / "Allanfa").
  final String label;

  /// Rock surround, matching the enclosure window frames.
  final Color frameColor;

  final VoidCallback onTapped;

  final double _frame;
  final double _signHeight;
  late final TextPainter _signPainter;

  static const double _signGap = 10;
  static const Color _doorColor = Color(0xFF3B6231);
  static const Color _signColor = Color(0xFF2E7D32);

  /// [doorCenterX] / door size come from [EnclosureWalkLayout]; the door
  /// stands on [floorTop]. The component's box also includes the rock
  /// surround and the sign above it.
  ExitDoorComponent({
    required this.label,
    required this.frameColor,
    required this.onTapped,
    required double doorCenterX,
    required double floorTop,
    required double doorWidth,
    required double doorHeight,
  })  : _frame = (doorWidth * 0.09).clamp(12.0, 24.0),
        _signHeight = (doorHeight * 0.11).clamp(32.0, 50.0),
        super(anchor: Anchor.bottomCenter, priority: 1) {
    size = Vector2(
      doorWidth + _frame * 2,
      _signHeight + _signGap + doorHeight + _frame,
    );
    position = Vector2(doorCenterX, floorTop);
  }

  /// The door leaf itself, in local coordinates (no frame below — the
  /// door meets the floor).
  Rect get _doorRect => Rect.fromLTWH(
        _frame,
        _signHeight + _signGap + _frame,
        size.x - _frame * 2,
        size.y - _signHeight - _signGap - _frame,
      );

  @override
  Future<void> onLoad() async {
    _signPainter = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: _signHeight * 0.52,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTapped();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint();
    final doorRect = _doorRect;

    // Rock surround around the top and sides of the doorway.
    paint.color = frameColor;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        doorRect.inflate(_frame).intersect(Offset.zero & size.toSize()),
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
      ),
      paint,
    );

    // Door leaf with two recessed panels and a handle.
    paint.color = _doorColor;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        doorRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      paint,
    );
    paint
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final panel in [
      Rect.fromLTRB(
        doorRect.left + doorRect.width * 0.18,
        doorRect.top + doorRect.height * 0.08,
        doorRect.right - doorRect.width * 0.18,
        doorRect.top + doorRect.height * 0.46,
      ),
      Rect.fromLTRB(
        doorRect.left + doorRect.width * 0.18,
        doorRect.top + doorRect.height * 0.54,
        doorRect.right - doorRect.width * 0.18,
        doorRect.bottom - doorRect.height * 0.08,
      ),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(6)),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFC9A63C);
    canvas.drawCircle(
      Offset(doorRect.right - doorRect.width * 0.14,
          doorRect.top + doorRect.height * 0.5),
      doorRect.width * 0.045,
      paint,
    );

    // Green "EXIT" sign above the doorway.
    final signWidth = _signPainter.width + _signHeight * 1.1;
    final sign = Rect.fromCenter(
      center: Offset(size.x / 2, _signHeight / 2),
      width: signWidth,
      height: _signHeight,
    );
    paint.color = _signColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(sign, const Radius.circular(8)),
      paint,
    );
    _signPainter.paint(
      canvas,
      Offset(
        sign.center.dx - _signPainter.width / 2,
        sign.center.dy - _signPainter.height / 2,
      ),
    );
  }
}
