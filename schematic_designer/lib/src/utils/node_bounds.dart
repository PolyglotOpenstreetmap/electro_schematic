// lib/src/utils/node_bounds.dart
//
// NodeBoundsHelper: approximate hit-test and bounding-rect for DrawableNodes.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

abstract final class NodeBoundsHelper {
  /// Returns approximate bounding rect in device-local coords, or null.
  ///
  /// Returns null for types whose bounds cannot be cheaply computed
  /// (DrawPath, DrawRepeat) or that depend on external state not available
  /// here without a definition.
  static Rect? boundsOf(DrawableNode node, [DeviceDefinition? definition]) {
    return switch (node) {
      DrawRect() => node.rect.inflate(node.strokeWidth / 2),
      DrawCircle() => Rect.fromCircle(
          center: node.center,
          radius: node.radius + node.strokeWidth / 2,
        ),
      DrawLine() => Rect.fromPoints(node.start, node.end)
          .inflate(_max(node.strokeWidth, 6.0)),
      DrawPolyline() => _polylineBounds(node),
      DrawText() => Rect.fromCenter(
          center: node.position,
          width: node.fontSize * 5,
          height: node.fontSize * 2,
        ),
      DrawCoil() => Rect.fromPoints(node.start, node.end).inflate(12),
      DrawCapacitor() => Rect.fromCircle(
          center: node.center,
          radius: (8 + 10) * node.scale,
        ),
      DrawTerminalAnchor() => _terminalAnchorBounds(node, definition),
      DrawGroup() => _groupBounds(node, definition),
      DrawRepeat() => null, // complex
      DrawPath() => null, // SVG too complex
    };
  }

  /// Returns the topmost node (last in list) whose bounds contain [point],
  /// or null if no node contains it.
  static DrawableNode? hitTest(
    List<DrawableNode> nodes,
    Offset point, [
    DeviceDefinition? definition,
  ]) {
    // Iterate in reverse so the topmost (last drawn) node wins.
    for (var i = nodes.length - 1; i >= 0; i--) {
      final bounds = boundsOf(nodes[i], definition);
      if (bounds != null && bounds.contains(point)) {
        return nodes[i];
      }
    }
    return null;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  static double _max(double a, double b) => a > b ? a : b;

  static Rect? _polylineBounds(DrawPolyline node) {
    if (node.points.isEmpty) return null;
    var minX = node.points.first.dx;
    var minY = node.points.first.dy;
    var maxX = minX;
    var maxY = minY;
    for (final p in node.points.skip(1)) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY)
        .inflate(_max(node.strokeWidth, 4.0));
  }

  static Rect? _terminalAnchorBounds(
      DrawTerminalAnchor node, DeviceDefinition? definition) {
    if (definition == null) return null;
    final terminal = definition.findTerminal(node.terminalDefId);
    if (terminal == null) return null;
    return Rect.fromCircle(
      center: terminal.anchorInConnector,
      radius: node.radius + 2,
    );
  }

  static Rect? _groupBounds(DrawGroup node, DeviceDefinition? definition) {
    Rect? result;
    final groupOffset = node.offset ?? Offset.zero;

    for (final child in node.children) {
      final childBounds = boundsOf(child, definition);
      if (childBounds == null) continue;
      final translated = childBounds.translate(groupOffset.dx, groupOffset.dy);
      result = result == null ? translated : result.expandToInclude(translated);
    }
    return result;
  }
}
