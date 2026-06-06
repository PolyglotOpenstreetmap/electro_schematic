// lib/src/drawable/composite_symbols.dart
//
// Composite / semantic drawable nodes: DrawCoil, DrawCapacitor,
// DrawTerminalAnchor, DrawGroup, DrawRepeat.
// This is a `part` file of drawable_node.dart.

part of 'drawable_node.dart';

// ─── DrawCoil ─────────────────────────────────────────────────────────────────

class DrawCoil extends DrawableNode {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final int? arcCount;

  const DrawCoil({
    super.id,
    super.showIf,
    required this.start,
    required this.end,
    required this.color,
    this.strokeWidth = 1.5,
    this.arcCount,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'coil',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'start': _offsetToJson(start),
        'end': _offsetToJson(end),
        'color': colorToHexCompact(color),
        'strokeWidth': strokeWidth,
        if (arcCount != null) 'arcCount': arcCount,
      };

  factory DrawCoil.fromJson(Map<String, dynamic> json) {
    return DrawCoil(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      start: _offsetFromJson(json['start'] as Map<String, dynamic>),
      end: _offsetFromJson(json['end'] as Map<String, dynamic>),
      color: colorFromHex(json['color'] as String),
      strokeWidth: (json['strokeWidth'] as num? ?? 1.5).toDouble(),
      arcCount: json['arcCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawCoil &&
          id == other.id &&
          start == other.start &&
          end == other.end &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          arcCount == other.arcCount;

  @override
  int get hashCode =>
      Object.hash(id, start, end, color, strokeWidth, arcCount);
}

// ─── DrawCapacitor ────────────────────────────────────────────────────────────

class DrawCapacitor extends DrawableNode {
  final Offset center;
  final bool horizontal;
  final double scale;
  final Color color;

  const DrawCapacitor({
    super.id,
    super.showIf,
    required this.center,
    this.horizontal = true,
    this.scale = 1.0,
    required this.color,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'capacitor',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'center': _offsetToJson(center),
        'horizontal': horizontal,
        'scale': scale,
        'color': colorToHexCompact(color),
      };

  factory DrawCapacitor.fromJson(Map<String, dynamic> json) {
    return DrawCapacitor(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      center: _offsetFromJson(json['center'] as Map<String, dynamic>),
      horizontal: json['horizontal'] as bool? ?? true,
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
      color: colorFromHex(json['color'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawCapacitor &&
          id == other.id &&
          center == other.center &&
          horizontal == other.horizontal &&
          scale == other.scale &&
          color == other.color;

  @override
  int get hashCode => Object.hash(id, center, horizontal, scale, color);
}

// ─── DrawTerminalAnchor ───────────────────────────────────────────────────────

class DrawTerminalAnchor extends DrawableNode {
  final String terminalDefId;
  final double radius;
  final TerminalColorBinding? colorBinding;

  const DrawTerminalAnchor({
    super.id,
    super.showIf,
    required this.terminalDefId,
    this.radius = 4.0,
    this.colorBinding,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'terminalAnchor',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'terminalDefId': terminalDefId,
        'radius': radius,
        if (colorBinding != null) 'colorBinding': colorBinding!.toJson(),
      };

  factory DrawTerminalAnchor.fromJson(Map<String, dynamic> json) {
    return DrawTerminalAnchor(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      terminalDefId: json['terminalDefId'] as String,
      radius: (json['radius'] as num? ?? 4.0).toDouble(),
      colorBinding: json['colorBinding'] != null
          ? TerminalColorBinding.fromJson(
              json['colorBinding'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawTerminalAnchor &&
          id == other.id &&
          terminalDefId == other.terminalDefId &&
          radius == other.radius &&
          colorBinding == other.colorBinding;

  @override
  int get hashCode => Object.hash(id, terminalDefId, radius, colorBinding);
}

// ─── DrawGroup ────────────────────────────────────────────────────────────────

class DrawGroup extends DrawableNode {
  final List<DrawableNode> children;
  final Offset? offset;
  final double scale;

  const DrawGroup({
    super.id,
    super.showIf,
    required this.children,
    this.offset,
    this.scale = 1.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'group',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'children': children.map((c) => c.toJson()).toList(),
        if (offset != null) 'offset': _offsetToJson(offset!),
        'scale': scale,
      };

  factory DrawGroup.fromJson(Map<String, dynamic> json) {
    return DrawGroup(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      children: (json['children'] as List)
          .map((c) => DrawableNodeFactory.fromJson(c as Map<String, dynamic>))
          .toList(),
      offset: json['offset'] != null
          ? _offsetFromJson(json['offset'] as Map<String, dynamic>)
          : null,
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
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
      other is DrawGroup &&
          id == other.id &&
          offset == other.offset &&
          scale == other.scale &&
          showIf == other.showIf &&
          _listEquals(children, other.children);

  @override
  int get hashCode =>
      Object.hash(id, offset, scale, showIf, Object.hashAll(children));
}

// ─── DrawRepeat ───────────────────────────────────────────────────────────────

enum RepeatAxis { horizontal, vertical }

class DrawRepeat extends DrawableNode {
  final DrawableNode templateChild;
  final String count;
  final RepeatAxis axis;
  final double spacing;

  const DrawRepeat({
    super.id,
    super.showIf,
    required this.templateChild,
    required this.count,
    this.axis = RepeatAxis.vertical,
    required this.spacing,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'repeat',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'templateChild': templateChild.toJson(),
        'count': count,
        'axis': axis.name,
        'spacing': spacing,
      };

  factory DrawRepeat.fromJson(Map<String, dynamic> json) {
    return DrawRepeat(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      templateChild: DrawableNodeFactory.fromJson(
          json['templateChild'] as Map<String, dynamic>),
      count: json['count'].toString(),
      axis: json['axis'] != null
          ? RepeatAxis.values.byName(json['axis'] as String)
          : RepeatAxis.vertical,
      spacing: (json['spacing'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawRepeat &&
          id == other.id &&
          count == other.count &&
          axis == other.axis &&
          spacing == other.spacing &&
          templateChild == other.templateChild;

  @override
  int get hashCode => Object.hash(id, templateChild, count, axis, spacing);
}
