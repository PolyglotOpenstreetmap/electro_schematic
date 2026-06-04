// schematic_topology — connection side enum.

/// Which border of a node a connection enters/exits.
enum ConnectionSide {
  top,
  bottom,
  left,
  right,
  center, // fallback for single/auto connections
}
