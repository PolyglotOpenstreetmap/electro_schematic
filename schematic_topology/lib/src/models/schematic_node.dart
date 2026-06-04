// schematic_topology — generic node interface.

import 'dart:ui';

/// A node the topology engine can position, hit-test, and route connections to.
///
/// Host models implement this on top of their domain object. [size] is the
/// layout / hit-test size used by the node card; [renderSize] is the size used
/// for connection geometry (often identical, but may differ when a node renders
/// larger/smaller than its nominal box).
abstract interface class SchematicNode {
  String get id;
  Offset get position;
  Size get size;
  Size get renderSize;
}
