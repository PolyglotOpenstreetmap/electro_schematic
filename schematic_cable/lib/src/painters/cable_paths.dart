// schematic_cable — low-level path/stroke helpers shared by the cable painters.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A smooth horizontal cubic from (x0,y0) to (x1,y1), used for breakout fan-out.
Path smoothCablePath(double x0, double y0, double x1, double y1,
    [double tension = 0.55]) {
  final dx = (x1 - x0) * tension;
  return Path()
    ..moveTo(x0, y0)
    ..cubicTo(x0 + dx, y0, x1 - dx, y1, x1, y1);
}

/// Draws a dashed stroke along [source] (used for striped-wire overlays).
void drawDashedCablePath(
  Canvas canvas,
  Path source, {
  required Color color,
  required double strokeWidth,
  required double dash,
  required double gap,
  double startOffset = 0,
}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;
  for (final metric in source.computeMetrics()) {
    var d = startOffset;
    while (d < metric.length) {
      final next = math.min(d + dash, metric.length);
      canvas.drawPath(metric.extractPath(d, next), paint);
      d = next + gap;
    }
  }
}
