# schematic_topology

A generic Flutter graph/topology editor — the reusable engine behind an
interactive node-and-connection canvas, with no domain coupling.

## Features

- **Interactive canvas** (`SchematicTopologyCanvas`) — pan/zoom, drag-to-connect,
  rubber-band multi-select, hover connection points.
- **Connection painter** (`SchematicConnectionPainter`) — bezier edges with
  parallel-offset for multi-edges, arrowheads, shadows, and label pills. Edge
  appearance is supplied by an injected `EdgeStyleResolver`.
- **Routing geometry** (`SchematicConnectionRouter`) — border connection points,
  90° corner waypoints, non-overlapping placement.
- **Overlay painters** — `SchematicGridPainter`, `SchematicDragConnectionPainter`,
  `SchematicSelectionRectPainter`.
- **Node card** (`SchematicNodeCard`) — wraps an app-supplied node visual with
  connection-point detection.

## Decoupling

The engine operates on two interfaces your domain models implement:

```dart
class MyNode implements SchematicNode { /* id, position, size, renderSize */ }
class MyEdge implements SchematicEdge { /* id, source/destNodeId, sides, waypoints */ }
```

Edge styling (color/dash/label) and visibility are decided by the host:

```dart
EdgeStyle? myResolver(SchematicEdge e) {
  if (hidden(e)) return null;               // hide
  return EdgeStyle(color: colorFor(e), dash: dashFor(e), label: labelFor(e));
}
```

## Example — house with detached garage

The snippet below models four devices spread across two buildings and connects
them with typed cables.  Each cable type gets a distinct color; data cables are
dashed.

```dart
import 'package:flutter/material.dart';
import 'package:schematic_topology/schematic_topology.dart';

// --- Domain models ----------------------------------------------------------

enum CableType { power6mm, power15mm, cat6 }

class Device implements SchematicNode {
  const Device(this.id, this.label, this.position)
      : size = const Size(140, 52),
        renderSize = const Size(140, 52);

  @override final String id;
  @override final Offset position;
  @override final Size size;
  @override final Size renderSize;
  final String label;
}

class Cable implements SchematicEdge {
  const Cable(this.id, this.sourceNodeId, this.destNodeId, this.type);

  @override final String id;
  @override final String sourceNodeId;
  @override final String destNodeId;
  @override ConnectionSide get exitSide  => ConnectionSide.right;
  @override ConnectionSide get entrySide => ConnectionSide.left;
  @override List<Offset>? get waypoints  => null;
  final CableType type;
}

// --- Style resolver ---------------------------------------------------------

EdgeStyle? _cableStyle(SchematicEdge edge) {
  final cable = edge as Cable;
  return switch (cable.type) {
    CableType.power6mm  => const EdgeStyle(color: Color(0xFFE65100), strokeWidth: 3, label: '6 mm² SWA'),
    CableType.power15mm => const EdgeStyle(color: Color(0xFFFFA000), strokeWidth: 2, label: '1.5 mm²'),
    CableType.cat6      => const EdgeStyle(color: Color(0xFF1565C0), dash: [6, 4], label: 'CAT6'),
  };
}

// --- Scene ------------------------------------------------------------------

const _devices = [
  Device('main_panel',      'Main Panel',         Offset(60,  80)),
  Device('router',          'Router',             Offset(60,  200)),
  Device('garage_panel',    'Garage Sub-Panel',   Offset(480, 80)),
  Device('gate_controller', 'Gate Controller',    Offset(480, 200)),
];

const _cables = [
  Cable('c1', 'main_panel',   'garage_panel',    CableType.power6mm),
  Cable('c2', 'router',       'garage_panel',    CableType.cat6),
  Cable('c3', 'garage_panel', 'gate_controller', CableType.power15mm),
];

// --- Widget -----------------------------------------------------------------

class HouseGarageTopology extends StatelessWidget {
  const HouseGarageTopology({super.key});

  @override
  Widget build(BuildContext context) {
    return SchematicTopologyCanvas<Device, Cable>(
      canvasSize: const Size(800, 360),
      transformationController: TransformationController(),
      nodes: _devices,
      edges: _cables,
      styleResolver: _cableStyle,
      nodeBuilder: (node, isSelected) => Card(
        color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
        child: SizedBox.fromSize(
          size: node.size,
          child: Center(child: Text(node.label)),
        ),
      ),
      backgroundPainter: const SchematicGridPainter(pageSize: Size(800, 360)),
      // interaction callbacks — wire up to StatefulWidget state in real use
      selectedNodeIds: const {},
      selectedNodeId: null,
      isDraggingConnection: false,
      dragStartNodeId: null,
      dragCurrentPosition: null,
      dragStartPosition: null,
      hoveredNodeId: null,
      hoveredSide: null,
      isRubberBanding: false,
      selectionStart: null,
      selectionEnd: null,
      onConnectionDragStart: (_, __, ___) {},
      onConnectionDragEnd: () {},
      onConnectionDragUpdate: (_) {},
      onHoverChanged: (_, __) {},
      onCanvasTap: (_) {},
      onPanStart: (_) {},
      onPanUpdate: (_) {},
      onPanEnd: () {},
    );
  }
}
```

The rendered canvas shows:
- **orange solid** line: 6 mm² armoured cable, Main Panel → Garage Sub-Panel
- **blue dashed** line: CAT6 patch, Router → Garage Sub-Panel
- **amber solid** line: 1.5 mm² tail, Garage Sub-Panel → Gate Controller

In a real app the interaction callbacks update a `StatefulWidget`'s state (selected
node, drag position, etc.); the static `{}` / `null` values above are fine for a
read-only view.

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
