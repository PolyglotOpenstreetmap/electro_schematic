import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shared canvas drawing utilities for diagram painters.
///
/// All functions are top-level so they can be used by any painter without
/// inheritance or mixins.

// ---------------------------------------------------------------------------
// Text helpers
// ---------------------------------------------------------------------------

/// Draw [text] left-aligned with its top-left at [position].
void drawText(
  Canvas canvas,
  String text,
  Offset position,
  TextStyle style,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, position);
}

/// Draw [text] right-aligned so its top-right edge is at [position].
void drawTextRight(
  Canvas canvas,
  String text,
  Offset position,
  TextStyle style,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(position.dx - tp.width, position.dy));
}

/// Draw [text] horizontally centered at [position] (top-center anchor).
void drawTextCentered(
  Canvas canvas,
  String text,
  Offset position,
  TextStyle style,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy));
}

/// Draw [text] rotated by [angle] radians, centered on [center].
void drawTextRotated(
  Canvas canvas,
  String text,
  Offset center,
  double angle,
  TextStyle style,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Dashed path helper
// ---------------------------------------------------------------------------

/// Draw [path] as a dashed stroke using [paint].
///
/// [dashWidth] and [dashSpace] are in logical pixels.
void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  double dashWidth = 6.0,
  double dashSpace = 4.0,
}) {
  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    bool drawing = true;
    while (distance < metric.length) {
      final len = drawing ? dashWidth : dashSpace;
      final end = math.min(distance + len, metric.length);
      if (drawing) {
        canvas.drawPath(metric.extractPath(distance, end), paint);
      }
      distance = end;
      drawing = !drawing;
    }
  }
}

// ---------------------------------------------------------------------------
// Circle helpers
// ---------------------------------------------------------------------------

/// Draw a filled circle with a stroke outline in one call.
void drawFilledCircleWithOutline(
  Canvas canvas,
  Offset center,
  double radius,
  Color fillColor, {
  Color outlineColor = Colors.black87,
  double strokeWidth = 1.0,
}) {
  canvas.drawCircle(center, radius, Paint()..color = fillColor);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth,
  );
}

// ---------------------------------------------------------------------------
// Small-suffix text helpers
// ---------------------------------------------------------------------------

/// Draw [text] followed by a smaller [suffix] on the same baseline.
///
/// Uses the low-level [ui.Paragraph] API so both runs share a single layout.
void drawTextWithSmallSuffix(
  Canvas canvas,
  String text,
  String suffix,
  Offset position, {
  double fontSize = 10,
  double suffixFontSize = 7,
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
  ))
        ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight))
        ..addText(text)
        ..pushStyle(ui.TextStyle(color: color, fontSize: suffixFontSize, fontWeight: fontWeight))
        ..addText(' $suffix'))
      .build()
    ..layout(const ui.ParagraphConstraints(width: 300));
  canvas.drawParagraph(paragraph, position);
}

/// Draw [text] with a smaller [suffix] on the next line, centered on [center].
void drawTextCenteredWithSmallSuffix(
  Canvas canvas,
  String text,
  String suffix,
  Offset center, {
  double fontSize = 10,
  double suffixFontSize = 7,
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    textAlign: TextAlign.center,
  ))
        ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight))
        ..addText(text)
        ..pushStyle(ui.TextStyle(color: color, fontSize: suffixFontSize, fontWeight: fontWeight))
        ..addText('\n$suffix'))
      .build()
    ..layout(const ui.ParagraphConstraints(width: 200));
  canvas.drawParagraph(paragraph, Offset(center.dx - 100, center.dy));
}
