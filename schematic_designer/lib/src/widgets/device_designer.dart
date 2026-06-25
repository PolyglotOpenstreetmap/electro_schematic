// lib/src/widgets/device_designer.dart
//
// DeviceDesigner: assembled full-screen editor widget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifier/designer_notifier.dart';
import '../utils/node_bounds.dart';
import 'connectors_panel.dart';
import 'designer_canvas.dart';
import 'level_switcher.dart';
import 'node_list.dart';
import 'node_palette.dart';
import 'properties_panel.dart';

/// Full-screen device editor: toolbar + left node list + canvas + right
/// properties panel.
///
/// Wrap this in a [Scaffold] or plain container as needed.
class DeviceDesigner extends StatefulWidget {
  final DesignerNotifier notifier;

  const DeviceDesigner({super.key, required this.notifier});

  @override
  State<DeviceDesigner> createState() => _DeviceDesignerState();
}

class _DeviceDesignerState extends State<DeviceDesigner> {
  String? _activePaletteType;
  int _leftPanelTab = 0; // 0 = nodes, 1 = connectors

  DesignerNotifier get _notifier => widget.notifier;

  Future<void> _onCanvasTap(Offset deviceLocalPos) async {
    final paletteType = _activePaletteType;
    if (paletteType != null) {
      switch (paletteType) {
        case 'terminal':
          _notifier.addTerminalWithAnchor(deviceLocalPos);
        case 'deviceRef':
          final typeKey = await _pickDeviceRefTypeKey();
          if (typeKey != null) {
            _notifier.addDeviceRef(typeKey, deviceLocalPos);
          }
        default:
          final node = _defaultNodeForType(paletteType, deviceLocalPos);
          if (node != null) _notifier.addNode(node);
      }
      if (mounted) setState(() => _activePaletteType = null);
    } else {
      final definition = _notifier.exportDefinition();
      final hit = NodeBoundsHelper.hitTest(
          _notifier.state.drawables,
          deviceLocalPos,
          definition,
          _notifier.resolver,
          _notifier.state.activeLevel);
      _notifier.selectNode(hit?.id);
    }
  }

  Future<String?> _pickDeviceRefTypeKey() async {
    final keys = _notifier.knownTypeKeys;
    if (keys.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
        content: Text('No placeable device types — construct the '
            'DesignerNotifier with knownTypeKeys.'),
      ));
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Place device reference',
            style: TextStyle(fontSize: 14)),
        children: [
          for (final key in keys)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(key),
              child: Text(key, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  dynamic _defaultNodeForType(String type, Offset pos) {
    return switch (type) {
      'rect' => _notifier.defaultRect(pos),
      'circle' => _notifier.defaultCircle(pos),
      'line' => _notifier.defaultLine(pos),
      'text' => _notifier.defaultText(pos),
      'coil' => _notifier.defaultCoil(pos),
      'capacitor' => _notifier.defaultCapacitor(pos),
      _ => null,
    };
  }

  Widget _leftTab(String label, int index) {
    final selected = _leftPanelTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _leftPanelTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                _UndoIntent(),
            SingleActivator(LogicalKeyboardKey.keyY, control: true):
                _RedoIntent(),
            SingleActivator(LogicalKeyboardKey.keyZ,
                control: true, shift: true): _RedoIntent(),
          },
          child: Actions(
            actions: {
              _UndoIntent: CallbackAction<_UndoIntent>(
                  onInvoke: (_) => _notifier.undo()),
              _RedoIntent: CallbackAction<_RedoIntent>(
                  onInvoke: (_) => _notifier.redo()),
            },
            child: Focus(
              autofocus: true,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    setState(() => _activePaletteType = null);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toolbar
                    _DesignerToolbar(
                      notifier: _notifier,
                      activePaletteType: _activePaletteType,
                      onPaletteSelected: (type) =>
                          setState(() => _activePaletteType = type),
                    ),
                    // Main area
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left panel: nodes / connectors tabs
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 28,
                                  color: Colors.grey.shade200,
                                  child: Row(
                                    children: [
                                      _leftTab('NODES', 0),
                                      _leftTab('CONNECTORS', 1),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _leftPanelTab == 0
                                      ? NodeList(notifier: _notifier)
                                      : ConnectorsPanel(notifier: _notifier),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          // Center: canvas
                          Expanded(
                            child: Stack(
                              children: [
                                DesignerCanvas(
                                  notifier: _notifier,
                                  activePaletteType: _activePaletteType,
                                  onTap: _onCanvasTap,
                                ),
                                // Placement hint banner
                                if (_activePaletteType != null)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 48,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Click canvas to place '
                                          '$_activePaletteType — '
                                          'press Esc to cancel',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          // Right panel: properties
                          SizedBox(
                            width: 280,
                            child: PropertiesPanel(notifier: _notifier),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Toolbar ──────────────────────────────────────────────────────────────────

class _DesignerToolbar extends StatelessWidget {
  final DesignerNotifier notifier;
  final String? activePaletteType;
  final void Function(String? type) onPaletteSelected;

  const _DesignerToolbar({
    required this.notifier,
    required this.activePaletteType,
    required this.onPaletteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Device name
          ListenableBuilder(
            listenable: notifier,
            builder: (_, __) => Text(
              notifier.state.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          // Level switcher
          LevelSwitcher(notifier: notifier),
          const SizedBox(width: 8),
          // Combined / exploded badge for the active level
          ListenableBuilder(
            listenable: notifier,
            builder: (context, _) {
              final isExploded = notifier.state
                      .appearanceFor(notifier.state.activeLevel)
                      ?.deviceRefs
                      .isNotEmpty ??
                  false;
              return Tooltip(
                message: isExploded
                    ? 'This level contains device refs — it renders the '
                        'assembly exploded into its components'
                    : 'This level renders as a combined glyph',
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(
                    isExploded ? 'exploded' : 'combined',
                    style: const TextStyle(fontSize: 9),
                  ),
                  backgroundColor: isExploded
                      ? Colors.orange.shade50
                      : Colors.blueGrey.shade50,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Palette
          NodePalette(
            activePaletteType: activePaletteType,
            onSelected: onPaletteSelected,
          ),
          const Spacer(),
          // Undo
          ListenableBuilder(
            listenable: notifier,
            builder: (_, __) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: notifier.canUndo ? () => notifier.undo() : null,
            ),
          ),
          // Redo
          ListenableBuilder(
            listenable: notifier,
            builder: (_, __) => IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: notifier.canRedo ? () => notifier.redo() : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Intent classes for keyboard shortcuts ────────────────────────────────────

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
