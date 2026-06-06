// lib/src/rendering/render_context.dart
//
// Diagram-level state that DSL bindings may need at render time.

import 'package:flutter/material.dart';

/// Optional diagram-level context passed to [DeviceRenderer.render].
///
/// Carries information that cannot be stored on a [DeviceInstance] because it
/// depends on the surrounding diagram rather than the device itself.
class RenderContext {
  /// Grid/supply voltage in volts (used by star/delta condition).
  final double? gridVoltage;

  /// Wire phase colors keyed by phase name (e.g. "L1", "L2", "L3").
  final Map<String, Color>? phaseColors;

  const RenderContext({
    this.gridVoltage,
    this.phaseColors,
  });

  static const RenderContext empty = RenderContext();
}
