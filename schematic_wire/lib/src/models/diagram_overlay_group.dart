// lib/models/physical/diagram_overlay_group.dart

import 'dart:ui' show Rect;

import 'base.dart' show Position2D;

/// A generic overlay group drawn as a labelled dashed rectangle on the diagram.
///
/// The painter draws this as a dashed bounding box with a label, without
/// needing to know what the members represent. App-specific positioning data
/// ([contentOrigin], [isLinear], [memberCount], [memberIds]) is carried here
/// so domain painters can use it without coupling back to domain model types.
class DiagramOverlayGroup {
  final String id;
  final String label;

  /// Bounding box in diagram coordinates, used for rendering and hit-testing.
  final Rect bounds;

  /// Base position of the first member within the group (e.g. first motor).
  /// Used by domain painters to position sub-elements (sensors, wires).
  final Position2D? contentOrigin;

  /// Whether members are stacked vertically (true) or side-by-side (false).
  final bool isLinear;

  /// Number of members in this group.
  final int memberCount;

  /// Ordered list of member identifier tokens used to match terminal blocks
  /// to their group (e.g. motor IDs extracted from terminal ID patterns).
  final List<String> memberIds;

  const DiagramOverlayGroup({
    required this.id,
    required this.label,
    required this.bounds,
    this.contentOrigin,
    this.isLinear = false,
    this.memberCount = 1,
    this.memberIds = const [],
  });
}
