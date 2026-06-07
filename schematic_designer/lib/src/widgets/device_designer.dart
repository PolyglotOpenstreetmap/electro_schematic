// lib/src/widgets/device_designer.dart
//
// DeviceDesigner: assembled full-screen editor widget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifier/designer_notifier.dart';
import '../utils/node_bounds.dart';
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

  DesignerNotifier get _notifier => widget.notifier;

  void _onCanvasTap(Offset deviceLocalPos) {
    if (_activePaletteType != null) {
      final node = _defaultNodeForType(_activePaletteType!, deviceLocalPos);
      if (node != null) _notifier.addNode(node);
      setState(() => _activePaletteType = null);
    } else {
      final definition = _notifier.exportDefinition();
      final hit = NodeBoundsHelper.hitTest(
          _notifier.state.drawables, deviceLocalPos, definition);
      _notifier.selectNode(hit?.id);
    }
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
                          // Left panel: node list
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 28,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: const Text(
                                    'NODES',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1),
                                  ),
                                ),
                                Expanded(child: NodeList(notifier: _notifier)),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          // Level switcher
          LevelSwitcher(notifier: notifier),
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
              onPressed:
                  notifier.canUndo ? () => notifier.undo() : null,
            ),
          ),
          // Redo
          ListenableBuilder(
            listenable: notifier,
            builder: (_, __) => IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed:
                  notifier.canRedo ? () => notifier.redo() : null,
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
