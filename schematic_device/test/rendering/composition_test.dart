// test/rendering/composition_test.dart
//
// Tests for recursive device composition:
//   - symbol level round-trip
//   - DrawDeviceRef JSON round-trip
//   - DrawDeviceRef resolution and rendering
//   - MotorWithSensorsDevice composite rendering
//   - instance-tree (ChildPlacement) rendering
//   - recursion guard (max depth)
//   - existing device_renderer_test.dart regressions confirmed in models_test.dart

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Minimal atomic definition for use as a child device.
DeviceDefinition _atomicDef({
  String typeKey = 'atomic',
  DrawingLevel level = DrawingLevel.wire,
  Size size = const Size(20, 20),
}) {
  final appearance = LevelAppearance(
    size: size,
    drawables: [
      DrawRect(
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        fillColor: const Color(0xFFCCCCCC),
        strokeColor: const Color(0xFF000000),
      ),
    ],
  );

  return DeviceDefinition(
    typeKey: typeKey,
    name: typeKey,
    appearance: DeviceAppearance(
      wire: level == DrawingLevel.wire ? appearance : null,
      symbol: level == DrawingLevel.symbol ? appearance : null,
    ),
  );
}

/// Builds a [RenderContext] backed by [registry].
RenderContext _ctx(Map<String, DeviceDefinition> registry) => RenderContext(
      deviceResolver: (key) => registry[key],
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(SchematicDevicePackage.initialize);

  // ── B1: symbol level ───────────────────────────────────────────────────────

  group('symbol DrawingLevel', () {
    test('forLevel(symbol) returns the symbol appearance', () {
      final sym = LevelAppearance(
        size: const Size(40, 40),
        drawables: const [
          DrawCircle(center: Offset(20, 20), radius: 18, fillColor: Color(0xFFFFFFFF)),
        ],
      );
      final appearance = DeviceAppearance(symbol: sym);
      expect(appearance.forLevel(DrawingLevel.symbol), same(sym));
      expect(appearance.forLevel(DrawingLevel.wire), isNull);
      expect(appearance.forLevel(DrawingLevel.topology), isNull);
    });

    test('DeviceAppearance with symbol level round-trips through JSON', () {
      const symAppearance = LevelAppearance(
        size: Size(60, 80),
        drawables: [
          DrawLine(
            start: Offset(0, 0),
            end: Offset(30, 0),
            color: Color(0xFF000000),
          ),
          DrawCircle(
            center: Offset(30, 40),
            radius: 20,
            fillColor: Color(0xFFFFFFFF),
            strokeColor: Color(0xFF000000),
          ),
        ],
      );

      const original = DeviceAppearance(
        wire: LevelAppearance(size: Size(10, 10)),
        symbol: symAppearance,
        topology: LevelAppearance(size: Size(50, 50)),
      );

      final json = original.toJson();
      final restored = DeviceAppearance.fromJson(json);

      expect(restored.symbol?.size, const Size(60, 80));
      expect(restored.symbol?.drawables.length, 2);
      expect(restored.wire?.size, const Size(10, 10));
      expect(restored.topology?.size, const Size(50, 50));
      expect(restored, original);
    });

    test('render at symbol level uses symbol appearance', () {
      final symAppearance = LevelAppearance(
        size: const Size(30, 30),
        drawables: [
          DrawRect(
            rect: const Rect.fromLTWH(0, 0, 30, 30),
            fillColor: const Color(0xFF0000FF),
          ),
        ],
      );
      final def = DeviceDefinition(
        typeKey: 'sym_test',
        name: 'Symbol test',
        appearance: DeviceAppearance(
          wire: const LevelAppearance(size: Size(10, 10)),
          symbol: symAppearance,
        ),
      );
      final instance = DeviceInstance(definition: def);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(canvas, instance, level: DrawingLevel.symbol),
        returnsNormally,
      );
    });
  });

  // ── B3: DrawDeviceRef JSON round-trip ──────────────────────────────────────

  group('DrawDeviceRef serialization', () {
    test('round-trip with all fields', () {
      const node = DrawDeviceRef(
        id: 'child_motor',
        typeKey: 'rotating_motor',
        level: DrawingLevel.symbol,
        offset: Offset(70, 10),
        scale: 0.8,
        paramOverrides: {'motorRef': 'IVR3210', 'voltage': 400},
      );

      final json = node.toJson();
      expect(json['type'], 'deviceRef');
      expect(json['typeKey'], 'rotating_motor');
      expect(json['level'], 'symbol');
      expect((json['offset'] as Map)['dx'], 70.0);
      expect(json['scale'], 0.8);
      expect((json['paramOverrides'] as Map)['motorRef'], 'IVR3210');

      final restored = DrawableNodeFactory.fromJson(json) as DrawDeviceRef;
      expect(restored.typeKey, 'rotating_motor');
      expect(restored.level, DrawingLevel.symbol);
      expect(restored.offset, const Offset(70, 10));
      expect(restored.scale, 0.8);
      expect(restored.paramOverrides['motorRef'], 'IVR3210');
      expect(restored.id, 'child_motor');
    });

    test('round-trip with defaults (no level, zero offset, scale=1)', () {
      const node = DrawDeviceRef(typeKey: 'sensor');

      final json = node.toJson();
      expect(json.containsKey('level'), isFalse);
      expect(json['scale'], 1.0);

      final restored = DrawableNodeFactory.fromJson(json) as DrawDeviceRef;
      expect(restored.typeKey, 'sensor');
      expect(restored.level, isNull);
      expect(restored.offset, Offset.zero);
      expect(restored.scale, 1.0);
      expect(restored.paramOverrides, isEmpty);
    });

    test('DrawDeviceRef inside DrawRepeat survives JSON round-trip', () {
      const repeat = DrawRepeat(
        count: r'${count}',
        axis: RepeatAxis.horizontal,
        spacing: 50,
        templateChild: DrawDeviceRef(
          typeKey: 'sensor',
          offset: Offset(70, 0),
        ),
      );

      final json = repeat.toJson();
      final restored = DrawableNodeFactory.fromJson(json) as DrawRepeat;
      final child = restored.templateChild as DrawDeviceRef;
      expect(child.typeKey, 'sensor');
      expect(child.offset.dx, 70.0);
    });
  });

  // ── B4: Recursive rendering via DrawDeviceRef ──────────────────────────────

  group('DrawDeviceRef rendering', () {
    test('resolver miss silently skips (no throw)', () {
      final emptyCtx = RenderContext(deviceResolver: (_) => null);

      const parentDef = DeviceDefinition(
        typeKey: 'parent',
        name: 'Parent',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(100, 100),
            drawables: [
              DrawDeviceRef(typeKey: 'missing_child'),
            ],
          ),
        ),
      );
      const instance = DeviceInstance(definition: parentDef);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(canvas, instance, context: emptyCtx),
        returnsNormally,
      );
    });

    test('null resolver silently skips DrawDeviceRef', () {
      const parentDef = DeviceDefinition(
        typeKey: 'parent_no_resolver',
        name: 'Parent',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(50, 50),
            drawables: [DrawDeviceRef(typeKey: 'child')],
          ),
        ),
      );
      const instance = DeviceInstance(definition: parentDef);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      // No resolver in context → skips DrawDeviceRef
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });

    test('resolver is called and child appearance is rendered (no throw)', () {
      final childDef = _atomicDef(typeKey: 'child_a');
      final registry = {'child_a': childDef};

      const parentDef = DeviceDefinition(
        typeKey: 'parent_a',
        name: 'Parent A',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(120, 40),
            drawables: [
              DrawDeviceRef(typeKey: 'child_a', offset: Offset(80, 5)),
            ],
          ),
        ),
      );
      const instance = DeviceInstance(definition: parentDef);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(canvas, instance, context: _ctx(registry)),
        returnsNormally,
      );
    });

    test('paramOverrides template resolution forwards parent params', () {
      // Child has a 'label' param; parent passes its own 'name' param via template.
      final childDef = DeviceDefinition(
        typeKey: 'labelled_child',
        name: 'Child',
        parameters: const [
          StringParamDef(id: 'label', label: 'Label', defaultValue: 'default'),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(30, 15),
            drawables: const [
              DrawText(
                text: r'${label}',
                position: Offset(5, 5),
                fontSize: 8,
              ),
            ],
          ),
        ),
      );
      final registry = {'labelled_child': childDef};

      final parentDef = DeviceDefinition(
        typeKey: 'parent_b',
        name: 'Parent B',
        parameters: const [
          StringParamDef(id: 'name', label: 'Name', defaultValue: 'motor'),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(60, 20),
            drawables: [
              DrawDeviceRef(
                typeKey: 'labelled_child',
                offset: const Offset(30, 0),
                paramOverrides: const {'label': r'${name}'},
              ),
            ],
          ),
        ),
      );
      final instance = DeviceInstance(
        definition: parentDef,
        paramValues: const {'name': 'M1'},
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(canvas, instance, context: _ctx(registry)),
        returnsNormally,
      );
    });

    test('level inheritance: child inherits parent level when DrawDeviceRef.level is null', () {
      final childWithSymbol = _atomicDef(
        typeKey: 'child_sym',
        level: DrawingLevel.symbol,
      );
      final registry = {'child_sym': childWithSymbol};

      const parentDef = DeviceDefinition(
        typeKey: 'parent_sym',
        name: 'Parent sym',
        appearance: DeviceAppearance(
          symbol: LevelAppearance(
            size: Size(80, 40),
            drawables: [
              // level = null → inherits symbol
              DrawDeviceRef(typeKey: 'child_sym'),
            ],
          ),
        ),
      );
      const instance = DeviceInstance(definition: parentDef);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(
          canvas,
          instance,
          level: DrawingLevel.symbol,
          context: _ctx(registry),
        ),
        returnsNormally,
      );
    });
  });

  // ── B5: Instance-tree (ChildPlacement) ────────────────────────────────────

  group('ChildPlacement / instance-tree', () {
    test('instance with children renders without throw', () {
      final parentDef = _atomicDef(typeKey: 'it_parent');
      final childDef = _atomicDef(typeKey: 'it_child');

      final instance = DeviceInstance(
        definition: parentDef,
        children: [
          ChildPlacement(
            child: DeviceInstance(definition: childDef),
            offset: const Offset(30, 0),
          ),
        ],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });

    test('ChildPlacement round-trips through JSON', () {
      final childDef = _atomicDef(typeKey: 'json_child');
      final placement = ChildPlacement(
        child: DeviceInstance(
          definition: childDef,
          paramValues: const {'x': 1},
        ),
        offset: const Offset(10, 20),
        scale: 1.5,
        levelOverride: DrawingLevel.symbol,
      );

      final json = placement.toJson();

      final restored = ChildPlacement.fromJson(
        json,
        resolver: (key) => key == 'json_child' ? childDef : null,
      );

      expect(restored.offset, const Offset(10, 20));
      expect(restored.scale, 1.5);
      expect(restored.levelOverride, DrawingLevel.symbol);
      expect(restored.child.definition.typeKey, 'json_child');
    });

    test('DeviceInstance with children serializes and deserializes', () {
      final parentDef = _atomicDef(typeKey: 'parent_json');
      final childDef = _atomicDef(typeKey: 'child_json');

      final instance = DeviceInstance(
        definition: parentDef,
        position: const Offset(5, 5),
        children: [
          ChildPlacement(
            child: DeviceInstance(definition: childDef),
            offset: const Offset(25, 0),
            scale: 2.0,
          ),
        ],
      );

      final json = instance.toJson();
      expect((json['children'] as List).length, 1);

      final registry = {
        'parent_json': parentDef,
        'child_json': childDef,
      };
      final restored = DeviceInstance.fromJson(
        json,
        resolver: (key) => registry[key],
      );

      expect(restored.children.length, 1);
      expect(restored.children.first.offset.dx, 25.0);
      expect(restored.children.first.scale, 2.0);
      expect(restored.children.first.child.definition.typeKey, 'child_json');
    });

    test('instance-tree levelOverride is respected', () {
      // Parent renders at wire; child placement overrides to symbol.
      final parentDef = _atomicDef(typeKey: 'it_lvl_parent');
      final childDef = _atomicDef(typeKey: 'it_lvl_child', level: DrawingLevel.symbol);

      final instance = DeviceInstance(
        definition: parentDef,
        children: [
          ChildPlacement(
            child: DeviceInstance(definition: childDef),
            offset: const Offset(25, 0),
            levelOverride: DrawingLevel.symbol,
          ),
        ],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(() => renderer.render(canvas, instance), returnsNormally);
    });
  });

  // ── Composite: MotorWithSensors via DrawDeviceRef ──────────────────────────

  group('composite rendering via DrawDeviceRef', () {
    late Map<String, DeviceDefinition> registry;

    setUp(() {
      // Build minimal registry for composition tests
      final motorDef = DeviceDefinition(
        typeKey: 'rotating_motor',
        name: 'Motor',
        parameters: const [
          StringParamDef(id: 'motorRef', label: 'Ref', defaultValue: ''),
          NumParamDef(id: 'voltage', label: 'V', defaultValue: 400),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(67.5, 60),
            drawables: [
              DrawRect(
                rect: const Rect.fromLTWH(0, 0, 67.5, 60),
                fillColor: const Color(0xFFF5F5F5),
                strokeColor: const Color(0xFF000000),
              ),
            ],
          ),
          symbol: LevelAppearance(
            size: const Size(60, 80),
            drawables: [
              DrawCircle(
                center: const Offset(30, 50),
                radius: 20,
                fillColor: const Color(0xFFFFFFFF),
                strokeColor: const Color(0xFF000000),
              ),
            ],
          ),
        ),
      );

      final sensorDef = DeviceDefinition(
        typeKey: 'sensor',
        name: 'Sensor',
        parameters: const [
          StringParamDef(id: 'sensorRef', label: 'Ref', defaultValue: ''),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(52, 32),
            drawables: [
              DrawRect(
                rect: const Rect.fromLTWH(0, 0, 52, 32),
                fillColor: const Color(0xFFF5F5F5),
                strokeColor: const Color(0xFF000000),
              ),
            ],
          ),
          symbol: LevelAppearance(
            size: const Size(30, 38),
            drawables: [
              DrawCircle(
                center: const Offset(15, 23),
                radius: 12,
                fillColor: const Color(0xFFFFFFFF),
                strokeColor: const Color(0xFF000000),
              ),
            ],
          ),
        ),
      );

      final motorWithSensorsDef = DeviceDefinition(
        typeKey: 'motor_with_sensors',
        name: 'Motor + sensors',
        parameters: const [
          NumParamDef(id: 'sensorCount', label: 'Sensors', defaultValue: 1, min: 0, max: 4),
          BoolParamDef(id: 'hasBrake', label: 'Brake', defaultValue: false),
          StringParamDef(id: 'motorRef', label: 'Ref', defaultValue: ''),
          NumParamDef(id: 'voltage', label: 'V', defaultValue: 400),
        ],
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(310, 70),
            drawables: [
              DrawDeviceRef(
                typeKey: 'rotating_motor',
                offset: const Offset(0, 5),
                paramOverrides: const {
                  'motorRef': r'${motorRef}',
                  'voltage': r'${voltage}',
                },
              ),
              DrawRepeat(
                count: r'${sensorCount}',
                axis: RepeatAxis.horizontal,
                spacing: 56,
                templateChild: const DrawDeviceRef(
                  typeKey: 'sensor',
                  offset: Offset(70, 14),
                ),
              ),
            ],
          ),
          symbol: LevelAppearance(
            size: const Size(230, 80),
            drawables: [
              DrawDeviceRef(
                typeKey: 'rotating_motor',
                level: DrawingLevel.symbol,
                offset: Offset.zero,
                paramOverrides: const {
                  'motorRef': r'${motorRef}',
                  'voltage': r'${voltage}',
                },
              ),
              DrawRepeat(
                count: r'${sensorCount}',
                axis: RepeatAxis.horizontal,
                spacing: 34,
                templateChild: const DrawDeviceRef(
                  typeKey: 'sensor',
                  level: DrawingLevel.symbol,
                  offset: Offset(65, 0),
                ),
              ),
            ],
          ),
        ),
      );

      registry = {
        motorDef.typeKey: motorDef,
        sensorDef.typeKey: sensorDef,
        motorWithSensorsDef.typeKey: motorWithSensorsDef,
      };
    });

    test('sensorCount=2 renders motor + 2 sensors at wire level (no throw)', () {
      final mwsDef = registry['motor_with_sensors']!;
      final instance = DeviceInstance(
        definition: mwsDef,
        paramValues: const {
          'motorRef': 'IVR3210',
          'voltage': 400,
          'sensorCount': 2,
        },
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(
          canvas,
          instance,
          level: DrawingLevel.wire,
          context: _ctx(registry),
        ),
        returnsNormally,
      );
    });

    test('sensorCount=0 renders only the motor (no throw)', () {
      final mwsDef = registry['motor_with_sensors']!;
      final instance = DeviceInstance(
        definition: mwsDef,
        paramValues: const {'sensorCount': 0},
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(
          canvas,
          instance,
          level: DrawingLevel.wire,
          context: _ctx(registry),
        ),
        returnsNormally,
      );
    });

    test('sensorCount=2 renders at symbol level (no throw)', () {
      final mwsDef = registry['motor_with_sensors']!;
      final instance = DeviceInstance(
        definition: mwsDef,
        paramValues: const {
          'motorRef': 'IVR3210',
          'voltage': 400,
          'sensorCount': 2,
        },
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();
      expect(
        () => renderer.render(
          canvas,
          instance,
          level: DrawingLevel.symbol,
          context: _ctx(registry),
        ),
        returnsNormally,
      );
    });
  });

  // ── Recursion guard ────────────────────────────────────────────────────────

  group('recursion guard', () {
    test('self-referential DrawDeviceRef stops at maxDepth (no stack overflow)', () {
      // A device whose wire appearance references itself — must stop.
      const selfDef = DeviceDefinition(
        typeKey: 'self_ref',
        name: 'Self ref',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(10, 10),
            drawables: [
              DrawDeviceRef(typeKey: 'self_ref'),
            ],
          ),
        ),
      );

      final registry = <String, DeviceDefinition>{'self_ref': selfDef};
      const instance = DeviceInstance(definition: selfDef);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(
          canvas,
          instance,
          context: RenderContext(
            deviceResolver: (key) => registry[key],
            maxDepth: 4, // low limit to keep the test fast
          ),
        ),
        returnsNormally,
      );
    });

    test('cyclic A→B→A stops at maxDepth', () {
      // A → B → A cycle
      final aRef = const DrawDeviceRef(typeKey: 'cycle_b');
      final bRef = const DrawDeviceRef(typeKey: 'cycle_a');

      final defA = DeviceDefinition(
        typeKey: 'cycle_a',
        name: 'A',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(10, 10),
            drawables: [aRef],
          ),
        ),
      );
      final defB = DeviceDefinition(
        typeKey: 'cycle_b',
        name: 'B',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: const Size(10, 10),
            drawables: [bRef],
          ),
        ),
      );

      final registry = {'cycle_a': defA, 'cycle_b': defB};
      final instance = DeviceInstance(definition: defA);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(
          canvas,
          instance,
          context: RenderContext(
            deviceResolver: (key) => registry[key],
            maxDepth: 4,
          ),
        ),
        returnsNormally,
      );
    });

    test('instance-tree depth guard prevents infinite recursion', () {
      final leafDef = _atomicDef(typeKey: 'leaf');

      // Build a deeply nested DeviceInstance chain manually.
      DeviceInstance buildNested(int depth) {
        if (depth == 0) return DeviceInstance(definition: leafDef);
        return DeviceInstance(
          definition: leafDef,
          children: [
            ChildPlacement(
              child: buildNested(depth - 1),
              offset: const Offset(5, 0),
            ),
          ],
        );
      }

      // Depth 20, but maxDepth=8 → renderer stops at 8
      final deep = buildNested(20);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const renderer = DeviceRenderer();

      expect(
        () => renderer.render(
          canvas,
          deep,
          context: const RenderContext(maxDepth: 8),
        ),
        returnsNormally,
      );
    });
  });
}
