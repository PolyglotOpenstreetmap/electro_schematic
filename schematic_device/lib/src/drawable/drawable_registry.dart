// lib/src/drawable/drawable_registry.dart
//
// Registers all built-in DrawableNode types into DrawableNodeFactory.

import 'drawable_node.dart';

/// Registers all built-in [DrawableNode] types into [DrawableNodeFactory].
///
/// Idempotent — calling multiple times has no effect because [register]
/// simply overwrites with the same factory.
void registerBuiltinDrawableNodes() {
  // Primitives (defined in the `drawable` library via primitives.dart)
  DrawableNodeFactory.register('rect', DrawRect.fromJson);
  DrawableNodeFactory.register('circle', DrawCircle.fromJson);
  DrawableNodeFactory.register('line', DrawLine.fromJson);
  DrawableNodeFactory.register('polyline', DrawPolyline.fromJson);
  DrawableNodeFactory.register('text', DrawText.fromJson);
  DrawableNodeFactory.register('path', DrawPath.fromJson);

  // Composite symbols (defined via composite_symbols.dart part)
  DrawableNodeFactory.register('coil', DrawCoil.fromJson);
  DrawableNodeFactory.register('capacitor', DrawCapacitor.fromJson);
  DrawableNodeFactory.register('terminalAnchor', DrawTerminalAnchor.fromJson);
  DrawableNodeFactory.register('group', DrawGroup.fromJson);
  DrawableNodeFactory.register('repeat', DrawRepeat.fromJson);
}
