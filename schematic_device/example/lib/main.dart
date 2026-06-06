// example/lib/main.dart
//
// Example app — renders a RotatingMotorDevice and a SimpleTerminalStripDevice
// side by side using DeviceRenderer.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import 'devices/rotating_motor_device.dart';
import 'devices/simple_terminal_strip_device.dart';

void main() {
  // Register all built-in drawable node serializers.
  SchematicDevicePackage.initialize();
  runApp(const ExampleApp());
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
    // ── Motor instance — connected terminals, voltage=400 (star)
    final motorDef = RotatingMotorDevice.build();
    final motorInstance = DeviceInstance(
      definition: motorDef,
      position: const Offset(40, 60),
      paramValues: const {'motorRef': 'IVR3210', 'voltage': 400},
      terminalConnected: const {
        RotatingMotorDevice.u1: true,
        RotatingMotorDevice.v1: true,
        RotatingMotorDevice.w1: true,
      },
    );

    // ── Motor instance — delta wiring (voltage < 300)
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

    // ── Terminal strip instance — 6 terminals
    final stripInstance = SimpleTerminalStripDevice.createInstance(
      count: 6,
      label: 'TB1',
      position: const Offset(290, 40),
    );

    final instances = [motorInstance, motorDelta, stripInstance];
    final labels = [
      'Star motor (400 V)',
      'Delta motor (230 V)',
      'Terminal strip (6T)',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('schematic_device — Device Gallery')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Data-driven device rendering — no hardcoded draw methods.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < instances.length; i++)
                  _DeviceCard(
                    instance: instances[i],
                    label: labels[i],
                  ),
              ],
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

  const _DeviceCard({required this.instance, required this.label});

  @override
  Widget build(BuildContext context) {
    final appearance =
        instance.definition.appearance.forLevel(DrawingLevel.wire);
    final size = appearance?.size ?? const Size(100, 100);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            instance.definition.typeKey,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.blue),
          ),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          // Render the device at its definition size + a small margin
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
              painter: _DevicePainter(instance: instance),
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
    return params.entries.map((e) => '${e.key}: ${e.value}').join('  ·  ');
  }
}

class _DevicePainter extends CustomPainter {
  final DeviceInstance instance;
  static const _renderer = DeviceRenderer();

  const _DevicePainter({required this.instance});

  @override
  void paint(Canvas canvas, Size size) {
    // Small margin offset so the device doesn't touch the border
    canvas.translate(10, 10);
    _renderer.render(
      canvas,
      instance,
      level: DrawingLevel.wire,
      context: const RenderContext(gridVoltage: 400),
    );
  }

  @override
  bool shouldRepaint(_DevicePainter old) => instance != old.instance;
}
