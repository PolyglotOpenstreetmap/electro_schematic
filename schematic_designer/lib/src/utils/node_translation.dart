// lib/src/utils/node_translation.dart
//
// translateNode: shifts a DrawableNode's positional coordinates by [delta].

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

/// Returns a copy of [node] with all positional coordinates shifted by [delta].
///
/// DrawTerminalAnchor, DrawPath, and DrawRepeat are returned unchanged because
/// their positions are defined indirectly (via terminal definitions, SVG path
/// strings, or template child indexing respectively).
DrawableNode translateNode(DrawableNode node, Offset delta) {
  return switch (node) {
    DrawRect() => DrawRect(
        id: node.id,
        showIf: node.showIf,
        rect: node.rect.shift(delta),
        cornerRadius: node.cornerRadius,
        fillColor: node.fillColor,
        strokeColor: node.strokeColor,
        strokeWidth: node.strokeWidth,
        lineStyle: node.lineStyle,
      ),
    DrawCircle() => DrawCircle(
        id: node.id,
        showIf: node.showIf,
        center: node.center + delta,
        radius: node.radius,
        fillColor: node.fillColor,
        strokeColor: node.strokeColor,
        strokeWidth: node.strokeWidth,
        fillBinding: node.fillBinding,
      ),
    DrawLine() => DrawLine(
        id: node.id,
        showIf: node.showIf,
        start: node.start + delta,
        end: node.end + delta,
        color: node.color,
        strokeWidth: node.strokeWidth,
        lineStyle: node.lineStyle,
      ),
    DrawPolyline() => DrawPolyline(
        id: node.id,
        showIf: node.showIf,
        points: node.points.map((p) => p + delta).toList(),
        color: node.color,
        strokeWidth: node.strokeWidth,
        lineStyle: node.lineStyle,
        closed: node.closed,
      ),
    DrawText() => DrawText(
        id: node.id,
        showIf: node.showIf,
        text: node.text,
        position: node.position + delta,
        anchor: node.anchor,
        fontSize: node.fontSize,
        bold: node.bold,
        color: node.color,
        colorBinding: node.colorBinding,
      ),
    DrawPath() => node, // SVG path data cannot be trivially translated
    DrawCoil() => DrawCoil(
        id: node.id,
        showIf: node.showIf,
        start: node.start + delta,
        end: node.end + delta,
        color: node.color,
        strokeWidth: node.strokeWidth,
        arcCount: node.arcCount,
      ),
    DrawCapacitor() => DrawCapacitor(
        id: node.id,
        showIf: node.showIf,
        center: node.center + delta,
        horizontal: node.horizontal,
        scale: node.scale,
        color: node.color,
      ),
    DrawTerminalAnchor() => node, // position is in the terminal definition
    DrawGroup() => DrawGroup(
        id: node.id,
        showIf: node.showIf,
        children: node.children,
        offset: (node.offset ?? Offset.zero) + delta,
        scale: node.scale,
      ),
    DrawRepeat() => node, // complex template — leave unchanged
    DrawDeviceRef() => node, // position is encoded in offset field; leave to caller
  };
}
