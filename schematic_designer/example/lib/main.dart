// example/lib/main.dart
//
// End-to-end demonstration:
//   1. Design a SimpleRelay device in the DeviceDesigner widget.
//   2. Export to JSON.
//   3. Load the JSON back into a DeviceDefinition.
//   4. Render it with DeviceRenderer.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schematic_designer/schematic_designer.dart';
import 'package:schematic_device/schematic_device.dart';

void main() {
  SchematicDevicePackage.initialize();
  runApp(const DesignerExampleApp());
}

class DesignerExampleApp extends StatelessWidget {
  const DesignerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Designer Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _DesignerHomePage(),
    );
  }
}

// ─── Home page ────────────────────────────────────────────────────────────────

class _DesignerHomePage extends StatefulWidget {
  const _DesignerHomePage();

  @override
  State<_DesignerHomePage> createState() => _DesignerHomePageState();
}

class _DesignerHomePageState extends State<_DesignerHomePage> {
  late final DesignerNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = DesignerNotifier(_buildSimpleRelay());
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schematic Designer — SimpleRelay example'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left 60%: designer
          Expanded(
            flex: 6,
            child: DeviceDesigner(notifier: _notifier),
          ),
          const VerticalDivider(width: 1),
          // Right 40%: preview
          Expanded(
            flex: 4,
            child: _PreviewPane(notifier: _notifier),
          ),
        ],
      ),
    );
  }
}

// ─── Pre-populated SimpleRelay device ────────────────────────────────────────

DesignerState _buildSimpleRelay() {
  return const DesignerState(
    typeKey: 'simple_relay',
    deviceName: 'Simple Relay (K)',
    canvasSize: Size(70, 60),
    drawables: [
      // Body
      DrawRect(
        id: 'body',
        rect: Rect.fromLTWH(0, 0, 70, 60),
        cornerRadius: 2,
        fillColor: Color(0xFFF5F5F5),
        strokeColor: Color(0xDD000000),
        strokeWidth: 1.5,
      ),
      // Left contact terminal line
      DrawLine(
        id: 'lterm',
        start: Offset(10, 0),
        end: Offset(10, 18),
        color: Color(0xDD000000),
        strokeWidth: 2,
      ),
      // Right contact terminal line
      DrawLine(
        id: 'rterm',
        start: Offset(60, 0),
        end: Offset(60, 18),
        color: Color(0xDD000000),
        strokeWidth: 2,
      ),
      // Contact gap left part
      DrawLine(
        id: 'gap_l',
        start: Offset(10, 22),
        end: Offset(32, 22),
        color: Color(0xDD000000),
        strokeWidth: 2,
      ),
      // Contact gap right part
      DrawLine(
        id: 'gap_r',
        start: Offset(38, 22),
        end: Offset(60, 22),
        color: Color(0xDD000000),
        strokeWidth: 2,
      ),
      // Coil inner rectangle
      DrawRect(
        id: 'coil_body',
        rect: Rect.fromLTWH(18, 28, 34, 18),
        fillColor: Color(0xFFFFFFFF),
        strokeColor: Color(0xDD000000),
        strokeWidth: 1,
      ),
      // Coil winding
      DrawCoil(
        id: 'coil',
        start: Offset(18, 37),
        end: Offset(52, 37),
        color: Color(0xDD000000),
        strokeWidth: 1.5,
        arcCount: 5,
      ),
      // Coil terminal left
      DrawLine(
        id: 'coil_term_l',
        start: Offset(18, 37),
        end: Offset(10, 37),
        color: Color(0xDD000000),
        strokeWidth: 1.5,
      ),
      // Coil terminal right
      DrawLine(
        id: 'coil_term_r',
        start: Offset(52, 37),
        end: Offset(60, 37),
        color: Color(0xDD000000),
        strokeWidth: 1.5,
      ),
      // Label
      DrawText(
        id: 'label',
        text: 'K1',
        position: Offset(35, 57),
        anchor: TextAnchor.bottomCenter,
        fontSize: 10,
        bold: true,
        color: Color(0xDD000000),
      ),
    ],
  );
}

// ─── Preview pane ─────────────────────────────────────────────────────────────

class _PreviewPane extends StatefulWidget {
  final DesignerNotifier notifier;

  const _PreviewPane({required this.notifier});

  @override
  State<_PreviewPane> createState() => _PreviewPaneState();
}

class _PreviewPaneState extends State<_PreviewPane> {
  String? _exportedJson;
  bool _renderFromJson = false;
  DeviceDefinition? _jsonLoadedDef;

  void _exportJson() {
    final json = widget.notifier.exportJson();
    final def =
        DeviceDefinition.fromJson(jsonDecode(json) as Map<String, dynamic>);
    setState(() {
      _exportedJson = json;
      _jsonLoadedDef = def;
      _renderFromJson = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          height: 48,
          color: Colors.indigo.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('Preview',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              TextButton.icon(
                onPressed: _exportJson,
                icon: const Icon(Icons.download, size: 16,
                    color: Colors.white70),
                label: const Text('Export JSON',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              if (_exportedJson != null)
                Switch(
                  value: _renderFromJson,
                  onChanged: (v) => setState(() => _renderFromJson = v),
                  activeThumbColor: Colors.lightBlueAccent,
                ),
            ],
          ),
        ),

        // Live preview
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text('Live preview',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ListenableBuilder(
                listenable: widget.notifier,
                builder: (_, __) => _DevicePreview(
                  definition: widget.notifier.exportDefinition(),
                ),
              ),
            ],
          ),
        ),

        // JSON output + JSON-loaded render
        if (_exportedJson != null) ...[
          const Divider(height: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Exported JSON',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      if (_renderFromJson)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text('(loaded & re-rendered below)',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.blueGrey)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SelectableText(
                      _exportedJson!,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ),
                if (_renderFromJson && _jsonLoadedDef != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text('Rendered from JSON',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _DevicePreview(definition: _jsonLoadedDef!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Device preview widget ────────────────────────────────────────────────────

class _DevicePreview extends StatelessWidget {
  final DeviceDefinition definition;

  const _DevicePreview({required this.definition});

  @override
  Widget build(BuildContext context) {
    final appearance = definition.appearance.wire;
    final deviceSize =
        appearance?.size ?? const Size(80, 60);
    const zoom = 3.0;

    final widgetW = deviceSize.width * zoom;
    final widgetH = deviceSize.height * zoom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      width: widgetW + 16,
      height: widgetH + 16,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CustomPaint(
          size: Size(widgetW, widgetH),
          painter: _PreviewPainter(
            definition: definition,
            zoom: zoom,
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final DeviceDefinition definition;
  final double zoom;

  const _PreviewPainter({required this.definition, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(zoom);
    const renderer = DeviceRenderer();
    final instance = DeviceInstance(definition: definition);
    renderer.render(canvas, instance, level: DrawingLevel.wire);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.definition != definition || old.zoom != zoom;
}
