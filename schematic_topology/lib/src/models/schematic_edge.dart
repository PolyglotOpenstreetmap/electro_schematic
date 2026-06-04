// schematic_topology — generic edge interface.

import 'dart:ui';

import 'connection_side.dart';

/// A connection between two [SchematicNode]s, identified by node ids.
///
/// Host models implement this on top of their domain connection object.
abstract interface class SchematicEdge {
  String get id;
  String get sourceNodeId;
  String get destNodeId;
  ConnectionSide get exitSide;
  ConnectionSide get entrySide;
  List<Offset>? get waypoints;
}
