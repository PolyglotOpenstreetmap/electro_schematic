import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/cross_reference.dart';

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

// ---------------------------------------------------------------------------
// Cross-reference marker
// ---------------------------------------------------------------------------

/// Draw an IEC 60617-style cross-reference marker at [anchor].
///
/// Renders a small bordered box with a directional arrow (→ or ←) and the
/// [ref.annotationText] inside, positioned so its arrow tip touches [anchor].
///
/// [anchor] should be the diagram-space coordinate of the wire exit point
/// (typically obtained via `getTerminalPosition`).
///
/// The marker is 44 × 12 px (logical). For [outgoing] markers the box is to
/// the right of [anchor] with an inbound pointing arrow; for [incoming] markers
/// it is to the left with an outbound pointing arrow.  Callers can adjust the
/// marker width by passing a different [width].
void drawCrossReferenceMarker(
  Canvas canvas,
  CrossReference ref,
  Offset anchor, {
  double width = 48.0,
  double height = 14.0,
  TextStyle? textStyle,
}) {
  const arrowW = 6.0;
  final isOutgoing = ref.direction == CrossReferenceDirection.outgoing;

  // Box rect: outgoing → box to the right of anchor; incoming → to the left.
  final boxRect = isOutgoing
      ? Rect.fromLTWH(anchor.dx + arrowW, anchor.dy - height / 2, width, height)
      : Rect.fromLTWH(anchor.dx - arrowW - width, anchor.dy - height / 2, width, height);

  // Background
  canvas.drawRect(
    boxRect,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );

  // Border
  canvas.drawRect(
    boxRect,
    Paint()
      ..color = Colors.black87
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke,
  );

  // Arrow polygon attached to the wire side of the box.
  final arrowTip = anchor;
  final arrowBase = isOutgoing
      ? Offset(anchor.dx + arrowW, anchor.dy)
      : Offset(anchor.dx - arrowW, anchor.dy);
  final arrowTop = Offset(arrowBase.dx, anchor.dy - height / 2);
  final arrowBot = Offset(arrowBase.dx, anchor.dy + height / 2);

  final arrowPath = Path()
    ..moveTo(arrowTip.dx, arrowTip.dy)
    ..lineTo(arrowTop.dx, arrowTop.dy)
    ..lineTo(arrowBot.dx, arrowBot.dy)
    ..close();

  canvas.drawPath(
    arrowPath,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    arrowPath,
    Paint()
      ..color = Colors.black87
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke,
  );

  // Label text
  final style = textStyle ??
      const TextStyle(
        color: Colors.black87,
        fontSize: 7,
        fontWeight: FontWeight.normal,
      );
  final tp = TextPainter(
    text: TextSpan(text: ref.annotationText, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 4);

  final textX = boxRect.left + (width - tp.width) / 2;
  final textY = boxRect.top + (height - tp.height) / 2;
  tp.paint(canvas, Offset(textX, textY));
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
