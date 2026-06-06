// lib/src/drawable/primitives.dart
//
// Primitive drawable node types: Rect, Circle, Line, Polyline, Text, Path.
// This is a `part` file of drawable_node.dart.

part of 'drawable_node.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Stroke style for drawn lines and shape outlines.
enum LineStyle {
  solid,
  dashed,
  dashDot;

  static LineStyle fromJson(String s) => LineStyle.values.byName(s);
}

/// Horizontal alignment of a [DrawText] label relative to its anchor point.
enum TextAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  static TextAnchor fromJson(String s) => TextAnchor.values.byName(s);
}

// ─── DrawRect ────────────────────────────────────────────────────────────────

/// Draws an axis-aligned rectangle with optional fill, stroke, corner radius,
/// and line style.
///
/// Use for device body outlines, terminal block borders, and background shapes.
/// Both [fillColor] and [strokeColor] may be null (invisible) independently.
class DrawRect extends DrawableNode {
  final Rect rect;
  final double cornerRadius;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final LineStyle lineStyle;

  const DrawRect({
    super.id,
    super.showIf,
    required this.rect,
    this.cornerRadius = 0,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.lineStyle = LineStyle.solid,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rect',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'rect': {
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        },
        'cornerRadius': cornerRadius,
        if (fillColor != null) 'fillColor': colorToHexCompact(fillColor!),
        if (strokeColor != null) 'strokeColor': colorToHexCompact(strokeColor!),
        'strokeWidth': strokeWidth,
        'lineStyle': lineStyle.name,
      };

  factory DrawRect.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return DrawRect(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      rect: Rect.fromLTRB(
        (r['left'] as num).toDouble(),
        (r['top'] as num).toDouble(),
        (r['right'] as num).toDouble(),
        (r['bottom'] as num).toDouble(),
      ),
      cornerRadius: (json['cornerRadius'] as num? ?? 0).toDouble(),
      fillColor: json['fillColor'] != null
          ? colorFromHex(json['fillColor'] as String)
          : null,
      strokeColor: json['strokeColor'] != null
          ? colorFromHex(json['strokeColor'] as String)
          : null,
      strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
      lineStyle: json['lineStyle'] != null
          ? LineStyle.fromJson(json['lineStyle'] as String)
          : LineStyle.solid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawRect &&
          id == other.id &&
          rect == other.rect &&
          cornerRadius == other.cornerRadius &&
          fillColor == other.fillColor &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          lineStyle == other.lineStyle;

  @override
  int get hashCode => Object.hash(
      id, rect, cornerRadius, fillColor, strokeColor, strokeWidth, lineStyle);
}

// ─── DrawCircle ───────────────────────────────────────────────────────────────

/// Draws a circle (or ellipse) by center point and radius.
///
/// When [radiusY] is omitted the shape is a perfect circle. Use for dots,
/// cable cross-section conductors, and schematic component symbols.
class DrawCircle extends DrawableNode {
  final Offset center;
  final double radius;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final TerminalColorBinding? fillBinding;

  const DrawCircle({
    super.id,
    super.showIf,
    required this.center,
    required this.radius,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.fillBinding,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'circle',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'center': _offsetToJson(center),
        'radius': radius,
        if (fillColor != null) 'fillColor': colorToHexCompact(fillColor!),
        if (strokeColor != null) 'strokeColor': colorToHexCompact(strokeColor!),
        'strokeWidth': strokeWidth,
        if (fillBinding != null) 'fillBinding': fillBinding!.toJson(),
      };

  factory DrawCircle.fromJson(Map<String, dynamic> json) {
    return DrawCircle(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      center: _offsetFromJson(json['center'] as Map<String, dynamic>),
      radius: (json['radius'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? colorFromHex(json['fillColor'] as String)
          : null,
      strokeColor: json['strokeColor'] != null
          ? colorFromHex(json['strokeColor'] as String)
          : null,
      strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
      fillBinding: json['fillBinding'] != null
          ? TerminalColorBinding.fromJson(
              json['fillBinding'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawCircle &&
          id == other.id &&
          center == other.center &&
          radius == other.radius &&
          fillColor == other.fillColor &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          fillBinding == other.fillBinding;

  @override
  int get hashCode => Object.hash(
      id, center, radius, fillColor, strokeColor, strokeWidth, fillBinding);
}

// ─── DrawLine ─────────────────────────────────────────────────────────────────

/// Draws a straight line segment between two points.
///
/// Supports solid, dashed, and dotted [lineStyle]. Use for wire stubs,
/// terminal connectors, and IEC symbol lines.
class DrawLine extends DrawableNode {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final LineStyle lineStyle;

  const DrawLine({
    super.id,
    super.showIf,
    required this.start,
    required this.end,
    required this.color,
    this.strokeWidth = 1.0,
    this.lineStyle = LineStyle.solid,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'line',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'start': _offsetToJson(start),
        'end': _offsetToJson(end),
        'color': colorToHexCompact(color),
        'strokeWidth': strokeWidth,
        'lineStyle': lineStyle.name,
      };

  factory DrawLine.fromJson(Map<String, dynamic> json) {
    return DrawLine(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      start: _offsetFromJson(json['start'] as Map<String, dynamic>),
      end: _offsetFromJson(json['end'] as Map<String, dynamic>),
      color: colorFromHex(json['color'] as String),
      strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
      lineStyle: json['lineStyle'] != null
          ? LineStyle.fromJson(json['lineStyle'] as String)
          : LineStyle.solid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawLine &&
          id == other.id &&
          start == other.start &&
          end == other.end &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          lineStyle == other.lineStyle;

  @override
  int get hashCode =>
      Object.hash(id, start, end, color, strokeWidth, lineStyle);
}

// ─── DrawPolyline ─────────────────────────────────────────────────────────────

/// Draws a multi-segment open path through an ordered list of points.
///
/// The path is stroked but not closed (for closed shapes use [DrawPath]).
/// Useful for zigzag resistor symbols, winding outlines, and custom outlines.
class DrawPolyline extends DrawableNode {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final LineStyle lineStyle;
  final bool closed;

  const DrawPolyline({
    super.id,
    super.showIf,
    required this.points,
    required this.color,
    this.strokeWidth = 1.0,
    this.lineStyle = LineStyle.solid,
    this.closed = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'polyline',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'points': points.map(_offsetToJson).toList(),
        'color': colorToHexCompact(color),
        'strokeWidth': strokeWidth,
        'lineStyle': lineStyle.name,
        'closed': closed,
      };

  factory DrawPolyline.fromJson(Map<String, dynamic> json) {
    return DrawPolyline(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      points: (json['points'] as List)
          .map((p) => _offsetFromJson(p as Map<String, dynamic>))
          .toList(),
      color: colorFromHex(json['color'] as String),
      strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
      lineStyle: json['lineStyle'] != null
          ? LineStyle.fromJson(json['lineStyle'] as String)
          : LineStyle.solid,
      closed: json['closed'] as bool? ?? false,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawPolyline &&
          id == other.id &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          lineStyle == other.lineStyle &&
          closed == other.closed &&
          _listEquals(points, other.points);

  @override
  int get hashCode => Object.hash(
      id, color, strokeWidth, lineStyle, closed, Object.hashAll(points));
}

// ─── DrawText ─────────────────────────────────────────────────────────────────

/// Renders a text label at a fixed position within device-local coordinates.
///
/// The [text] string supports `\${paramId}` substitution — at render time
/// each `\${…}` placeholder is replaced with the corresponding resolved
/// parameter value from [DeviceInstance]. [anchor] controls whether the text
/// is left-, center-, or right-aligned relative to [position].
class DrawText extends DrawableNode {
  final String text;
  final Offset position;
  final TextAnchor anchor;
  final double fontSize;
  final bool bold;
  final Color color;
  final TerminalColorBinding? colorBinding;

  const DrawText({
    super.id,
    super.showIf,
    required this.text,
    required this.position,
    this.anchor = TextAnchor.topLeft,
    this.fontSize = 10.0,
    this.bold = false,
    this.color = const Color(0xFF000000),
    this.colorBinding,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'text': text,
        'position': _offsetToJson(position),
        'anchor': anchor.name,
        'fontSize': fontSize,
        'bold': bold,
        'color': colorToHexCompact(color),
        if (colorBinding != null) 'colorBinding': colorBinding!.toJson(),
      };

  factory DrawText.fromJson(Map<String, dynamic> json) {
    return DrawText(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      text: json['text'] as String,
      position: _offsetFromJson(json['position'] as Map<String, dynamic>),
      anchor: json['anchor'] != null
          ? TextAnchor.fromJson(json['anchor'] as String)
          : TextAnchor.topLeft,
      fontSize: (json['fontSize'] as num? ?? 10.0).toDouble(),
      bold: json['bold'] as bool? ?? false,
      color: json['color'] != null
          ? colorFromHex(json['color'] as String)
          : const Color(0xFF000000),
      colorBinding: json['colorBinding'] != null
          ? TerminalColorBinding.fromJson(
              json['colorBinding'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawText &&
          id == other.id &&
          text == other.text &&
          position == other.position &&
          anchor == other.anchor &&
          fontSize == other.fontSize &&
          bold == other.bold &&
          color == other.color &&
          colorBinding == other.colorBinding;

  @override
  int get hashCode => Object.hash(
      id, text, position, anchor, fontSize, bold, color, colorBinding);
}

// ─── DrawPath ─────────────────────────────────────────────────────────────────

/// Draws an arbitrary path described as a list of `ui.Path` operations.
///
/// Operations are stored as a JSON-serializable list of `{'op': String, ...}`
/// maps and reconstructed into a `ui.Path` at render time. Supports all
/// standard Flutter path operations (moveTo, lineTo, cubicTo, close, etc.).
/// Use for IEC component symbols, arrowheads, and complex outlines.
class DrawPath extends DrawableNode {
  final List<String> svgPathData;
  final Color color;
  final double strokeWidth;
  final LineStyle lineStyle;
  final bool fill;

  const DrawPath({
    super.id,
    super.showIf,
    required this.svgPathData,
    required this.color,
    this.strokeWidth = 1.0,
    this.lineStyle = LineStyle.solid,
    this.fill = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'path',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'svgPathData': svgPathData,
        'color': colorToHexCompact(color),
        'strokeWidth': strokeWidth,
        'lineStyle': lineStyle.name,
        'fill': fill,
      };

  factory DrawPath.fromJson(Map<String, dynamic> json) {
    return DrawPath(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      svgPathData: List<String>.from(json['svgPathData'] as List),
      color: colorFromHex(json['color'] as String),
      strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
      lineStyle: json['lineStyle'] != null
          ? LineStyle.fromJson(json['lineStyle'] as String)
          : LineStyle.solid,
      fill: json['fill'] as bool? ?? false,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawPath &&
          id == other.id &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          lineStyle == other.lineStyle &&
          fill == other.fill &&
          _listEquals(svgPathData, other.svgPathData);

  @override
  int get hashCode => Object.hash(
      id, color, strokeWidth, lineStyle, fill, Object.hashAll(svgPathData));
}
