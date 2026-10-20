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

/// How [TextCapturingCanvas.drawTextRun] anchors the text horizontally.
enum DiagramTextAnchor { left, center, right }

/// Implemented by canvases that want text as text rather than as an opaque
/// paragraph — e.g. the PDF exporter, which writes real (vector, searchable)
/// text. The text helpers below call it instead of painting a `TextPainter`.
/// [position] is the top of the line box (and the left / centre / right edge,
/// per [anchor]) in the canvas' current coordinate system.
abstract interface class TextCapturingCanvas {
  void drawTextRun(
      String text, TextStyle style, Offset position, DiagramTextAnchor anchor);
}

// ---------------------------------------------------------------------------
// Entity grouping
// ---------------------------------------------------------------------------

/// Implemented by canvases that keep the drawing's structure — e.g. the SVG
/// exporter, which writes every group as a `<g>` so the entities of a schematic
/// (a device, a wire, a net) stay selectable as one object in a vector editor.
/// Painters mark an entity with [drawGrouped]; ordinary canvases ignore it.
abstract interface class GroupingCanvas {
  /// Opens a group. [id] names the entity (unique within the drawing), [label]
  /// is its human-readable name, [kind] its type, [data] free-form attributes
  /// (written as `data-*`). A [layer] is a top-level group of the drawing.
  void beginGroup(
    String id, {
    String? label,
    String? kind,
    Map<String, String> data = const {},
    bool layer = false,
  });

  /// Closes the group opened last.
  void endGroup();

  /// Writes an invisible marker at [position] (a connection point: the
  /// terminal of a device) that wires can be attached to. [id] must be unique.
  void anchor(String id, Offset position, {String? label});

  /// Whether wires between two anchors should be written as connectors that a
  /// vector editor keeps attached to them (see [drawConnectedPolyline]).
  bool get keepsConnectors;

  /// Whether the nets (a lane with drops) should be drawn as chains of
  /// straight connectors between terminal anchors and junction anchors, which
  /// no editor can re-route into something else. See [wantsNetChains].
  bool get connectsNets;

  /// Everything drawn until the matching [endOption] belongs to the option
  /// layer [name] (a layer of the drawing that can be hidden, as in LibreOffice
  /// Draw). Canvases without layers ignore it.
  void beginOption(String name);

  /// Ends the option opened last.
  void endOption();

  /// Draws the wire along [points] as a connector from the anchor [startId] to
  /// the anchor [endId] (the ids as given to [anchor]). The points run from
  /// one anchor's position to the other's.
  void connector(
    List<Offset> points,
    Paint paint, {
    required String startId,
    required String endId,
  });
}

/// Whether [canvas] wants wires between anchors as connectors.
bool wantsConnectors(Canvas canvas) =>
    canvas is GroupingCanvas && (canvas as GroupingCanvas).keepsConnectors;

/// Draws the polyline [points] with [paint]: a connector from the anchor
/// [from] to the anchor [to] on a canvas that [wantsConnectors], else an
/// ordinary stroked path.
void drawConnectedPolyline(
  Canvas canvas,
  List<Offset> points,
  Paint paint, {
  required String from,
  required String to,
}) {
  if (wantsConnectors(canvas)) {
    (canvas as GroupingCanvas)
        .connector(points, paint, startId: from, endId: to);
    return;
  }
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path, paint);
}

/// Runs [draw] inside a group of [canvas] when it keeps groups
/// ([GroupingCanvas]); a plain call of [draw] on every other canvas. With
/// [option], the group's contents go to that option layer.
void drawGrouped(
  Canvas canvas,
  String id,
  void Function() draw, {
  String? label,
  String? kind,
  Map<String, String> data = const {},
  bool layer = false,
  String? option,
}) {
  if (canvas is! GroupingCanvas) {
    draw();
    return;
  }
  final grouping = canvas as GroupingCanvas;
  if (option != null) grouping.beginOption(option);
  grouping.beginGroup(id, label: label, kind: kind, data: data, layer: layer);
  try {
    draw();
  } finally {
    grouping.endGroup();
    if (option != null) grouping.endOption();
  }
}

/// Runs [draw] on the option layer [option] of canvases that have layers
/// ([GroupingCanvas]); a plain call of [draw] elsewhere or without [option].
void drawOnOption(Canvas canvas, String? option, void Function() draw) {
  if (option == null || canvas is! GroupingCanvas) {
    draw();
    return;
  }
  final grouping = canvas as GroupingCanvas;
  grouping.beginOption(option);
  try {
    draw();
  } finally {
    grouping.endOption();
  }
}

/// Whether [canvas] wants nets as chains of connectors ([GroupingCanvas.connectsNets]).
bool wantsNetChains(Canvas canvas) =>
    canvas is GroupingCanvas && (canvas as GroupingCanvas).connectsNets;

/// Marks a connection point at [position] on canvases that keep structure
/// ([GroupingCanvas]); does nothing elsewhere.
void markAnchor(Canvas canvas, String id, Offset position, {String? label}) {
  if (canvas is GroupingCanvas) {
    (canvas as GroupingCanvas).anchor(id, position, label: label);
  }
}

/// Draw [text] left-aligned with its top-left at [position].
void drawText(
  Canvas canvas,
  String text,
  Offset position,
  TextStyle style,
) {
  if (canvas is TextCapturingCanvas) {
    (canvas as TextCapturingCanvas)
        .drawTextRun(text, style, position, DiagramTextAnchor.left);
    return;
  }
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
  if (canvas is TextCapturingCanvas) {
    (canvas as TextCapturingCanvas)
        .drawTextRun(text, style, position, DiagramTextAnchor.right);
    return;
  }
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
  if (canvas is TextCapturingCanvas) {
    (canvas as TextCapturingCanvas)
        .drawTextRun(text, style, position, DiagramTextAnchor.center);
    return;
  }
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
  if (canvas is TextCapturingCanvas) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    (canvas as TextCapturingCanvas).drawTextRun(text, style,
        Offset(0, -(style.fontSize ?? 14) * 0.59), DiagramTextAnchor.center);
    canvas.restore();
    return;
  }
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

/// Implemented by canvases that can dash a stroke themselves (the SVG
/// exporter writes one element with `stroke-dasharray` instead of a path per
/// dash). [drawDashedPath] calls it instead of cutting the path up.
abstract interface class DashedPathCapturingCanvas {
  void drawDashedStroke(
    Path path,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  });
}

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
  if (canvas is DashedPathCapturingCanvas) {
    (canvas as DashedPathCapturingCanvas).drawDashedStroke(path, paint,
        dashWidth: dashWidth, dashSpace: dashSpace);
    return;
  }
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
        ..pushStyle(ui.TextStyle(
            color: color, fontSize: fontSize, fontWeight: fontWeight))
        ..addText(text)
        ..pushStyle(ui.TextStyle(
            color: color, fontSize: suffixFontSize, fontWeight: fontWeight))
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
      : Rect.fromLTWH(
          anchor.dx - arrowW - width, anchor.dy - height / 2, width, height);

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
        ..pushStyle(ui.TextStyle(
            color: color, fontSize: fontSize, fontWeight: fontWeight))
        ..addText(text)
        ..pushStyle(ui.TextStyle(
            color: color, fontSize: suffixFontSize, fontWeight: fontWeight))
        ..addText('\n$suffix'))
      .build()
    ..layout(const ui.ParagraphConstraints(width: 200));
  canvas.drawParagraph(paragraph, Offset(center.dx - 100, center.dy));
}
