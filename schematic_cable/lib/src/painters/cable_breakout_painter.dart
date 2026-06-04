// schematic_cable — cable-to-terminal breakout painter.
//
// Renders a cable jacket on the left fanning out to labelled terminals on the
// right, in the "solid + striped (telecom)" style.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/cable_spec.dart';
import 'cable_paths.dart';

class CableBreakoutPainter extends CustomPainter {
  CableBreakoutPainter({
    required this.spec,
    required this.stroke,
    required this.paper,
  });

  final CableSpec spec;
  final Color stroke;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const cableX = 8.0;
    final cableW = math.min(180.0, w * 0.28);
    const cableH = 32.0;
    final cableY = (h - cableH) / 2;
    final cableEndX = cableX + cableW;

    final termX = w - 100;
    final n = spec.wireCount;
    if (n == 0) return;

    const topPad = 24.0, bottomPad = 24.0;
    final endY = List<double>.generate(n, (i) {
      if (n == 1) return h / 2;
      return topPad + (h - topPad - bottomPad) * (i / (n - 1));
    });

    final spread = math.min(28.0, cableH * 0.7);
    final breakX = cableEndX + 4;
    final breakY = List<double>.generate(n, (i) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      return cableY + cableH / 2 + (t - 0.5) * spread;
    });

    _drawJacket(canvas, cableX, cableY, cableW, cableH);

    for (var i = 0; i < n; i++) {
      _drawWire(canvas, breakX, breakY[i], termX, endY[i], spec.wires[i]);
    }
    for (var i = 0; i < n; i++) {
      _drawTerminal(canvas, termX, endY[i], spec.wires[i]);
    }

    _drawText(canvas, spec.label, Offset(cableX + 6, cableY - 14),
        fontSize: 10, color: stroke);
  }

  void _drawJacket(Canvas c, double x, double y, double w, double h) {
    final r = Radius.circular(h / 2);
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), r);
    c.drawRRect(rect, Paint()..color = const Color(0xFF2C3340));
    c.drawRRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    c.drawRect(Rect.fromLTWH(x + 6, y + 5, w - 12, 2.2),
        Paint()..color = const Color(0xB34A5365));
    c.drawRect(Rect.fromLTWH(x + 6, y + h - 7, w - 12, 2.2),
        Paint()..color = const Color(0xB315191F));
    c.drawOval(
      Rect.fromCenter(center: Offset(x + w, y + h / 2), width: 6, height: h - 4),
      Paint()..color = const Color(0xFF0E1116),
    );
  }

  void _drawWire(Canvas c, double x0, double y0, double x1, double y1, WireSpec w) {
    final path = smoothCablePath(x0, y0, x1, y1);
    c.drawPath(
      path,
      Paint()
        ..color = w.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w.stripeColor != null ? 3.0 : 2.4
        ..strokeCap = StrokeCap.round,
    );
    if (w.stripeColor != null) {
      drawDashedCablePath(c, path,
          color: w.stripeColor!, strokeWidth: 3.0, dash: 5, gap: 9);
      c.drawPath(
          path,
          Paint()
            ..color = stroke.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.4);
    }
  }

  void _drawTerminal(Canvas c, double x, double y, WireSpec w) {
    c.drawCircle(Offset(x, y), 3.5, Paint()..color = w.color);
    c.drawCircle(
        Offset(x, y),
        3.5,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final box = Rect.fromLTWH(x + 8, y - 9, 84, 18);
    c.drawRect(
        box,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    _drawText(c, w.label, Offset(x + 14, y - 6), fontSize: 10, color: stroke);
    if (w.subLabel != null) {
      _drawText(c, w.subLabel!, Offset(x + 14, y + 4),
          fontSize: 8, color: const Color(0xFF5A6478));
    }
  }

  void _drawText(Canvas c, String text, Offset topLeft,
      {required double fontSize, required Color color}) {
    (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamilyFallback: const ['monospace', 'Courier'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(c, topLeft);
  }

  @override
  bool shouldRepaint(covariant CableBreakoutPainter old) =>
      old.spec != spec || old.stroke != stroke || old.paper != paper;
}
