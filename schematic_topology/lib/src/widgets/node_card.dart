// schematic_topology — node card with connection-point detection.

import 'package:flutter/material.dart';

import '../models/connection_side.dart';

/// Wraps an app-supplied node visual ([child]) with hover-driven connection
/// points and drag-to-connect handles. The card is domain-agnostic: it only
/// needs the node's [nodeId], [nodeSize], and [nodePosition].
class SchematicNodeCard extends StatefulWidget {
  const SchematicNodeCard({
    super.key,
    required this.nodeId,
    required this.nodeSize,
    required this.nodePosition,
    required this.child,
    required this.onConnectionDragStart,
    required this.onConnectionDragEnd,
    required this.onHoverChanged,
    required this.isDraggingConnection,
    required this.dragStartNodeId,
    required this.showConnectionPoints,
    this.hoveredNodeId,
    this.hoveredSide,
  });

  final String nodeId;
  final Size nodeSize;
  final Offset nodePosition;
  final Widget child;
  final void Function(String nodeId, ConnectionSide side, Offset position)
      onConnectionDragStart;
  final VoidCallback onConnectionDragEnd;
  final void Function(String? nodeId, ConnectionSide? side) onHoverChanged;
  final bool isDraggingConnection;
  final String? dragStartNodeId;
  final bool showConnectionPoints;
  final String? hoveredNodeId;
  final ConnectionSide? hoveredSide;

  @override
  State<SchematicNodeCard> createState() => _SchematicNodeCardState();
}

class _SchematicNodeCardState extends State<SchematicNodeCard> {
  ConnectionSide? _hoveredSide;
  final double _connectionPointSize = 12.0;
  final double _hoverDistance = 30.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _handleMouseExit(),
      onHover: (event) => _handleMouseHover(event.localPosition),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (widget.showConnectionPoints || _hoveredSide != null)
            ..._buildConnectionPoints(),
        ],
      ),
    );
  }

  void _handleMouseExit() {
    setState(() => _hoveredSide = null);
    widget.onHoverChanged(null, null);
  }

  void _handleMouseHover(Offset localPosition) {
    final size = widget.nodeSize;
    final distances = {
      ConnectionSide.top: localPosition.dy,
      ConnectionSide.bottom: size.height - localPosition.dy,
      ConnectionSide.left: localPosition.dx,
      ConnectionSide.right: size.width - localPosition.dx,
    };

    final minEntry =
        distances.entries.reduce((a, b) => a.value < b.value ? a : b);
    final newHoveredSide =
        minEntry.value < _hoverDistance ? minEntry.key : null;

    if (newHoveredSide != _hoveredSide) {
      setState(() => _hoveredSide = newHoveredSide);
      widget.onHoverChanged(
        newHoveredSide != null ? widget.nodeId : null,
        newHoveredSide,
      );
    }
  }

  List<Widget> _buildConnectionPoints() {
    final sidesToShow = widget.isDraggingConnection &&
            widget.dragStartNodeId != widget.nodeId
        ? [
            ConnectionSide.top,
            ConnectionSide.bottom,
            ConnectionSide.left,
            ConnectionSide.right,
          ]
        : _hoveredSide != null
            ? [_hoveredSide!]
            : <ConnectionSide>[];

    return sidesToShow
        .map((side) => _buildConnectionPoint(side, widget.nodeSize))
        .toList();
  }

  Widget _buildConnectionPoint(ConnectionSide side, Size size) {
    final half = _connectionPointSize / 2;
    final Offset position;
    switch (side) {
      case ConnectionSide.top:
        position = Offset(size.width / 2 - half, -half);
        break;
      case ConnectionSide.bottom:
        position = Offset(size.width / 2 - half, size.height - half);
        break;
      case ConnectionSide.left:
        position = Offset(-half, size.height / 2 - half);
        break;
      case ConnectionSide.right:
        position = Offset(size.width - half, size.height / 2 - half);
        break;
      case ConnectionSide.center:
        position = Offset(size.width / 2 - half, size.height / 2 - half);
        break;
    }

    final isHoveredTarget = widget.hoveredNodeId == widget.nodeId &&
        widget.hoveredSide == side &&
        widget.isDraggingConnection;
    final pointSize =
        isHoveredTarget ? _connectionPointSize * 1.5 : _connectionPointSize;
    final pointColor =
        isHoveredTarget ? Colors.green : Theme.of(context).colorScheme.primary;
    final extraOffset = isHoveredTarget ? _connectionPointSize * 0.25 : 0.0;

    return Positioned(
      left: position.dx - extraOffset,
      top: position.dy - extraOffset,
      child: GestureDetector(
        onPanStart: (_) {
          final globalPosition = Offset(
            widget.nodePosition.dx + position.dx + half,
            widget.nodePosition.dy + position.dy + half,
          );
          widget.onConnectionDragStart(widget.nodeId, side, globalPosition);
        },
        onPanEnd: (_) => widget.onConnectionDragEnd(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: pointSize,
          height: pointSize,
          decoration: BoxDecoration(
            color: pointColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isHoveredTarget
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimary,
              width: isHoveredTarget ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHoveredTarget
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: isHoveredTarget ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
