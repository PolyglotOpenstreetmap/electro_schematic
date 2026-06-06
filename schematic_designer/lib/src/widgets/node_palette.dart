// lib/src/widgets/node_palette.dart
//
// NodePalette: popup button for choosing a node type to place.

import 'package:flutter/material.dart';

/// Toolbar widget that lets the user pick a node type to add to the canvas.
///
/// [activePaletteType] is the currently pending type string, or null.
/// [onSelected] is called with the type string when a type is chosen, or
/// null when the active type is deselected.
class NodePalette extends StatelessWidget {
  final String? activePaletteType;
  final void Function(String? type) onSelected;

  const NodePalette({
    super.key,
    required this.activePaletteType,
    required this.onSelected,
  });

  static const _items = [
    ('rect', 'Rect', Icons.crop_square),
    ('circle', 'Circle', Icons.radio_button_unchecked),
    ('line', 'Line', Icons.show_chart),
    ('text', 'Text', Icons.text_fields),
    ('coil', 'Coil', Icons.waves),
    ('capacitor', 'Capacitor', Icons.battery_charging_full),
  ];

  @override
  Widget build(BuildContext context) {
    final isActive = activePaletteType != null;

    return PopupMenuButton<String>(
      tooltip: 'Add shape',
      onSelected: (type) {
        // Toggle off if already active.
        if (type == activePaletteType) {
          onSelected(null);
        } else {
          onSelected(type);
        }
      },
      itemBuilder: (context) => _items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.$1,
              child: Row(
                children: [
                  Icon(item.$3, size: 18),
                  const SizedBox(width: 8),
                  Text(item.$2),
                  if (item.$1 == activePaletteType) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: TextButton.icon(
        onPressed: null, // handled by PopupMenuButton
        icon: Icon(
          Icons.add,
          size: 16,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        label: Text(
          isActive ? 'Placing: $activePaletteType ▾' : 'Add Shape ▾',
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
