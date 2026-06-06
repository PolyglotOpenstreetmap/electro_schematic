// lib/src/models/device_instance.dart
//
// A placed, parameterised instance of a DeviceDefinition.

import 'package:flutter/material.dart';

import 'device_definition.dart';

/// A concrete, placed instance of a [DeviceDefinition].
///
/// Combines the type-level blueprint with:
/// - a canvas position
/// - concrete parameter values
/// - runtime terminal state (connected? jumpered?)
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

  const DeviceInstance({
    required this.definition,
    this.position = Offset.zero,
    this.paramValues = const {},
    this.terminalConnected = const {},
    this.terminalIsJumper = const {},
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
  }) {
    return DeviceInstance(
      definition: definition ?? this.definition,
      position: position ?? this.position,
      paramValues: paramValues ?? this.paramValues,
      terminalConnected: terminalConnected ?? this.terminalConnected,
      terminalIsJumper: terminalIsJumper ?? this.terminalIsJumper,
    );
  }

  Map<String, dynamic> toJson() => {
        'typeKey': definition.typeKey,
        'position': {'dx': position.dx, 'dy': position.dy},
        'paramValues': paramValues,
        'terminalConnected': terminalConnected,
        'terminalIsJumper': terminalIsJumper,
      };
}
