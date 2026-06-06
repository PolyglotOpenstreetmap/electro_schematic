// test/models_test.dart
//
// JSON round-trip tests for DeviceDefinition and related models.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_device/schematic_device.dart';

void main() {
  setUpAll(() {
    SchematicDevicePackage.initialize();
  });

  // ─── ParameterDef round-trips ─────────────────────────────────────────────
  group('ParameterDef serialization', () {
    test('StringParamDef round-trip', () {
      const original = StringParamDef(
        id: 'ref',
        label: 'Reference',
        defaultValue: 'ABC123',
      );
      final restored = ParameterDef.fromJson(original.toJson());
      expect(restored, isA<StringParamDef>());
      expect((restored as StringParamDef).id, 'ref');
      expect(restored.label, 'Reference');
      expect(restored.defaultValue, 'ABC123');
    });

    test('NumParamDef round-trip with min/max', () {
      const original = NumParamDef(
        id: 'count',
        label: 'Count',
        defaultValue: 4,
        min: 1,
        max: 32,
      );
      final restored = ParameterDef.fromJson(original.toJson());
      expect(restored, isA<NumParamDef>());
      final p = restored as NumParamDef;
      expect(p.defaultValue, 4);
      expect(p.min, 1);
      expect(p.max, 32);
    });

    test('NumParamDef round-trip without min/max', () {
      const original = NumParamDef(
        id: 'voltage',
        label: 'Voltage',
        defaultValue: 400,
      );
      final restored = ParameterDef.fromJson(original.toJson()) as NumParamDef;
      expect(restored.min, isNull);
      expect(restored.max, isNull);
    });

    test('BoolParamDef round-trip', () {
      const original = BoolParamDef(
        id: 'hasCapacitor',
        label: 'Has capacitor',
        defaultValue: true,
      );
      final restored = ParameterDef.fromJson(original.toJson());
      expect(restored, isA<BoolParamDef>());
      expect((restored as BoolParamDef).defaultValue, true);
    });

    test('EnumParamDef round-trip', () {
      const original = EnumParamDef(
        id: 'motorType',
        label: 'Motor type',
        values: ['standard', 'decoster'],
        defaultValue: 'standard',
      );
      final restored = ParameterDef.fromJson(original.toJson());
      expect(restored, isA<EnumParamDef>());
      final p = restored as EnumParamDef;
      expect(p.values, ['standard', 'decoster']);
      expect(p.defaultValue, 'standard');
    });
  });

  // ─── ConditionExpr round-trips ────────────────────────────────────────────
  group('ConditionExpr serialization', () {
    test('ParamEqualsCondition', () {
      const original = ParamEqualsCondition('motorType', 'decoster');
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<ParamEqualsCondition>());
      expect(
          (restored as ParamEqualsCondition).evaluate(
              {'motorType': 'decoster'}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'motorType': 'standard'}, RenderContext.empty),
          isFalse);
    });

    test('ParamLessThanCondition', () {
      const original = ParamLessThanCondition('voltage', 300);
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<ParamLessThanCondition>());
      expect(
          (restored as ParamLessThanCondition)
              .evaluate({'voltage': 230}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'voltage': 400}, RenderContext.empty), isFalse);
    });

    test('ParamGreaterThanCondition', () {
      const original = ParamGreaterThanCondition('voltage', 300);
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<ParamGreaterThanCondition>());
      expect(
          (restored as ParamGreaterThanCondition)
              .evaluate({'voltage': 400}, RenderContext.empty),
          isTrue);
    });

    test('ParamStartsWithCondition', () {
      const original = ParamStartsWithCondition('motorRef', 'SV21');
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<ParamStartsWithCondition>());
      expect(
          (restored as ParamStartsWithCondition)
              .evaluate({'motorRef': 'SV21-something'}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'motorRef': 'IV3-something'}, RenderContext.empty),
          isFalse);
    });

    test('BoolParamCondition', () {
      const original = BoolParamCondition('hasCapacitor');
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<BoolParamCondition>());
      expect(
          (restored as BoolParamCondition)
              .evaluate({'hasCapacitor': true}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'hasCapacitor': false}, RenderContext.empty),
          isFalse);
    });

    test('NotCondition', () {
      const original = NotCondition(BoolParamCondition('flag'));
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<NotCondition>());
      expect(
          (restored as NotCondition)
              .evaluate({'flag': false}, RenderContext.empty),
          isTrue);
    });

    test('AndCondition', () {
      const original = AndCondition([
        BoolParamCondition('a'),
        BoolParamCondition('b'),
      ]);
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<AndCondition>());
      expect(
          (restored as AndCondition).evaluate(
              {'a': true, 'b': true}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'a': true, 'b': false}, RenderContext.empty),
          isFalse);
    });

    test('OrCondition', () {
      const original = OrCondition([
        BoolParamCondition('a'),
        BoolParamCondition('b'),
      ]);
      final restored = ConditionExpr.fromJson(original.toJson());
      expect(restored, isA<OrCondition>());
      expect(
          (restored as OrCondition).evaluate(
              {'a': false, 'b': true}, RenderContext.empty),
          isTrue);
      expect(
          restored.evaluate({'a': false, 'b': false}, RenderContext.empty),
          isFalse);
    });
  });

  // ─── DrawableNode round-trips ──────────────────────────────────────────────
  group('DrawableNode serialization', () {
    test('DrawRect round-trip', () {
      const node = DrawRect(
        id: 'body',
        rect: Rect.fromLTWH(0, 0, 67.5, 60),
        cornerRadius: 4,
        fillColor: Color(0xFFF5F5F5),
        strokeColor: Color(0xDD000000),
        strokeWidth: 1.5,
        lineStyle: LineStyle.solid,
      );
      final restored = DrawableNodeFactory.fromJson(node.toJson());
      expect(restored, isA<DrawRect>());
      expect((restored as DrawRect).rect, node.rect);
      expect(restored.cornerRadius, 4.0);
      expect(restored.fillColor, node.fillColor);
    });

    test('DrawCircle round-trip with fillBinding', () {
      const node = DrawCircle(
        center: Offset(10, 10),
        radius: 2.5,
        strokeColor: Color(0xFF000000),
        strokeWidth: 0.8,
        fillBinding: TerminalColorBinding(
          terminalDefId: 'U1',
          connectedColor: Color(0xFF4CAF50),
          jumperColor: Color(0xFF1976D2),
          unconnectedColor: Color(0xFFEF6C00),
        ),
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawCircle;
      expect(restored.center, const Offset(10, 10));
      expect(restored.fillBinding?.terminalDefId, 'U1');
    });

    test('DrawLine round-trip', () {
      const node = DrawLine(
        start: Offset(0, 0),
        end: Offset(10, 20),
        color: Color(0xFF000000),
        strokeWidth: 1.0,
      );
      final restored = DrawableNodeFactory.fromJson(node.toJson()) as DrawLine;
      expect(restored.start, const Offset(0, 0));
      expect(restored.end, const Offset(10, 20));
    });

    test('DrawPolyline round-trip', () {
      const node = DrawPolyline(
        points: [Offset(0, 0), Offset(5, 5), Offset(10, 0)],
        color: Color(0xFF000000),
        closed: true,
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawPolyline;
      expect(restored.points.length, 3);
      expect(restored.closed, isTrue);
    });

    test('DrawText round-trip with template', () {
      const node = DrawText(
        text: r'${motorRef}',
        position: Offset(33.75, 54),
        anchor: TextAnchor.bottomCenter,
        fontSize: 8,
        bold: false,
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawText;
      expect(restored.text, r'${motorRef}');
      expect(restored.anchor, TextAnchor.bottomCenter);
    });

    test('DrawPath round-trip', () {
      const node = DrawPath(
        svgPathData: ['M 0 0', 'L 10 10', 'Z'],
        color: Color(0xFF333333),
        fill: true,
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawPath;
      expect(restored.svgPathData, ['M 0 0', 'L 10 10', 'Z']);
      expect(restored.fill, isTrue);
    });

    test('DrawCoil round-trip', () {
      const node = DrawCoil(
        start: Offset(10, 8),
        end: Offset(10, 25.5),
        color: Color(0xDD000000),
        strokeWidth: 1.5,
        arcCount: 4,
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawCoil;
      expect(restored.arcCount, 4);
      expect(restored.start, const Offset(10, 8));
    });

    test('DrawCapacitor round-trip', () {
      const node = DrawCapacitor(
        center: Offset(20, 5),
        horizontal: true,
        scale: 0.8,
        color: Color(0xFF000000),
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawCapacitor;
      expect(restored.horizontal, isTrue);
      expect(restored.scale, 0.8);
    });

    test('DrawTerminalAnchor round-trip', () {
      const node = DrawTerminalAnchor(
        terminalDefId: 'U1',
        radius: 2.5,
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawTerminalAnchor;
      expect(restored.terminalDefId, 'U1');
      expect(restored.radius, 2.5);
    });

    test('DrawGroup round-trip with showIf', () {
      const node = DrawGroup(
        id: 'star',
        showIf: NotCondition(ParamLessThanCondition('voltage', 300)),
        children: [
          DrawLine(
            start: Offset(0, 0),
            end: Offset(5, 5),
            color: Color(0xFF555555),
          ),
        ],
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawGroup;
      expect(restored.id, 'star');
      expect(restored.children.length, 1);
      expect(restored.showIf, isNotNull);
      // Verify the condition evaluates correctly after round-trip
      expect(
          restored.showIf!.evaluate({'voltage': 400}, RenderContext.empty),
          isTrue);
      expect(
          restored.showIf!.evaluate({'voltage': 230}, RenderContext.empty),
          isFalse);
    });

    test('DrawRepeat round-trip', () {
      const node = DrawRepeat(
        count: r'${count}',
        axis: RepeatAxis.vertical,
        spacing: 15,
        templateChild: DrawCircle(
          center: Offset(15, 10),
          radius: 4.0,
          strokeColor: Color(0xFF000000),
        ),
      );
      final restored =
          DrawableNodeFactory.fromJson(node.toJson()) as DrawRepeat;
      expect(restored.count, r'${count}');
      expect(restored.axis, RepeatAxis.vertical);
      expect(restored.spacing, 15.0);
      expect(restored.templateChild, isA<DrawCircle>());
    });
  });

  // ─── TerminalDef / ConnectorDef round-trips ───────────────────────────────
  group('TerminalDef serialization', () {
    test('round-trip', () {
      const original = TerminalDef(
        id: 'U1',
        label: 'U1',
        group: ElectricalGroup.power,
        anchorInConnector: Offset(7.5, 8.0),
        isJumper: false,
        description: 'First winding start',
      );
      final restored = TerminalDef.fromJson(original.toJson());
      expect(restored, original);
    });

    test('isJumper=true preserved', () {
      const original = TerminalDef(
        id: 'U2',
        label: 'U2',
        group: ElectricalGroup.power,
        anchorInConnector: Offset(25, 25.5),
        isJumper: true,
      );
      final restored = TerminalDef.fromJson(original.toJson());
      expect(restored.isJumper, isTrue);
    });
  });

  group('ConnectorDef serialization', () {
    test('round-trip', () {
      const original = ConnectorDef(
        id: 'main',
        name: 'Motor terminals',
        placement: ConnectorPlacement.top,
        terminals: [
          TerminalDef(
            id: 'U1',
            label: 'U1',
            group: ElectricalGroup.power,
            anchorInConnector: Offset(7.5, 8.0),
          ),
        ],
      );
      final restored = ConnectorDef.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.terminals.length, 1);
    });
  });

  // ─── DeviceDefinition round-trips ────────────────────────────────────────
  group('DeviceDefinition serialization', () {
    test('minimal definition round-trip', () {
      const original = DeviceDefinition(
        typeKey: 'test_device',
        name: 'Test Device',
        appearance: DeviceAppearance(
          wire: LevelAppearance(size: Size(50, 50)),
        ),
      );
      final json = original.toJson();
      final restored = DeviceDefinition.fromJson(json);
      expect(restored.typeKey, 'test_device');
      expect(restored.name, 'Test Device');
      expect(restored.appearance.wire?.size, const Size(50, 50));
    });

    test('full definition round-trip with parameters and connectors', () {
      const original = DeviceDefinition(
        typeKey: 'full_device',
        name: 'Full Device',
        description: 'A comprehensive test device',
        parameters: [
          StringParamDef(id: 'ref', label: 'Reference'),
          NumParamDef(id: 'count', label: 'Count', defaultValue: 4, min: 1, max: 32),
          BoolParamDef(id: 'flag', label: 'Flag'),
          EnumParamDef(
            id: 'type',
            label: 'Type',
            values: ['a', 'b'],
            defaultValue: 'a',
          ),
        ],
        connectors: [
          ConnectorDef(
            id: 'c1',
            name: 'Connector 1',
            placement: ConnectorPlacement.top,
            terminals: [
              TerminalDef(
                id: 't1',
                label: 'T1',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(10, 10),
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(80, 80),
            drawables: [
              DrawRect(
                rect: Rect.fromLTWH(0, 0, 80, 80),
                fillColor: Color(0xFFFFFFFF),
                strokeColor: Color(0xFF000000),
              ),
            ],
          ),
        ),
      );

      final json = original.toJson();
      final restored = DeviceDefinition.fromJson(json);
      expect(restored, original);
    });

    test('defaultParams returns parameter defaults', () {
      const def = DeviceDefinition(
        typeKey: 'p',
        name: 'P',
        parameters: [
          NumParamDef(id: 'voltage', label: 'V', defaultValue: 400),
          StringParamDef(id: 'ref', label: 'Ref', defaultValue: 'X'),
        ],
        appearance: DeviceAppearance(),
      );
      final defaults = def.defaultParams;
      expect(defaults['voltage'], 400);
      expect(defaults['ref'], 'X');
    });
  });

  // ─── DeviceInstance helpers ───────────────────────────────────────────────
  group('DeviceInstance', () {
    late DeviceDefinition def;

    setUp(() {
      def = const DeviceDefinition(
        typeKey: 'inst_test',
        name: 'Test',
        parameters: [
          NumParamDef(id: 'voltage', label: 'V', defaultValue: 400),
        ],
        connectors: [
          ConnectorDef(
            id: 'c',
            name: 'C',
            placement: ConnectorPlacement.top,
            terminals: [
              TerminalDef(
                id: 'T1',
                label: 'T1',
                group: ElectricalGroup.power,
                anchorInConnector: Offset(10, 10),
                isJumper: true,
              ),
            ],
          ),
        ],
        appearance: DeviceAppearance(),
      );
    });

    test('param falls back to definition default', () {
      final inst = DeviceInstance(definition: def);
      expect(inst.param('voltage'), 400);
    });

    test('param returns instance override', () {
      final inst = DeviceInstance(
        definition: def,
        paramValues: const {'voltage': 230},
      );
      expect(inst.param('voltage'), 230);
    });

    test('isTerminalConnected returns false by default', () {
      final inst = DeviceInstance(definition: def);
      expect(inst.isTerminalConnected('T1'), isFalse);
    });

    test('isTerminalConnected returns true when set', () {
      final inst = DeviceInstance(
        definition: def,
        terminalConnected: const {'T1': true},
      );
      expect(inst.isTerminalConnected('T1'), isTrue);
    });

    test('isTerminalJumper reads from definition by default', () {
      final inst = DeviceInstance(definition: def);
      expect(inst.isTerminalJumper('T1'), isTrue);
    });

    test('isTerminalJumper can be overridden per-instance', () {
      final inst = DeviceInstance(
        definition: def,
        terminalIsJumper: const {'T1': false},
      );
      expect(inst.isTerminalJumper('T1'), isFalse);
    });

    test('copyWith produces updated instance', () {
      final inst = DeviceInstance(definition: def);
      final copy = inst.copyWith(
        position: const Offset(100, 200),
        paramValues: {'voltage': 110},
      );
      expect(copy.position, const Offset(100, 200));
      expect(copy.param('voltage'), 110);
    });
  });

  // ─── Color utilities ──────────────────────────────────────────────────────
  group('Color utilities', () {
    test('colorFromHex #RRGGBB', () {
      final c = colorFromHex('#4CAF50');
      expect(c, const Color(0xFF4CAF50));
    });

    test('colorFromHex #AARRGGBB', () {
      final c = colorFromHex('#884CAF50');
      expect(c, const Color(0x884CAF50));
    });

    test('colorFromHex #RGB expands', () {
      final c = colorFromHex('#ABC');
      expect(c, const Color(0xFFAABBCC));
    });

    test('colorToHexCompact opaque', () {
      final s = colorToHexCompact(const Color(0xFF4CAF50));
      expect(s.toLowerCase(), '#4caf50');
    });

    test('colorToHex round-trip', () {
      const original = Color(0x884CAF50);
      final hex = colorToHex(original);
      final restored = colorFromHex(hex);
      expect(restored, original);
    });
  });
}
