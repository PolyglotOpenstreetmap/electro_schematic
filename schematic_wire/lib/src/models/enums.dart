// lib/models/physical/enums.dart

/// Output signal types available on control devices.
///
/// Different output types have different electrical characteristics
/// and are suitable for different loads.
enum OutputType {
  /// Mechanical relay contact
  ///
  /// Suitable for high-current AC/DC loads, provides galvanic isolation.
  /// Typical ratings: 10A @ 230VAC
  relay,

  /// FET (Field-Effect Transistor) output
  ///
  /// Solid-state DC switching, fast operation, low power consumption.
  /// Typical ratings: 5A @ 48VDC
  fet,

  /// TRIAC AC switching output
  ///
  /// Solid-state AC switching, zero-crossing detection.
  /// Typical ratings: 2A @ 230VAC
  triac,

  /// Continuous analog signal output
  ///
  /// Variable voltage/current output for proportional control.
  /// Used for motor speed control, dimming, etc.
  continuous,
}

/// Input signal types.
///
/// Defines how control signals are received by devices.
enum InputType {
  /// Digital on/off signal
  digital,

  /// Analog voltage/current input
  analog,

  /// Serial bus communication (RS485, CAN, etc.)
  communication,
}

/// Connection groupings for diagram layout organization.
///
/// Groups connections by function to improve diagram readability
/// and facilitate systematic wiring.
enum ConnectionGroup {
  /// AC/DC power supply connections
  power,

  /// Control signal connections (outputs to strikers, motors, etc.)
  control,

  /// Communication bus connections (RS485, Ethernet, etc.)
  communication,

  /// Mechanical mounting and physical connections
  mechanical,
}

/// Installation environment types.
///
/// Affects environmental protection requirements, wiring methods,
/// and equipment ratings.
enum EnvironmentType {
  /// Indoor protected environment
  indoor,

  /// Outdoor weather-exposed environment
  outdoor,

  /// Bell tower environment (partially protected)
  tower,

  /// Ground level equipment room
  groundLevel,
}

/// Power supply configurations.
///
/// Standard power supply voltages used in bell installations.
enum PowerSupply {
  /// 110V AC single-phase (North America)
  ac110v,

  /// 230V AC single-phase (Europe, most of world)
  ac230v,

  /// 24V DC (common for control circuits and strikers)
  dc24v,

  /// 48V DC (heavy-duty strikers and some motors)
  dc48v,
}

extension OutputTypeExtension on OutputType {
  /// Human-readable display name for the output type.
  String get displayName {
    switch (this) {
      case OutputType.relay:
        return 'Relay';
      case OutputType.fet:
        return 'FET';
      case OutputType.triac:
        return 'TRIAC';
      case OutputType.continuous:
        return 'Continuous';
    }
  }

  /// Typical maximum current rating in amperes for this output type.
  int get typicalMaxCurrentAmps {
    switch (this) {
      case OutputType.relay:
        return 10;
      case OutputType.fet:
        return 5;
      case OutputType.triac:
        return 2;
      case OutputType.continuous:
        return 1;
    }
  }
}

extension PowerSupplyExtension on PowerSupply {
  /// Human-readable display name for the power supply type.
  String get displayName {
    switch (this) {
      case PowerSupply.ac110v:
        return '110V AC';
      case PowerSupply.ac230v:
        return '230V AC';
      case PowerSupply.dc24v:
        return '24V DC';
      case PowerSupply.dc48v:
        return '48V DC';
    }
  }

  /// Voltage level in volts.
  int get voltage {
    switch (this) {
      case PowerSupply.ac110v:
        return 110;
      case PowerSupply.ac230v:
        return 230;
      case PowerSupply.dc24v:
        return 24;
      case PowerSupply.dc48v:
        return 48;
    }
  }

  /// Whether this is an AC power supply.
  bool get isAC {
    return this == PowerSupply.ac110v || this == PowerSupply.ac230v;
  }

  /// Whether this is a DC power supply.
  bool get isDC {
    return this == PowerSupply.dc24v || this == PowerSupply.dc48v;
  }
}

extension ConnectionGroupExtension on ConnectionGroup {
  /// Human-readable display name for the connection group.
  String get displayName {
    switch (this) {
      case ConnectionGroup.power:
        return 'Power';
      case ConnectionGroup.control:
        return 'Control';
      case ConnectionGroup.communication:
        return 'Communication';
      case ConnectionGroup.mechanical:
        return 'Mechanical';
    }
  }

  /// Color code for visual representation in diagrams.
  ///
  /// Returns a color code suitable for wire/connection coloring:
  /// - Power: Red
  /// - Control: Blue
  /// - Communication: Green
  /// - Mechanical: Gray
  String get colorCode {
    switch (this) {
      case ConnectionGroup.power:
        return '#FF0000'; // Red
      case ConnectionGroup.control:
        return '#0000FF'; // Blue
      case ConnectionGroup.communication:
        return '#00FF00'; // Green
      case ConnectionGroup.mechanical:
        return '#808080'; // Gray
    }
  }
}
