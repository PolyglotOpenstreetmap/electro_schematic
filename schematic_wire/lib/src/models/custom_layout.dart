// lib/models/physical/custom_layout.dart

import 'package:flutter/material.dart' show Color;
import 'base.dart';

/// Custom connection drawn by user between terminal blocks.
///
/// Represents a manual connection with visual styling (3 parallel lines
/// for power connections) that can be added by the user.
class CustomConnection {
  /// Unique identifier
  final String id;

  /// Source terminal block ID
  final String sourceBlockId;

  /// Destination terminal block ID
  final String destBlockId;

  /// Optional source terminal ID (null = block center)
  final String? sourceTerminalId;

  /// Optional destination terminal ID (null = block center)
  final String? destTerminalId;

  /// Connection style (single, triple, etc.)
  final ConnectionStyle style;

  /// Line color
  final Color color;

  /// Line width (for each parallel line)
  final double strokeWidth;

  /// User-provided label
  final String? label;

  const CustomConnection({
    required this.id,
    required this.sourceBlockId,
    required this.destBlockId,
    this.sourceTerminalId,
    this.destTerminalId,
    this.style = ConnectionStyle.triple,
    this.color = const Color(0xFF000000),
    this.strokeWidth = 2.5,
    this.label,
  });

  /// Create from JSON
  factory CustomConnection.fromJson(Map<String, dynamic> json) {
    return CustomConnection(
      id: json['id'] as String,
      sourceBlockId: json['sourceBlockId'] as String,
      destBlockId: json['destBlockId'] as String,
      sourceTerminalId: json['sourceTerminalId'] as String?,
      destTerminalId: json['destTerminalId'] as String?,
      style: ConnectionStyle.values.byName(
        json['style'] as String? ?? 'triple',
      ),
      color: Color(json['color'] as int? ?? 0xFF000000),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.5,
      label: json['label'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceBlockId': sourceBlockId,
      'destBlockId': destBlockId,
      'sourceTerminalId': sourceTerminalId,
      'destTerminalId': destTerminalId,
      'style': style.name,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'label': label,
    };
  }

  /// Create a copy with modified fields
  CustomConnection copyWith({
    String? id,
    String? sourceBlockId,
    String? destBlockId,
    String? sourceTerminalId,
    String? destTerminalId,
    ConnectionStyle? style,
    Color? color,
    double? strokeWidth,
    String? label,
  }) {
    return CustomConnection(
      id: id ?? this.id,
      sourceBlockId: sourceBlockId ?? this.sourceBlockId,
      destBlockId: destBlockId ?? this.destBlockId,
      sourceTerminalId: sourceTerminalId ?? this.sourceTerminalId,
      destTerminalId: destTerminalId ?? this.destTerminalId,
      style: style ?? this.style,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      label: label ?? this.label,
    );
  }
}

/// Connection visual style
enum ConnectionStyle {
  /// Single line
  single,

  /// Three parallel lines (for 3-phase power)
  triple,

  /// Dashed line
  dashed,
}

/// Custom layout configuration storing user-defined terminal block positions.
///
/// This allows users to save their custom node positions for the wiring diagram.
/// Connections are auto-generated from topology and not saved in the layout.
class DiagramLayout {
  /// Layout identifier
  final String id;

  /// Layout name
  final String name;

  /// Layout description
  final String? description;

  /// Custom terminal block positions (block ID → Position)
  final Map<String, Position2D> blockPositions;

  /// Custom wire bundle Y offsets (bundle ID → Y offset delta)
  final Map<String, double> bundleYOverrides;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime modifiedAt;

  DiagramLayout({
    required this.id,
    required this.name,
    this.description,
    Map<String, Position2D>? blockPositions,
    Map<String, double>? bundleYOverrides,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : blockPositions = blockPositions ?? {},
        bundleYOverrides = bundleYOverrides ?? {},
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create from JSON
  factory DiagramLayout.fromJson(Map<String, dynamic> json) {
    return DiagramLayout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      blockPositions: (json['blockPositions'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    key,
                    Position2D.fromJson(value as Map<String, dynamic>),
                  )) ??
          {},
      bundleYOverrides: (json['bundleYOverrides'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'blockPositions': blockPositions.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'bundleYOverrides': bundleYOverrides,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  DiagramLayout copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, Position2D>? blockPositions,
    Map<String, double>? bundleYOverrides,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DiagramLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      blockPositions: blockPositions ?? this.blockPositions,
      bundleYOverrides: bundleYOverrides ?? this.bundleYOverrides,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Update block position
  DiagramLayout updateBlockPosition(String blockId, Position2D position) {
    final newPositions = Map<String, Position2D>.from(blockPositions);
    newPositions[blockId] = position;
    return copyWith(
      blockPositions: newPositions,
      modifiedAt: DateTime.now(),
    );
  }

  /// Update wire bundle Y offset
  DiagramLayout updateBundleYOverride(String bundleId, double yOffset) {
    final newOverrides = Map<String, double>.from(bundleYOverrides);
    newOverrides[bundleId] = yOffset;
    return copyWith(
      bundleYOverrides: newOverrides,
      modifiedAt: DateTime.now(),
    );
  }
}
