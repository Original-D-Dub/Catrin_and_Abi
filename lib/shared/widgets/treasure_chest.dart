import 'dart:math';

import 'package:flutter/material.dart';

/// State of a treasure chest on the level map.
enum ChestState {
  /// Its level hasn't been completed yet.
  locked,

  /// Its level is completed but the chest hasn't been opened.
  ready,

  /// Already opened — it gave the player a card.
  opened,
}

/// A felt treasure chest: closed with a padlock while [ChestState.locked],
/// closed and gleaming when [ChestState.ready], lid open when opened.
class TreasureChestPainter extends CustomPainter {
  TreasureChestPainter(this.state);

  final ChestState state;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.8, h * 0.45);
    final lidClosed = Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.3);
    const woodLight = Color(0xFFE38A2E);
    const wood = Color(0xFFC2611A);
    const woodDark = Color(0xFF5C2806);
    const gold = Color(0xFFFFCC1A);
    const goldDark = Color(0xFFC26E00);
    const outline = Color(0xFF3A1503);
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeJoin = StrokeJoin.round;
    final locked = state == ChestState.locked;
    // Locked chests are washed out below; the layer keeps that wash to the
    // chest's own pixels.
    if (locked) canvas.saveLayer(Offset.zero & size, Paint());

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.92),
        width: w * 0.85,
        height: h * 0.12,
      ),
      Paint()..color = Colors.black26,
    );

    if (state == ChestState.ready) {
      canvas.drawCircle(
        Offset(w / 2, h * 0.55),
        w * 0.5,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFF59D).withValues(alpha: 0.9),
                  const Color(0xFFFFF59D).withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(w / 2, h * 0.55),
                  radius: w * 0.5,
                ),
              ),
      );
    }

    Paint fill(Rect r, Color top, Color bottom) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(r);

    final bodyR = RRect.fromRectAndCorners(
      body,
      bottomLeft: Radius.circular(w * 0.06),
      bottomRight: Radius.circular(w * 0.06),
    );
    canvas.drawRRect(bodyR, fill(body, wood, woodDark));
    canvas.drawRRect(bodyR, outlinePaint);

    if (state == ChestState.opened) {
      // Inside of the box and the lid tipped back.
      canvas.drawRect(
        Rect.fromLTWH(body.left + 4, body.top, body.width - 8, h * 0.06),
        Paint()..color = const Color(0xFF240C01),
      );
      final lid = Path()
        ..moveTo(body.left, body.top)
        ..lineTo(body.left + w * 0.06, h * 0.08)
        ..lineTo(body.right - w * 0.06, h * 0.08)
        ..lineTo(body.right, body.top)
        ..close();
      canvas.drawPath(lid, fill(lid.getBounds(), woodDark, woodLight));
      canvas.drawPath(lid, outlinePaint);
      // A card peeking out.
      final card = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.3, w * 0.28, h * 0.22),
        Radius.circular(w * 0.03),
      );
      canvas.drawRRect(card, Paint()..color = Colors.white);
      canvas.drawRRect(
        card,
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      final lidR = RRect.fromRectAndCorners(
        lidClosed,
        topLeft: Radius.circular(w * 0.3),
        topRight: Radius.circular(w * 0.3),
      );
      canvas.drawRRect(lidR, fill(lidClosed, woodLight, wood));
      canvas.drawRRect(lidR, outlinePaint);
      // Gold rim where the lid meets the box.
      canvas.drawRect(
        Rect.fromLTWH(body.left, body.top - h * 0.03, body.width, h * 0.06),
        fill(lidClosed, gold, goldDark),
      );
      canvas.drawRect(
        Rect.fromLTWH(body.left, body.top - h * 0.03, body.width, h * 0.06),
        outlinePaint..strokeWidth = w * 0.015,
      );
      outlinePaint.strokeWidth = w * 0.025;
    }

    // Gold straps.
    for (final x in [0.26, 0.74]) {
      final strap = Rect.fromLTWH(
        w * x - w * 0.045,
        body.top,
        w * 0.09,
        body.height,
      );
      canvas.drawRect(strap, fill(body, gold, goldDark));
      canvas.drawRect(
        strap,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012,
      );
    }

    // Lock plate (padlock while locked).
    final plate = Rect.fromCenter(
      center: Offset(w / 2, body.top + h * 0.08),
      width: w * 0.16,
      height: h * 0.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, Radius.circular(w * 0.03)),
      fill(plate, gold, goldDark),
    );
    if (locked) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w / 2, plate.top),
          width: w * 0.1,
          height: h * 0.12,
        ),
        pi,
        pi,
        false,
        Paint()
          ..color = const Color(0xFF8A8A8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.025,
      );
    }
    canvas.drawCircle(
      Offset(w / 2, plate.center.dy),
      w * 0.02,
      Paint()..color = outline,
    );

    // Felt stitching along the body.
    final stitch = Paint()
      ..color = const Color(0xE6FFE2A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = bodyR.deflate(w * 0.04);
    for (final metric in (Path()..addRRect(inner)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 3.5), stitch);
      }
    }

    if (locked) {
      // Greyed out until the level is done.
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..blendMode = BlendMode.srcATop,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(TreasureChestPainter old) => old.state != state;
}
