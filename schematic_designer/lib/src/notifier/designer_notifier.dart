// lib/src/notifier/designer_notifier.dart
//
// DesignerNotifier: ChangeNotifier wrapping DesignerHistory.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../model/designer_state.dart';
import '../utils/node_translation.dart';

/// ChangeNotifier that owns the designer state and exposes mutations.
///
/// All structural mutations push a history entry so undo/redo works.
/// Selection changes are silent (no history entry).
class DesignerNotifier extends ChangeNotifier {
  DesignerNotifier(DesignerState initial) : _history = DesignerHistory(initial);

  final DesignerHistory _history;
  int _idCounter = 0;

  // Drag state
  DesignerState? _preDragState;
  String? _draggingId;

  // ─── Accessors ─────────────────────────────────────────────────────────────

  DesignerState get state => _history.current;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  // ─── Selection (no history) ────────────────────────────────────────────────

  void selectNode(String? id) {
    if (state.selectedId == id) return;
    _history.updateSilent(state.copyWith(selectedId: id));
    notifyListeners();
  }

  // ─── Structural mutations (push to history) ────────────────────────────────

  void addNode(DrawableNode node) {
    // Assign an id if the node doesn't have one.
    final DrawableNode nodeWithId;
    if (node.id == null) {
      final newId = 'n${_idCounter++}';
      nodeWithId =
          DrawableNodeFactory.fromJson({...node.toJson(), 'id': newId});
    } else {
      nodeWithId = node;
      // Ensure counter stays ahead of any explicitly-assigned 'nN' ids.
      final match = RegExp(r'^n(\d+)$').firstMatch(node.id!);
      if (match != null) {
        final num = int.parse(match.group(1)!);
        if (num >= _idCounter) _idCounter = num + 1;
      }
    }

    final newDrawables = [...state.drawables, nodeWithId];
    _history.push(
        state.copyWith(drawables: newDrawables, selectedId: nodeWithId.id));
    notifyListeners();
  }

  void removeNode(String id) {
    final newDrawables =
        state.drawables.where((d) => d.id != id).toList();
    final newSelected =
        state.selectedId == id ? null : state.selectedId;
    _history.push(state.copyWith(
        drawables: newDrawables, selectedId: newSelected));
    notifyListeners();
  }

  void updateNode(DrawableNode updated) {
    final idx = state.drawables.indexWhere((d) => d.id == updated.id);
    if (idx < 0) return;
    final newDrawables = [...state.drawables];
    newDrawables[idx] = updated;
    _history.push(state.copyWith(drawables: newDrawables));
    notifyListeners();
  }

  void reorderNodes(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = [...state.drawables];
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    _history.push(state.copyWith(drawables: list));
    notifyListeners();
  }

  void updateDeviceMeta(
      {String? typeKey, String? deviceName, Size? canvasSize}) {
    _history.push(state.copyWith(
      typeKey: typeKey,
      deviceName: deviceName,
      canvasSize: canvasSize,
    ));
    notifyListeners();
  }

  // ─── Drag (checkpoint + liveUpdate pattern) ────────────────────────────────

  void beginDrag(String nodeId) {
    // Select the node silently first.
    if (state.selectedId != nodeId) {
      _history.updateSilent(state.copyWith(selectedId: nodeId));
    }
    // Save the pre-drag state to undo stack.
    _history.checkpoint();
    _preDragState = state;
    _draggingId = nodeId;
    notifyListeners();
  }

  void updateDrag(String nodeId, Offset totalDelta) {
    final pre = _preDragState;
    if (pre == null || nodeId != _draggingId) return;

    final idx = pre.drawables.indexWhere((d) => d.id == nodeId);
    if (idx < 0) return;

    final translated = translateNode(pre.drawables[idx], totalDelta);
    final newDrawables = [...pre.drawables];
    newDrawables[idx] = translated;
    _history.updateSilent(pre.copyWith(drawables: newDrawables));
    notifyListeners();
  }

  void endDrag() {
    _preDragState = null;
    _draggingId = null;
    notifyListeners();
  }

  // ─── Undo / Redo ──────────────────────────────────────────────────────────

  void undo() {
    if (_history.undo() != null) notifyListeners();
  }

  void redo() {
    if (_history.redo() != null) notifyListeners();
  }

  // ─── Export / Import ──────────────────────────────────────────────────────

  /// Builds a [DeviceDefinition] from the current designer state.
  ///
  /// The definition has a single wire-level [LevelAppearance] with the
  /// current drawables and canvas size.
  DeviceDefinition exportDefinition() {
    final appearance = LevelAppearance(
      size: state.canvasSize,
      drawables: List.unmodifiable(state.drawables),
    );
    return DeviceDefinition(
      typeKey: state.typeKey,
      name: state.deviceName,
      appearance: DeviceAppearance(wire: appearance),
    );
  }

  /// Exports the current definition as a JSON string (pretty-printed, 2 spaces).
  String exportJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportDefinition().toJson());
  }

  /// Loads a device definition from [jsonStr], replacing the current state.
  /// Pushes the new state to history so undo can recover the previous state.
  void loadFromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final def = DeviceDefinition.fromJson(map);
    final appearance = def.appearance.wire;
    final newState = DesignerState(
      typeKey: def.typeKey,
      deviceName: def.name,
      canvasSize: appearance?.size ?? const Size(100, 100),
      drawables: List.of(appearance?.drawables ?? const []),
    );
    _history.push(newState);
    notifyListeners();
  }

  // ─── Default node factories (for palette) ─────────────────────────────────

  DrawableNode defaultRect(Offset pos) => DrawRect(
        rect: Rect.fromLTWH(pos.dx, pos.dy, 40, 30),
        cornerRadius: 0,
        fillColor: const Color(0xFFF5F5F5),
        strokeColor: const Color(0xFF212121),
        strokeWidth: 1.5,
      );

  DrawableNode defaultCircle(Offset pos) => DrawCircle(
        center: pos,
        radius: 15,
        strokeColor: const Color(0xFF212121),
        strokeWidth: 1.5,
      );

  DrawableNode defaultLine(Offset pos) => DrawLine(
        start: pos,
        end: pos + const Offset(40, 0),
        color: const Color(0xFF212121),
        strokeWidth: 1.5,
      );

  DrawableNode defaultText(Offset pos) => DrawText(
        text: 'Text',
        position: pos,
        anchor: TextAnchor.topLeft,
        fontSize: 10,
        bold: false,
        color: const Color(0xFF212121),
      );

  DrawableNode defaultCoil(Offset pos) => DrawCoil(
        start: pos,
        end: pos + const Offset(40, 0),
        color: const Color(0xFF212121),
        strokeWidth: 1.5,
        arcCount: 5,
      );

  DrawableNode defaultCapacitor(Offset pos) => DrawCapacitor(
        center: pos,
        horizontal: true,
        scale: 1.0,
        color: const Color(0xFF212121),
      );
}
