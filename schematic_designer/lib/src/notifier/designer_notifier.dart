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
/// Selection changes and level-switching are silent (no history entry).
class DesignerNotifier extends ChangeNotifier {
  DesignerNotifier(
    DesignerState initial, {
    DeviceDefinition? Function(String typeKey)? resolver,
  })  : _history = DesignerHistory(initial),
        _resolver = resolver;

  final DesignerHistory _history;
  final DeviceDefinition? Function(String typeKey)? _resolver;
  int _idCounter = 0;

  // Drag state
  DesignerState? _preDragState;
  String? _draggingId;

  // ─── Accessors ─────────────────────────────────────────────────────────────

  DesignerState get state => _history.current;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// A [RenderContext] that uses this notifier's resolver, if one was provided.
  RenderContext get renderContext {
    final resolver = _resolver;
    return resolver != null
        ? RenderContext(deviceResolver: resolver)
        : RenderContext.empty;
  }

  // ─── Private helper: update active level's drawables ─────────────────────

  DesignerState _withActiveDrawables(List<DrawableNode> newDrawables) {
    final current = state.appearances[state.activeLevel];
    final updated = LevelAppearance(
      size: current?.size ?? const Size(100, 100),
      drawables: List.unmodifiable(newDrawables),
    );
    final newAppearances =
        Map<DrawingLevel, LevelAppearance>.from(state.appearances)
          ..[state.activeLevel] = updated;
    return state.copyWith(appearances: newAppearances);
  }

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
        _withActiveDrawables(newDrawables).copyWith(selectedId: nodeWithId.id));
    notifyListeners();
  }

  void removeNode(String id) {
    final newDrawables = state.drawables.where((d) => d.id != id).toList();
    final newSelected =
        state.selectedId == id ? null : state.selectedId;
    _history.push(_withActiveDrawables(newDrawables)
        .copyWith(selectedId: newSelected));
    notifyListeners();
  }

  void updateNode(DrawableNode updated) {
    final idx = state.drawables.indexWhere((d) => d.id == updated.id);
    if (idx < 0) return;
    final newDrawables = [...state.drawables];
    newDrawables[idx] = updated;
    _history.push(_withActiveDrawables(newDrawables));
    notifyListeners();
  }

  void reorderNodes(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = [...state.drawables];
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    _history.push(_withActiveDrawables(list));
    notifyListeners();
  }

  void updateDeviceMeta({
    String? typeKey,
    String? deviceName,
    String? description,
    Size? canvasSize,
  }) {
    // canvasSize is now per-level; delegate to setLevelSize which pushes its
    // own history entry.
    if (canvasSize != null) {
      setLevelSize(state.activeLevel, canvasSize);
      if (typeKey == null && deviceName == null && description == null) return;
    }
    _history.push(state.copyWith(
      typeKey: typeKey,
      deviceName: deviceName,
      description: description,
    ));
    notifyListeners();
  }

  // ─── Level management ─────────────────────────────────────────────────────

  /// Switches the active editing level.  Does not create a history entry so
  /// level changes cannot be undone (they are a view concern, not a data
  /// mutation).
  void setActiveLevel(DrawingLevel level) {
    if (state.activeLevel == level) return;
    _history.updateSilent(
        state.copyWith(activeLevel: level, selectedId: null));
    notifyListeners();
  }

  /// Adds a new empty level.  No-op if the level already exists.
  void addLevel(DrawingLevel level, {Size? size}) {
    if (state.appearances.containsKey(level)) return;
    final newApps =
        Map<DrawingLevel, LevelAppearance>.from(state.appearances)
          ..[level] =
              LevelAppearance(size: size ?? const Size(100, 100));
    _history.push(state.copyWith(appearances: newApps));
    notifyListeners();
  }

  /// Removes a level.  No-op if the map would become empty (must keep at
  /// least one level).
  void removeLevel(DrawingLevel level) {
    if (state.appearances.length <= 1) return;
    final newApps =
        Map<DrawingLevel, LevelAppearance>.from(state.appearances)
          ..remove(level);
    final newActive = state.activeLevel == level
        ? newApps.keys.first
        : state.activeLevel;
    _history.push(
        state.copyWith(appearances: newApps, activeLevel: newActive));
    notifyListeners();
  }

  /// Copies all drawables and the size from [from] to [to].
  ///
  /// Drawables are deep-copied via JSON round-trip so the two levels do not
  /// share mutable objects.
  void copyLevel(DrawingLevel from, DrawingLevel to) {
    final src = state.appearances[from];
    if (src == null) return;
    final copied = src.drawables
        .map((n) => DrawableNodeFactory.fromJson(n.toJson()))
        .toList();
    final newApps =
        Map<DrawingLevel, LevelAppearance>.from(state.appearances)
          ..[to] = LevelAppearance(
              size: src.size, drawables: List.unmodifiable(copied));
    _history.push(state.copyWith(appearances: newApps));
    notifyListeners();
  }

  /// Updates the canvas size for [level].  No-op if [level] has no appearance.
  void setLevelSize(DrawingLevel level, Size size) {
    final current = state.appearances[level];
    if (current == null) return;
    final updated = LevelAppearance(size: size, drawables: current.drawables);
    final newApps =
        Map<DrawingLevel, LevelAppearance>.from(state.appearances)
          ..[level] = updated;
    _history.push(state.copyWith(appearances: newApps));
    notifyListeners();
  }

  // ─── Parameter mutations ──────────────────────────────────────────────────

  /// Adds [param].  Rejects duplicates (same [ParameterDef.id]).
  void addParameter(ParameterDef param) {
    if (state.parameters.any((p) => p.id == param.id)) return;
    _history.push(
        state.copyWith(parameters: [...state.parameters, param]));
    notifyListeners();
  }

  /// Replaces the parameter at [index].
  void updateParameter(int index, ParameterDef param) {
    if (index < 0 || index >= state.parameters.length) return;
    final list = [...state.parameters];
    list[index] = param;
    _history.push(state.copyWith(parameters: list));
    notifyListeners();
  }

  /// Removes the parameter with [id].
  void removeParameter(String id) {
    _history.push(state.copyWith(
        parameters: state.parameters.where((p) => p.id != id).toList()));
    notifyListeners();
  }

  // ─── Connector/terminal mutations ─────────────────────────────────────────

  /// Appends [connector].
  void addConnector(ConnectorDef connector) {
    _history.push(state.copyWith(
        connectors: [...state.connectors, connector]));
    notifyListeners();
  }

  /// Replaces an existing connector with the same [ConnectorDef.id].
  void updateConnector(ConnectorDef connector) {
    final list = state.connectors
        .map((c) => c.id == connector.id ? connector : c)
        .toList();
    _history.push(state.copyWith(connectors: list));
    notifyListeners();
  }

  /// Removes the connector with [id].
  void removeConnector(String id) {
    _history.push(state.copyWith(
        connectors:
            state.connectors.where((c) => c.id != id).toList()));
    notifyListeners();
  }

  /// Appends [terminal] to the connector identified by [connectorId].
  void addTerminal(String connectorId, TerminalDef terminal) {
    final list = _replaceConnectorTerminals(
        connectorId, (ts) => [...ts, terminal]);
    if (list == null) return;
    _history.push(state.copyWith(connectors: list));
    notifyListeners();
  }

  /// Replaces the terminal with matching [TerminalDef.id] inside [connectorId].
  void updateTerminal(String connectorId, TerminalDef terminal) {
    final list = _replaceConnectorTerminals(connectorId,
        (ts) => ts.map((t) => t.id == terminal.id ? terminal : t).toList());
    if (list == null) return;
    _history.push(state.copyWith(connectors: list));
    notifyListeners();
  }

  /// Removes the terminal with [terminalId] from the connector [connectorId].
  void removeTerminal(String connectorId, String terminalId) {
    final list = _replaceConnectorTerminals(connectorId,
        (ts) => ts.where((t) => t.id != terminalId).toList());
    if (list == null) return;
    _history.push(state.copyWith(connectors: list));
    notifyListeners();
  }

  /// Updates [TerminalDef.anchorInConnector] for a specific terminal.
  void moveTerminalAnchor(
      String connectorId, String terminalId, Offset newAnchor) {
    final list = _replaceConnectorTerminals(connectorId, (ts) => ts.map((t) {
          if (t.id != terminalId) return t;
          final j = {
            ...t.toJson(),
            'anchorInConnector': {
              'dx': newAnchor.dx,
              'dy': newAnchor.dy,
            },
          };
          return TerminalDef.fromJson(j);
        }).toList());
    if (list == null) return;
    _history.push(state.copyWith(connectors: list));
    notifyListeners();
  }

  /// Returns a new connector list with the terminals of [connectorId] replaced
  /// by the result of calling [fn] on the current terminal list.
  /// Returns null if [connectorId] is not found.
  List<ConnectorDef>? _replaceConnectorTerminals(
      String connectorId, List<TerminalDef> Function(List<TerminalDef>) fn) {
    final idx = state.connectors.indexWhere((c) => c.id == connectorId);
    if (idx < 0) return null;
    final c = state.connectors[idx];
    final newTerminals = fn(c.terminals);
    final j = {
      ...c.toJson(),
      'terminals': newTerminals.map((t) => t.toJson()).toList(),
    };
    final updated = ConnectorDef.fromJson(j);
    final list = [...state.connectors];
    list[idx] = updated;
    return list;
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

    // Build updated appearances based on the pre-drag state.
    final current = pre.appearances[pre.activeLevel];
    final updated = LevelAppearance(
      size: current?.size ?? const Size(100, 100),
      drawables: List.unmodifiable(newDrawables),
    );
    final newAppearances =
        Map<DrawingLevel, LevelAppearance>.from(pre.appearances)
          ..[pre.activeLevel] = updated;
    _history.updateSilent(pre.copyWith(appearances: newAppearances));
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

  /// Builds a [DeviceDefinition] from the current designer state, losslessly
  /// capturing all levels, connectors, parameters, and description.
  DeviceDefinition exportDefinition() {
    return DeviceDefinition(
      typeKey: state.typeKey,
      name: state.deviceName,
      description: state.description,
      parameters: List.unmodifiable(state.parameters),
      connectors: List.unmodifiable(state.connectors),
      appearance: DeviceAppearance(
        symbol: state.appearances[DrawingLevel.symbol],
        wire: state.appearances[DrawingLevel.wire],
        cable: state.appearances[DrawingLevel.cable],
        topology: state.appearances[DrawingLevel.topology],
      ),
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
    final newState = DesignerState.fromDefinition(def);
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
