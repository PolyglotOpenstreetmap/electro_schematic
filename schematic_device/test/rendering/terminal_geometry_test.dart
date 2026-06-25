// test/rendering/terminal_geometry_test.dart
//
// Tests for TerminalGeometry: per-level anchors, composite delegation,
// forcedLevel, cycle guards, and renderer transform parity.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

/// Atomic child with one terminal at (5, 15) and a DrawTerminalAnchor for it.
DeviceDefinition _childDef({String typeKey = 'child'}) => DeviceDefinition(
      typeKey: typeKey,
      name: typeKey,
      connectors: const [
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
      appearance: const DeviceAppearance(
        wire: LevelAppearance(
          size: Size(30, 30),
          drawables: [
            DrawRect(
              rect: Rect.fromLTWH(0, 0, 30, 30),
              strokeColor: Color(0xFF000000),
            ),
            DrawTerminalAnchor(terminalDefId: 'T1'),
          ],
        ),
      ),
    );

/// Composite parent: combined glyph at symbol level, exploded (one child ref,
/// nested in an offset/scaled group) at wire level. The facade terminal `IN`
/// delegates to the child's `T1` and carries a symbol-level static anchor.
DeviceDefinition _compositeDef({
  Offset refOffset = const Offset(40, 20),
  double refScale = 1.0,
  Offset groupOffset = Offset.zero,
  double groupScale = 1.0,
}) {
  final ref = DrawDeviceRef(
    id: 'ref_child',
    typeKey: 'child',
    offset: refOffset,
    scale: refScale,
  );
  final wireDrawables = groupOffset == Offset.zero && groupScale == 1.0
      ? <DrawableNode>[ref]
      : <DrawableNode>[
          DrawGroup(offset: groupOffset, scale: groupScale, children: [ref]),
        ];
  return DeviceDefinition(
    typeKey: 'assembly',
    name: 'Assembly',
    connectors: const [
      ConnectorDef(
        id: 'external',
        name: 'External',
        placement: ConnectorPlacement.left,
        terminals: [
          TerminalDef(
            id: 'IN',
            label: 'IN',
            group: ElectricalGroup.power,
            anchorInConnector: Offset(0, 25),
            levelAnchors: {DrawingLevel.symbol: Offset(0, 10)},
            delegate: TerminalDelegate(refId: 'ref_child', terminalId: 'T1'),
          ),
        ],
      ),
    ],
    appearance: DeviceAppearance(
      symbol: const LevelAppearance(
        size: Size(60, 20),
        drawables: [
          DrawRect(
            rect: Rect.fromLTWH(0, 0, 60, 20),
            strokeColor: Color(0xFF000000),
          ),
        ],
      ),
      wire:
          LevelAppearance(size: const Size(200, 100), drawables: wireDrawables),
    ),
  );
}

DeviceResolver _registry(Map<String, DeviceDefinition> defs) =>
    (key) => defs[key];

// ─── Recording canvas (transform-aware) ───────────────────────────────────────

/// Minimal Canvas that tracks translate/scale and records absolute centers of
/// drawCircle calls. Only the operations DeviceRenderer uses for terminal
/// anchors are modelled.
class _RecordingCanvas implements Canvas {
  final List<Offset> circleCenters = [];
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  final List<(Offset, double)> _stack = [];

  @override
  void save() => _stack.add((_offset, _scale));

  @override
  void restore() {
    final s = _stack.removeLast();
    _offset = s.$1;
    _scale = s.$2;
  }

  @override
  void translate(double dx, double dy) {
    _offset += Offset(dx, dy) * _scale;
  }

  @override
  void scale(double sx, [double? sy]) {
    _scale *= sx;
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleCenters.add(_offset + c * _scale);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(SchematicDevicePackage.initialize);

  group('TerminalGeometry.resolve — static anchors', () {
    test('unknown terminal returns null', () {
      expect(
        TerminalGeometry.resolve(
          definition: _childDef(),
          terminalId: 'nope',
          level: DrawingLevel.wire,
        ),
        isNull,
      );
    });

    test('base anchor without overrides', () {
      expect(
        TerminalGeometry.resolve(
          definition: _childDef(),
          terminalId: 'T1',
          level: DrawingLevel.wire,
        ),
        const Offset(5, 15),
      );
    });

    test('levelAnchors override wins at its level (combined glyph)', () {
      final def = _compositeDef();
      // Symbol level: appearance has no ref → static symbol anchor.
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.symbol,
          resolver: _registry({'child': _childDef(), 'assembly': def}),
        ),
        const Offset(0, 10),
      );
    });

    test('falls back to base anchor at levels without override or ref', () {
      final def = _compositeDef();
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.topology,
          resolver: _registry({'child': _childDef()}),
        ),
        const Offset(0, 25),
      );
    });
  });

  group('TerminalGeometry.resolve — delegation', () {
    test('delegates onto the child terminal at the exploded level', () {
      final def = _compositeDef(refOffset: const Offset(40, 20));
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.wire,
          resolver: _registry({'child': _childDef()}),
        ),
        // ref.offset (40,20) + childAnchor (5,15)
        const Offset(45, 35),
      );
    });

    test('applies ref scale and enclosing group offset/scale', () {
      final def = _compositeDef(
        refOffset: const Offset(10, 10),
        refScale: 2.0,
        groupOffset: const Offset(100, 0),
        groupScale: 0.5,
      );
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.wire,
          resolver: _registry({'child': _childDef()}),
        ),
        // groupOffset + (refOffset + anchor*refScale) * groupScale
        // = (100,0) + ((10,10) + (5,15)*2) * 0.5 = (100,0) + (10,20) = (110,20)
        const Offset(110, 20),
      );
    });

    test('two-deep delegation chain resolves through both composites', () {
      final inner = _compositeDef(refOffset: const Offset(40, 20));
      const outer = DeviceDefinition(
        typeKey: 'outer',
        name: 'Outer',
        connectors: [
          ConnectorDef(
            id: 'ext',
            name: 'Ext',
            placement: ConnectorPlacement.left,
            terminals: [
              TerminalDef(
                id: 'X',
                label: 'X',
                group: ElectricalGroup.power,
                anchorInConnector: Offset.zero,
                delegate:
                    TerminalDelegate(refId: 'ref_inner', terminalId: 'IN'),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(400, 200),
            drawables: [
              DrawDeviceRef(
                id: 'ref_inner',
                typeKey: 'assembly',
                offset: Offset(7, 3),
              ),
            ],
          ),
        ),
      );
      expect(
        TerminalGeometry.resolve(
          definition: outer,
          terminalId: 'X',
          level: DrawingLevel.wire,
          resolver: _registry({'assembly': inner, 'child': _childDef()}),
        ),
        // (7,3) + inner delegated (45,35)
        const Offset(52, 38),
      );
    });

    test('missing resolver falls back to static anchor', () {
      final def = _compositeDef();
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.wire,
        ),
        const Offset(0, 25),
      );
    });

    test('unknown refId falls back to static anchor', () {
      final def = _compositeDef();
      // Registry resolves typeKeys, but the ref id in the appearance is
      // 'ref_child'; point the delegate at a nonexistent id via a modified def.
      final broken = DeviceDefinition.fromJson({
        ...def.toJson(),
        'connectors': [
          {
            'id': 'external',
            'name': 'External',
            'placement': 'left',
            'terminals': [
              {
                'id': 'IN',
                'label': 'IN',
                'group': 'power',
                'anchorInConnector': {'dx': 0.0, 'dy': 25.0},
                'delegate': {'refId': 'no_such_ref', 'terminalId': 'T1'},
              }
            ],
          }
        ],
      });
      expect(
        TerminalGeometry.resolve(
          definition: broken,
          terminalId: 'IN',
          level: DrawingLevel.wire,
          resolver: _registry({'child': _childDef()}),
        ),
        const Offset(0, 25),
      );
    });

    test('unknown child terminal falls back to static anchor', () {
      final def = DeviceDefinition.fromJson({
        ..._compositeDef().toJson(),
      });
      const childWithoutT1 = DeviceDefinition(
        typeKey: 'child',
        name: 'child',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(30, 30)),
        ),
      );
      expect(
        TerminalGeometry.resolve(
          definition: def,
          terminalId: 'IN',
          level: DrawingLevel.wire,
          resolver: _registry({'child': childWithoutT1}),
        ),
        const Offset(0, 25),
      );
    });

    test('self-referential cycle terminates and returns static fallback', () {
      // Device whose wire appearance refs itself and whose terminal delegates
      // into that ref onto the same terminal id.
      const cyclic = DeviceDefinition(
        typeKey: 'cyclic',
        name: 'Cyclic',
        connectors: [
          ConnectorDef(
            id: 'c',
            name: 'C',
            placement: ConnectorPlacement.left,
            terminals: [
              TerminalDef(
                id: 'T',
                label: 'T',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(1, 2),
                delegate: TerminalDelegate(refId: 'ref_self', terminalId: 'T'),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(50, 50),
            drawables: [
              DrawDeviceRef(
                id: 'ref_self',
                typeKey: 'cyclic',
                offset: Offset(10, 0),
              ),
            ],
          ),
        ),
      );
      final result = TerminalGeometry.resolve(
        definition: cyclic,
        terminalId: 'T',
        level: DrawingLevel.wire,
        resolver: _registry({'cyclic': cyclic}),
      );
      // Terminates: maxDepth bounded. Innermost call returns the static
      // anchor (1,2); each of the 8 wrapping levels adds the ref offset.
      expect(result, isNotNull);
      expect(result!.dx, closeTo(81, 0.001));
      expect(result.dy, closeTo(2, 0.001));
    });
  });

  group('TerminalGeometry.resolveForInstance', () {
    test('adds instance position', () {
      final inst = DeviceInstance(
        definition: _childDef(),
        position: const Offset(100, 200),
      );
      expect(
        TerminalGeometry.resolveForInstance(inst, 'T1', DrawingLevel.wire),
        const Offset(105, 215),
      );
    });

    test('forcedLevel switches between combined and exploded geometry', () {
      final def = _compositeDef(refOffset: const Offset(40, 20));
      final resolver = _registry({'child': _childDef()});
      final collapsed = DeviceInstance(definition: def);
      final exploded = collapsed.copyWith(forcedLevel: DrawingLevel.wire);

      // Diagram at symbol level, no override → static symbol anchor.
      expect(
        TerminalGeometry.resolveForInstance(
            collapsed, 'IN', DrawingLevel.symbol,
            resolver: resolver),
        const Offset(0, 10),
      );
      // Same diagram level, forced to wire → delegated child position.
      expect(
        TerminalGeometry.resolveForInstance(exploded, 'IN', DrawingLevel.symbol,
            resolver: resolver),
        const Offset(45, 35),
      );
    });
  });

  group('Renderer parity and forcedLevel rendering', () {
    test('TerminalGeometry matches the point the renderer draws', () {
      final def = _compositeDef(
        refOffset: const Offset(10, 10),
        refScale: 2.0,
        groupOffset: const Offset(100, 0),
        groupScale: 0.5,
      );
      final resolver = _registry({'child': _childDef()});
      final instance =
          DeviceInstance(definition: def, position: const Offset(3, 4));

      final canvas = _RecordingCanvas();
      const DeviceRenderer().render(
        canvas,
        instance,
        level: DrawingLevel.wire,
        context: RenderContext(deviceResolver: resolver),
      );

      final expected = TerminalGeometry.resolveForInstance(
          instance, 'IN', DrawingLevel.wire,
          resolver: resolver)!;
      expect(
        canvas.circleCenters.any((c) =>
            (c.dx - expected.dx).abs() < 0.001 &&
            (c.dy - expected.dy).abs() < 0.001),
        isTrue,
        reason: 'renderer drew terminal circles at ${canvas.circleCenters}, '
            'TerminalGeometry resolved $expected',
      );
    });

    test('forcedLevel renders the exploded appearance at a symbol diagram', () {
      final def = _compositeDef(refOffset: const Offset(40, 20));
      final resolver = _registry({'child': _childDef()});
      final forced = DeviceInstance(
        definition: def,
        forcedLevel: DrawingLevel.wire,
      );

      final canvas = _RecordingCanvas();
      const DeviceRenderer().render(
        canvas,
        forced,
        level: DrawingLevel.symbol,
        context: RenderContext(deviceResolver: resolver),
      );

      // The symbol glyph has no circles; the exploded child draws its
      // terminal dot (fill + stroke) at ref.offset + anchor = (45,35).
      expect(canvas.circleCenters, isNotEmpty);
      expect(
        canvas.circleCenters.any((c) => c == const Offset(45, 35)),
        isTrue,
      );
    });

    test('without forcedLevel the symbol glyph renders (no child circles)', () {
      final def = _compositeDef(refOffset: const Offset(40, 20));
      final resolver = _registry({'child': _childDef()});
      final inst = DeviceInstance(definition: def);

      final canvas = _RecordingCanvas();
      const DeviceRenderer().render(
        canvas,
        inst,
        level: DrawingLevel.symbol,
        context: RenderContext(deviceResolver: resolver),
      );
      expect(canvas.circleCenters, isEmpty);
    });
  });
}
