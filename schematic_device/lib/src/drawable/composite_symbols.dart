// lib/src/drawable/composite_symbols.dart
//
// Composite / semantic drawable nodes: DrawCoil, DrawCapacitor,
// DrawTerminalAnchor, DrawGroup, DrawRepeat.
// This is a `part` file of drawable_node.dart.

part of 'drawable_node.dart';

// ─── DrawCoil ─────────────────────────────────────────────────────────────────

/// Draws an inductor / relay-coil winding as a series of filled semicircular
/// arcs between [start] and [end].
///
/// The number of arcs is auto-calculated from the distance when [arcCount] is
/// null, or pinned to [arcCount] when specified. Used for relay coil symbols,
/// motor winding representations, and inductors.
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

/// Draws a capacitor symbol as two parallel horizontal plates on a vertical
/// conductor.
///
/// [center] is the midpoint between the two plates; [plateWidth] and
/// [plateGap] control the plate geometry. Used for motor run/start capacitor
/// symbols.
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

/// Marks a named terminal connection point within a device's appearance.
///
/// The renderer draws a small dot at [position] whose fill color is
/// determined by [colorBinding]:
/// - [TerminalColorBinding.connected] → green
/// - [TerminalColorBinding.jumper] → blue
/// - [TerminalColorBinding.unconnected] → orange
///
/// When [colorBinding] is null the dot is drawn in [defaultColor] (default
/// black). The [terminalId] must match a [TerminalDef.id] declared in the
/// enclosing [DeviceDefinition].
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

/// A conditional container that groups child [DrawableNode]s under a shared
/// [showIf] condition.
///
/// When [DrawableNode.showIf] on the group itself evaluates to false the
/// entire group (and all its [children]) is skipped. Useful for star/delta
/// jumpers, capacitor presence, and optional winding configurations that
/// depend on parameter values at render time.
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

// ─── DrawDeviceRef ────────────────────────────────────────────────────────────

/// A drawable node that references another device by its [typeKey] and renders
/// it inline, translated/scaled, at the specified (or inherited) drawing level.
///
/// The renderer resolves [typeKey] through [RenderContext.deviceResolver].
/// If the resolver is null or the key is not found, this node is silently
/// skipped.  Recursion is bounded by [RenderContext.maxDepth].
///
/// This is the template-authoring path for composite devices.  The
/// instance-tree path uses [DeviceInstance.children] instead.
class DrawDeviceRef extends DrawableNode {
  /// Type key of the child device to look up and render.
  final String typeKey;

  /// Drawing level at which to render the child.  When null, inherits the
  /// current level from the parent render call.
  final DrawingLevel? level;

  /// Offset from the current canvas origin at which to draw the child.
  final Offset offset;

  /// Uniform scale applied to the child before drawing.
  final double scale;

  /// Parameter overrides passed to the child device instance.  Values may be
  /// literal values or `"\${parentParam}"` template strings that are resolved
  /// against the parent's resolved parameter map.
  final Map<String, dynamic> paramOverrides;

  const DrawDeviceRef({
    super.id,
    super.showIf,
    required this.typeKey,
    this.level,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.paramOverrides = const {},
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'deviceRef',
        if (id != null) 'id': id,
        if (showIf != null) 'showIf': showIf!.toJson(),
        'typeKey': typeKey,
        if (level != null) 'level': level!.name,
        'offset': _offsetToJson(offset),
        'scale': scale,
        if (paramOverrides.isNotEmpty) 'paramOverrides': paramOverrides,
      };

  factory DrawDeviceRef.fromJson(Map<String, dynamic> json) {
    return DrawDeviceRef(
      id: json['id'] as String?,
      showIf: _conditionFromJson(json['showIf']),
      typeKey: json['typeKey'] as String,
      level: json['level'] != null
          ? DrawingLevel.fromJson(json['level'] as String)
          : null,
      offset: json['offset'] != null
          ? _offsetFromJson(json['offset'] as Map<String, dynamic>)
          : Offset.zero,
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
      paramOverrides: Map<String, dynamic>.from(
          json['paramOverrides'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawDeviceRef &&
          id == other.id &&
          typeKey == other.typeKey &&
          level == other.level &&
          offset == other.offset &&
          scale == other.scale &&
          _mapEquals(paramOverrides, other.paramOverrides);

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, typeKey, level, offset, scale);
}

// ─── DrawRepeat ───────────────────────────────────────────────────────────────

/// Direction in which [DrawRepeat] lays out repeated copies.
enum RepeatAxis { horizontal, vertical }

/// Repeats a list of child [DrawableNode]s a parametric number of times,
/// stepping each copy by [step] pixels along [axis].
///
/// The repeat count is read from [countParam] in the instance's parameter
/// map at render time, allowing a single [DeviceDefinition] to scale terminal
/// strips to any count. Within repeated children, the special template
/// `\${_repeatIndex}` is replaced with the zero-based iteration index.
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
