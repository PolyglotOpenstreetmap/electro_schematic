// lib/models/physical/outputs.dart

import 'enums.dart';
import 'terminals.dart';
import 'base.dart';

/// Base class for control device outputs.
///
/// Represents a physical output channel on a control device (relay, FET, TRIAC).
abstract class BaseOutput {
  /// Unique identifier for this output
  final String id;

  /// Output channel number (1-based)
  final int channel;

  /// Output type (relay, FET, TRIAC, continuous)
  final OutputType type;

  /// Maximum current rating in amperes
  final double maxCurrentAmps;

  /// Terminal connections for this output
  final TerminalGroup terminals;

  /// Whether this output is currently assigned to a load
  final bool isAssigned;

  /// ID of connected load (striker, motor, etc.), if any
  final String? connectedLoadId;

  const BaseOutput({
    required this.id,
    required this.channel,
    required this.type,
    required this.maxCurrentAmps,
    required this.terminals,
    this.isAssigned = false,
    this.connectedLoadId,
  });

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'type': type.name,
        'maxCurrentAmps': maxCurrentAmps,
        'terminals': terminals.toJson(),
        'isAssigned': isAssigned,
        if (connectedLoadId != null) 'connectedLoadId': connectedLoadId,
      };

  @override
  String toString() => 'Output $channel (${type.displayName}, ${maxCurrentAmps}A)';
}

/// Relay output with normally-open and normally-closed contacts.
class RelayOutput extends BaseOutput {
  /// Whether this is a changeover relay (has both NO and NC)
  final bool hasChangeoverContact;

  const RelayOutput({
    required super.id,
    required super.channel,
    required super.maxCurrentAmps,
    required super.terminals,
    super.isAssigned,
    super.connectedLoadId,
    this.hasChangeoverContact = true,
  }) : super(type: OutputType.relay);

  /// Factory: Standard relay with NO/NC contacts
  factory RelayOutput.standard({
    required String id,
    required int channel,
    required double maxCurrentAmps,
    required Position2D basePosition,
  }) {
    return RelayOutput(
      id: id,
      channel: channel,
      maxCurrentAmps: maxCurrentAmps,
      hasChangeoverContact: true,
      terminals: TerminalGroup(
        id: '${id}_terminals',
        name: 'Relay $channel',
        category: ConnectionGroup.control,
        terminals: [
          Terminal(
            id: '${id}_com',
            label: 'COM',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(0, 0),
            description: 'Common',
          ),
          Terminal(
            id: '${id}_no',
            label: 'NO',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(15, 0),
            description: 'Normally Open',
          ),
          Terminal(
            id: '${id}_nc',
            label: 'NC',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(30, 0),
            description: 'Normally Closed',
          ),
        ],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hasChangeoverContact': hasChangeoverContact,
      };

  factory RelayOutput.fromJson(Map<String, dynamic> json) {
    return RelayOutput(
      id: json['id'] as String,
      channel: json['channel'] as int,
      maxCurrentAmps: (json['maxCurrentAmps'] as num).toDouble(),
      terminals: TerminalGroup.fromJson(
          json['terminals'] as Map<String, dynamic>),
      isAssigned: json['isAssigned'] as bool? ?? false,
      connectedLoadId: json['connectedLoadId'] as String?,
      hasChangeoverContact: json['hasChangeoverContact'] as bool? ?? true,
    );
  }
}

/// FET (Field-Effect Transistor) solid-state output for DC switching.
class FETOutput extends BaseOutput {
  /// Whether this FET has flyback diode protection
  final bool hasFlybackProtection;

  const FETOutput({
    required super.id,
    required super.channel,
    required super.maxCurrentAmps,
    required super.terminals,
    super.isAssigned,
    super.connectedLoadId,
    this.hasFlybackProtection = true,
  }) : super(type: OutputType.fet);

  /// Factory: Standard FET output with flyback protection
  factory FETOutput.standard({
    required String id,
    required int channel,
    required double maxCurrentAmps,
    required Position2D basePosition,
  }) {
    return FETOutput(
      id: id,
      channel: channel,
      maxCurrentAmps: maxCurrentAmps,
      hasFlybackProtection: true,
      terminals: TerminalGroup(
        id: '${id}_terminals',
        name: 'FET $channel',
        category: ConnectionGroup.control,
        terminals: [
          Terminal(
            id: '${id}_plus',
            label: '+',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(0, 0),
            description: 'Positive output',
          ),
          Terminal(
            id: '${id}_minus',
            label: '-',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(15, 0),
            description: 'Switched ground',
          ),
        ],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hasFlybackProtection': hasFlybackProtection,
      };

  factory FETOutput.fromJson(Map<String, dynamic> json) {
    return FETOutput(
      id: json['id'] as String,
      channel: json['channel'] as int,
      maxCurrentAmps: (json['maxCurrentAmps'] as num).toDouble(),
      terminals: TerminalGroup.fromJson(
          json['terminals'] as Map<String, dynamic>),
      isAssigned: json['isAssigned'] as bool? ?? false,
      connectedLoadId: json['connectedLoadId'] as String?,
      hasFlybackProtection: json['hasFlybackProtection'] as bool? ?? true,
    );
  }
}

/// TRIAC solid-state output for AC switching.
class TRIACOutput extends BaseOutput {
  /// Whether this TRIAC has zero-crossing detection
  final bool hasZeroCrossing;

  const TRIACOutput({
    required super.id,
    required super.channel,
    required super.maxCurrentAmps,
    required super.terminals,
    super.isAssigned,
    super.connectedLoadId,
    this.hasZeroCrossing = true,
  }) : super(type: OutputType.triac);

  /// Factory: Standard TRIAC output with zero-crossing
  factory TRIACOutput.standard({
    required String id,
    required int channel,
    required double maxCurrentAmps,
    required Position2D basePosition,
  }) {
    return TRIACOutput(
      id: id,
      channel: channel,
      maxCurrentAmps: maxCurrentAmps,
      hasZeroCrossing: true,
      terminals: TerminalGroup(
        id: '${id}_terminals',
        name: 'TRIAC $channel',
        category: ConnectionGroup.control,
        terminals: [
          Terminal(
            id: '${id}_l',
            label: 'L',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(0, 0),
            description: 'Line input',
          ),
          Terminal(
            id: '${id}_load',
            label: 'LOAD',
            group: ConnectionGroup.control,
            diagramPosition: basePosition + const Position2D(15, 0),
            description: 'Switched load output',
          ),
        ],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hasZeroCrossing': hasZeroCrossing,
      };

  factory TRIACOutput.fromJson(Map<String, dynamic> json) {
    return TRIACOutput(
      id: json['id'] as String,
      channel: json['channel'] as int,
      maxCurrentAmps: (json['maxCurrentAmps'] as num).toDouble(),
      terminals: TerminalGroup.fromJson(
          json['terminals'] as Map<String, dynamic>),
      isAssigned: json['isAssigned'] as bool? ?? false,
      connectedLoadId: json['connectedLoadId'] as String?,
      hasZeroCrossing: json['hasZeroCrossing'] as bool? ?? true,
    );
  }
}
