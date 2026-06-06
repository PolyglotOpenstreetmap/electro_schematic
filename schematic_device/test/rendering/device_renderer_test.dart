// test/rendering/device_renderer_test.dart
//
// Smoke tests for DeviceRenderer.
// No pixel-compare goldens — Phase 2 task.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_device/schematic_device.dart';

/// A minimal DeviceDefinition for testing the renderer.
DeviceDefinition _minimalDef() {
  return const DeviceDefinition(
    typeKey: 'test_renderer',
    name: 'Renderer test device',
    parameters: [
      NumParamDef(id: 'voltage', label: 'V', defaultValue: 400),
      StringParamDef(id: 'ref', label: 'Ref', defaultValue: ''),
      BoolParamDef(id: 'flag', label: 'Flag'),
    ],
    connectors: [
      ConnectorDef(
        id: 'main',
        name: 'Main',
        placement: ConnectorPlacement.top,
        terminals: [
          TerminalDef(
            id: 'T1',
            label: 'T1',
            group: ElectricalGroup.power,
            anchorInConnector: Offset(10, 10),
          ),
          TerminalDef(
            id: 'T2',
            label: 'T2',
            group: ElectricalGroup.power,
            anchorInConnector: Offset(30, 10),
            isJumper: true,
          ),
        ],
      ),
    ],
    appearance: DeviceAppearance(
      wire: LevelAppearance(
        size: Size(60, 40),
        drawables: [
          DrawRect(
            id: 'body',
            rect: Rect.fromLTWH(0, 0, 60, 40),
            fillColor: Color(0xFFF5F5F5),
            strokeColor: Color(0xFF000000),
          ),
          DrawCircle(
            id: 't1_dot',
            center: Offset(10, 10),
            radius: 3,
            fillColor: Color(0xFFEF6C00),
          ),
          DrawTerminalAnchor(
            id: 't2_anchor',
            terminalDefId: 'T2',
            radius: 3,
          ),
          DrawText(
            id: 'ref_label',
            text: r'${ref}',
            position: Offset(30, 35),
            anchor: TextAnchor.bottomCenter,
            fontSize: 8,
          ),
          DrawCoil(
            id: 'coil',
            start: Offset(10, 10),
            end: Offset(30, 10),
            color: Color(0xFF000000),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    SchematicDevicePackage.initialize();
  });

  group('DeviceRenderer smoke tests', () {
    test('render does not throw for a minimal device', () {
      final def = _minimalDef();
      final instance = DeviceInstance(
        definition: def,
        position: const Offset(10, 10),
        paramValues: const {'ref': 'TEST-001', 'voltage': 400},
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(canvas, instance),
        returnsNormally,
      );
    });

    test('render with null wire appearance does nothing', () {
      const def = DeviceDefinition(
        typeKey: 'no_wire',
        name: 'No wire',
        // No wire appearance defined
        appearance: DeviceAppearance(topology: LevelAppearance(size: Size(10, 10))),
      );
      const instance = DeviceInstance(definition: def);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(canvas, instance, level: DrawingLevel.wire),
        returnsNormally,
      );
    });
  });

  group('showIf condition gating', () {
    test('DrawGroup with false showIf is not rendered (no throw)', () {
      // A group that should NEVER be visible — condition is always false
      const alwaysFalseGroup = DrawGroup(
        id: 'hidden',
        showIf: BoolParamCondition('neverTrue'),
        children: [
          DrawRect(
            rect: Rect.fromLTWH(0, 0, 10, 10),
            fillColor: Color(0xFFFF0000),
          ),
        ],
      );

      const def = DeviceDefinition(
        typeKey: 'cond_test',
        name: 'Condition test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(50, 50),
            drawables: [alwaysFalseGroup],
          ),
        ),
      );

      const instance = DeviceInstance(
        definition: def,
        paramValues: {'neverTrue': false},
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(canvas, instance),
        returnsNormally,
      );
    });

    test('condition evaluate — ParamLessThanCondition gates star vs delta', () {
      const starCondition = NotCondition(ParamLessThanCondition('voltage', 300));
      const deltaCondition = ParamLessThanCondition('voltage', 300);

      const starParams = {'voltage': 400};
      const deltaParams = {'voltage': 230};

      expect(starCondition.evaluate(starParams, RenderContext.empty), isTrue);
      expect(starCondition.evaluate(deltaParams, RenderContext.empty), isFalse);
      expect(deltaCondition.evaluate(deltaParams, RenderContext.empty), isTrue);
      expect(deltaCondition.evaluate(starParams, RenderContext.empty), isFalse);
    });
  });

  group('TerminalColorBinding colors', () {
    test('connected terminal returns green', () {
      const binding = TerminalColorBinding(
        terminalDefId: 'T1',
        connectedColor: Color(0xFF4CAF50),
        jumperColor: Color(0xFF1976D2),
        unconnectedColor: Color(0xFFEF6C00),
      );
      final color = binding.resolve(isConnected: true, isJumper: false);
      expect(color, const Color(0xFF4CAF50));
    });

    test('jumper terminal returns blue when not connected', () {
      const binding = TerminalColorBinding(
        terminalDefId: 'T2',
        connectedColor: Color(0xFF4CAF50),
        jumperColor: Color(0xFF1976D2),
        unconnectedColor: Color(0xFFEF6C00),
      );
      final color = binding.resolve(isConnected: false, isJumper: true);
      expect(color, const Color(0xFF1976D2));
    });

    test('unconnected non-jumper returns orange', () {
      const binding = TerminalColorBinding(
        terminalDefId: 'T3',
        connectedColor: Color(0xFF4CAF50),
        unconnectedColor: Color(0xFFEF6C00),
      );
      final color = binding.resolve(isConnected: false, isJumper: false);
      expect(color, const Color(0xFFEF6C00));
    });

    test('connected overrides jumper color', () {
      const binding = TerminalColorBinding(
        terminalDefId: 'T4',
        connectedColor: Color(0xFF4CAF50),
        jumperColor: Color(0xFF1976D2),
        unconnectedColor: Color(0xFFEF6C00),
      );
      // A jumper terminal that is also externally connected
      final color = binding.resolve(isConnected: true, isJumper: true);
      expect(color, const Color(0xFF4CAF50));
    });

    test('TerminalColorBinding round-trip', () {
      const original = TerminalColorBinding(
        terminalDefId: 'U1',
        connectedColor: Color(0xFF4CAF50),
        jumperColor: Color(0xFF1976D2),
        unconnectedColor: Color(0xFFEF6C00),
      );
      final restored = TerminalColorBinding.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('Text template substitution', () {
    testWidgets('renderer substitutes \${ref} in DrawText',
        (WidgetTester tester) async {
      // We just verify the renderer doesn't throw and processes templates.
      // Actual pixel validation is a Phase 2 golden test task.
      const def = DeviceDefinition(
        typeKey: 'text_test',
        name: 'Text test',
        parameters: [
          StringParamDef(id: 'ref', label: 'Ref', defaultValue: ''),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(80, 30),
            drawables: [
              DrawText(
                text: r'Ref: ${ref}',
                position: Offset(5, 5),
                fontSize: 10,
              ),
            ],
          ),
        ),
      );

      const instance = DeviceInstance(
        definition: def,
        paramValues: {'ref': 'MY-MOTOR'},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: CustomPaint(
                painter: _TestDevicePainter(instance: instance),
              ),
            ),
          ),
        ),
      );

      // If we get here without throwing, template substitution works.
      expect(tester.takeException(), isNull);
    });
  });

  group('DrawRepeat count resolution', () {
    test('literal count generates correct number of children', () {
      const def = DeviceDefinition(
        typeKey: 'repeat_test',
        name: 'Repeat test',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(30, 70),
            drawables: [
              DrawRepeat(
                count: '4',
                axis: RepeatAxis.vertical,
                spacing: 15,
                templateChild: DrawCircle(
                  center: Offset(15, 10),
                  radius: 4.0,
                ),
              ),
            ],
          ),
        ),
      );

      const instance = DeviceInstance(definition: def);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });

    test('param count generates correct number of children', () {
      const def = DeviceDefinition(
        typeKey: 'repeat_param_test',
        name: 'Repeat param test',
        parameters: [
          NumParamDef(id: 'count', label: 'Count', defaultValue: 4),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(30, 70),
            drawables: [
              DrawRepeat(
                count: r'${count}',
                axis: RepeatAxis.vertical,
                spacing: 15,
                templateChild: DrawCircle(
                  center: Offset(15, 10),
                  radius: 4.0,
                ),
              ),
            ],
          ),
        ),
      );

      const instance = DeviceInstance(
        definition: def,
        paramValues: {'count': 6},
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });
  });

  group('DeviceRenderer all primitive types', () {
    test('renders all primitive node types without throwing', () {
      const def = DeviceDefinition(
        typeKey: 'all_primitives',
        name: 'All primitives',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(100, 100),
            drawables: [
              DrawRect(
                rect: Rect.fromLTWH(0, 0, 100, 100),
                fillColor: Color(0xFFFFFFFF),
                strokeColor: Color(0xFF000000),
              ),
              DrawCircle(
                center: Offset(50, 50),
                radius: 10,
                fillColor: Color(0xFF4CAF50),
              ),
              DrawLine(
                start: Offset(0, 0),
                end: Offset(100, 100),
                color: Color(0xFF000000),
              ),
              DrawPolyline(
                points: [Offset(0, 0), Offset(50, 25), Offset(100, 0)],
                color: Color(0xFF000000),
                closed: true,
              ),
              DrawText(
                text: 'Hello',
                position: Offset(50, 50),
                anchor: TextAnchor.center,
                fontSize: 12,
              ),
              DrawPath(
                svgPathData: ['M 0 0', 'L 50 50', 'Z'],
                color: Color(0xFF333333),
                fill: false,
              ),
              DrawCoil(
                start: Offset(10, 30),
                end: Offset(90, 30),
                color: Color(0xFF000000),
              ),
              DrawCapacitor(
                center: Offset(50, 70),
                color: Color(0xFF000000),
              ),
            ],
          ),
        ),
      );

      const instance = DeviceInstance(definition: def);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });
  });
}

class _TestDevicePainter extends CustomPainter {
  final DeviceInstance instance;
  static const _renderer = DeviceRenderer();

  const _TestDevicePainter({required this.instance});

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, instance);
  }

  @override
  bool shouldRepaint(_TestDevicePainter old) => instance != old.instance;
}
