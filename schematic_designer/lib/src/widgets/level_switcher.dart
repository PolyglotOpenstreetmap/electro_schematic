// lib/src/widgets/level_switcher.dart
//
// LevelSwitcher: compact toolbar control for switching drawing levels.
//
// Populated levels render as filled/outlined chips; unpopulated show a "+"
// affordance that adds the level on tap.  Long-press on a populated level
// offers copy-from and remove via a context menu.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../notifier/designer_notifier.dart';

const _ordered = [
  DrawingLevel.symbol,
  DrawingLevel.wire,
  DrawingLevel.cable,
  DrawingLevel.topology,
];

const _names = {
  DrawingLevel.symbol: 'Symbol',
  DrawingLevel.wire: 'Wire',
  DrawingLevel.cable: 'Cable',
  DrawingLevel.topology: 'Topology',
};

/// A row of level-selection chips placed in the designer toolbar.
///
/// Populated levels are solid/outlined; unpopulated levels show a "+" and
/// are added automatically when tapped.  Long-pressing a populated level
/// opens a context menu with copy-from and remove actions.
class LevelSwitcher extends StatelessWidget {
  final DesignerNotifier notifier;

  const LevelSwitcher({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (_, __) {
        final state = notifier.state;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in _ordered)
              _LevelChip(
                notifier: notifier,
                level: level,
                isActive: state.activeLevel == level,
                isPopulated: state.appearances.containsKey(level),
              ),
          ],
        );
      },
    );
  }
}

class _LevelChip extends StatelessWidget {
  final DesignerNotifier notifier;
  final DrawingLevel level;
  final bool isActive;
  final bool isPopulated;

  const _LevelChip({
    required this.notifier,
    required this.level,
    required this.isActive,
    required this.isPopulated,
  });

  void _onTap() {
    if (isPopulated) {
      notifier.setActiveLevel(level);
    } else {
      notifier.addLevel(level);
      notifier.setActiveLevel(level);
    }
  }

  void _onLongPress(BuildContext context, Offset globalPos) {
    if (!isPopulated) return;
    final state = notifier.state;

    final copyItems = <PopupMenuEntry<String>>[];
    for (final l in _ordered) {
      if (l != level && state.appearances.containsKey(l)) {
        copyItems.add(PopupMenuItem(
          value: 'copy_${l.name}',
          child: Text('Copy from ${_names[l]}'),
        ));
      }
    }

    final removeItem = state.appearances.length > 1
        ? <PopupMenuEntry<String>>[
            if (copyItems.isNotEmpty) const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove level'),
            ),
          ]
        : <PopupMenuEntry<String>>[];

    final items = [...copyItems, ...removeItem];
    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          globalPos.dx, globalPos.dy, globalPos.dx + 1, globalPos.dy + 1),
      items: items,
    ).then((value) {
      if (value == null) return;
      if (value == 'remove') {
        notifier.removeLevel(level);
      } else if (value.startsWith('copy_')) {
        final fromName = value.substring('copy_'.length);
        final from = DrawingLevel.values.byName(fromName);
        notifier.copyLevel(from, level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    if (isActive && isPopulated) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isPopulated) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface;
    } else {
      bg = Colors.transparent;
      fg = cs.onSurface.withValues(alpha: 0.45);
    }

    return GestureDetector(
      onLongPressStart: (d) => _onLongPress(context, d.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: isPopulated
                ? Text(
                    _names[level]!,
                    style: TextStyle(
                      fontSize: 11,
                      color: fg,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _names[level]!,
                        style: TextStyle(fontSize: 11, color: fg),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.add, size: 10, color: fg),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
