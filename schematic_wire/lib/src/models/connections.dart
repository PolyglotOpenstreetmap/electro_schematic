// lib/models/physical/connections.dart

import 'enums.dart';
import 'power_grid.dart';

/// Wire specification for physical connections.
///
/// Defines the electrical and physical characteristics of a wire
/// used to connect components.
class WireSpec {
  /// Wire gauge (AWG or mm²)
  final String gauge;

  /// Wire color for identification
  final String color;

  /// Maximum current capacity in amperes
  final double maxCurrentAmps;

  /// Wire type (stranded, solid, shielded, etc.)
  final String wireType;

  const WireSpec({
    required this.gauge,
    required this.color,
    required this.maxCurrentAmps,
    this.wireType = 'Stranded copper',
  });

  /// Factory: Standard 1.5mm² wire (common for 24V DC)
  factory WireSpec.standard1_5mm({required String color}) {
    return WireSpec(
      gauge: '1.5mm²',
      color: color,
      maxCurrentAmps: 16,
      wireType: 'Stranded copper',
    );
  }

  /// Factory: Standard 2.5mm² wire (common for AC mains)
  factory WireSpec.standard2_5mm({required String color}) {
    return WireSpec(
      gauge: '2.5mm²',
      color: color,
      maxCurrentAmps: 25,
      wireType: 'Stranded copper',
    );
  }

  Map<String, dynamic> toJson() => {
        'gauge': gauge,
        'color': color,
        'maxCurrentAmps': maxCurrentAmps,
        'wireType': wireType,
      };

  factory WireSpec.fromJson(Map<String, dynamic> json) {
    return WireSpec(
      gauge: json['gauge'] as String,
      color: json['color'] as String,
      maxCurrentAmps: (json['maxCurrentAmps'] as num).toDouble(),
      wireType: json['wireType'] as String? ?? 'Stranded copper',
    );
  }

  @override
  String toString() => '$gauge $color ($maxCurrentAmps A)';
}

/// Physical connection between two points.
///
/// Represents a wire connecting a source terminal to a destination terminal.
class Connection {
  /// Unique identifier for this connection
  final String id;

  /// Source device ID
  final String sourceDeviceId;

  /// Source terminal ID
  final String sourceTerminalId;

  /// Destination device ID
  final String destDeviceId;

  /// Destination terminal ID
  final String destTerminalId;

  /// Wire specification
  final WireSpec wireSpec;

  /// Connection group classification
  final ConnectionGroup group;

  /// Wire length in meters (if known)
  final double? lengthMeters;

  /// Optional label for this connection
  final String? label;

  /// Power phase assignment for this connection (L1, L2, L3, N, PE, etc.)
  ///
  /// Used for power connections to track which electrical phase this wire carries.
  /// Null for non-power connections (communication, mechanical, etc.).
  final PowerPhase? phase;

  /// Whether this connection uses the shared horizontal corridor routing.
  ///
  /// When true (default), the wire is routed through the auto-distributed
  /// corridor system and included in bundle label rendering.
  /// When false, the wire uses its own point-to-point routing method
  /// (e.g. striker wires, clock cable wires) and is excluded from corridor logic.
  final bool usesCorridorRouting;

  const Connection({
    required this.id,
    required this.sourceDeviceId,
    required this.sourceTerminalId,
    required this.destDeviceId,
    required this.destTerminalId,
    required this.wireSpec,
    required this.group,
    this.lengthMeters,
    this.label,
    this.phase,
    this.usesCorridorRouting = true,
  });

  /// Validate this connection for safety and compatibility
  String? validate() {
    // Check if wire gauge is sufficient for the load
    // This is a simplified check - real validation would query device specs
    if (wireSpec.maxCurrentAmps < 1.0) {
      return 'Wire current capacity too low';
    }
    return null; // Valid
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceDeviceId': sourceDeviceId,
        'sourceTerminalId': sourceTerminalId,
        'destDeviceId': destDeviceId,
        'destTerminalId': destTerminalId,
        'wireSpec': wireSpec.toJson(),
        'group': group.name,
        'usesCorridorRouting': usesCorridorRouting,
        if (lengthMeters != null) 'lengthMeters': lengthMeters,
        if (label != null) 'label': label,
        if (phase != null) 'phase': phase!.name,
      };

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      sourceTerminalId: json['sourceTerminalId'] as String,
      destDeviceId: json['destDeviceId'] as String,
      destTerminalId: json['destTerminalId'] as String,
      wireSpec: WireSpec.fromJson(json['wireSpec'] as Map<String, dynamic>),
      group: ConnectionGroup.values.byName(json['group'] as String),
      lengthMeters: json['lengthMeters'] != null
          ? (json['lengthMeters'] as num).toDouble()
          : null,
      label: json['label'] as String?,
      phase: json['phase'] != null
          ? PowerPhase.values.byName(json['phase'] as String)
          : null,
      usesCorridorRouting: json['usesCorridorRouting'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'Connection($sourceDeviceId:$sourceTerminalId → $destDeviceId:$destTerminalId)';

  Connection copyWith({
    String? id,
    String? sourceDeviceId,
    String? sourceTerminalId,
    String? destDeviceId,
    String? destTerminalId,
    WireSpec? wireSpec,
    ConnectionGroup? group,
    double? lengthMeters,
    String? label,
    PowerPhase? phase,
    bool? usesCorridorRouting,
  }) {
    return Connection(
      id: id ?? this.id,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceTerminalId: sourceTerminalId ?? this.sourceTerminalId,
      destDeviceId: destDeviceId ?? this.destDeviceId,
      destTerminalId: destTerminalId ?? this.destTerminalId,
      wireSpec: wireSpec ?? this.wireSpec,
      group: group ?? this.group,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      label: label ?? this.label,
      phase: phase ?? this.phase,
      usesCorridorRouting: usesCorridorRouting ?? this.usesCorridorRouting,
    );
  }
}

// StrikerConnection and MotorConnection moved to lib/models/domain/domain_connections.dart

/// Connection validation errors.
class ConnectionValidationError {
  /// Connection ID with the error
  final String connectionId;

  /// Error severity (error, warning, info)
  final String severity;

  /// Human-readable error message
  final String message;

  /// Optional fix suggestion
  final String? suggestion;

  const ConnectionValidationError({
    required this.connectionId,
    required this.severity,
    required this.message,
    this.suggestion,
  });

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';

  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'severity': severity,
        'message': message,
        if (suggestion != null) 'suggestion': suggestion,
      };

  factory ConnectionValidationError.fromJson(Map<String, dynamic> json) {
    return ConnectionValidationError(
      connectionId: json['connectionId'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      suggestion: json['suggestion'] as String?,
    );
  }

  @override
  String toString() => '[$severity] $connectionId: $message';
}
