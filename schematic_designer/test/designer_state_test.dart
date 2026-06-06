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
    canvasSize: canvasSize,
    drawables: const [],
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
}
