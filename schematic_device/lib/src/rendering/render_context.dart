// lib/src/rendering/render_context.dart
//
// Diagram-level state that DSL bindings may need at render time.

import 'package:flutter/material.dart';

import '../models/device_definition.dart';

/// Optional diagram-level context passed to [DeviceRenderer.render].
///
/// Carries information that cannot be stored on a [DeviceInstance] because it
/// depends on the surrounding diagram rather than the device itself.
class RenderContext {
  /// Grid/supply voltage in volts (used by star/delta condition).
  final double? gridVoltage;

  /// Wire phase colors keyed by phase name (e.g. "L1", "L2", "L3").
  final Map<String, Color>? phaseColors;

  /// Resolver for [DrawDeviceRef] nodes — looks up a [DeviceDefinition] by
  /// its [DeviceDefinition.typeKey].  When null, device-ref nodes are skipped.
  final DeviceDefinition? Function(String typeKey)? deviceResolver;

  /// Current recursion depth (incremented by the renderer on each nested
  /// device-ref resolution).  Starts at 0 on the outermost [render] call.
  final int depth;

  /// Maximum allowed recursion depth before device-ref resolution is aborted.
  /// Guards against self-referential or cyclic device graphs.
  final int maxDepth;

  const RenderContext({
    this.gridVoltage,
    this.phaseColors,
    this.deviceResolver,
    this.depth = 0,
    this.maxDepth = 8,
  });

  static const RenderContext empty = RenderContext();

  /// Returns a copy of this context with [depth] incremented by one.
  RenderContext withDepth(int newDepth) => RenderContext(
        gridVoltage: gridVoltage,
        phaseColors: phaseColors,
        deviceResolver: deviceResolver,
        depth: newDepth,
        maxDepth: maxDepth,
      );
}
