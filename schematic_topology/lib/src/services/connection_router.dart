// schematic_topology — connection routing geometry (pure, stateless).

import 'dart:ui';

import '../models/connection_side.dart';
import '../models/schematic_node.dart';

/// Stateless geometry for connection routing. No stored state.
class SchematicConnectionRouter {
  const SchematicConnectionRouter();

  /// The connection point on a node's border for a given [side].
  ///
  /// For dual connections between the same node pair, [isMulticore] offsets the
  /// point to avoid overlap.
  Offset getConnectionPoint(
    SchematicNode node,
    ConnectionSide side, {
    bool isMulticore = false,
  }) {
    final nodeCenter = Offset(
      node.position.dx + node.size.width / 2,
      node.position.dy + node.size.height / 2,
    );

    if (side == ConnectionSide.center) {
      return nodeCenter;
    }

    const dualOffset = 15.0;
    final offset = isMulticore ? dualOffset : -dualOffset;

    switch (side) {
      case ConnectionSide.top:
        return Offset(nodeCenter.dx + offset, node.position.dy);
      case ConnectionSide.bottom:
        return Offset(
            nodeCenter.dx + offset, node.position.dy + node.size.height);
      case ConnectionSide.left:
        return Offset(node.position.dx, nodeCenter.dy + offset);
      case ConnectionSide.right:
        return Offset(
            node.position.dx + node.size.width, nodeCenter.dy + offset);
      case ConnectionSide.center:
        return nodeCenter;
    }
  }

  /// 90-degree corner waypoints between two ports.
  List<Offset> generate90DegreeRoute(
    Offset startPoint,
    Offset endPoint,
    ConnectionSide exitSide,
    ConnectionSide entrySide,
  ) {
    final waypoints = <Offset>[];

    final needsCorners =
        exitSide != ConnectionSide.center && entrySide != ConnectionSide.center;
    if (!needsCorners) return waypoints;

    final isExitHorizontal =
        exitSide == ConnectionSide.left || exitSide == ConnectionSide.right;
    final isEntryHorizontal =
        entrySide == ConnectionSide.left || entrySide == ConnectionSide.right;

    if (isExitHorizontal == isEntryHorizontal) {
      final midX = (startPoint.dx + endPoint.dx) / 2;
      final midY = (startPoint.dy + endPoint.dy) / 2;
      if (isExitHorizontal) {
        waypoints.add(Offset(midX, startPoint.dy));
        waypoints.add(Offset(midX, endPoint.dy));
      } else {
        waypoints.add(Offset(startPoint.dx, midY));
        waypoints.add(Offset(endPoint.dx, midY));
      }
    } else {
      if (isExitHorizontal) {
        waypoints.add(Offset(endPoint.dx, startPoint.dy));
      } else {
        waypoints.add(Offset(startPoint.dx, endPoint.dy));
      }
    }

    return waypoints;
  }

  /// Find a non-overlapping position for a node, avoiding [existingNodes].
  Offset findNonOverlappingPosition(
    Offset desiredPosition,
    Size nodeSize, {
    required List<SchematicNode> existingNodes,
    int maxAttempts = 20,
  }) {
    const double minDistance = 50.0;
    int attempts = 0;
    Offset currentPosition = desiredPosition;

    while (attempts < maxAttempts) {
      bool hasOverlap = false;

      for (final node in existingNodes) {
        final dx = currentPosition.dx - node.position.dx;
        final dy = currentPosition.dy - node.position.dy;
        final distance = (dx * dx + dy * dy);
        final minDistSquared = minDistance * minDistance;

        if (distance < minDistSquared) {
          hasOverlap = true;
          final radius = 60.0 + (attempts * 10);
          currentPosition = Offset(
            desiredPosition.dx + (radius * (attempts % 2 == 0 ? 1 : -1)),
            desiredPosition.dy + (radius * ((attempts ~/ 2) % 2 == 0 ? 1 : -1)),
          );
          break;
        }
      }

      if (!hasOverlap) return currentPosition;
      attempts++;
    }

    return Offset(desiredPosition.dx + 150, desiredPosition.dy + 150);
  }
}
