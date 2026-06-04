// lib/models/physical/power_grid.dart

import 'dart:ui' show Color;

/// Power phases used in electrical wiring diagrams.
///
/// Supports both AC (alternating current) and DC (direct current) power
/// phases with IEC 60446 standardized color coding for international compliance.
enum PowerPhase {
  /// AC Line 1 (Brown)
  l1,

  /// AC Line 2 (Black)
  l2,

  /// AC Line 3 (Grey)
  l3,

  /// AC Neutral (Blue)
  n,

  /// Protective Earth / Ground (Green/Yellow)
  pe,

  /// DC 0V / Ground (Black)
  dc0v,

  /// DC +12V (Red)
  dc12v,

  /// DC +24V (Red)
  dc24v,

  /// DC +312V (Dark Red)
  dc312v,
}

/// Extension methods for [PowerPhase] to provide IEC 60446 color codes
/// and display labels.
extension PowerPhaseExtension on PowerPhase {
  /// IEC 60446 standard color code for this power phase.
  ///
  /// Returns the primary color as a [Color] object for wire/conductor
  /// representation in wiring diagrams.
  ///
  /// Note: PE (protective earth) uses green as primary color. The yellow
  /// striping should be handled separately in rendering logic.
  Color get iecColorCode {
    switch (this) {
      case PowerPhase.l1:
        return const Color(0xFF8B4513); // Brown
      case PowerPhase.l2:
        return const Color(0xFF000000); // Black
      case PowerPhase.l3:
        return const Color(0xFF808080); // Grey
      case PowerPhase.n:
        return const Color(0xFF0000FF); // Blue
      case PowerPhase.pe:
        return const Color(0xFF00FF00); // Green (with yellow stripes)
      case PowerPhase.dc0v:
        return const Color(0xFF000000); // Black
      case PowerPhase.dc12v:
        return const Color(0xFFFF0000); // Red
      case PowerPhase.dc24v:
        return const Color(0xFFFF0000); // Red
      case PowerPhase.dc312v:
        return const Color(0xFF8B0000); // Dark Red
    }
  }

  /// Secondary color for striped conductors (currently only PE).
  ///
  /// Returns null for solid-color conductors, or the stripe color
  /// for conductors that require two-color representation.
  Color? get secondaryColorCode {
    if (this == PowerPhase.pe) {
      return const Color(0xFFFFFF00); // Yellow stripes on green
    }
    return null;
  }

  /// Human-readable display label for this power phase.
  ///
  /// Returns standard electrical notation:
  /// - AC: "L1", "L2", "L3", "N", "PE"
  /// - DC: "0V", "+12V", "+24V", "+312V"
  String get displayLabel {
    switch (this) {
      case PowerPhase.l1:
        return 'L1';
      case PowerPhase.l2:
        return 'L2';
      case PowerPhase.l3:
        return 'L3';
      case PowerPhase.n:
        return 'N';
      case PowerPhase.pe:
        return 'PE';
      case PowerPhase.dc0v:
        return '0V';
      case PowerPhase.dc12v:
        return '+12V';
      case PowerPhase.dc24v:
        return '+24V';
      case PowerPhase.dc312v:
        return '+312V';
    }
  }

  /// Whether this is an AC phase (L1, L2, L3, N, PE).
  bool get isAC {
    return this == PowerPhase.l1 ||
        this == PowerPhase.l2 ||
        this == PowerPhase.l3 ||
        this == PowerPhase.n ||
        this == PowerPhase.pe;
  }

  /// Whether this is a DC phase (dc0v, dc12v, dc24v, dc312v).
  bool get isDC {
    return !isAC;
  }

  /// Whether this is a protective conductor (PE or DC 0V).
  bool get isProtective {
    return this == PowerPhase.pe || this == PowerPhase.dc0v;
  }
}

/// Power grid types representing different electrical supply configurations.
///
/// Covers common AC three-phase, AC single-phase, and DC power grid
/// configurations used in bell tower installations worldwide.
enum PowerGridType {
  /// 3-phase 400V AC (Europe, most of world)
  ///
  /// Three live conductors (L1, L2, L3) at 400V line-to-line,
  /// 230V line-to-neutral, with neutral (N) and protective earth (PE).
  ac3x400v,

  /// 3-phase 230V AC (older European installations)
  ///
  /// Three live conductors at 230V line-to-line with neutral and PE.
  /// Being phased out in favor of 3x400V.
  ac3x230v,

  /// Single-phase 230V AC (Europe, most of world)
  ///
  /// Single live conductor (L1) at 230V to neutral, with N and PE.
  ac1x230v,

  /// Single-phase 110V AC (North America, Japan)
  ///
  /// Single live conductor (L1) at 110V to neutral, with N and PE.
  ac1x110v,

  /// 2-phase 220V AC (North America split-phase)
  ///
  /// Two live conductors (L1, L2) at 220V line-to-line,
  /// 110V line-to-neutral, with N and PE.
  ac2x220v,

  /// AC 24V power supply
  ///
  /// Low-voltage AC for control circuits, Apollo master clock, and actuators.
  /// Common in US installations for control wiring.
  ac24v,

  /// DC 12V power supply
  ///
  /// Low-voltage DC for control circuits and small strikers.
  dc12v,

  /// DC 24V power supply
  ///
  /// Standard DC voltage for control circuits, strikers, and actuators.
  dc24v,

  /// DC 312V power supply
  ///
  /// High-voltage DC for heavy-duty bell motors and actuators.
  /// Typically rectified from 3-phase AC.
  dc312v,
}

/// Extension methods for [PowerGridType] to provide notation strings
/// and available phases.
extension PowerGridTypeExtension on PowerGridType {
  /// Standard notation string for this power grid type.
  ///
  /// Returns electrical shorthand notation (e.g., "3x400V", "DC24V")
  /// suitable for diagrams and technical documentation.
  String get notation {
    switch (this) {
      case PowerGridType.ac3x400v:
        return '3×400V';
      case PowerGridType.ac3x230v:
        return '3×230V';
      case PowerGridType.ac1x230v:
        return '1×230V';
      case PowerGridType.ac1x110v:
        return '1×110V';
      case PowerGridType.ac2x220v:
        return '2×220V';
      case PowerGridType.ac24v:
        return 'AC 24V';
      case PowerGridType.dc12v:
        return 'DC 12V';
      case PowerGridType.dc24v:
        return 'DC 24V';
      case PowerGridType.dc312v:
        return 'DC 312V';
    }
  }

  /// List of power phases available in this grid type.
  ///
  /// Returns all conductors/phases present in this power configuration,
  /// in standard sequence order for wiring diagrams.
  List<PowerPhase> get availablePhases {
    switch (this) {
      case PowerGridType.ac3x400v:
      case PowerGridType.ac3x230v:
        return [
          PowerPhase.l1,
          PowerPhase.l2,
          PowerPhase.l3,
          PowerPhase.n,
          PowerPhase.pe,
        ];
      case PowerGridType.ac1x230v:
      case PowerGridType.ac1x110v:
      case PowerGridType.ac24v:
        return [
          PowerPhase.l1,
          PowerPhase.n,
          PowerPhase.pe,
        ];
      case PowerGridType.ac2x220v:
        return [
          PowerPhase.l1,
          PowerPhase.l2,
          PowerPhase.n,
          PowerPhase.pe,
        ];
      case PowerGridType.dc12v:
        return [
          PowerPhase.dc12v,
          PowerPhase.dc0v,
        ];
      case PowerGridType.dc24v:
        return [
          PowerPhase.dc24v,
          PowerPhase.dc0v,
        ];
      case PowerGridType.dc312v:
        return [
          PowerPhase.dc312v,
          PowerPhase.dc0v,
        ];
    }
  }

  /// Nominal voltage of this power grid in volts.
  ///
  /// Returns the line-to-line voltage for AC systems,
  /// or the positive rail voltage for DC systems.
  int get nominalVoltage {
    switch (this) {
      case PowerGridType.ac3x400v:
        return 400;
      case PowerGridType.ac3x230v:
      case PowerGridType.ac1x230v:
        return 230;
      case PowerGridType.ac2x220v:
        return 220;
      case PowerGridType.ac1x110v:
        return 110;
      case PowerGridType.ac24v:
      case PowerGridType.dc24v:
        return 24;
      case PowerGridType.dc12v:
        return 12;
      case PowerGridType.dc312v:
        return 312;
    }
  }

  /// Frequency in Hertz for AC grids, 0 for DC grids.
  ///
  /// Returns 50 Hz for European AC systems, 60 Hz for North American
  /// AC systems, and 0 for DC systems.
  int get frequency {
    switch (this) {
      case PowerGridType.ac3x400v:
      case PowerGridType.ac3x230v:
      case PowerGridType.ac1x230v:
        return 50; // Europe, most of world
      case PowerGridType.ac1x110v:
      case PowerGridType.ac2x220v:
      case PowerGridType.ac24v:
        return 60; // North America
      case PowerGridType.dc12v:
      case PowerGridType.dc24v:
      case PowerGridType.dc312v:
        return 0; // DC has no frequency
    }
  }

  /// Whether this is an AC power grid.
  bool get isAC {
    return this == PowerGridType.ac3x400v ||
        this == PowerGridType.ac3x230v ||
        this == PowerGridType.ac1x230v ||
        this == PowerGridType.ac1x110v ||
        this == PowerGridType.ac2x220v ||
        this == PowerGridType.ac24v;
  }

  /// Whether this is a DC power grid.
  bool get isDC {
    return !isAC;
  }

  /// Whether this is a three-phase grid.
  bool get isThreePhase {
    return this == PowerGridType.ac3x400v || this == PowerGridType.ac3x230v;
  }
}

/// Represents a power grid configuration for wiring diagrams.
///
/// Encapsulates the electrical supply characteristics including voltage,
/// frequency, and available phases. Used for generating accurate wiring
/// diagrams and validating equipment compatibility.
class PowerGrid {
  /// Type of power grid configuration.
  final PowerGridType type;

  /// Standard notation string for display (e.g., "3×400V", "DC 24V").
  final String notation;

  /// List of available power phases in this grid.
  final List<PowerPhase> availablePhases;

  /// Frequency in Hertz (50 or 60 for AC, 0 for DC).
  final int frequency;

  /// Creates a power grid with explicit configuration.
  ///
  /// For most cases, prefer using factory constructors like
  /// [PowerGrid.ac3x400v] or [PowerGrid.dc24v] which provide
  /// standard configurations.
  const PowerGrid({
    required this.type,
    required this.notation,
    required this.availablePhases,
    required this.frequency,
  });

  /// Creates a 3-phase 400V AC power grid (50 Hz, Europe).
  ///
  /// Standard European three-phase supply: L1, L2, L3, N, PE
  /// - Line-to-line: 400V
  /// - Line-to-neutral: 230V
  /// - Frequency: 50 Hz
  factory PowerGrid.ac3x400v() {
    return PowerGrid(
      type: PowerGridType.ac3x400v,
      notation: PowerGridType.ac3x400v.notation,
      availablePhases: PowerGridType.ac3x400v.availablePhases,
      frequency: 50,
    );
  }

  /// Creates a 3-phase 230V AC power grid (50 Hz, older European).
  ///
  /// Older European three-phase supply: L1, L2, L3, N, PE
  /// - Line-to-line: 230V
  /// - Frequency: 50 Hz
  factory PowerGrid.ac3x230v() {
    return PowerGrid(
      type: PowerGridType.ac3x230v,
      notation: PowerGridType.ac3x230v.notation,
      availablePhases: PowerGridType.ac3x230v.availablePhases,
      frequency: 50,
    );
  }

  /// Creates a single-phase 230V AC power grid (50 Hz, Europe).
  ///
  /// Standard European single-phase supply: L1, N, PE
  /// - Voltage: 230V
  /// - Frequency: 50 Hz
  factory PowerGrid.ac1x230v() {
    return PowerGrid(
      type: PowerGridType.ac1x230v,
      notation: PowerGridType.ac1x230v.notation,
      availablePhases: PowerGridType.ac1x230v.availablePhases,
      frequency: 50,
    );
  }

  /// Creates a single-phase 110V AC power grid (60 Hz, North America/Japan).
  ///
  /// North American/Japanese single-phase supply: L1, N, PE
  /// - Voltage: 110V
  /// - Frequency: 60 Hz
  factory PowerGrid.ac1x110v() {
    return PowerGrid(
      type: PowerGridType.ac1x110v,
      notation: PowerGridType.ac1x110v.notation,
      availablePhases: PowerGridType.ac1x110v.availablePhases,
      frequency: 60,
    );
  }

  /// Creates a 2-phase 220V AC power grid (60 Hz, North America).
  ///
  /// North American split-phase supply: L1, L2, N, PE
  /// - Line-to-line: 220V
  /// - Line-to-neutral: 110V
  /// - Frequency: 60 Hz
  factory PowerGrid.ac2x220v() {
    return PowerGrid(
      type: PowerGridType.ac2x220v,
      notation: PowerGridType.ac2x220v.notation,
      availablePhases: PowerGridType.ac2x220v.availablePhases,
      frequency: 60,
    );
  }

  /// Creates a 24V AC power grid (60 Hz, control circuits).
  ///
  /// Low-voltage AC supply for control circuits and Apollo: L1, N, PE
  /// - Voltage: 24V AC
  /// - Frequency: 60 Hz
  /// - Common in US installations for control wiring
  factory PowerGrid.ac24v() {
    return PowerGrid(
      type: PowerGridType.ac24v,
      notation: PowerGridType.ac24v.notation,
      availablePhases: PowerGridType.ac24v.availablePhases,
      frequency: 60,
    );
  }

  /// Creates a DC 12V power grid.
  ///
  /// Low-voltage DC supply for control circuits: +12V, 0V
  factory PowerGrid.dc12v() {
    return const PowerGrid(
      type: PowerGridType.dc12v,
      notation: 'DC 12V',
      availablePhases: [PowerPhase.dc12v, PowerPhase.dc0v],
      frequency: 0,
    );
  }

  /// Creates a DC 24V power grid.
  ///
  /// Standard DC supply for strikers and control circuits: +24V, 0V
  factory PowerGrid.dc24v() {
    return const PowerGrid(
      type: PowerGridType.dc24v,
      notation: 'DC 24V',
      availablePhases: [PowerPhase.dc24v, PowerPhase.dc0v],
      frequency: 0,
    );
  }

  /// Creates a DC 312V power grid.
  ///
  /// High-voltage DC supply for heavy-duty motors: +312V, 0V
  /// (Rectified from 3-phase 400V AC)
  factory PowerGrid.dc312v() {
    return const PowerGrid(
      type: PowerGridType.dc312v,
      notation: 'DC 312V',
      availablePhases: [PowerPhase.dc312v, PowerPhase.dc0v],
      frequency: 0,
    );
  }

  /// Nominal voltage of this power grid in volts.
  int get nominalVoltage => type.nominalVoltage;

  /// Whether this is an AC power grid.
  bool get isAC => type.isAC;

  /// Whether this is a DC power grid.
  bool get isDC => type.isDC;

  /// Whether this is a three-phase AC grid.
  bool get isThreePhase => type.isThreePhase;

  /// Checks if a specific phase is available in this grid.
  bool hasPhase(PowerPhase phase) {
    return availablePhases.contains(phase);
  }

  /// Validates if this power grid is compatible with a required voltage.
  ///
  /// For AC grids, accepts both line-to-line and line-to-neutral voltages.
  /// For DC grids, checks exact voltage match.
  bool isCompatibleWithVoltage(int requiredVoltage) {
    if (isDC) {
      return nominalVoltage == requiredVoltage;
    }

    // AC grids: check line-to-line and line-to-neutral
    if (isThreePhase) {
      final lineToNeutral = (nominalVoltage / 1.732).round(); // √3 ≈ 1.732
      return nominalVoltage == requiredVoltage ||
          lineToNeutral == requiredVoltage;
    }

    return nominalVoltage == requiredVoltage;
  }

  /// Serializes this power grid to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'notation': notation,
      'availablePhases': availablePhases.map((p) => p.name).toList(),
      'frequency': frequency,
    };
  }

  /// Deserializes a power grid from JSON.
  ///
  /// Throws [ArgumentError] if the JSON is invalid or contains
  /// unrecognized enum values.
  factory PowerGrid.fromJson(Map<String, dynamic> json) {
    // Parse type
    final typeStr = json['type'] as String;
    final type = PowerGridType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => throw ArgumentError('Unknown PowerGridType: $typeStr'),
    );

    // Parse available phases
    final phasesList = json['availablePhases'] as List<dynamic>;
    final phases = phasesList.map((phaseStr) {
      return PowerPhase.values.firstWhere(
        (p) => p.name == phaseStr,
        orElse: () => throw ArgumentError('Unknown PowerPhase: $phaseStr'),
      );
    }).toList();

    return PowerGrid(
      type: type,
      notation: json['notation'] as String,
      availablePhases: phases,
      frequency: json['frequency'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PowerGrid) return false;

    return type == other.type &&
        notation == other.notation &&
        frequency == other.frequency &&
        _listEquals(availablePhases, other.availablePhases);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      notation,
      frequency,
      Object.hashAll(availablePhases),
    );
  }

  /// Helper method for list equality comparison.
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'PowerGrid($notation, ${frequency}Hz, ${availablePhases.length} phases)';
  }
}
