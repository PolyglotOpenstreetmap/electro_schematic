// lib/src/models/device_definition.dart
//
// Core data model: DeviceDefinition, ConnectorDef, TerminalDef.

import 'package:flutter/material.dart';

import '../drawable/drawable_node.dart';
import 'parameter_def.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Functional grouping of a terminal — analogous to ConnectionGroup in
/// schematic_wire but defined locally so this package has no dependency on it.
enum ElectricalGroup {
  power,
  communication,
  control,
  ground,
  pe;

  static ElectricalGroup fromJson(String name) =>
      ElectricalGroup.values.byName(name);
}

/// Where a connector is located on a device body.
enum ConnectorPlacement {
  top,
  bottom,
  left,
  right,
  internal,
  embedded;

  static ConnectorPlacement fromJson(String name) =>
      ConnectorPlacement.values.byName(name);
}

/// Which diagram level to render at.
enum DrawingLevel {
  wire,
  cable,
  topology;

  static DrawingLevel fromJson(String name) =>
      DrawingLevel.values.byName(name);
}

// ─── TerminalDef ─────────────────────────────────────────────────────────────

/// Definition of a single electrical terminal within a ConnectorDef.
class TerminalDef {
  final String id;
  final String label;
  final ElectricalGroup group;

  /// Position (in connector-local coordinates) at which the terminal dot is
  /// drawn and from which wires exit.
  final Offset anchorInConnector;

  /// True for terminals that carry jumper bridges internally (e.g. U2/V2/W2
  /// in a star-wound motor before star/delta switching).
  final bool isJumper;

  final String? description;

  const TerminalDef({
    required this.id,
    required this.label,
    required this.group,
    required this.anchorInConnector,
    this.isJumper = false,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'group': group.name,
        'anchorInConnector': {
          'dx': anchorInConnector.dx,
          'dy': anchorInConnector.dy,
        },
        'isJumper': isJumper,
        if (description != null) 'description': description,
      };

  factory TerminalDef.fromJson(Map<String, dynamic> json) {
    final anchor = json['anchorInConnector'] as Map<String, dynamic>;
    return TerminalDef(
      id: json['id'] as String,
      label: json['label'] as String,
      group: ElectricalGroup.fromJson(json['group'] as String),
      anchorInConnector: Offset(
        (anchor['dx'] as num).toDouble(),
        (anchor['dy'] as num).toDouble(),
      ),
      isJumper: json['isJumper'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalDef &&
          id == other.id &&
          label == other.label &&
          group == other.group &&
          anchorInConnector == other.anchorInConnector &&
          isJumper == other.isJumper &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, label, group, anchorInConnector,
      isJumper, description);
}

// ─── ConnectorDef ────────────────────────────────────────────────────────────

/// A logical group of terminals on one side / location of a device.
class ConnectorDef {
  final String id;
  final String name;
  final ConnectorPlacement placement;
  final List<TerminalDef> terminals;

  const ConnectorDef({
    required this.id,
    required this.name,
    required this.placement,
    required this.terminals,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'placement': placement.name,
        'terminals': terminals.map((t) => t.toJson()).toList(),
      };

  factory ConnectorDef.fromJson(Map<String, dynamic> json) {
    return ConnectorDef(
      id: json['id'] as String,
      name: json['name'] as String,
      placement: ConnectorPlacement.fromJson(json['placement'] as String),
      terminals: (json['terminals'] as List)
          .map((t) => TerminalDef.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectorDef &&
          id == other.id &&
          name == other.name &&
          placement == other.placement &&
          _listEquals(terminals, other.terminals);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name, placement, Object.hashAll(terminals));
}

// ─── LevelAppearance ─────────────────────────────────────────────────────────

/// Drawing specification for one diagram level (wire / cable / topology).
class LevelAppearance {
  final Size size;
  final List<DrawableNode> drawables;

  const LevelAppearance({
    required this.size,
    this.drawables = const [],
  });

  Map<String, dynamic> toJson() => {
        'size': {'width': size.width, 'height': size.height},
        'drawables': drawables.map((d) => d.toJson()).toList(),
      };

  factory LevelAppearance.fromJson(Map<String, dynamic> json) {
    final s = json['size'] as Map<String, dynamic>;
    return LevelAppearance(
      size: Size(
        (s['width'] as num).toDouble(),
        (s['height'] as num).toDouble(),
      ),
      drawables: (json['drawables'] as List? ?? [])
          .map((d) => DrawableNodeFactory.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelAppearance &&
          size == other.size &&
          _listEquals(drawables, other.drawables);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(drawables));
}

// ─── DeviceAppearance ────────────────────────────────────────────────────────

/// Per-level appearance container.
class DeviceAppearance {
  final LevelAppearance? wire;
  final LevelAppearance? cable;
  final LevelAppearance? topology;

  const DeviceAppearance({
    this.wire,
    this.cable,
    this.topology,
  });

  LevelAppearance? forLevel(DrawingLevel level) => switch (level) {
        DrawingLevel.wire => wire,
        DrawingLevel.cable => cable,
        DrawingLevel.topology => topology,
      };

  Map<String, dynamic> toJson() => {
        if (wire != null) 'wire': wire!.toJson(),
        if (cable != null) 'cable': cable!.toJson(),
        if (topology != null) 'topology': topology!.toJson(),
      };

  factory DeviceAppearance.fromJson(Map<String, dynamic> json) {
    return DeviceAppearance(
      wire: json['wire'] != null
          ? LevelAppearance.fromJson(json['wire'] as Map<String, dynamic>)
          : null,
      cable: json['cable'] != null
          ? LevelAppearance.fromJson(json['cable'] as Map<String, dynamic>)
          : null,
      topology: json['topology'] != null
          ? LevelAppearance.fromJson(json['topology'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAppearance &&
          wire == other.wire &&
          cable == other.cable &&
          topology == other.topology;

  @override
  int get hashCode => Object.hash(wire, cable, topology);
}

// ─── DeviceDefinition ────────────────────────────────────────────────────────

/// Blueprint for a type of electrical device.
///
/// Defines what terminals are available, how they are grouped into connectors,
/// what parameters can be configured, and how to draw the device at each
/// diagram level.
class DeviceDefinition {
  final String typeKey;
  final String name;
  final String? description;
  final List<ParameterDef> parameters;
  final List<ConnectorDef> connectors;
  final DeviceAppearance appearance;

  const DeviceDefinition({
    required this.typeKey,
    required this.name,
    this.description,
    this.parameters = const [],
    this.connectors = const [],
    required this.appearance,
  });

  /// All terminal definitions across all connectors.
  List<TerminalDef> get allTerminals =>
      connectors.expand((c) => c.terminals).toList();

  /// Find a terminal definition by its [id].
  TerminalDef? findTerminal(String id) {
    for (final c in connectors) {
      for (final t in c.terminals) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  /// Effective [defaultValue] map for all parameters.
  Map<String, dynamic> get defaultParams =>
      {for (final p in parameters) p.id: p.defaultValue};

  Map<String, dynamic> toJson() => {
        'typeKey': typeKey,
        'name': name,
        if (description != null) 'description': description,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'connectors': connectors.map((c) => c.toJson()).toList(),
        'appearance': appearance.toJson(),
      };

  factory DeviceDefinition.fromJson(Map<String, dynamic> json) {
    return DeviceDefinition(
      typeKey: json['typeKey'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parameters: (json['parameters'] as List? ?? [])
          .map((p) => ParameterDef.fromJson(p as Map<String, dynamic>))
          .toList(),
      connectors: (json['connectors'] as List? ?? [])
          .map((c) => ConnectorDef.fromJson(c as Map<String, dynamic>))
          .toList(),
      appearance: DeviceAppearance.fromJson(
          json['appearance'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceDefinition &&
          typeKey == other.typeKey &&
          name == other.name &&
          description == other.description &&
          _listEquals(parameters, other.parameters) &&
          _listEquals(connectors, other.connectors) &&
          appearance == other.appearance;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      typeKey, name, description,
      Object.hashAll(parameters),
      Object.hashAll(connectors),
      appearance);
}
