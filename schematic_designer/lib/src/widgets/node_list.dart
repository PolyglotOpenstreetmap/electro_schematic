// lib/src/widgets/node_list.dart
//
// NodeList: left panel showing the drawable nodes in a reorderable list.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../notifier/designer_notifier.dart';

/// Left panel: reorderable list of drawable nodes with selection and delete.
class NodeList extends StatelessWidget {
  final DesignerNotifier notifier;

  const NodeList({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final state = notifier.state;
        final drawables = state.drawables;

        if (drawables.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No nodes.\nUse Add Shape to begin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return ReorderableListView.builder(
          itemCount: drawables.length,
          onReorder: notifier.reorderNodes,
          buildDefaultDragHandles: true,
          itemBuilder: (context, index) {
            final node = drawables[index];
            final isSelected = node.id == state.selectedId;
            return ListTile(
              key: ValueKey(node.id ?? index),
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: Icon(
                _iconFor(node),
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                _labelFor(node),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedTileColor:
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                tooltip: 'Remove node',
                visualDensity: VisualDensity.compact,
                onPressed: node.id != null
                    ? () => notifier.removeNode(node.id!)
                    : null,
              ),
              onTap: () => notifier.selectNode(node.id),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(DrawableNode node) {
    return switch (node) {
      DrawRect() => Icons.crop_square,
      DrawCircle() => Icons.radio_button_unchecked,
      DrawLine() => Icons.show_chart,
      DrawPolyline() => Icons.polyline,
      DrawText() => Icons.text_fields,
      DrawPath() => Icons.gesture,
      DrawCoil() => Icons.waves,
      DrawCapacitor() => Icons.battery_charging_full,
      DrawTerminalAnchor() => Icons.electric_bolt,
      DrawGroup() => Icons.folder,
      DrawRepeat() => Icons.repeat,
    };
  }

  String _labelFor(DrawableNode node) {
    final typeName = switch (node) {
      DrawRect() => 'Rect',
      DrawCircle() => 'Circle',
      DrawLine() => 'Line',
      DrawPolyline() => 'Polyline',
      DrawText() => 'Text',
      DrawPath() => 'Path',
      DrawCoil() => 'Coil',
      DrawCapacitor() => 'Cap',
      DrawTerminalAnchor() => 'Terminal',
      DrawGroup() => 'Group',
      DrawRepeat() => 'Repeat',
    };
    final idStr = node.id != null ? ' [${node.id}]' : '';
    return '$typeName$idStr';
  }
}
