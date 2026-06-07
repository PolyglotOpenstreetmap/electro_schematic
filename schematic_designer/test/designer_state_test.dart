// test/designer_state_test.dart
//
// Unit tests for DesignerHistory, DesignerNotifier, translateNode, and
// exportDefinition / JSON round-trip.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_designer/schematic_designer.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

DesignerState _emptyState({
  String typeKey = 'test_device',
  String deviceName = 'Test Device',
  Size canvasSize = const Size(100, 80),
}) {
  return DesignerState(
    typeKey: typeKey,
    deviceName: deviceName,
    activeLevel: DrawingLevel.wire,
    appearances: {
      DrawingLevel.wire: LevelAppearance(
        size: canvasSize,
        drawables: const [],
      ),
    },
    parameters: const [],
    connectors: const [],
  );
}

const _defaultRect = DrawRect(
  rect: Rect.fromLTWH(10, 20, 30, 40),
  strokeColor: Color(0xFF000000),
  strokeWidth: 1.0,
);

const _defaultLine = DrawLine(
  start: Offset(0, 0),
  end: Offset(10, 10),
  color: Color(0xFF000000),
  strokeWidth: 1.0,
);

const _defaultText = DrawText(
  text: 'Hello',
  position: Offset(5, 5),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    SchematicDevicePackage.initialize();
  });

  // ─── 1. DesignerHistory: undo / redo / checkpoint ─────────────────────────

  group('DesignerHistory', () {
    test('initial state is returned by current', () {
      final initial = _emptyState();
      final history = DesignerHistory(initial);
      expect(history.current, same(initial));
    });

    test('canUndo and canRedo are false initially', () {
      final history = DesignerHistory(_emptyState());
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('push makes canUndo true and clears redo', () {
      final history = DesignerHistory(_emptyState());
      final s1 = _emptyState(typeKey: 'a');
      final s2 = _emptyState(typeKey: 'b');
      history.push(s1);
      history.push(s2); // push again to ensure redo is cleared properly
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.current, same(s2));
    });

    test('undo restores previous state and enables redo', () {
      final initial = _emptyState(typeKey: 'initial');
      final history = DesignerHistory(initial);
      final s1 = _emptyState(typeKey: 'after');
      history.push(s1);

      final result = history.undo();
      expect(result, same(initial));
      expect(history.current.typeKey, 'initial');
      expect(history.canRedo, isTrue);
    });

    test('redo restores undone state', () {
      final history = DesignerHistory(_emptyState(typeKey: 'orig'));
      final s1 = _emptyState(typeKey: 'pushed');
      history.push(s1);
      history.undo();
      final result = history.redo();
      expect(result?.typeKey, 'pushed');
      expect(history.canRedo, isFalse);
    });

    test('undo returns null when stack is empty', () {
      final history = DesignerHistory(_emptyState());
      expect(history.undo(), isNull);
    });

    test('redo returns null when stack is empty', () {
      final history = DesignerHistory(_emptyState());
      expect(history.redo(), isNull);
    });

    test('checkpoint saves current to undo without changing current', () {
      final initial = _emptyState(typeKey: 'before_checkpoint');
      final history = DesignerHistory(initial);
      history.checkpoint();

      expect(history.current.typeKey, 'before_checkpoint');
      expect(history.canUndo, isTrue);
    });

    test('updateSilent does not touch undo/redo stacks', () {
      final history = DesignerHistory(_emptyState(typeKey: 'orig'));
      history.updateSilent(_emptyState(typeKey: 'silent'));
      expect(history.canUndo, isFalse);
      expect(history.current.typeKey, 'silent');
    });
  });

  // ─── 2. DesignerNotifier.addNode assigns id and pushes history ────────────

  group('DesignerNotifier.addNode', () {
    test('assigns id starting with "n" when node has no id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);

      expect(notifier.state.drawables, hasLength(1));
      final id = notifier.state.drawables.first.id;
      expect(id, isNotNull);
      expect(id, startsWith('n'));
    });

    test('second addNode gets a different id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.addNode(_defaultLine);

      final ids = notifier.state.drawables.map((d) => d.id).toList();
      expect(ids[0], isNot(equals(ids[1])));
    });

    test('addNode pushes to history so undo works', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);

      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.state.drawables, isEmpty);
    });

    test('addNode selects the new node', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      expect(notifier.state.selectedId,
          equals(notifier.state.drawables.first.id));
    });
  });

  // ─── 3. DesignerNotifier.removeNode ──────────────────────────────────────

  group('DesignerNotifier.removeNode', () {
    test('removes the node with matching id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      final id = notifier.state.drawables.first.id!;

      notifier.removeNode(id);
      expect(notifier.state.drawables, isEmpty);
    });

    test('removeNode pushes to history', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      final id = notifier.state.drawables.first.id!;
      notifier.removeNode(id);

      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.state.drawables, hasLength(1));
    });

    test('clears selectedId if removed node was selected', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      final id = notifier.state.drawables.first.id!;
      notifier.selectNode(id);
      notifier.removeNode(id);

      expect(notifier.state.selectedId, isNull);
    });
  });

  // ─── 4. DesignerNotifier.undo / redo ─────────────────────────────────────

  group('DesignerNotifier undo/redo', () {
    test('undo after addNode restores empty drawables', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.undo();
      expect(notifier.state.drawables, isEmpty);
    });

    test('redo after undo restores the node', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.undo();
      notifier.redo();
      expect(notifier.state.drawables, hasLength(1));
    });

    test('canUndo is false initially', () {
      final notifier = DesignerNotifier(_emptyState());
      expect(notifier.canUndo, isFalse);
    });

    test('canRedo is false after a new mutation', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.undo();
      notifier.addNode(_defaultLine); // new mutation clears redo
      expect(notifier.canRedo, isFalse);
    });
  });

  // ─── 5. exportDefinition produces correct DeviceDefinition ───────────────

  group('DesignerNotifier.exportDefinition', () {
    test('returns definition with matching typeKey and deviceName', () {
      final notifier = DesignerNotifier(
          _emptyState(typeKey: 'my_relay', deviceName: 'My Relay'));
      final def = notifier.exportDefinition();

      expect(def.typeKey, 'my_relay');
      expect(def.name, 'My Relay');
    });

    test('wire level appearance matches canvas size', () {
      const size = Size(120, 90);
      final notifier = DesignerNotifier(_emptyState(canvasSize: size));
      final def = notifier.exportDefinition();

      expect(def.appearance.wire?.size, size);
    });

    test('drawables are included in wire appearance', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      final def = notifier.exportDefinition();

      expect(def.appearance.wire?.drawables, hasLength(1));
    });
  });

  // ─── 6. JSON round-trip ──────────────────────────────────────────────────

  group('JSON round-trip', () {
    test('exportJson / loadFromJson preserves drawable count and typeKey', () {
      final notifier = DesignerNotifier(
          _emptyState(typeKey: 'relay_v2', deviceName: 'Relay V2'));
      notifier.addNode(_defaultRect);
      notifier.addNode(_defaultLine);

      final json = notifier.exportJson();

      // New notifier, load from exported JSON.
      final notifier2 = DesignerNotifier(_emptyState());
      notifier2.loadFromJson(json);

      expect(notifier2.state.drawables, hasLength(2));
      expect(notifier2.state.typeKey, 'relay_v2');
    });

    test('exported JSON is valid JSON', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultText);

      final json = notifier.exportJson();
      expect(() => jsonDecode(json), returnsNormally);
    });

    test('DeviceDefinition.fromJson round-trips drawables', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.addNode(_defaultLine);

      final json = notifier.exportJson();
      final def = DeviceDefinition.fromJson(
          jsonDecode(json) as Map<String, dynamic>);

      expect(def.appearance.wire?.drawables, hasLength(2));
      expect(def.appearance.wire?.drawables.first, isA<DrawRect>());
    });

    test('loadFromJson pushes to history', () {
      final notifier = DesignerNotifier(_emptyState(typeKey: 'before'));
      notifier.addNode(_defaultRect);
      final json = notifier.exportJson();

      final notifier2 = DesignerNotifier(_emptyState(typeKey: 'initial'));
      notifier2.loadFromJson(json);

      expect(notifier2.canUndo, isTrue);
      notifier2.undo();
      expect(notifier2.state.typeKey, 'initial');
    });
  });

  // ─── 7. translateNode ─────────────────────────────────────────────────────

  group('translateNode', () {
    const delta = Offset(10, 5);

    test('shifts DrawRect', () {
      const node = DrawRect(
        rect: Rect.fromLTWH(0, 0, 20, 10),
        strokeColor: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawRect;
      expect(result.rect.left, closeTo(10, 0.001));
      expect(result.rect.top, closeTo(5, 0.001));
    });

    test('shifts DrawLine start and end', () {
      const node = DrawLine(
        start: Offset(1, 2),
        end: Offset(3, 4),
        color: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawLine;
      expect(result.start, const Offset(11, 7));
      expect(result.end, const Offset(13, 9));
    });

    test('shifts DrawText position', () {
      const node = DrawText(
        text: 'Hi',
        position: Offset(10, 20),
      );
      final result = translateNode(node, delta) as DrawText;
      expect(result.position, const Offset(20, 25));
    });

    test('shifts DrawCircle center', () {
      const node = DrawCircle(
        center: Offset(5, 5),
        radius: 4,
        strokeColor: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawCircle;
      expect(result.center, const Offset(15, 10));
    });

    test('shifts DrawCoil start and end', () {
      const node = DrawCoil(
        start: Offset(0, 0),
        end: Offset(20, 0),
        color: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawCoil;
      expect(result.start, const Offset(10, 5));
      expect(result.end, const Offset(30, 5));
    });

    test('shifts DrawCapacitor center', () {
      const node = DrawCapacitor(
        center: Offset(15, 15),
        color: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawCapacitor;
      expect(result.center, const Offset(25, 20));
    });

    test('returns DrawTerminalAnchor unchanged', () {
      const node = DrawTerminalAnchor(terminalDefId: 'T1');
      final result = translateNode(node, delta);
      expect(result, same(node));
    });

    test('returns DrawPath unchanged', () {
      const node = DrawPath(
        svgPathData: ['M 0 0', 'L 10 10'],
        color: Color(0xFF000000),
      );
      final result = translateNode(node, delta);
      expect(result, same(node));
    });

    test('returns DrawRepeat unchanged', () {
      const template = DrawRect(
        rect: Rect.fromLTWH(0, 0, 10, 10),
        strokeColor: Color(0xFF000000),
      );
      const node = DrawRepeat(
        templateChild: template,
        count: '3',
        spacing: 15,
      );
      final result = translateNode(node, delta);
      expect(result, same(node));
    });

    test('shifts DrawPolyline points', () {
      const node = DrawPolyline(
        points: [Offset(0, 0), Offset(10, 10)],
        color: Color(0xFF000000),
      );
      final result = translateNode(node, delta) as DrawPolyline;
      expect(result.points[0], const Offset(10, 5));
      expect(result.points[1], const Offset(20, 15));
    });

    test('shifts DrawGroup offset', () {
      const node = DrawGroup(children: []);
      final result = translateNode(node, delta) as DrawGroup;
      // offset was null → (0,0) + delta
      expect(result.offset, delta);
    });
  });

  // ─── 8. DesignerState.fromDefinition ─────────────────────────────────────

  group('DesignerState.fromDefinition', () {
    test('populates appearances from definition levels', () {
      const def = DeviceDefinition(
        typeKey: 'test',
        name: 'Test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(80, 60)),
          symbol: LevelAppearance(size: Size(20, 20)),
        ),
      );
      final s = DesignerState.fromDefinition(def);
      expect(s.appearances.containsKey(DrawingLevel.wire), isTrue);
      expect(s.appearances.containsKey(DrawingLevel.symbol), isTrue);
      expect(s.appearances.containsKey(DrawingLevel.cable), isFalse);
    });

    test('active level defaults to symbol when it is the first populated', () {
      const def = DeviceDefinition(
        typeKey: 'test',
        name: 'Test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(80, 60)),
          symbol: LevelAppearance(size: Size(20, 20)),
        ),
      );
      final s = DesignerState.fromDefinition(def);
      // [symbol, wire, cable, topology] order → symbol comes first
      expect(s.activeLevel, DrawingLevel.symbol);
    });

    test('active level falls back to wire when only wire is present', () {
      const def = DeviceDefinition(
        typeKey: 'test',
        name: 'Test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(80, 60)),
        ),
      );
      final s = DesignerState.fromDefinition(def);
      expect(s.activeLevel, DrawingLevel.wire);
    });

    test('initialLevel overrides default level selection', () {
      const def = DeviceDefinition(
        typeKey: 'test',
        name: 'Test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(80, 60)),
          cable: LevelAppearance(size: Size(80, 60)),
        ),
      );
      final s = DesignerState.fromDefinition(def,
          initialLevel: DrawingLevel.cable);
      expect(s.activeLevel, DrawingLevel.cable);
    });

    test('connectors are preserved', () {
      const def = DeviceDefinition(
        typeKey: 'relay',
        name: 'Relay',
        connectors: [
          ConnectorDef(
            id: 'main',
            name: 'Main',
            placement: ConnectorPlacement.left,
            terminals: [
              TerminalDef(
                id: 't1',
                label: '1',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(0, 10),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
            wire: LevelAppearance(size: Size(40, 20))),
      );
      final s = DesignerState.fromDefinition(def);
      expect(s.connectors, hasLength(1));
      expect(s.connectors.first.id, 'main');
      expect(s.connectors.first.terminals, hasLength(1));
    });

    test('parameters are preserved', () {
      const def = DeviceDefinition(
        typeKey: 'relay',
        name: 'Relay',
        parameters: [
          StringParamDef(id: 'label', label: 'Label'),
        ],
        appearance: DeviceAppearance(
            wire: LevelAppearance(size: Size(40, 20))),
      );
      final s = DesignerState.fromDefinition(def);
      expect(s.parameters, hasLength(1));
      expect(s.parameters.first.id, 'label');
    });

    test('description is preserved', () {
      const def = DeviceDefinition(
        typeKey: 'relay',
        name: 'Relay',
        description: 'A test relay',
        appearance: DeviceAppearance(
            wire: LevelAppearance(size: Size(40, 20))),
      );
      final s = DesignerState.fromDefinition(def);
      expect(s.description, 'A test relay');
    });
  });

  // ─── 9. DesignerState.empty ───────────────────────────────────────────────

  group('DesignerState.empty', () {
    test('seeds wire level appearance', () {
      final s = DesignerState.empty('relay', 'Relay');
      expect(s.appearances.containsKey(DrawingLevel.wire), isTrue);
      expect(s.activeLevel, DrawingLevel.wire);
    });

    test('drawables is empty', () {
      final s = DesignerState.empty('relay', 'Relay');
      expect(s.drawables, isEmpty);
    });

    test('connectors and parameters are empty', () {
      final s = DesignerState.empty('relay', 'Relay');
      expect(s.connectors, isEmpty);
      expect(s.parameters, isEmpty);
    });
  });

  // ─── 10. Level mutations ──────────────────────────────────────────────────

  group('Level mutations', () {
    test('addLevel adds a new level', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.cable);
      expect(
          notifier.state.appearances.containsKey(DrawingLevel.cable), isTrue);
    });

    test('addLevel is no-op if level already exists', () {
      final notifier = DesignerNotifier(_emptyState());
      final before = notifier.state.appearances.length;
      notifier.addLevel(DrawingLevel.wire); // already exists
      expect(notifier.state.appearances.length, before);
    });

    test('addLevel pushes to history', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.cable);
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(
          notifier.state.appearances.containsKey(DrawingLevel.cable), isFalse);
    });

    test('setActiveLevel changes activeLevel', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.symbol);
      notifier.setActiveLevel(DrawingLevel.symbol);
      expect(notifier.state.activeLevel, DrawingLevel.symbol);
    });

    test('setActiveLevel clears selectedId', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.addLevel(DrawingLevel.symbol);
      notifier.setActiveLevel(DrawingLevel.symbol);
      expect(notifier.state.selectedId, isNull);
    });

    test('setActiveLevel does not push to history', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.symbol);
      final undoCountBefore = notifier.canUndo;
      // undo count is true from addLevel; setActiveLevel should not add more
      notifier.setActiveLevel(DrawingLevel.symbol);
      // canUndo was already true; undoing should restore to pre-addLevel
      notifier.undo();
      expect(
          notifier.state.appearances.containsKey(DrawingLevel.symbol), isFalse,
          reason: 'undo should have removed the symbol level, not just reverted level switch');
      expect(undoCountBefore, isTrue); // guard
    });

    test('removeLevel removes a level', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.cable);
      notifier.removeLevel(DrawingLevel.cable);
      expect(
          notifier.state.appearances.containsKey(DrawingLevel.cable), isFalse);
    });

    test('removeLevel does not remove the last level', () {
      final notifier = DesignerNotifier(_emptyState());
      expect(notifier.state.appearances.length, 1);
      notifier.removeLevel(DrawingLevel.wire);
      expect(notifier.state.appearances.length, 1); // unchanged
    });

    test('editing wire level does not affect symbol level', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addLevel(DrawingLevel.symbol);
      notifier.setActiveLevel(DrawingLevel.wire);
      notifier.addNode(_defaultRect);

      expect(notifier.state.appearances[DrawingLevel.wire]!.drawables,
          hasLength(1));
      expect(notifier.state.appearances[DrawingLevel.symbol]!.drawables,
          isEmpty);
    });

    test('setLevelSize updates the size of a level', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.setLevelSize(DrawingLevel.wire, const Size(200, 150));
      expect(notifier.state.canvasSize, const Size(200, 150));
    });

    test('setLevelSize is no-op for non-existent level', () {
      final notifier = DesignerNotifier(_emptyState());
      expect(notifier.canUndo, isFalse);
      notifier.setLevelSize(DrawingLevel.cable, const Size(200, 150));
      // cable does not exist → no push
      expect(notifier.canUndo, isFalse);
    });

    test('copyLevel copies drawables and size to target level', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addNode(_defaultRect);
      notifier.addLevel(DrawingLevel.symbol);
      notifier.copyLevel(DrawingLevel.wire, DrawingLevel.symbol);

      expect(
          notifier.state.appearances[DrawingLevel.symbol]!.drawables,
          hasLength(1));
      expect(
          notifier.state.appearances[DrawingLevel.symbol]!.size,
          notifier.state.appearances[DrawingLevel.wire]!.size);
    });
  });

  // ─── 11. Parameter mutations ──────────────────────────────────────────────

  group('Parameter mutations', () {
    test('addParameter adds to state', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'P1'));
      expect(notifier.state.parameters, hasLength(1));
    });

    test('addParameter pushes to history', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'P1'));
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.state.parameters, isEmpty);
    });

    test('addParameter rejects duplicate id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'P1'));
      notifier.addParameter(
          const StringParamDef(id: 'p1', label: 'P1 duplicate'));
      expect(notifier.state.parameters, hasLength(1));
    });

    test('updateParameter replaces by index', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'Old'));
      notifier
          .updateParameter(0, const StringParamDef(id: 'p1', label: 'New'));
      expect(notifier.state.parameters.first.label, 'New');
    });

    test('updateParameter is no-op for out-of-range index', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'P1'));
      final countBefore = notifier.state.parameters.length;
      notifier.updateParameter(5, const StringParamDef(id: 'p9', label: 'P9'));
      expect(notifier.state.parameters.length, countBefore);
    });

    test('removeParameter removes by id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'P1'));
      notifier.removeParameter('p1');
      expect(notifier.state.parameters, isEmpty);
    });

    test('exportDefinition reflects parameters', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'Param 1'));
      final def = notifier.exportDefinition();
      expect(def.parameters, hasLength(1));
      expect(def.parameters.first.id, 'p1');
    });
  });

  // ─── 12. Connector/terminal mutations ────────────────────────────────────

  group('Connector/terminal mutations', () {
    ConnectorDef makeConnector([String id = 'c1']) => ConnectorDef(
          id: id,
          name: 'Connector $id',
          placement: ConnectorPlacement.left,
          terminals: const [],
        );

    const testTerminal = TerminalDef(
      id: 't1',
      label: '1',
      group: ElectricalGroup.power,
      anchorInConnector: Offset(0, 10),
    );

    test('addConnector adds to state', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      expect(notifier.state.connectors, hasLength(1));
    });

    test('addConnector pushes to history', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.state.connectors, isEmpty);
    });

    test('updateConnector replaces by id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.updateConnector(const ConnectorDef(
        id: 'c1',
        name: 'Updated Name',
        placement: ConnectorPlacement.right,
        terminals: [],
      ));
      expect(notifier.state.connectors.first.name, 'Updated Name');
    });

    test('removeConnector removes by id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.removeConnector('c1');
      expect(notifier.state.connectors, isEmpty);
    });

    test('addTerminal adds terminal to connector', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.addTerminal('c1', testTerminal);
      expect(notifier.state.connectors.first.terminals, hasLength(1));
    });

    test('updateTerminal replaces terminal by id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.addTerminal('c1', testTerminal);
      const updated = TerminalDef(
        id: 't1',
        label: 'one-updated',
        group: ElectricalGroup.ground,
        anchorInConnector: Offset(0, 20),
      );
      notifier.updateTerminal('c1', updated);
      expect(notifier.state.connectors.first.terminals.first.label,
          'one-updated');
    });

    test('removeTerminal removes terminal by id', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.addTerminal('c1', testTerminal);
      notifier.removeTerminal('c1', 't1');
      expect(notifier.state.connectors.first.terminals, isEmpty);
    });

    test('moveTerminalAnchor updates anchorInConnector', () {
      final notifier = DesignerNotifier(_emptyState());
      notifier.addConnector(makeConnector());
      notifier.addTerminal('c1', testTerminal);
      notifier.moveTerminalAnchor('c1', 't1', const Offset(5, 15));
      expect(
          notifier.state.connectors.first.terminals.first.anchorInConnector,
          const Offset(5, 15));
    });

    test('connector mutations are no-op for unknown connector id', () {
      final notifier = DesignerNotifier(_emptyState());
      final before = notifier.canUndo;
      notifier.addTerminal('nonexistent', testTerminal);
      expect(notifier.canUndo, before); // no change
    });
  });

  // ─── 13. Lossless round-trip ──────────────────────────────────────────────

  group('Lossless round-trip', () {
    test('export and re-import produces identical JSON', () {
      final notifier = DesignerNotifier(
          _emptyState(typeKey: 'round_trip', deviceName: 'Round Trip'));
      notifier.addNode(_defaultRect);
      notifier.addParameter(const StringParamDef(id: 'p1', label: 'Param 1'));
      notifier.addConnector(const ConnectorDef(
        id: 'c1',
        name: 'Conn 1',
        placement: ConnectorPlacement.left,
        terminals: [
          TerminalDef(
            id: 't1',
            label: '1',
            group: ElectricalGroup.power,
            anchorInConnector: Offset(0, 10),
          ),
        ],
      ));

      final json1 = notifier.exportJson();

      final notifier2 = DesignerNotifier(_emptyState());
      notifier2.loadFromJson(json1);
      final json2 = notifier2.exportJson();

      expect(json1, json2);
    });

    test('multi-level definition round-trips all levels', () {
      const def = DeviceDefinition(
        typeKey: 'multi',
        name: 'Multi Level',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(80, 60)),
          symbol: LevelAppearance(size: Size(20, 20)),
        ),
      );

      final notifier = DesignerNotifier(DesignerState.fromDefinition(def));
      final json1 = notifier.exportJson();

      final notifier2 = DesignerNotifier(_emptyState());
      notifier2.loadFromJson(json1);

      expect(notifier2.state.appearances.containsKey(DrawingLevel.wire),
          isTrue);
      expect(notifier2.state.appearances.containsKey(DrawingLevel.symbol),
          isTrue);
    });
  });

  // ─── 14. Resolver injection ───────────────────────────────────────────────

  group('Resolver injection', () {
    test('resolver is reflected in renderContext.deviceResolver', () {
      const def = DeviceDefinition(
        typeKey: 'foo',
        name: 'Foo',
        appearance: DeviceAppearance(
            wire: LevelAppearance(size: Size(40, 20))),
      );
      final notifier = DesignerNotifier(
        _emptyState(),
        resolver: (key) => key == 'foo' ? def : null,
      );
      expect(notifier.renderContext.deviceResolver, isNotNull);
      expect(notifier.renderContext.deviceResolver!('foo'), same(def));
      expect(notifier.renderContext.deviceResolver!('bar'), isNull);
    });

    test('renderContext.deviceResolver is null when no resolver provided', () {
      final notifier = DesignerNotifier(_emptyState());
      expect(notifier.renderContext.deviceResolver, isNull);
    });
  });

  // ─── 15. Back-compat legacy load ─────────────────────────────────────────

  group('Back-compat legacy load', () {
    test('loads old single-wire format without connectors or params', () {
      final oldJson = jsonEncode({
        'typeKey': 'old_device',
        'name': 'Old Device',
        'parameters': <dynamic>[],
        'connectors': <dynamic>[],
        'appearance': {
          'wire': {
            'size': {'width': 80.0, 'height': 60.0},
            'drawables': <dynamic>[],
          },
        },
      });

      final notifier = DesignerNotifier(_emptyState());
      notifier.loadFromJson(oldJson);

      expect(notifier.state.typeKey, 'old_device');
      expect(notifier.state.appearances.containsKey(DrawingLevel.wire), isTrue);
      expect(notifier.state.connectors, isEmpty);
      expect(notifier.state.parameters, isEmpty);
    });

    test('loading pushes to history allowing undo', () {
      final notifier = DesignerNotifier(_emptyState(typeKey: 'original'));
      final json = jsonEncode({
        'typeKey': 'loaded',
        'name': 'Loaded Device',
        'parameters': <dynamic>[],
        'connectors': <dynamic>[],
        'appearance': {
          'wire': {
            'size': {'width': 80.0, 'height': 60.0},
            'drawables': <dynamic>[],
          },
        },
      });

      notifier.loadFromJson(json);
      expect(notifier.state.typeKey, 'loaded');
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.state.typeKey, 'original');
    });
  });
}
