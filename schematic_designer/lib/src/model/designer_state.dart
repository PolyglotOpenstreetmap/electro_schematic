// lib/src/model/designer_state.dart
//
// DesignerState (immutable snapshot) + DesignerHistory (undo/redo stack).

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Sentinel for nullable copyWith ──────────────────────────────────────────

const Object _sentinel = Object();

// ─── DesignerState ────────────────────────────────────────────────────────────

/// Immutable snapshot of the designer canvas state.
///
/// Supports multiple drawing levels via [appearances]. The [activeLevel]
/// determines which level is currently displayed and edited. Derived getters
/// [drawables] and [canvasSize] delegate to the active level, preserving
/// backward compatibility with code written against the single-level API.
class DesignerState {
  final String typeKey;
  final String deviceName;
  final String? description;

  /// Parameters that the device exposes for configuration.
  final List<ParameterDef> parameters;

  /// Connector/terminal definitions grouped by connector.
  final List<ConnectorDef> connectors;

  /// Which drawing level is currently active for editing.
  final DrawingLevel activeLevel;

  /// Per-level appearance data.  Only levels that have been explicitly
  /// populated are present in the map.
  final Map<DrawingLevel, LevelAppearance> appearances;

  /// Id of the currently selected node, or null.
  final String? selectedId;

  const DesignerState({
    required this.typeKey,
    required this.deviceName,
    this.description,
    this.parameters = const [],
    this.connectors = const [],
    this.activeLevel = DrawingLevel.wire,
    this.appearances = const <DrawingLevel, LevelAppearance>{},
    this.selectedId,
  });

  // ─── Named constructors ──────────────────────────────────────────────────────

  /// Creates an empty state seeded with a single wire-level appearance.
  factory DesignerState.empty(String typeKey, String deviceName) {
    return DesignerState(
      typeKey: typeKey,
      deviceName: deviceName,
      activeLevel: DrawingLevel.wire,
      appearances: const <DrawingLevel, LevelAppearance>{
        DrawingLevel.wire: LevelAppearance(size: Size(100, 100)),
      },
      parameters: const [],
      connectors: const [],
    );
  }

  /// Populates state from an existing [DeviceDefinition].
  ///
  /// [initialLevel] forces the active level; when omitted the first populated
  /// level in the order [symbol, wire, cable, topology] is selected.
  factory DesignerState.fromDefinition(
    DeviceDefinition def, {
    DrawingLevel? initialLevel,
  }) {
    final apps = <DrawingLevel, LevelAppearance>{};
    for (final level in DrawingLevel.values) {
      final la = def.appearance.forLevel(level);
      if (la != null) apps[level] = la;
    }
    if (apps.isEmpty) {
      apps[DrawingLevel.wire] = const LevelAppearance(size: Size(100, 100));
    }

    DrawingLevel active;
    if (initialLevel != null) {
      active = initialLevel;
    } else {
      const order = [
        DrawingLevel.symbol,
        DrawingLevel.wire,
        DrawingLevel.cable,
        DrawingLevel.topology,
      ];
      active = order.firstWhere(
        (l) => apps.containsKey(l),
        orElse: () => DrawingLevel.wire,
      );
    }

    return DesignerState(
      typeKey: def.typeKey,
      deviceName: def.name,
      description: def.description,
      parameters: List.unmodifiable(def.parameters),
      connectors: List.unmodifiable(def.connectors),
      activeLevel: active,
      appearances: Map.unmodifiable(apps),
    );
  }

  // ─── Derived getters (backward-compat with single-level API) ─────────────────

  /// Ordered list of drawable nodes for the active level, bottom-first.
  List<DrawableNode> get drawables =>
      appearances[activeLevel]?.drawables ?? const [];

  /// Bounding box of the device for the active level.
  Size get canvasSize =>
      appearances[activeLevel]?.size ?? const Size(100, 100);

  /// Returns the selected node, or null if none is selected.
  DrawableNode? get selectedNode {
    if (selectedId == null) return null;
    for (final d in drawables) {
      if (d.id == selectedId) return d;
    }
    return null;
  }

  /// Returns the [LevelAppearance] for [l], or null if that level has not been
  /// populated.
  LevelAppearance? appearanceFor(DrawingLevel l) => appearances[l];

  // ─── copyWith ────────────────────────────────────────────────────────────────

  DesignerState copyWith({
    String? typeKey,
    String? deviceName,
    Object? description = _sentinel,
    List<ParameterDef>? parameters,
    List<ConnectorDef>? connectors,
    DrawingLevel? activeLevel,
    Map<DrawingLevel, LevelAppearance>? appearances,
    Object? selectedId = _sentinel,
  }) {
    return DesignerState(
      typeKey: typeKey ?? this.typeKey,
      deviceName: deviceName ?? this.deviceName,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      parameters: parameters ?? this.parameters,
      connectors: connectors ?? this.connectors,
      activeLevel: activeLevel ?? this.activeLevel,
      appearances: appearances ?? this.appearances,
      selectedId: identical(selectedId, _sentinel)
          ? this.selectedId
          : selectedId as String?,
    );
  }
}

// ─── DesignerHistory ──────────────────────────────────────────────────────────

/// Manages undo/redo stacks for [DesignerState].
class DesignerHistory {
  DesignerHistory(DesignerState initial) : _current = initial;

  DesignerState _current;
  final List<DesignerState> _undoStack = [];
  final List<DesignerState> _redoStack = [];

  DesignerState get current => _current;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Pushes current to undo stack, sets new current, clears redo stack.
  void push(DesignerState state) {
    _undoStack.add(_current);
    _current = state;
    _redoStack.clear();
  }

  /// Updates current without touching the undo/redo stacks.
  void updateSilent(DesignerState s) {
    _current = s;
  }

  /// Saves current to the undo stack without changing current.
  /// Used to record the pre-drag state before live updates begin.
  void checkpoint() {
    _undoStack.add(_current);
    _redoStack.clear();
  }

  /// Pops from undo, pushes current to redo, returns new current.
  /// Returns null if undo stack is empty.
  DesignerState? undo() {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(_current);
    _current = _undoStack.removeLast();
    return _current;
  }

  /// Pops from redo, pushes current to undo, returns new current.
  /// Returns null if redo stack is empty.
  DesignerState? redo() {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(_current);
    _current = _redoStack.removeLast();
    return _current;
  }
}
