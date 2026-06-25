// lib/src/rendering/terminal_geometry.dart
//
// TerminalGeometry: resolves the position of a logical terminal at a given
// drawing level, following per-level anchors and composite delegation.

import 'package:flutter/material.dart';

import '../models/device_definition.dart';
import '../models/device_instance.dart';

/// Signature of a device-definition lookup by typeKey (same shape as
/// `RenderContext.deviceResolver`).
typedef DeviceResolver = DeviceDefinition? Function(String typeKey);

/// Resolves terminal positions across drawing levels.
///
/// A composite device's terminal may sit at different points depending on the
/// level it is rendered at:
///
/// - At **combined** levels (glyph-only appearance) the terminal's static
///   anchor applies: [TerminalDef.levelAnchors] override for the level, else
///   [TerminalDef.anchorInConnector].
/// - At **exploded** levels (appearance contains [DrawDeviceRef]s) a terminal
///   with a [TerminalDef.delegate] resolves to the referenced child's
///   terminal, transformed through the ref's (and any enclosing
///   [DrawGroup]s') offset and scale.
///
/// Wires attached to logical terminals therefore re-anchor automatically when
/// the rendered level — or a [DeviceInstance.forcedLevel] override — changes.
abstract final class TerminalGeometry {
  /// Device-local position of [terminalId] on [definition] at [level].
  ///
  /// Returns null when the terminal id is unknown. Delegation requires
  /// [resolver]; when the resolver is missing, the referenced ref is absent
  /// from the level's appearance, or the delegation chain exceeds [maxDepth]
  /// (cycle guard), resolution falls back to the static anchor — it never
  /// throws.
  static Offset? resolve({
    required DeviceDefinition definition,
    required String terminalId,
    required DrawingLevel level,
    DeviceResolver? resolver,
    int depth = 0,
    int maxDepth = 8,
  }) {
    final term = definition.findTerminal(terminalId);
    if (term == null) return null;

    final delegate = term.delegate;
    if (delegate != null && resolver != null && depth < maxDepth) {
      final appearance = definition.appearance.forLevel(level);
      final resolved = appearance?.findDeviceRef(delegate.refId);
      if (resolved != null) {
        final childDef = resolver(resolved.ref.typeKey);
        if (childDef != null) {
          final childAnchor = resolve(
            definition: childDef,
            terminalId: delegate.terminalId,
            level: resolved.ref.level ?? level,
            resolver: resolver,
            depth: depth + 1,
            maxDepth: maxDepth,
          );
          if (childAnchor != null) {
            // Mirror the renderer's transforms: enclosing groups translate
            // then scale, the ref translates then scales.
            return resolved.groupOffset +
                (resolved.ref.offset + childAnchor * resolved.ref.scale) *
                    resolved.groupScale;
          }
        }
      }
    }

    return term.anchorForLevel(level);
  }

  /// Diagram-coordinate position of [terminalId] for a placed [instance]
  /// when the surrounding diagram renders at [level].
  ///
  /// Applies [DeviceInstance.forcedLevel] (so a force-exploded composite
  /// reports its delegated child positions) and offsets by
  /// [DeviceInstance.position].
  static Offset? resolveForInstance(
    DeviceInstance instance,
    String terminalId,
    DrawingLevel level, {
    DeviceResolver? resolver,
    int maxDepth = 8,
  }) {
    final local = resolve(
      definition: instance.definition,
      terminalId: terminalId,
      level: instance.effectiveLevel(level),
      resolver: resolver,
      maxDepth: maxDepth,
    );
    if (local == null) return null;
    return instance.position + local;
  }
}
