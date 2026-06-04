// schematic_topology — interactive topology canvas.

import 'package:flutter/material.dart';

import '../models/connection_side.dart';
import '../models/edge_style.dart';
import '../models/schematic_edge.dart';
import '../models/schematic_node.dart';
import '../painters/connection_painter.dart';
import '../painters/overlay_painters.dart';
import 'node_card.dart';

/// An interactive pan/zoom canvas that renders [nodes] and [edges], supports
/// drag-to-connect and rubber-band selection, and is fully domain-agnostic.
///
/// The host app supplies:
/// - [nodeBuilder]: the visual for each node (wrapped in a [SchematicNodeCard]).
/// - [styleResolver]: per-edge color/dash/label (return `null` to hide an edge).
/// - [backgroundPainter]: page/grid/title-block chrome (optional).
/// - [backgroundOverlays]: extra widgets drawn behind the nodes (e.g. hulls).
class SchematicTopologyCanvas<N extends SchematicNode, E extends SchematicEdge>
    extends StatelessWidget {
  const SchematicTopologyCanvas({
    super.key,
    required this.canvasSize,
    required this.transformationController,
    required this.nodes,
    required this.edges,
    required this.styleResolver,
    required this.nodeBuilder,
    this.backgroundPainter,
    this.backgroundOverlays = const [],
    // Selection
    required this.selectedNodeIds,
    required this.selectedNodeId,
    // Connection drag
    required this.isDraggingConnection,
    required this.dragStartNodeId,
    required this.dragCurrentPosition,
    required this.dragStartPosition,
    required this.hoveredNodeId,
    required this.hoveredSide,
    // Rubber-band
    required this.isRubberBanding,
    required this.selectionStart,
    required this.selectionEnd,
    // Callbacks
    required this.onConnectionDragStart,
    required this.onConnectionDragEnd,
    required this.onConnectionDragUpdate,
    required this.onHoverChanged,
    required this.onCanvasTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Size canvasSize;
  final TransformationController transformationController;

  final List<N> nodes;
  final List<E> edges;
  final EdgeStyleResolver styleResolver;
  final Widget Function(N node, bool isSelected) nodeBuilder;
  final CustomPainter? backgroundPainter;
  final List<Widget> backgroundOverlays;

  final Set<String> selectedNodeIds;
  final String? selectedNodeId;

  final bool isDraggingConnection;
  final String? dragStartNodeId;
  final Offset? dragCurrentPosition;
  final Offset? dragStartPosition;
  final String? hoveredNodeId;
  final ConnectionSide? hoveredSide;

  final bool isRubberBanding;
  final Offset? selectionStart;
  final Offset? selectionEnd;

  final void Function(String nodeId, ConnectionSide side, Offset position)
      onConnectionDragStart;
  final VoidCallback onConnectionDragEnd;
  final void Function(Offset position) onConnectionDragUpdate;
  final void Function(String? nodeId, ConnectionSide? side) onHoverChanged;
  final void Function(Offset position) onCanvasTap;
  final void Function(Offset position) onPanStart;
  final void Function(Offset position) onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: 0.1,
        maxScale: 4.0,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false,
        child: Listener(
          onPointerMove: (event) {
            if (isDraggingConnection) {
              onConnectionDragUpdate(event.localPosition);
            }
          },
          onPointerUp: (event) {
            if (isDraggingConnection) onConnectionDragEnd();
          },
          child: GestureDetector(
            onTapUp: (d) => onCanvasTap(d.localPosition),
            onPanStart: (d) => onPanStart(d.localPosition),
            onPanUpdate: (d) => onPanUpdate(d.localPosition),
            onPanEnd: (_) => onPanEnd(),
            child: MouseRegion(
              cursor: isDraggingConnection
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.basic,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: CustomPaint(
                  painter: backgroundPainter,
                  foregroundPainter: SchematicConnectionPainter(
                    edges: edges,
                    nodes: nodes,
                    styleResolver: styleResolver,
                  ),
                  child: Stack(
                    children: [
                      ...backgroundOverlays,
                      ..._buildNodes(),
                      if (isRubberBanding &&
                          selectionStart != null &&
                          selectionEnd != null)
                        CustomPaint(
                          painter: SchematicSelectionRectPainter(
                            rect: Rect.fromPoints(
                                selectionStart!, selectionEnd!),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      if (isDraggingConnection &&
                          dragCurrentPosition != null &&
                          dragStartPosition != null)
                        CustomPaint(
                          painter: SchematicDragConnectionPainter(
                            startPosition: dragStartPosition!,
                            endPosition: dragCurrentPosition!,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: const SizedBox.expand(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodes() {
    return nodes.map((node) {
      final isSelected =
          selectedNodeIds.contains(node.id) || node.id == selectedNodeId;
      final showConnectionPoints =
          isDraggingConnection && dragStartNodeId != node.id;

      return Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: SchematicNodeCard(
          nodeId: node.id,
          nodeSize: node.size,
          nodePosition: node.position,
          isDraggingConnection: isDraggingConnection,
          dragStartNodeId: dragStartNodeId,
          showConnectionPoints: showConnectionPoints,
          hoveredNodeId: hoveredNodeId,
          hoveredSide: hoveredSide,
          onConnectionDragStart: onConnectionDragStart,
          onConnectionDragEnd: onConnectionDragEnd,
          onHoverChanged: onHoverChanged,
          child: nodeBuilder(node, isSelected),
        ),
      );
    }).toList();
  }
}
