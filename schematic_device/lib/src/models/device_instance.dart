// lib/src/models/device_instance.dart
//
// A placed, parameterised instance of a DeviceDefinition.

import 'package:flutter/material.dart';

import 'device_definition.dart';
import 'drawing_level.dart';

// ─── ChildPlacement ───────────────────────────────────────────────────────────

/// A child [DeviceInstance] placed within a parent's coordinate space.
///
/// This is the instance-tree storage mechanism for composite devices.
/// [offset] and [scale] define the child's local transform relative to the
/// parent.  [levelOverride], when non-null, renders the child at that level
/// instead of inheriting the parent's current level.
class ChildPlacement {
  final DeviceInstance child;
  final Offset offset;
  final double scale;
  final DrawingLevel? levelOverride;

  const ChildPlacement({
    required this.child,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.levelOverride,
  });

  Map<String, dynamic> toJson() => {
        'child': child.toJson(),
        'offset': {'dx': offset.dx, 'dy': offset.dy},
        'scale': scale,
        if (levelOverride != null) 'levelOverride': levelOverride!.name,
      };

  static ChildPlacement fromJson(
    Map<String, dynamic> json, {
    DeviceDefinition? Function(String typeKey)? resolver,
  }) {
    final offsetJson = json['offset'] as Map<String, dynamic>;
    return ChildPlacement(
      child: DeviceInstance.fromJson(
        json['child'] as Map<String, dynamic>,
        resolver: resolver,
      ),
      offset: Offset(
        (offsetJson['dx'] as num).toDouble(),
        (offsetJson['dy'] as num).toDouble(),
      ),
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
      levelOverride: json['levelOverride'] != null
          ? DrawingLevel.fromJson(json['levelOverride'] as String)
          : null,
    );
  }
}

// ─── DeviceInstance ───────────────────────────────────────────────────────────

/// A concrete, placed instance of a [DeviceDefinition].
///
/// Combines the type-level blueprint with:
/// - a canvas position
/// - concrete parameter values
/// - runtime terminal state (connected? jumpered?)
/// - an optional list of explicitly placed child instances (instance-tree
///   composition path, as opposed to the template [DrawDeviceRef] path)
class DeviceInstance {
  final DeviceDefinition definition;

  /// Position of the device origin in diagram/canvas coordinates.
  final Offset position;

  /// Concrete values for each parameter declared in [DeviceDefinition.parameters].
  /// Keys are parameter ids. Missing keys fall back to the parameter's
  /// [ParameterDef.defaultValue].
  final Map<String, dynamic> paramValues;

  /// Whether each terminal (by [TerminalDef.id]) is connected to a wire.
  final Map<String, bool> terminalConnected;

  /// Per-instance override of the isJumper flag.
  ///
  /// When present, overrides [TerminalDef.isJumper] for the named terminal.
  final Map<String, bool> terminalIsJumper;

  /// Explicitly placed child instances (instance-tree composition path).
  ///
  /// The renderer draws the parent's own appearance, then recurses into each
  /// child using its [ChildPlacement.offset], [ChildPlacement.scale], and
  /// [ChildPlacement.levelOverride].
  final List<ChildPlacement> children;

  const DeviceInstance({
    required this.definition,
    this.position = Offset.zero,
    this.paramValues = const {},
    this.terminalConnected = const {},
    this.terminalIsJumper = const {},
    this.children = const [],
  });

  /// Resolved parameter value: instance value → definition default → null.
  dynamic param(String id) {
    if (paramValues.containsKey(id)) return paramValues[id];
    try {
      return definition.parameters
          .firstWhere((p) => p.id == id)
          .defaultValue;
    } catch (_) {
      return null;
    }
  }

  /// Whether the named terminal is connected.
  bool isTerminalConnected(String terminalId) =>
      terminalConnected[terminalId] ?? false;

  /// Effective isJumper: instance override → definition value → false.
  bool isTerminalJumper(String terminalId) {
    if (terminalIsJumper.containsKey(terminalId)) {
      return terminalIsJumper[terminalId]!;
    }
    final def = definition.findTerminal(terminalId);
    return def?.isJumper ?? false;
  }

  /// Creates a copy with modified fields.
  DeviceInstance copyWith({
    DeviceDefinition? definition,
    Offset? position,
    Map<String, dynamic>? paramValues,
    Map<String, bool>? terminalConnected,
    Map<String, bool>? terminalIsJumper,
    List<ChildPlacement>? children,
  }) {
    return DeviceInstance(
      definition: definition ?? this.definition,
      position: position ?? this.position,
      paramValues: paramValues ?? this.paramValues,
      terminalConnected: terminalConnected ?? this.terminalConnected,
      terminalIsJumper: terminalIsJumper ?? this.terminalIsJumper,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
        'typeKey': definition.typeKey,
        'position': {'dx': position.dx, 'dy': position.dy},
        'paramValues': paramValues,
        'terminalConnected': terminalConnected,
        'terminalIsJumper': terminalIsJumper,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(),
      };

  /// Deserializes a [DeviceInstance] from JSON.
  ///
  /// [resolver] is required to reconstruct [DeviceDefinition]s from their
  /// [DeviceDefinition.typeKey]s.  Children are deserialized recursively
  /// using the same resolver.
  ///
  /// Throws [ArgumentError] if the resolver cannot find a definition for the
  /// instance's typeKey.
  static DeviceInstance fromJson(
    Map<String, dynamic> json, {
    DeviceDefinition? Function(String typeKey)? resolver,
  }) {
    final typeKey = json['typeKey'] as String;
    final definition = resolver?.call(typeKey);
    if (definition == null) {
      throw ArgumentError(
        'DeviceInstance.fromJson: no definition found for typeKey "$typeKey". '
        'Provide a resolver that covers all device types in the graph.',
      );
    }
    final posJson = json['position'] as Map<String, dynamic>? ??
        const {'dx': 0.0, 'dy': 0.0};
    return DeviceInstance(
      definition: definition,
      position: Offset(
        (posJson['dx'] as num).toDouble(),
        (posJson['dy'] as num).toDouble(),
      ),
      paramValues:
          Map<String, dynamic>.from(json['paramValues'] as Map? ?? {}),
      terminalConnected:
          Map<String, bool>.from(json['terminalConnected'] as Map? ?? {}),
      terminalIsJumper:
          Map<String, bool>.from(json['terminalIsJumper'] as Map? ?? {}),
      children: (json['children'] as List? ?? [])
          .map((c) => ChildPlacement.fromJson(
                c as Map<String, dynamic>,
                resolver: resolver,
              ))
          .toList(),
    );
  }
}
