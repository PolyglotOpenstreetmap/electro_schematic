// lib/models/physical/wiring_overview_models.dart

import 'base.dart';

enum WiringOverviewNodeType {
  motor,
  striker,
  triacBoard,  // Movotron / TRIAC cabinet
  sbsi,
  iv3mod3srl,
  masterClock,
  towerClock,
  powerEntry,
  serialDevice,
}

enum WiringOverviewEdgeType { cable, serialBus, power }

/// Where a terminal strip is anchored in the layout. The painter resolves these
/// anchors to actual coordinates after the cabinet bounding box is known.
///   - [cabinetMotor]      → bottom edge of the cabinet, packed right-to-left
///   - [cabinetSerialBus]  → top edge of the cabinet, packed left-to-right
///   - [cabinetMains]      → top-right of the cabinet, horizontal
///                           (mains entry distribution block)
///   - [cabinetStriker]    → bottom edge of the cabinet, packed left-to-right
///                           (kept separate from motor strips to honour user
///                            convention "motor wiring exits bottom-right")
///   - [boardBottom]       → bottom edge of a specific board node (Movotron
///                           board / IV3MOD3SRL); strips line up below the
///                           board where the field cables actually arrive.
///   - [device]            → attached to a single node (motor / striker)
enum WiringOverviewStripAnchor {
  cabinetMotor,
  cabinetSerialBus,
  cabinetMains,
  cabinetStriker,
  boardBottom,
  device,
}

/// A single screw on a [WiringOverviewTerminalStrip].
class WiringOverviewTerminal {
  final String id;
  final String label;          // "U", "V", "W", "PE", "BR", "OR", "PU", "GR", …
  final String? colorHex;      // optional fill color hint (e.g., wire color)
  // Free-form per-terminal metadata. Currently used to mark SBSI slot screws:
  //   {'role': 'comm'}                — shared common terminal
  //   {'role': 'out', 'outputNum': 4} — switched output (1-based global per plate)
  final Map<String, dynamic> metadata;

  const WiringOverviewTerminal({
    required this.id,
    required this.label,
    this.colorHex,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (colorHex != null) 'colorHex': colorHex,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory WiringOverviewTerminal.fromJson(Map<String, dynamic> json) =>
      WiringOverviewTerminal(
        id: json['id'] as String,
        label: json['label'] as String,
        colorHex: json['colorHex'] as String?,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );
}

/// Visual idiom for a terminal strip. Most strips are simple bus rows; SBSI
/// slot strips have a distinguishing top band coloured by card type and a
/// COMM screw rendered differently from the OUT screws.
enum WiringOverviewStripKind { bus, sbsiSlot }

/// A small labelled terminal block where a cable lands. Reuses the
/// detailed-wiring-tab visual idiom (bordered rect + labelled screws).
///
/// [attachedToId] points to the cabinet (for cabinet* anchors) or to the node
/// (for [WiringOverviewStripAnchor.device]). [orderIndex] disambiguates when
/// multiple strips share the same anchor on the same cabinet.
class WiringOverviewTerminalStrip {
  final String id;
  final String label;
  final List<WiringOverviewTerminal> terminals;
  final WiringOverviewStripAnchor anchor;
  final String attachedToId;
  final int pageIndex;
  final int orderIndex;
  // Optional grouping key — strips that share a [groupKey] are visually clustered
  // on the cabinet wall (e.g., one Movotron board's worth of motor strips).
  final String? groupKey;
  // When true, render as a small unlabelled rounded rect (a "lug") with just
  // the strip [label] in the centre — no individual screws or terminal labels.
  // Cables terminate as a single bundled line on this lug. Used for the small
  // sensor connector beside a motor.
  final bool compact;
  // Visual idiom: default [bus] = simple labelled row; [sbsiSlot] adds a
  // card-type top band and renders COMM distinctly from OUT screws.
  final WiringOverviewStripKind kind;
  // Free-form strip metadata. For [sbsiSlot] kind, carries:
  //   {'cardType': 'fet' | 'rel' | 'empty', 'slotNumber': 1, 'plateNumber': 1}
  final Map<String, dynamic> metadata;

  const WiringOverviewTerminalStrip({
    required this.id,
    required this.label,
    required this.terminals,
    required this.anchor,
    required this.attachedToId,
    required this.pageIndex,
    this.orderIndex = 0,
    this.groupKey,
    this.compact = false,
    this.kind = WiringOverviewStripKind.bus,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'terminals': terminals.map((t) => t.toJson()).toList(),
        'anchor': anchor.name,
        'attachedToId': attachedToId,
        'pageIndex': pageIndex,
        'orderIndex': orderIndex,
        if (groupKey != null) 'groupKey': groupKey,
        if (compact) 'compact': true,
        if (kind != WiringOverviewStripKind.bus) 'kind': kind.name,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory WiringOverviewTerminalStrip.fromJson(Map<String, dynamic> json) =>
      WiringOverviewTerminalStrip(
        id: json['id'] as String,
        label: json['label'] as String,
        terminals: (json['terminals'] as List?)
                ?.map((e) => WiringOverviewTerminal.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        anchor: WiringOverviewStripAnchor.values.byName(json['anchor'] as String),
        attachedToId: json['attachedToId'] as String,
        pageIndex: json['pageIndex'] as int,
        orderIndex: json['orderIndex'] as int? ?? 0,
        groupKey: json['groupKey'] as String?,
        compact: json['compact'] as bool? ?? false,
        kind: json['kind'] is String
            ? WiringOverviewStripKind.values.byName(json['kind'] as String)
            : WiringOverviewStripKind.bus,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );
}

/// Subdivision type carried into the overview, mirrors topology.SubdivisionType.
/// Used to derive cabinet color (sacristy=blue, towerFloor=purple, clockTower=green).
enum WiringOverviewCabinetType { sacristy, towerFloor, clockTower }

/// A labelled enclosure that visually groups equipment nodes living in the same
/// physical [SubdivisionNode]. Cabinets are layout-only — they don't introduce
/// new connectivity, they just give the painter a frame to draw around their
/// contained nodes.
class WiringOverviewCabinet {
  final String id;
  final String subdivisionId;
  final WiringOverviewCabinetType type;
  final String label;
  final List<String> containedNodeIds;
  final int pageIndex;

  const WiringOverviewCabinet({
    required this.id,
    required this.subdivisionId,
    required this.type,
    required this.label,
    required this.containedNodeIds,
    required this.pageIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subdivisionId': subdivisionId,
        'type': type.name,
        'label': label,
        'containedNodeIds': containedNodeIds,
        'pageIndex': pageIndex,
      };

  factory WiringOverviewCabinet.fromJson(Map<String, dynamic> json) =>
      WiringOverviewCabinet(
        id: json['id'] as String,
        subdivisionId: json['subdivisionId'] as String,
        type: WiringOverviewCabinetType.values.byName(json['type'] as String),
        label: json['label'] as String,
        containedNodeIds:
            (json['containedNodeIds'] as List?)?.map((e) => e as String).toList() ?? [],
        pageIndex: json['pageIndex'] as int,
      );
}

class WiringOverviewNode {
  final String id;
  final WiringOverviewNodeType type;
  final String label;
  Position2D position;
  final int pageIndex;
  final Map<String, dynamic> metadata; // voltage, kW, weightKg, rpm, starDelta, etc.

  WiringOverviewNode({
    required this.id,
    required this.type,
    required this.label,
    required this.position,
    required this.pageIndex,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'position': position.toJson(),
        'pageIndex': pageIndex,
        'metadata': metadata,
      };

  factory WiringOverviewNode.fromJson(Map<String, dynamic> json) =>
      WiringOverviewNode(
        id: json['id'] as String,
        type: WiringOverviewNodeType.values.byName(json['type'] as String),
        label: json['label'] as String,
        position: Position2D.fromJson(json['position'] as Map<String, dynamic>),
        pageIndex: json['pageIndex'] as int,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

class WiringOverviewEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final WiringOverviewEdgeType edgeType;
  final List<String> wireColors;
  // Optional terminal strip endpoints. When set, the painter terminates the
  // wires on the strip's named screws instead of generic dots on the node face.
  final String? sourceStripId;
  final String? destStripId;
  // Optional per-terminal endpoints inside a strip. When set, the painter
  // routes the wire to that specific screw rather than fanning all screws to
  // the bundle anchor. Single-wire edges that name a terminal land on that
  // one screw.
  final String? sourceTerminalId;
  final String? destTerminalId;
  // Edges that share a non-null [parallelGroupId] are drawn as parallel
  // routes (e.g., a motor power cable + its sensor cable).
  final String? parallelGroupId;

  const WiringOverviewEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.edgeType,
    this.wireColors = const [],
    this.sourceStripId,
    this.destStripId,
    this.sourceTerminalId,
    this.destTerminalId,
    this.parallelGroupId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        'edgeType': edgeType.name,
        'wireColors': wireColors,
        if (sourceStripId != null) 'sourceStripId': sourceStripId,
        if (destStripId != null) 'destStripId': destStripId,
        if (sourceTerminalId != null) 'sourceTerminalId': sourceTerminalId,
        if (destTerminalId != null) 'destTerminalId': destTerminalId,
        if (parallelGroupId != null) 'parallelGroupId': parallelGroupId,
      };

  factory WiringOverviewEdge.fromJson(Map<String, dynamic> json) =>
      WiringOverviewEdge(
        id: json['id'] as String,
        fromNodeId: json['fromNodeId'] as String,
        toNodeId: json['toNodeId'] as String,
        edgeType: WiringOverviewEdgeType.values.byName(json['edgeType'] as String),
        wireColors: (json['wireColors'] as List?)?.map((e) => e as String).toList() ?? [],
        sourceStripId: json['sourceStripId'] as String?,
        destStripId: json['destStripId'] as String?,
        sourceTerminalId: json['sourceTerminalId'] as String?,
        destTerminalId: json['destTerminalId'] as String?,
        parallelGroupId: json['parallelGroupId'] as String?,
      );
}

class WiringOverviewLayout {
  final List<WiringOverviewNode> nodes;
  final List<WiringOverviewEdge> edges;
  final List<WiringOverviewCabinet> cabinets;
  final List<WiringOverviewTerminalStrip> terminalStrips;
  final int pageCount;
  // User-overridden positions (nodeId → position); merged over auto-layout
  final Map<String, Position2D> userPositions;

  const WiringOverviewLayout({
    this.nodes = const [],
    this.edges = const [],
    this.cabinets = const [],
    this.terminalStrips = const [],
    this.pageCount = 1,
    this.userPositions = const {},
  });

  static const WiringOverviewLayout empty = WiringOverviewLayout();

  /// Returns effective position for a node (user override takes precedence).
  Position2D effectivePosition(WiringOverviewNode node) =>
      userPositions[node.id] ?? node.position;

  WiringOverviewLayout copyWithUserPosition(String nodeId, Position2D pos) {
    final updated = Map<String, Position2D>.from(userPositions);
    updated[nodeId] = pos;
    return WiringOverviewLayout(
      nodes: nodes,
      edges: edges,
      cabinets: cabinets,
      terminalStrips: terminalStrips,
      pageCount: pageCount,
      userPositions: updated,
    );
  }

  WiringOverviewLayout clearUserPositions() => WiringOverviewLayout(
        nodes: nodes,
        edges: edges,
        cabinets: cabinets,
        terminalStrips: terminalStrips,
        pageCount: pageCount,
      );

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
        'cabinets': cabinets.map((c) => c.toJson()).toList(),
        'terminalStrips': terminalStrips.map((s) => s.toJson()).toList(),
        'pageCount': pageCount,
        'userPositions': userPositions.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  factory WiringOverviewLayout.fromJson(Map<String, dynamic> json) =>
      WiringOverviewLayout(
        nodes: (json['nodes'] as List?)
                ?.map((e) => WiringOverviewNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        edges: (json['edges'] as List?)
                ?.map((e) => WiringOverviewEdge.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        cabinets: (json['cabinets'] as List?)
                ?.map((e) =>
                    WiringOverviewCabinet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        terminalStrips: (json['terminalStrips'] as List?)
                ?.map((e) => WiringOverviewTerminalStrip.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        pageCount: json['pageCount'] as int? ?? 1,
        userPositions: (json['userPositions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, Position2D.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
      );
}
