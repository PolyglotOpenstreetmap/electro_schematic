// example/lib/main.dart
//
// Motor-type gallery: demonstrates all three DSL DeviceDefinition variants:
//   • Rotating motor  (standard 3-phase, star/delta terminal block)
//   • Linear motor    (IV7xxx, 6 numbered terminals, zigzag coils)
//   • DeCoster motor  (IV21xxx, 3 terminals U/V/W, internally connected)
//
// Left 60%: live DeviceDesigner for the selected motor type.
// Right 40%: side-by-side wire + symbol level previews and JSON export.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schematic_designer/schematic_designer.dart';
import 'package:schematic_device/schematic_device.dart';

import 'devices/motor_devices.dart';

void main() {
  SchematicDevicePackage.initialize();
  runApp(const DesignerExampleApp());
}

class DesignerExampleApp extends StatelessWidget {
  const DesignerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Device Designer',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _DesignerHomePage(),
    );
  }
}

// ─── Motor type selector ──────────────────────────────────────────────────────

enum _MotorPreset {
  rotating('Rotating', Icons.rotate_right),
  linear('Linear', Icons.linear_scale),
  decoster('DeCoster', Icons.electrical_services);

  final String label;
  final IconData icon;
  const _MotorPreset(this.label, this.icon);
}

DeviceDefinition _buildDef(_MotorPreset preset) => switch (preset) {
      _MotorPreset.rotating => rotatingMotorDef(),
      _MotorPreset.linear => linearMotorDef(),
      _MotorPreset.decoster => deCosterMotorDef(),
    };

// ─── Home page ────────────────────────────────────────────────────────────────

class _DesignerHomePage extends StatefulWidget {
  const _DesignerHomePage();

  @override
  State<_DesignerHomePage> createState() => _DesignerHomePageState();
}

class _DesignerHomePageState extends State<_DesignerHomePage> {
  _MotorPreset _preset = _MotorPreset.rotating;
  late DesignerNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = _makeNotifier(_preset);
  }

  DesignerNotifier _makeNotifier(_MotorPreset preset) {
    final def = _buildDef(preset);
    // Start at the wire level so the terminal-block view is immediately visible.
    final state = DesignerState.fromDefinition(def,
        initialLevel: DrawingLevel.wire);
    return DesignerNotifier(state);
  }

  void _selectPreset(_MotorPreset preset) {
    if (preset == _preset) return;
    final old = _notifier;
    setState(() {
      _preset = preset;
      _notifier = _makeNotifier(preset);
    });
    old.dispose();
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
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        title: const Text('Motor Device Designer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _MotorPicker(
              selected: _preset,
              onSelect: _selectPreset,
            ),
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left 60%: full device designer
          Expanded(
            flex: 6,
            child: DeviceDesigner(notifier: _notifier),
          ),
          const VerticalDivider(width: 1),
          // Right 40%: live preview for both levels + JSON export
          Expanded(
            flex: 4,
            child: _PreviewPane(notifier: _notifier, preset: _preset),
          ),
        ],
      ),
    );
  }
}

// ─── Motor type picker ────────────────────────────────────────────────────────

class _MotorPicker extends StatelessWidget {
  final _MotorPreset selected;
  final void Function(_MotorPreset) onSelect;

  const _MotorPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_MotorPreset>(
      segments: _MotorPreset.values
          .map((p) => ButtonSegment<_MotorPreset>(
                value: p,
                label: Text(p.label,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                icon: Icon(p.icon, size: 16, color: Colors.white70),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (s) => onSelect(s.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.indigo.shade400;
          }
          return Colors.indigo.shade800;
        }),
        side: WidgetStateProperty.all(
            BorderSide(color: Colors.indigo.shade300, width: 1)),
      ),
    );
  }
}

// ─── Preview pane ─────────────────────────────────────────────────────────────

class _PreviewPane extends StatefulWidget {
  final DesignerNotifier notifier;
  final _MotorPreset preset;

  const _PreviewPane({required this.notifier, required this.preset});

  @override
  State<_PreviewPane> createState() => _PreviewPaneState();
}

class _PreviewPaneState extends State<_PreviewPane> {
  String? _exportedJson;
  bool _showJson = false;
  DeviceDefinition? _jsonDef;

  void _exportJson() {
    final json = widget.notifier.exportJson();
    final def =
        DeviceDefinition.fromJson(jsonDecode(json) as Map<String, dynamic>);
    setState(() {
      _exportedJson = json;
      _jsonDef = def;
      _showJson = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          height: 44,
          color: Colors.indigo.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                '${widget.preset.label} — Preview',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _exportJson,
                icon: const Icon(Icons.download, size: 15, color: Colors.white70),
                label: const Text('Export JSON',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
              if (_exportedJson != null)
                Switch(
                  value: _showJson,
                  onChanged: (v) => setState(() => _showJson = v),
                  activeThumbColor: Colors.lightBlueAccent,
                ),
            ],
          ),
        ),

        // Live wire + symbol previews
        ListenableBuilder(
          listenable: widget.notifier,
          builder: (_, __) {
            final def = widget.notifier.exportDefinition();
            return Padding(
              padding: const EdgeInsets.all(12),
              child: _LevelPreviewRow(definition: def),
            );
          },
        ),

        const Divider(height: 1),

        // JSON output area
        if (_exportedJson != null && _showJson)
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
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      if (_jsonDef != null)
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
                if (_jsonDef != null) ...[
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
                        const SizedBox(height: 8),
                        _LevelPreviewRow(definition: _jsonDef!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        else if (_exportedJson == null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Press "Export JSON" to see the DSL round-trip.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }
}

// ─── Wire + symbol side-by-side preview ───────────────────────────────────────

class _LevelPreviewRow extends StatelessWidget {
  final DeviceDefinition definition;
  const _LevelPreviewRow({required this.definition});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LabelledPreview(
            label: 'Wire level',
            level: DrawingLevel.wire,
            definition: definition,
            zoom: 3.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LabelledPreview(
            label: 'Symbol level',
            level: DrawingLevel.symbol,
            definition: definition,
            zoom: 3.0,
          ),
        ),
      ],
    );
  }
}

class _LabelledPreview extends StatelessWidget {
  final String label;
  final DrawingLevel level;
  final DeviceDefinition definition;
  final double zoom;

  const _LabelledPreview({
    required this.label,
    required this.level,
    required this.definition,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = definition.appearance.forLevel(level);
    if (appearance == null) {
      return Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text('—', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    final deviceSize = appearance.size;
    final widgetW = deviceSize.width * zoom;
    final widgetH = deviceSize.height * zoom;

    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
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
                level: level,
                zoom: zoom,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Canvas painter for a specific level ─────────────────────────────────────

class _PreviewPainter extends CustomPainter {
  final DeviceDefinition definition;
  final DrawingLevel level;
  final double zoom;

  const _PreviewPainter({
    required this.definition,
    required this.level,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(zoom);
    const renderer = DeviceRenderer();
    final instance = DeviceInstance(
      definition: definition,
      position: Offset.zero,
      paramValues: definition.defaultParams,
    );
    renderer.render(canvas, instance, level: level);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.definition != definition || old.level != level || old.zoom != zoom;
}
