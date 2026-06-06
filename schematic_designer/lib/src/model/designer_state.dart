// lib/src/model/designer_state.dart
//
// DesignerState (immutable snapshot) + DesignerHistory (undo/redo stack).

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Sentinel for nullable copyWith ──────────────────────────────────────────

const Object _sentinel = Object();

// ─── DesignerState ────────────────────────────────────────────────────────────

/// Immutable snapshot of the designer canvas state.
class DesignerState {
  final String typeKey;
  final String deviceName;

  /// Bounding box of the device (canvas size in device-local coords).
  final Size canvasSize;

  /// Ordered list of drawable nodes, bottom-first (first = back).
  final List<DrawableNode> drawables;

  /// Id of the currently selected node, or null.
  final String? selectedId;

  const DesignerState({
    required this.typeKey,
    required this.deviceName,
    required this.canvasSize,
    required this.drawables,
    this.selectedId,
  });

  /// Returns the selected node, or null if none is selected.
  DrawableNode? get selectedNode {
    if (selectedId == null) return null;
    for (final d in drawables) {
      if (d.id == selectedId) return d;
    }
    return null;
  }

  DesignerState copyWith({
    String? typeKey,
    String? deviceName,
    Size? canvasSize,
    List<DrawableNode>? drawables,
    Object? selectedId = _sentinel,
  }) {
    return DesignerState(
      typeKey: typeKey ?? this.typeKey,
      deviceName: deviceName ?? this.deviceName,
      canvasSize: canvasSize ?? this.canvasSize,
      drawables: drawables ?? this.drawables,
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
