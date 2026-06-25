// test/composite_authoring_test.dart
//
// Tests for composite-authoring support in the designer: terminal delegation,
// per-level anchor overrides, the terminal/device-ref palette mutations, and
// resolver-aware bounds for DrawDeviceRef.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_designer/schematic_designer.dart';
import 'package:schematic_device/schematic_device.dart';

DeviceDefinition _childDef() => const DeviceDefinition(
      typeKey: 'child',
      name: 'Child',
      connectors: [
        ConnectorDef(
          id: 'main',
          name: 'Main',
          placement: ConnectorPlacement.left,
          terminals: [
            TerminalDef(
              id: 'T1',
              label: 'T1',
              group: ElectricalGroup.power,
              anchorInConnector: Offset(5, 15),
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(size: Size(30, 30)),
        symbol: LevelAppearance(size: Size(20, 20)),
      ),
    );

DesignerNotifier _notifier({DesignerState? initial}) => DesignerNotifier(
      initial ?? DesignerState.empty('assembly', 'Assembly'),
      resolver: (key) => key == 'child' ? _childDef() : null,
      knownTypeKeys: const ['child'],
    );

/// State seeded with one connector + one terminal.
DesignerState _stateWithTerminal() => DesignerState.fromDefinition(
      const DeviceDefinition(
        typeKey: 'assembly',
        name: 'Assembly',
        connectors: [
          ConnectorDef(
            id: 'ext',
            name: 'External',
            placement: ConnectorPlacement.left,
            terminals: [
              TerminalDef(
                id: 'IN',
                label: 'IN',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(0, 25),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(200, 100)),
        ),
      ),
    );

void main() {
  setUpAll(SchematicDevicePackage.initialize);

  group('setTerminalDelegate', () {
    test('sets, exports, clears, and undoes', () {
      final n = _notifier(initial: _stateWithTerminal());

      n.setTerminalDelegate('ext', 'IN',
          const TerminalDelegate(refId: 'ref_child', terminalId: 'T1'));
      var term = n.exportDefinition().findTerminal('IN')!;
      expect(term.delegate,
          const TerminalDelegate(refId: 'ref_child', terminalId: 'T1'));

      n.undo();
      term = n.exportDefinition().findTerminal('IN')!;
      expect(term.delegate, isNull);

      n.redo();
      n.setTerminalDelegate('ext', 'IN', null);
      term = n.exportDefinition().findTerminal('IN')!;
      expect(term.delegate, isNull);
    });
  });

  group('setTerminalLevelAnchor', () {
    test('sets and removes a per-level override, undoable', () {
      final n = _notifier(initial: _stateWithTerminal());

      n.setTerminalLevelAnchor(
          'ext', 'IN', DrawingLevel.symbol, const Offset(7, 8));
      var term = n.exportDefinition().findTerminal('IN')!;
      expect(term.levelAnchors[DrawingLevel.symbol], const Offset(7, 8));
      expect(term.anchorInConnector, const Offset(0, 25));

      n.setTerminalLevelAnchor('ext', 'IN', DrawingLevel.symbol, null);
      term = n.exportDefinition().findTerminal('IN')!;
      expect(term.levelAnchors, isEmpty);

      n.undo();
      term = n.exportDefinition().findTerminal('IN')!;
      expect(term.levelAnchors[DrawingLevel.symbol], const Offset(7, 8));
    });
  });

  group('moveTerminalAnchor (level-aware)', () {
    test('writes the base anchor when no override exists', () {
      final n = _notifier(initial: _stateWithTerminal());
      n.moveTerminalAnchor('ext', 'IN', const Offset(3, 4));
      final term = n.exportDefinition().findTerminal('IN')!;
      expect(term.anchorInConnector, const Offset(3, 4));
      expect(term.levelAnchors, isEmpty);
    });

    test('writes the active-level override when one exists', () {
      final n = _notifier(initial: _stateWithTerminal());
      // The active level is wire (only populated level).
      n.setTerminalLevelAnchor(
          'ext', 'IN', DrawingLevel.wire, const Offset(1, 1));
      n.moveTerminalAnchor('ext', 'IN', const Offset(9, 9));
      final term = n.exportDefinition().findTerminal('IN')!;
      expect(term.levelAnchors[DrawingLevel.wire], const Offset(9, 9));
      expect(term.anchorInConnector, const Offset(0, 25));
    });
  });

  group('palette tools', () {
    test(
        'addTerminalWithAnchor creates TerminalDef + DrawTerminalAnchor in '
        'one history entry', () {
      final n = _notifier();
      n.addTerminalWithAnchor(const Offset(12, 34));

      final def = n.exportDefinition();
      final term = def.findTerminal('t1');
      expect(term, isNotNull);
      expect(term!.anchorInConnector, const Offset(12, 34));
      expect(def.connectors.single.id, 'default');
      expect(
        n.state.drawables.whereType<DrawTerminalAnchor>().single.terminalDefId,
        't1',
      );

      // Single undo removes both.
      n.undo();
      expect(n.exportDefinition().connectors, isEmpty);
      expect(n.state.drawables, isEmpty);
    });

    test(
        'addTerminalWithAnchor appends to an existing connector with a '
        'unique id', () {
      final n = _notifier(initial: _stateWithTerminal());
      n.addTerminalWithAnchor(const Offset(1, 2));
      final connector = n.exportDefinition().connectors.single;
      expect(connector.id, 'ext');
      expect(connector.terminals.map((t) => t.id), ['IN', 't1']);
    });

    test('addDeviceRef places a DrawDeviceRef at the position', () {
      final n = _notifier();
      n.addDeviceRef('child', const Offset(40, 20));
      final ref = n.state.drawables.whereType<DrawDeviceRef>().single;
      expect(ref.typeKey, 'child');
      expect(ref.offset, const Offset(40, 20));
      expect(ref.id, isNotNull);
    });
  });

  group('delegatableRefs', () {
    test('collects ids across all populated levels', () {
      final n = _notifier();
      n.addDeviceRef('child', const Offset(0, 0)); // on wire level
      n.addLevel(DrawingLevel.symbol);
      n.setActiveLevel(DrawingLevel.symbol);
      n.addDeviceRef('child', const Offset(5, 5)); // on symbol level
      expect(n.delegatableRefs.length, 2);
      expect(n.delegatableRefs.every((r) => r.id != null), isTrue);
    });
  });

  group('resolver-aware bounds (DrawDeviceRef)', () {
    test('bounds come from the referenced appearance size, offset and scale',
        () {
      const ref = DrawDeviceRef(
        id: 'r',
        typeKey: 'child',
        offset: Offset(10, 20),
        scale: 2.0,
      );
      final bounds = NodeBoundsHelper.boundsOf(ref, null,
          (key) => key == 'child' ? _childDef() : null, DrawingLevel.wire);
      expect(bounds, const Rect.fromLTWH(10, 20, 60, 60));
    });

    test('ref.level override wins over the requested level', () {
      const ref = DrawDeviceRef(
        id: 'r',
        typeKey: 'child',
        level: DrawingLevel.symbol,
        offset: Offset(0, 0),
      );
      final bounds = NodeBoundsHelper.boundsOf(ref, null,
          (key) => key == 'child' ? _childDef() : null, DrawingLevel.wire);
      expect(bounds, const Rect.fromLTWH(0, 0, 20, 20));
    });

    test('unresolved ref gets a selectable fallback box', () {
      const ref = DrawDeviceRef(id: 'r', typeKey: 'nope', offset: Offset(5, 5));
      expect(NodeBoundsHelper.boundsOf(ref), const Rect.fromLTWH(5, 5, 24, 24));
    });

    test('hitTest selects a resolved ref', () {
      const ref =
          DrawDeviceRef(id: 'r', typeKey: 'child', offset: Offset(10, 10));
      final hit = NodeBoundsHelper.hitTest([ref], const Offset(25, 25), null,
          (key) => key == 'child' ? _childDef() : null, DrawingLevel.wire);
      expect(hit, same(ref));
    });
  });

  group('translateNode (DrawDeviceRef)', () {
    test('dragging a ref shifts its offset', () {
      const ref =
          DrawDeviceRef(id: 'r', typeKey: 'child', offset: Offset(10, 10));
      final moved = translateNode(ref, const Offset(5, -3)) as DrawDeviceRef;
      expect(moved.offset, const Offset(15, 7));
      expect(moved.typeKey, 'child');
      expect(moved.id, 'r');
    });
  });

  group('lossless round-trip with composite fields', () {
    test('delegate + levelAnchors survive export → load → export', () {
      const def = DeviceDefinition(
        typeKey: 'assembly',
        name: 'Assembly',
        connectors: [
          ConnectorDef(
            id: 'ext',
            name: 'External',
            placement: ConnectorPlacement.left,
            terminals: [
              TerminalDef(
                id: 'IN',
                label: 'IN',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(0, 25),
                levelAnchors: {DrawingLevel.symbol: Offset(0, 10)},
                delegate:
                    TerminalDelegate(refId: 'ref_child', terminalId: 'T1'),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          symbol: LevelAppearance(size: Size(60, 20)),
          wire: LevelAppearance(
            size: Size(200, 100),
            drawables: [
              DrawDeviceRef(
                  id: 'ref_child', typeKey: 'child', offset: Offset(40, 20)),
            ],
          ),
        ),
      );

      final n = _notifier();
      n.loadFromJson(jsonEncode(def.toJson()));
      expect(jsonDecode(n.exportJson()), def.toJson());
    });

    test('legacy definition without composite fields stays byte-stable', () {
      const legacy = DeviceDefinition(
        typeKey: 'simple',
        name: 'Simple',
        connectors: [
          ConnectorDef(
            id: 'main',
            name: 'Main',
            placement: ConnectorPlacement.top,
            terminals: [
              TerminalDef(
                id: 'A',
                label: 'A',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(1, 2),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(50, 50)),
        ),
      );
      final n = _notifier();
      n.loadFromJson(jsonEncode(legacy.toJson()));
      expect(jsonDecode(n.exportJson()), legacy.toJson());
    });
  });
}
