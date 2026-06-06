// packages/electro_schematic/schematic_wire/lib/src/models/connector.dart

/// A single pin in a multi-pin electrical connector.
///
/// Pairs the plug-side terminal (the physical plug on the cable) with the
/// matching socket-side terminal (the receptacle on the equipment).
class ConnectorPort {
  /// Pin designation as printed on the connector housing (e.g. '1', 'A', 'PE').
  final String pinLabel;

  /// [Terminal.id] on the plug-side [TerminalBlock].
  final String plugTerminalId;

  /// [Terminal.id] on the socket-side [TerminalBlock].
  final String socketTerminalId;

  /// Optional description of the signal carried by this pin.
  final String? description;

  const ConnectorPort({
    required this.pinLabel,
    required this.plugTerminalId,
    required this.socketTerminalId,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'pinLabel': pinLabel,
        'plugTerminalId': plugTerminalId,
        'socketTerminalId': socketTerminalId,
        if (description != null) 'description': description,
      };

  factory ConnectorPort.fromJson(Map<String, dynamic> json) => ConnectorPort(
        pinLabel: json['pinLabel'] as String,
        plugTerminalId: json['plugTerminalId'] as String,
        socketTerminalId: json['socketTerminalId'] as String,
        description: json['description'] as String?,
      );

  @override
  String toString() => 'ConnectorPort($pinLabel: $plugTerminalId ↔ $socketTerminalId)';
}

/// A multi-pin electrical connector pairing a plug-side [TerminalBlock] to a
/// socket-side [TerminalBlock].
///
/// Models physical connectors (e.g. Deutsch DT04, M12) as first-class objects.
/// Each pin is a [ConnectorPort] that names the matching terminal IDs on both
/// sides; the diagram painter can render the mating pair as a matched connector
/// symbol rather than a plain wire.
class CableConnector {
  /// Unique identifier for this connector (e.g. 'X1', 'CONN_MOTOR_1').
  final String id;

  /// Label shown on the schematic (e.g. 'X1', 'P1/S1').
  final String label;

  /// [TerminalBlock.id] for the plug side (the cable end).
  final String plugBlockId;

  /// [TerminalBlock.id] for the socket side (the equipment end).
  final String socketBlockId;

  /// Ordered list of pin assignments.
  final List<ConnectorPort> ports;

  /// Optional connector type for reference (e.g. 'Deutsch DT04-4P').
  final String? connectorType;

  /// Optional description.
  final String? description;

  const CableConnector({
    required this.id,
    required this.label,
    required this.plugBlockId,
    required this.socketBlockId,
    required this.ports,
    this.connectorType,
    this.description,
  });

  /// Returns the [ConnectorPort] for [pinLabel], or null if not found.
  ConnectorPort? portByPin(String pinLabel) {
    for (final p in ports) {
      if (p.pinLabel == pinLabel) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'plugBlockId': plugBlockId,
        'socketBlockId': socketBlockId,
        'ports': ports.map((p) => p.toJson()).toList(),
        if (connectorType != null) 'connectorType': connectorType,
        if (description != null) 'description': description,
      };

  factory CableConnector.fromJson(Map<String, dynamic> json) => CableConnector(
        id: json['id'] as String,
        label: json['label'] as String,
        plugBlockId: json['plugBlockId'] as String,
        socketBlockId: json['socketBlockId'] as String,
        ports: (json['ports'] as List)
            .map((e) => ConnectorPort.fromJson(e as Map<String, dynamic>))
            .toList(),
        connectorType: json['connectorType'] as String?,
        description: json['description'] as String?,
      );

  @override
  String toString() => 'CableConnector($label, ${ports.length} pins)';
}
