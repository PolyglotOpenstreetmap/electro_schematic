// lib/models/physical/base.dart

import 'dart:math';
import 'dart:ui';
import 'enums.dart';

/// 2D position for diagram rendering.
///
/// Represents an (x, y) coordinate in a 2D plane, used for positioning
/// components in connection diagrams and layout calculations.
class Position2D {
  /// X coordinate (horizontal position)
  final double x;

  /// Y coordinate (vertical position)
  final double y;

  const Position2D(this.x, this.y);

  /// Creates a position at the origin (0, 0)
  const Position2D.origin() : this(0, 0);

  /// Adds two positions component-wise
  Position2D operator +(Position2D other) {
    return Position2D(x + other.x, y + other.y);
  }

  /// Subtracts two positions component-wise
  Position2D operator -(Position2D other) {
    return Position2D(x - other.x, y - other.y);
  }

  /// Scales position by a scalar factor
  Position2D operator *(double scalar) {
    return Position2D(x * scalar, y * scalar);
  }

  /// Calculates Euclidean distance to another position
  double distanceTo(Position2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Converts to Flutter Offset for rendering
  Offset toOffset() => Offset(x, y);

  /// Creates from Flutter Offset
  factory Position2D.fromOffset(Offset offset) {
    return Position2D(offset.dx, offset.dy);
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  /// JSON deserialization
  factory Position2D.fromJson(Map<String, dynamic> json) {
    return Position2D(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position2D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Position2D($x, $y)';

  /// Creates a copy with optional parameter overrides
  Position2D copyWith({double? x, double? y}) {
    return Position2D(x ?? this.x, y ?? this.y);
  }
}

/// 3D position for physical installation planning.
///
/// Represents an (x, y, z) coordinate in 3D space, used for tower layout
/// and physical component positioning in the real installation.
class Position3D {
  /// X coordinate (east-west position in meters)
  final double x;

  /// Y coordinate (north-south position in meters)
  final double y;

  /// Z coordinate (vertical elevation in meters)
  final double z;

  const Position3D(this.x, this.y, this.z);

  /// Creates a position at the origin (0, 0, 0)
  const Position3D.origin() : this(0, 0, 0);

  /// Adds two positions component-wise
  Position3D operator +(Position3D other) {
    return Position3D(x + other.x, y + other.y, z + other.z);
  }

  /// Subtracts two positions component-wise
  Position3D operator -(Position3D other) {
    return Position3D(x - other.x, y - other.y, z - other.z);
  }

  /// Scales position by a scalar factor
  Position3D operator *(double scalar) {
    return Position3D(x * scalar, y * scalar, z * scalar);
  }

  /// Calculates Euclidean distance to another position
  double distanceTo(Position3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Projects to 2D by dropping Z coordinate
  Position2D projectToXY() => Position2D(x, y);

  /// Projects to 2D by dropping Y coordinate (side view)
  Position2D projectToXZ() => Position2D(x, z);

  /// JSON serialization
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  /// JSON deserialization
  factory Position3D.fromJson(Map<String, dynamic> json) {
    return Position3D(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['z'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position3D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Position3D($x, $y, $z)';

  /// Creates a copy with optional parameter overrides
  Position3D copyWith({double? x, double? y, double? z}) {
    return Position3D(x ?? this.x, y ?? this.y, z ?? this.z);
  }
}

/// Physical connection point on a device.
///
/// Represents a specific location where wires can be connected to a device,
/// such as a terminal block position, relay contact, or motor winding connection.
class PhysicalConnectionPoint {
  /// Unique identifier for this connection point
  final String id;

  /// Human-readable label (e.g., "L1", "COM", "NO", "U1")
  final String label;

  /// Functional group this connection belongs to
  final ConnectionGroup group;

  /// 2D position for diagram rendering (relative to parent device)
  final Position2D diagramPosition;

  /// 3D position for installation planning (absolute coordinates)
  final Position3D? physicalPosition;

  /// Optional description of function (e.g., "Phase 1 input", "Normally Open contact")
  final String? description;

  const PhysicalConnectionPoint({
    required this.id,
    required this.label,
    required this.group,
    required this.diagramPosition,
    this.physicalPosition,
    this.description,
  });

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'group': group.name,
        'diagramPosition': diagramPosition.toJson(),
        if (physicalPosition != null)
          'physicalPosition': physicalPosition!.toJson(),
        if (description != null) 'description': description,
      };

  /// JSON deserialization
  factory PhysicalConnectionPoint.fromJson(Map<String, dynamic> json) {
    return PhysicalConnectionPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      group: ConnectionGroup.values.byName(json['group'] as String),
      diagramPosition:
          Position2D.fromJson(json['diagramPosition'] as Map<String, dynamic>),
      physicalPosition: json['physicalPosition'] != null
          ? Position3D.fromJson(json['physicalPosition'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalConnectionPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          group == other.group &&
          diagramPosition == other.diagramPosition &&
          physicalPosition == other.physicalPosition &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        group,
        diagramPosition,
        physicalPosition,
        description,
      );

  @override
  String toString() => 'PhysicalConnectionPoint($label, $group)';

  /// Creates a copy with optional parameter overrides
  PhysicalConnectionPoint copyWith({
    String? id,
    String? label,
    ConnectionGroup? group,
    Position2D? diagramPosition,
    Position3D? physicalPosition,
    String? description,
  }) {
    return PhysicalConnectionPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      group: group ?? this.group,
      diagramPosition: diagramPosition ?? this.diagramPosition,
      physicalPosition: physicalPosition ?? this.physicalPosition,
      description: description ?? this.description,
    );
  }
}

/// View type for diagram rendering.
///
/// Determines how the connection diagram should be rendered, affecting
/// the level of detail and information displayed.
enum ViewType {
  /// Simplified schematic view showing logical connections
  schematic,

  /// Detailed wiring view showing physical wire routing
  wiring,

  /// Installation view showing physical layout in tower
  installation,

  /// Compact overview for documentation
  overview,
}

extension ViewTypeExtension on ViewType {
  /// Human-readable display name
  String get displayName {
    switch (this) {
      case ViewType.schematic:
        return 'Schematic';
      case ViewType.wiring:
        return 'Wiring Diagram';
      case ViewType.installation:
        return 'Installation Layout';
      case ViewType.overview:
        return 'Overview';
    }
  }

  /// Whether this view shows detailed wire routing
  bool get showsWireRouting {
    return this == ViewType.wiring || this == ViewType.installation;
  }

  /// Whether this view includes physical dimensions
  bool get includesPhysicalDimensions {
    return this == ViewType.installation;
  }
}
