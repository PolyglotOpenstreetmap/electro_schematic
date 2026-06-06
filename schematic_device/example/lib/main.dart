// example/lib/main.dart
//
// Example app — device gallery showing atomic and composite devices at
// wire and symbol levels using DeviceRenderer.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import 'devices/motor_with_sensors_device.dart';
import 'devices/rotating_motor_device.dart';
import 'devices/sensor_device.dart';
import 'devices/simple_terminal_strip_device.dart';
import 'devices/three_phase_motor_symbol.dart';

void main() {
  SchematicDevicePackage.initialize();
  runApp(const ExampleApp());
}

/// Builds the device registry used by DrawDeviceRef resolution.
Map<String, DeviceDefinition> _buildRegistry() {
  final motorDef = RotatingMotorDevice.build();
  final sensorDef = SensorDevice.build();
  final motorSymbolDef = ThreePhaseMotorSymbol.build();
  final motorWithSensorsDef = MotorWithSensorsDevice.build();
  return {
    motorDef.typeKey: motorDef,
    sensorDef.typeKey: sensorDef,
    motorSymbolDef.typeKey: motorSymbolDef,
    motorWithSensorsDef.typeKey: motorWithSensorsDef,
  };
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'schematic_device Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const DeviceGalleryPage(),
    );
  }
}

class DeviceGalleryPage extends StatelessWidget {
  const DeviceGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = _buildRegistry();
    DeviceDefinition? resolver(String key) => registry[key];

    // ── Atomic: star motor (wire level, 400 V)
    final motorDef = RotatingMotorDevice.build();
    final motorStar = DeviceInstance(
      definition: motorDef,
      position: const Offset(40, 60),
      paramValues: const {'motorRef': 'IVR3210', 'voltage': 400},
      terminalConnected: const {
        RotatingMotorDevice.u1: true,
        RotatingMotorDevice.v1: true,
        RotatingMotorDevice.w1: true,
      },
    );

    // ── Atomic: delta motor (wire level, 230 V)
    final motorDelta = DeviceInstance(
      definition: motorDef,
      position: const Offset(160, 60),
      paramValues: const {'motorRef': 'IVR3210-D', 'voltage': 230},
      terminalConnected: const {
        RotatingMotorDevice.u1: true,
        RotatingMotorDevice.v1: true,
        RotatingMotorDevice.w1: true,
      },
    );

    // ── Atomic: motor at symbol level (star, 400 V)
    final motorSymStar = DeviceInstance(
      definition: motorDef,
      position: Offset.zero,
      paramValues: const {'motorRef': 'IVR3210', 'voltage': 400},
    );

    // ── Atomic: motor at symbol level (delta, 230 V)
    final motorSymDelta = DeviceInstance(
      definition: motorDef,
      position: Offset.zero,
      paramValues: const {'motorRef': 'IVR3210-D', 'voltage': 230},
    );

    // ── Atomic: capacitor motor at symbol level
    final motorSymCap = DeviceInstance(
      definition: motorDef,
      position: Offset.zero,
      paramValues: const {'motorRef': 'IV21-something', 'voltage': 230},
    );

    // ── Atomic: sensor (wire level)
    final sensorDef = SensorDevice.build();
    final sensorWire = DeviceInstance(
      definition: sensorDef,
      position: Offset.zero,
      paramValues: const {'sensorRef': 'DET-01'},
    );

    // ── Atomic: sensor (symbol level)
    final sensorSym = DeviceInstance(
      definition: sensorDef,
      position: Offset.zero,
      paramValues: const {'sensorRef': 'DET-01'},
    );

    // ── Composite: motor + 2 sensors (wire level)
    final mwsDef = MotorWithSensorsDevice.build();
    final mwsWire = DeviceInstance(
      definition: mwsDef,
      position: Offset.zero,
      paramValues: const {
        'motorRef': 'IVR3210',
        'voltage': 400,
        'sensorCount': 2,
        'hasBrake': false,
      },
    );

    // ── Composite: motor + 2 sensors (symbol level)
    final mwsSym = DeviceInstance(
      definition: mwsDef,
      position: Offset.zero,
      paramValues: const {
        'motorRef': 'IVR3210-D',
        'voltage': 230,
        'sensorCount': 2,
        'hasBrake': false,
      },
    );

    // ── Old-style motor symbol device (kept for backwards compat display)
    final motorSymbolDef = ThreePhaseMotorSymbol.build();
    final motorSymbolOld = DeviceInstance(
      definition: motorSymbolDef,
      position: Offset.zero,
      paramValues: const {'ref': 'M1'},
    );

    // ── Terminal strip
    final stripInstance = SimpleTerminalStripDevice.createInstance(
      count: 6,
      label: 'TB1',
      position: Offset.zero,
    );

    final items = <({DeviceInstance inst, String label, DrawingLevel level})>[
      (inst: motorStar, label: 'Star motor 400V\n(wire)', level: DrawingLevel.wire),
      (inst: motorDelta, label: 'Delta motor 230V\n(wire)', level: DrawingLevel.wire),
      (inst: motorSymStar, label: 'Motor symbol\nstar (symbol)', level: DrawingLevel.symbol),
      (inst: motorSymDelta, label: 'Motor symbol\ndelta (symbol)', level: DrawingLevel.symbol),
      (inst: motorSymCap, label: 'Capacitor motor\n(symbol)', level: DrawingLevel.symbol),
      (inst: sensorWire, label: 'Sensor\n(wire)', level: DrawingLevel.wire),
      (inst: sensorSym, label: 'Sensor\n(symbol)', level: DrawingLevel.symbol),
      (inst: mwsWire, label: 'Motor+2 sensors\n(wire)', level: DrawingLevel.wire),
      (inst: mwsSym, label: 'Motor+2 sensors\n(symbol)', level: DrawingLevel.symbol),
      (inst: motorSymbolOld, label: 'Legacy motor symbol\n(wire)', level: DrawingLevel.wire),
      (inst: stripInstance, label: 'Terminal strip 6T\n(wire)', level: DrawingLevel.wire),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('schematic_device — Device Gallery')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Data-driven device rendering — atomic and composite, wire and symbol levels.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    _DeviceCard(
                      instance: item.inst,
                      label: item.label,
                      level: item.level,
                      resolver: resolver,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceInstance instance;
  final String label;
  final DrawingLevel level;
  final DeviceDefinition? Function(String)? resolver;

  const _DeviceCard({
    required this.instance,
    required this.label,
    this.level = DrawingLevel.wire,
    this.resolver,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = instance.definition.appearance.forLevel(level);
    final size = appearance?.size ?? const Size(100, 100);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${instance.definition.typeKey} · ${level.name}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.blue),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            width: size.width + 20,
            height: size.height + 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: CustomPaint(
              size: Size(size.width + 20, size.height + 20),
              painter: _DevicePainter(
                instance: instance,
                level: level,
                resolver: resolver,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _paramSummary(instance),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _paramSummary(DeviceInstance inst) {
    final params = {...inst.definition.defaultParams, ...inst.paramValues};
    return params.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('  ·  ');
  }
}

class _DevicePainter extends CustomPainter {
  final DeviceInstance instance;
  final DrawingLevel level;
  final DeviceDefinition? Function(String)? resolver;
  static const _renderer = DeviceRenderer();

  const _DevicePainter({
    required this.instance,
    required this.level,
    this.resolver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(10, 10);
    _renderer.render(
      canvas,
      instance,
      level: level,
      context: RenderContext(
        gridVoltage: 400,
        deviceResolver: resolver,
      ),
    );
  }

  @override
  bool shouldRepaint(_DevicePainter old) =>
      instance != old.instance || level != old.level;
}
