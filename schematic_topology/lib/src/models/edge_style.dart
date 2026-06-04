// schematic_topology — pluggable edge styling.

import 'dart:ui';

import 'schematic_edge.dart';

/// Visual style for a single edge, supplied by the host app's domain logic.
class EdgeStyle {
  const EdgeStyle({
    required this.color,
    this.strokeWidth = 2.0,
    this.dash,
    this.label,
  });

  final Color color;
  final double strokeWidth;

  /// `null` = solid stroke; otherwise `[dashLength, gapLength]`.
  final List<double>? dash;

  /// Optional label drawn in a pill at the midpoint of the edge.
  final String? label;
}

/// Resolves the [EdgeStyle] for an edge. Returning `null` hides the edge
/// (used for cable-type visibility filters).
typedef EdgeStyleResolver = EdgeStyle? Function(SchematicEdge edge);
