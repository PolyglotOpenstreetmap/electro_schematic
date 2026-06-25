// lib/src/widgets/connectors_panel.dart
//
// ConnectorsPanel: tree editor for ConnectorDef → TerminalDef, including
// per-level anchor overrides and composite delegation (TerminalDelegate).

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../notifier/designer_notifier.dart';

/// Left-side panel that edits the device's connectors and terminals.
///
/// Selecting a terminal selects its bound [DrawTerminalAnchor] on the canvas
/// (when one exists on the active level). The "Delegates to" editor needs the
/// notifier's resolver to list the referenced child's terminals.
class ConnectorsPanel extends StatelessWidget {
  final DesignerNotifier notifier;

  const ConnectorsPanel({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final state = notifier.state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (final connector in state.connectors)
                    _ConnectorTile(notifier: notifier, connector: connector),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label:
                    const Text('Add connector', style: TextStyle(fontSize: 11)),
                onPressed: () => _addConnector(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addConnector() {
    final existing = notifier.state.connectors.map((c) => c.id).toSet();
    var n = 1;
    while (existing.contains('c$n')) {
      n++;
    }
    notifier.addConnector(ConnectorDef(
      id: 'c$n',
      name: 'Connector $n',
      placement: ConnectorPlacement.left,
      terminals: const [],
    ));
  }
}

// ─── Connector tile ───────────────────────────────────────────────────────────

class _ConnectorTile extends StatelessWidget {
  final DesignerNotifier notifier;
  final ConnectorDef connector;

  const _ConnectorTile({required this.notifier, required this.connector});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey('connector_${connector.id}'),
      initiallyExpanded: true,
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.only(left: 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${connector.name} (${connector.placement.name})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 15),
            tooltip: 'Add terminal',
            visualDensity: VisualDensity.compact,
            onPressed: () => _addTerminal(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 15),
            tooltip: 'Delete connector',
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.removeConnector(connector.id),
          ),
        ],
      ),
      children: [
        for (final terminal in connector.terminals)
          _TerminalEditor(
            key: ValueKey('term_${connector.id}_${terminal.id}'),
            notifier: notifier,
            connector: connector,
            terminal: terminal,
          ),
      ],
    );
  }

  void _addTerminal() {
    final existing = {
      for (final c in notifier.state.connectors) ...c.terminals.map((t) => t.id)
    };
    var n = 1;
    while (existing.contains('t$n')) {
      n++;
    }
    notifier.addTerminal(
      connector.id,
      TerminalDef(
        id: 't$n',
        label: 'T$n',
        group: ElectricalGroup.power,
        anchorInConnector: Offset.zero,
      ),
    );
  }
}

// ─── Terminal editor ──────────────────────────────────────────────────────────

class _TerminalEditor extends StatelessWidget {
  final DesignerNotifier notifier;
  final ConnectorDef connector;
  final TerminalDef terminal;

  const _TerminalEditor({
    super.key,
    required this.notifier,
    required this.connector,
    required this.terminal,
  });

  DrawingLevel get _activeLevel => notifier.state.activeLevel;

  bool get _hasLevelOverride => terminal.levelAnchors.containsKey(_activeLevel);

  /// The DrawTerminalAnchor on the active level bound to this terminal, if any.
  String? _boundAnchorNodeId() {
    for (final d in notifier.state.drawables) {
      if (d is DrawTerminalAnchor && d.terminalDefId == terminal.id) {
        return d.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = notifier.state.selectedId != null &&
        notifier.state.selectedId == _boundAnchorNodeId();

    return ExpansionTile(
      key: PageStorageKey('terminal_${connector.id}_${terminal.id}'),
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
      leading: Icon(
        terminal.delegate != null ? Icons.call_made : Icons.adjust,
        size: 14,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        '${terminal.id} — ${terminal.label}'
        '${terminal.delegate != null ? ' → ${terminal.delegate!.refId}.${terminal.delegate!.terminalId}' : ''}',
        style: TextStyle(
          fontSize: 10,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onExpansionChanged: (expanded) {
        if (expanded) {
          final nodeId = _boundAnchorNodeId();
          if (nodeId != null) notifier.selectNode(nodeId);
        }
      },
      children: [
        // Label + group + jumper
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('label_${terminal.id}_${terminal.label}'),
                initialValue: terminal.label,
                decoration:
                    const InputDecoration(labelText: 'Label', isDense: true),
                style: const TextStyle(fontSize: 11),
                onFieldSubmitted: (v) => notifier.updateTerminal(
                  connector.id,
                  _copy(label: v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<ElectricalGroup>(
              value: terminal.group,
              isDense: true,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              items: [
                for (final g in ElectricalGroup.values)
                  DropdownMenuItem(value: g, child: Text(g.name)),
              ],
              onChanged: (g) {
                if (g != null) {
                  notifier.updateTerminal(connector.id, _copy(group: g));
                }
              },
            ),
          ],
        ),
        // Anchor editor with per-level override toggle.
        Row(
          children: [
            Expanded(child: _anchorField(context, isX: true)),
            const SizedBox(width: 6),
            Expanded(child: _anchorField(context, isX: false)),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _hasLevelOverride,
              visualDensity: VisualDensity.compact,
              onChanged: (v) {
                if (v == true) {
                  notifier.setTerminalLevelAnchor(connector.id, terminal.id,
                      _activeLevel, terminal.anchorForLevel(_activeLevel));
                } else {
                  notifier.setTerminalLevelAnchor(
                      connector.id, terminal.id, _activeLevel, null);
                }
              },
            ),
            Expanded(
              child: Text(
                'Override anchor for ${_activeLevel.name}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        _DelegateEditor(
            notifier: notifier, connector: connector, terminal: terminal),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text('Delete', style: TextStyle(fontSize: 10)),
            onPressed: () => notifier.removeTerminal(connector.id, terminal.id),
          ),
        ),
      ],
    );
  }

  Widget _anchorField(BuildContext context, {required bool isX}) {
    final anchor = terminal.anchorForLevel(_activeLevel);
    final value = isX ? anchor.dx : anchor.dy;
    return TextFormField(
      key: ValueKey(
          'anchor_${terminal.id}_${_activeLevel.name}_${isX ? 'x' : 'y'}_$value'),
      initialValue: value.toStringAsFixed(1),
      decoration: InputDecoration(
        labelText: isX ? 'Anchor X' : 'Anchor Y',
        isDense: true,
      ),
      style: const TextStyle(fontSize: 11),
      keyboardType: TextInputType.number,
      onFieldSubmitted: (v) {
        final parsed = double.tryParse(v);
        if (parsed == null) return;
        final updated =
            isX ? Offset(parsed, anchor.dy) : Offset(anchor.dx, parsed);
        // moveTerminalAnchor writes the level override when one exists for
        // the active level, the base anchor otherwise.
        notifier.moveTerminalAnchor(connector.id, terminal.id, updated);
      },
    );
  }

  TerminalDef _copy({String? label, ElectricalGroup? group}) => TerminalDef(
        id: terminal.id,
        label: label ?? terminal.label,
        group: group ?? terminal.group,
        anchorInConnector: terminal.anchorInConnector,
        levelAnchors: terminal.levelAnchors,
        delegate: terminal.delegate,
        isJumper: terminal.isJumper,
        description: terminal.description,
      );
}

// ─── Delegate editor ──────────────────────────────────────────────────────────

class _DelegateEditor extends StatelessWidget {
  final DesignerNotifier notifier;
  final ConnectorDef connector;
  final TerminalDef terminal;

  const _DelegateEditor({
    required this.notifier,
    required this.connector,
    required this.terminal,
  });

  @override
  Widget build(BuildContext context) {
    final refs = notifier.delegatableRefs;
    final resolver = notifier.resolver;
    final enabled = refs.isNotEmpty && resolver != null;

    final currentRefId = terminal.delegate?.refId;
    final refIds = refs.map((r) => r.id!).toSet().toList();
    // Keep a stale refId visible so it can be cleared.
    if (currentRefId != null && !refIds.contains(currentRefId)) {
      refIds.add(currentRefId);
    }

    final selectedRef = refs.where((r) => r.id == currentRefId).firstOrNull;
    final childTerminals = selectedRef != null
        ? (resolver?.call(selectedRef.typeKey)?.allTerminals ??
            const <TerminalDef>[])
        : const <TerminalDef>[];
    final terminalIds = childTerminals.map((t) => t.id).toList();
    final currentChildTerminal = terminal.delegate?.terminalId;
    if (currentChildTerminal != null &&
        !terminalIds.contains(currentChildTerminal)) {
      terminalIds.add(currentChildTerminal);
    }

    return Tooltip(
      message: enabled
          ? 'Delegate this terminal to a referenced child device\'s terminal'
          : 'Place a Device ref with an id (and supply a resolver) to '
              'enable delegation',
      child: Row(
        children: [
          const Text('Delegates to', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<String?>(
              value: currentRefId,
              isDense: true,
              isExpanded: true,
              hint: const Text('—', style: TextStyle(fontSize: 10)),
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('(none)')),
                for (final id in refIds)
                  DropdownMenuItem<String?>(value: id, child: Text(id)),
              ],
              onChanged: enabled || currentRefId != null
                  ? (refId) {
                      if (refId == null) {
                        notifier.setTerminalDelegate(
                            connector.id, terminal.id, null);
                      } else {
                        final ref =
                            refs.where((r) => r.id == refId).firstOrNull;
                        final childDef =
                            ref != null ? resolver?.call(ref.typeKey) : null;
                        final firstTerminal =
                            childDef?.allTerminals.firstOrNull?.id ?? '';
                        notifier.setTerminalDelegate(
                          connector.id,
                          terminal.id,
                          TerminalDelegate(
                              refId: refId, terminalId: firstTerminal),
                        );
                      }
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<String>(
              value: currentChildTerminal != null &&
                      terminalIds.contains(currentChildTerminal)
                  ? currentChildTerminal
                  : null,
              isDense: true,
              isExpanded: true,
              hint: const Text('terminal', style: TextStyle(fontSize: 10)),
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              items: [
                for (final id in terminalIds)
                  DropdownMenuItem(value: id, child: Text(id)),
              ],
              onChanged: terminal.delegate != null
                  ? (terminalId) {
                      if (terminalId == null) return;
                      notifier.setTerminalDelegate(
                        connector.id,
                        terminal.id,
                        TerminalDelegate(
                            refId: terminal.delegate!.refId,
                            terminalId: terminalId),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
