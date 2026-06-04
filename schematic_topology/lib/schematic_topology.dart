// packages/electro_schematic/schematic_topology/lib/schematic_topology.dart
//
// Public API for the schematic_topology package.

// ── Models ──────────────────────────────────────────────────────────────────
export 'src/models/connection_side.dart';
export 'src/models/schematic_node.dart';
export 'src/models/schematic_edge.dart';
export 'src/models/edge_style.dart';

// ── Services ─────────────────────────────────────────────────────────────────
export 'src/services/connection_router.dart';

// ── Painters ─────────────────────────────────────────────────────────────────
export 'src/painters/connection_painter.dart';
export 'src/painters/overlay_painters.dart';

// ── Widgets ──────────────────────────────────────────────────────────────────
export 'src/widgets/node_card.dart';
export 'src/widgets/topology_canvas.dart';
