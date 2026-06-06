// lib/models/physical/terminals.dart

import 'package:collection/collection.dart';
import 'base.dart';
import 'enums.dart';
import 'power_grid.dart';

/// Single electrical terminal connection point.
///
/// MUTABLE: Connection state changes as wiring is configured.
/// Represents a physical screw terminal, spring cage, or other connection
/// point where a wire can be attached.
class Terminal {
  /// Unique identifier for this terminal
  final String id;

  /// Human-readable label (e.g., "L1", "U", "PE")
  final String label;

  /// Functional group this terminal belongs to
  final ConnectionGroup group;

  /// Current wire connected to this terminal (null if unconnected)
  String? connectedWireId;

  /// 2D position for diagram rendering
  final Position2D diagramPosition;

  /// Optional description of function
  final String? description;

  /// Assigned power phase for this terminal (L1, L2, L3, N, PE, etc.)
  ///
  /// For power terminals, indicates which electrical phase this terminal
  /// is connected to. Null for non-power terminals (communication, etc.).
  PowerPhase? assignedPhase;

  Terminal({
    required this.id,
    required this.label,
    required this.group,
    this.connectedWireId,
    required this.diagramPosition,
    this.description,
    this.assignedPhase,
  });

  /// Whether this terminal has a wire connected
  bool get isConnected => connectedWireId != null;

  /// Connect a wire to this terminal
  void connect(String wireId) {
    if (isConnected) {
      throw StateError(
          'Terminal $label already connected to wire $connectedWireId');
    }
    connectedWireId = wireId;
  }

  /// Disconnect the current wire from this terminal
  void disconnect() {
    connectedWireId = null;
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'group': group.name,
        'connectedWireId': connectedWireId,
        'diagramPosition': diagramPosition.toJson(),
        if (description != null) 'description': description,
        if (assignedPhase != null) 'assignedPhase': assignedPhase!.name,
      };

  /// JSON deserialization
  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'] as String,
      label: json['label'] as String,
      group: ConnectionGroup.values.byName(json['group'] as String),
      connectedWireId: json['connectedWireId'] as String?,
      diagramPosition:
          Position2D.fromJson(json['diagramPosition'] as Map<String, dynamic>),
      description: json['description'] as String?,
      assignedPhase: json['assignedPhase'] != null
          ? PowerPhase.values.byName(json['assignedPhase'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Terminal($label, ${isConnected ? "connected to $connectedWireId" : "unconnected"})';
}

/// Group of related terminals (e.g., motor terminals, power input).
///
/// Provides logical grouping and organization for terminals that work together.
class TerminalGroup {
  /// Unique identifier for this group
  final String id;

  /// Human-readable name (e.g., "Motor Windings", "Power Input")
  final String name;

  /// Functional category
  final ConnectionGroup category;

  /// Terminals in this group
  final List<Terminal> terminals;

  /// Optional description of the group's function
  final String? description;

  const TerminalGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.terminals,
    this.description,
  });

  // Motor-type factory methods moved to lib/models/domain/motor_terminal_factories.dart

  /// Get terminal by label
  Terminal? getTerminal(String label) {
    return terminals.firstWhereOrNull((t) => t.label == label);
  }

  /// Get all unconnected terminals
  List<Terminal> get unconnectedTerminals =>
      terminals.where((t) => !t.isConnected).toList();

  /// Get all connected terminals
  List<Terminal> get connectedTerminals =>
      terminals.where((t) => t.isConnected).toList();

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'terminals': terminals.map((t) => t.toJson()).toList(),
        if (description != null) 'description': description,
      };

  /// JSON deserialization
  factory TerminalGroup.fromJson(Map<String, dynamic> json) {
    return TerminalGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ConnectionGroup.values.byName(json['category'] as String),
      terminals: (json['terminals'] as List)
          .map((t) => Terminal.fromJson(t as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
    );
  }

  @override
  String toString() => 'TerminalGroup($name, ${terminals.length} terminals)';
}

/// Physical terminal block or terminal strip.
///
/// Represents a physical assembly containing multiple terminals,
/// such as a DIN-rail mounted terminal block or a motor terminal box.
class TerminalBlock {
  /// Unique identifier for this block
  final String id;

  /// Human-readable name (e.g., "TB1", "Motor Terminal Box")
  final String name;

  /// Terminal groups in this block
  final List<TerminalGroup> groups;

  /// 2D position for diagram rendering
  final Position2D diagramPosition;

  /// 3D position for installation planning
  final Position3D? physicalPosition;

  /// Optional description
  final String? description;

  /// Whether this equipment is existing (true) or new to install (false)
  final bool isExisting;

  /// Whether this block connects to clock tower (for IV3MOD3SRL relay rendering)
  final bool connectsToClockTower;

  /// Explicit render key for painter dispatch.
  ///
  /// When non-null, the diagram painter uses this key to select the drawing
  /// method instead of falling back to `block.id.contains(...)` matching.
  /// See [BlockRenderKeys] for the set of well-known keys.
  final String? blockRenderKey;

  /// Optional device-specific parameters for DeviceRenderer dispatch.
  /// Set by the service layer when building domain blocks; consumed by
  /// [PaginatedDiagramPainter._buildDeviceInstance] to construct a [DeviceInstance].
  final Map<String, dynamic>? deviceParams;

  const TerminalBlock({
    required this.id,
    required this.name,
    required this.groups,
    required this.diagramPosition,
    this.physicalPosition,
    this.description,
    this.isExisting = true,
    this.connectsToClockTower = false,
    this.blockRenderKey,
    this.deviceParams,
  });

  /// Get all terminals across all groups
  List<Terminal> get allTerminals => groups.expand((g) => g.terminals).toList();

  /// Get terminal by label (searches all groups)
  Terminal? getTerminal(String label) {
    for (final group in groups) {
      final terminal = group.getTerminal(label);
      if (terminal != null) return terminal;
    }
    return null;
  }

  /// Get terminal by ID (searches all groups)
  Terminal? getTerminalById(String terminalId) {
    for (final terminal in allTerminals) {
      if (terminal.id == terminalId) return terminal;
    }
    return null;
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groups': groups.map((g) => g.toJson()).toList(),
        'diagramPosition': diagramPosition.toJson(),
        if (physicalPosition != null)
          'physicalPosition': physicalPosition!.toJson(),
        if (description != null) 'description': description,
        'isExisting': isExisting,
        'connectsToClockTower': connectsToClockTower,
        if (blockRenderKey != null) 'blockRenderKey': blockRenderKey,
        if (deviceParams != null) 'deviceParams': deviceParams,
      };

  /// JSON deserialization
  factory TerminalBlock.fromJson(Map<String, dynamic> json) {
    return TerminalBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      groups: (json['groups'] as List)
          .map((g) => TerminalGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      diagramPosition:
          Position2D.fromJson(json['diagramPosition'] as Map<String, dynamic>),
      physicalPosition: json['physicalPosition'] != null
          ? Position3D.fromJson(
              json['physicalPosition'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      isExisting: json['isExisting'] as bool? ?? true,
      connectsToClockTower: json['connectsToClockTower'] as bool? ?? false,
      blockRenderKey: json['blockRenderKey'] as String?,
      deviceParams: json['deviceParams'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'TerminalBlock($name, ${allTerminals.length} terminals)';
}
