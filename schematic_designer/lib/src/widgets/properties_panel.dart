// lib/src/widgets/properties_panel.dart
//
// PropertiesPanel: right panel with JSON editor for the selected node and
// device meta settings.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../notifier/designer_notifier.dart';

/// Right panel: properties editor for selected node + device meta settings.
class PropertiesPanel extends StatefulWidget {
  final DesignerNotifier notifier;

  const PropertiesPanel({super.key, required this.notifier});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final state = widget.notifier.state;
        final node = state.selectedNode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              height: 32,
              color: Colors.grey.shade200,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text(
                'PROPERTIES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
            // Device meta settings
            _DeviceMetaEditor(notifier: widget.notifier),
            const Divider(height: 1),
            // Node editor
            if (node == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Select a node to edit',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: _NodeEditor(
                  key: ValueKey(node.id),
                  node: node,
                  notifier: widget.notifier,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Device meta editor ───────────────────────────────────────────────────────

class _DeviceMetaEditor extends StatefulWidget {
  final DesignerNotifier notifier;
  const _DeviceMetaEditor({required this.notifier});

  @override
  State<_DeviceMetaEditor> createState() => _DeviceMetaEditorState();
}

class _DeviceMetaEditorState extends State<_DeviceMetaEditor> {
  late TextEditingController _typeKeyCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    _syncFromState();
  }

  void _syncFromState() {
    final s = widget.notifier.state;
    _typeKeyCtrl = TextEditingController(text: s.typeKey);
    _nameCtrl = TextEditingController(text: s.deviceName);
    _widthCtrl =
        TextEditingController(text: s.canvasSize.width.toStringAsFixed(1));
    _heightCtrl =
        TextEditingController(text: s.canvasSize.height.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _typeKeyCtrl.dispose();
    _nameCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final w = double.tryParse(_widthCtrl.text) ?? widget.notifier.state.canvasSize.width;
    final h = double.tryParse(_heightCtrl.text) ??
        widget.notifier.state.canvasSize.height;
    widget.notifier.updateDeviceMeta(
      typeKey: _typeKeyCtrl.text,
      deviceName: _nameCtrl.text,
      canvasSize: Size(w, h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Device Settings',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _buildField('Type Key', _typeKeyCtrl),
        const SizedBox(height: 4),
        _buildField('Name', _nameCtrl),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildField('Width', _widthCtrl)),
            const SizedBox(width: 4),
            Expanded(child: _buildField('Height', _heightCtrl)),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              minimumSize: const Size(60, 28),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Apply'),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 11),
    );
  }
}

// ─── Node JSON editor ─────────────────────────────────────────────────────────

class _NodeEditor extends StatefulWidget {
  final DrawableNode node;
  final DesignerNotifier notifier;

  const _NodeEditor({super.key, required this.node, required this.notifier});

  @override
  State<_NodeEditor> createState() => _NodeEditorState();
}

class _NodeEditorState extends State<_NodeEditor> {
  late TextEditingController _ctrl;

  String _prettyJson(DrawableNode node) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(node.toJson());
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _prettyJson(widget.node));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      final map = jsonDecode(_ctrl.text) as Map<String, dynamic>;
      final parsed = DrawableNodeFactory.fromJson(map);
      widget.notifier.updateNode(parsed);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid JSON: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _revert() {
    _ctrl.text = _prettyJson(widget.node);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final typeName = node.runtimeType.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Type chip + id
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(typeName,
                    style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              if (node.id != null)
                Chip(
                  label: Text('id: ${node.id}',
                      style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        // JSON editor
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(6),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        // Buttons
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _revert,
                style: TextButton.styleFrom(
                  minimumSize: const Size(60, 28),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Revert'),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(60, 28),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
