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

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
