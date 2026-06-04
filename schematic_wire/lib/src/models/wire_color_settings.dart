// lib/models/wire_color_settings.dart

import 'package:flutter/material.dart';

/// Motor categories for per-type wire spacing configuration.
enum MotorCategory {
  /// Linear motors (IV7xxx) with numbered terminals 1-6
  linear,

  /// DeCoster motors (IV21xxx) with U, V, W terminals (no numbers)
  deCoster,

  /// Standard rotating motors with U1, V1, W1, U2, V2, W2 terminals
  standard,
}

/// Wire color configuration for wiring diagrams.
///
/// Stores user-configurable colors for phase wires (U, V, W) and striker wires.
/// Follows IEC 60446 standards by default but allows customization.
class WireColorSettings {
  /// U phase wire color (default: Black per IEC 60446 L2)
  final Color uPhaseColor;

  /// V phase wire color (default: Brown per IEC 60446 L1)
  final Color vPhaseColor;

  /// W phase wire color (default: Grey per IEC 60446 L3)
  final Color wPhaseColor;

  /// Striker positive wire color (default: Red)
  final Color strikerPlusColor;

  /// Striker negative wire color (default: Blue)
  final Color strikerMinusColor;

  /// IV3MOD3SRL relay 1A wire color (default: Black)
  /// Used for connections from IV3MOD3SRL relay terminal 1 to 1A
  final Color iv3Fet1Color;

  /// IV3MOD3SRL relay 1B wire color (default: Brown)
  /// Used for connections from IV3MOD3SRL relay terminal 2 to 1B
  final Color iv3Fet2Color;

  /// IV3MOD3SRL relay common (C) wire color (default: Blue)
  /// Used for connections from IV3MOD3SRL common terminal to C
  final Color iv3CommonColor;

  /// Linear motor wire offset left (default: -15.0)
  final double linearWireOffsetLeft;

  /// Linear motor wire offset right (default: 25.0)
  final double linearWireOffsetRight;

  /// DeCoster motor wire offset left (default: 0.0)
  final double deCosterWireOffsetLeft;

  /// DeCoster motor wire offset right (default: 0.0)
  final double deCosterWireOffsetRight;

  /// Standard rotating motor wire offset left (default: -15.0)
  final double standardWireOffsetLeft;

  /// Standard rotating motor wire offset right (default: 25.0)
  final double standardWireOffsetRight;

  /// Horizontal spacing for striker wires when moving vertically
  final double strikerWireSpacing;

  /// Whether to show wire gauge labels (e.g. "3x 2.5mm²") on power wires
  final bool showWireGaugeLabels;

  const WireColorSettings({
    this.uPhaseColor = const Color(0xFF424242), // Black (IEC L2)
    this.vPhaseColor = const Color(0xFF8D6E63), // Brown (IEC L1)
    this.wPhaseColor = const Color(0xFF757575), // Grey (IEC L3)
    this.strikerPlusColor = const Color(0xFFD32F2F), // Red
    this.strikerMinusColor = const Color(0xFF1976D2), // Blue
    this.iv3Fet1Color = const Color(0xFF000000), // Black for 1A
    this.iv3Fet2Color = const Color(0xFF8B4513), // Brown for 1B
    this.iv3CommonColor = const Color(0xFF0000FF), // Blue for C
    this.linearWireOffsetLeft = -15.0,
    this.linearWireOffsetRight = 25.0,
    this.deCosterWireOffsetLeft = 0.0,
    this.deCosterWireOffsetRight = 0.0,
    this.standardWireOffsetLeft = -15.0,
    this.standardWireOffsetRight = 25.0,
    this.strikerWireSpacing = 10.0, // Default 10px spacing
    this.showWireGaugeLabels = true,
  });

  /// Get the left wire offset for a specific motor category.
  double getMotorOffsetLeft(MotorCategory type) => switch (type) {
        MotorCategory.linear => linearWireOffsetLeft,
        MotorCategory.deCoster => deCosterWireOffsetLeft,
        MotorCategory.standard => standardWireOffsetLeft,
      };

  /// Get the right wire offset for a specific motor category.
  double getMotorOffsetRight(MotorCategory type) => switch (type) {
        MotorCategory.linear => linearWireOffsetRight,
        MotorCategory.deCoster => deCosterWireOffsetRight,
        MotorCategory.standard => standardWireOffsetRight,
      };

  /// Create settings from JSON.
  /// Supports both the new per-type format and the legacy single-value format.
  factory WireColorSettings.fromJson(Map<String, dynamic> json) {
    // Migration: if old single-value fields exist, use them as defaults
    // for all motor types (backward compatibility).
    final legacyLeft =
        (json['motorWireOffsetLeft'] as num?)?.toDouble() ?? -15.0;
    final legacyRight =
        (json['motorWireOffsetRight'] as num?)?.toDouble() ?? 25.0;

    return WireColorSettings(
      uPhaseColor: Color(json['uPhaseColor'] as int? ?? 0xFF424242),
      vPhaseColor: Color(json['vPhaseColor'] as int? ?? 0xFF8D6E63),
      wPhaseColor: Color(json['wPhaseColor'] as int? ?? 0xFF757575),
      strikerPlusColor: Color(json['strikerPlusColor'] as int? ?? 0xFFD32F2F),
      strikerMinusColor:
          Color(json['strikerMinusColor'] as int? ?? 0xFF1976D2),
      iv3Fet1Color: Color(json['iv3Fet1Color'] as int? ?? 0xFF000000),
      iv3Fet2Color: Color(json['iv3Fet2Color'] as int? ?? 0xFF8B4513),
      iv3CommonColor: Color(json['iv3CommonColor'] as int? ?? 0xFF0000FF),
      linearWireOffsetLeft:
          (json['linearWireOffsetLeft'] as num?)?.toDouble() ?? legacyLeft,
      linearWireOffsetRight:
          (json['linearWireOffsetRight'] as num?)?.toDouble() ?? legacyRight,
      deCosterWireOffsetLeft:
          (json['deCosterWireOffsetLeft'] as num?)?.toDouble() ?? 0.0,
      deCosterWireOffsetRight:
          (json['deCosterWireOffsetRight'] as num?)?.toDouble() ?? 0.0,
      standardWireOffsetLeft:
          (json['standardWireOffsetLeft'] as num?)?.toDouble() ?? legacyLeft,
      standardWireOffsetRight:
          (json['standardWireOffsetRight'] as num?)?.toDouble() ?? legacyRight,
      strikerWireSpacing:
          (json['strikerWireSpacing'] as num?)?.toDouble() ?? 10.0,
      showWireGaugeLabels: json['showWireGaugeLabels'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uPhaseColor': uPhaseColor.toARGB32(),
      'vPhaseColor': vPhaseColor.toARGB32(),
      'wPhaseColor': wPhaseColor.toARGB32(),
      'strikerPlusColor': strikerPlusColor.toARGB32(),
      'strikerMinusColor': strikerMinusColor.toARGB32(),
      'iv3Fet1Color': iv3Fet1Color.toARGB32(),
      'iv3Fet2Color': iv3Fet2Color.toARGB32(),
      'iv3CommonColor': iv3CommonColor.toARGB32(),
      'linearWireOffsetLeft': linearWireOffsetLeft,
      'linearWireOffsetRight': linearWireOffsetRight,
      'deCosterWireOffsetLeft': deCosterWireOffsetLeft,
      'deCosterWireOffsetRight': deCosterWireOffsetRight,
      'standardWireOffsetLeft': standardWireOffsetLeft,
      'standardWireOffsetRight': standardWireOffsetRight,
      'strikerWireSpacing': strikerWireSpacing,
      'showWireGaugeLabels': showWireGaugeLabels,
    };
  }

  /// Create a copy with optional field overrides
  WireColorSettings copyWith({
    Color? uPhaseColor,
    Color? vPhaseColor,
    Color? wPhaseColor,
    Color? strikerPlusColor,
    Color? strikerMinusColor,
    Color? iv3Fet1Color,
    Color? iv3Fet2Color,
    Color? iv3CommonColor,
    double? linearWireOffsetLeft,
    double? linearWireOffsetRight,
    double? deCosterWireOffsetLeft,
    double? deCosterWireOffsetRight,
    double? standardWireOffsetLeft,
    double? standardWireOffsetRight,
    double? strikerWireSpacing,
    bool? showWireGaugeLabels,
  }) {
    return WireColorSettings(
      uPhaseColor: uPhaseColor ?? this.uPhaseColor,
      vPhaseColor: vPhaseColor ?? this.vPhaseColor,
      wPhaseColor: wPhaseColor ?? this.wPhaseColor,
      strikerPlusColor: strikerPlusColor ?? this.strikerPlusColor,
      strikerMinusColor: strikerMinusColor ?? this.strikerMinusColor,
      iv3Fet1Color: iv3Fet1Color ?? this.iv3Fet1Color,
      iv3Fet2Color: iv3Fet2Color ?? this.iv3Fet2Color,
      iv3CommonColor: iv3CommonColor ?? this.iv3CommonColor,
      linearWireOffsetLeft: linearWireOffsetLeft ?? this.linearWireOffsetLeft,
      linearWireOffsetRight:
          linearWireOffsetRight ?? this.linearWireOffsetRight,
      deCosterWireOffsetLeft:
          deCosterWireOffsetLeft ?? this.deCosterWireOffsetLeft,
      deCosterWireOffsetRight:
          deCosterWireOffsetRight ?? this.deCosterWireOffsetRight,
      standardWireOffsetLeft:
          standardWireOffsetLeft ?? this.standardWireOffsetLeft,
      standardWireOffsetRight:
          standardWireOffsetRight ?? this.standardWireOffsetRight,
      strikerWireSpacing: strikerWireSpacing ?? this.strikerWireSpacing,
      showWireGaugeLabels: showWireGaugeLabels ?? this.showWireGaugeLabels,
    );
  }

  /// Get color for a specific phase terminal
  Color getPhaseColor(String terminalLabel) {
    if (terminalLabel.contains('U')) return uPhaseColor;
    if (terminalLabel.contains('V')) return vPhaseColor;
    if (terminalLabel.contains('W')) return wPhaseColor;
    return Colors.black; // Fallback
  }

  /// Get color for striker wire based on polarity
  Color getStrikerColor(bool isPositive) {
    return isPositive ? strikerPlusColor : strikerMinusColor;
  }

  /// Get color for IV3MOD3SRL wire based on terminal type
  /// - FET1 (1A): returns iv3Fet1Color (black)
  /// - FET2 (1B): returns iv3Fet2Color (brown)
  /// - Common (C): returns iv3CommonColor (blue)
  Color getIV3WireColor(String terminalLabel) {
    if (terminalLabel.contains('FET1')) return iv3Fet1Color;
    if (terminalLabel.contains('FET2')) return iv3Fet2Color;
    if (terminalLabel.contains('C')) return iv3CommonColor;
    return Colors.black; // Fallback
  }

  /// Default IEC 60446 colors (for reset functionality)
  static const WireColorSettings iecDefault = WireColorSettings();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WireColorSettings &&
          runtimeType == other.runtimeType &&
          uPhaseColor == other.uPhaseColor &&
          vPhaseColor == other.vPhaseColor &&
          wPhaseColor == other.wPhaseColor &&
          strikerPlusColor == other.strikerPlusColor &&
          strikerMinusColor == other.strikerMinusColor &&
          iv3Fet1Color == other.iv3Fet1Color &&
          iv3Fet2Color == other.iv3Fet2Color &&
          iv3CommonColor == other.iv3CommonColor &&
          linearWireOffsetLeft == other.linearWireOffsetLeft &&
          linearWireOffsetRight == other.linearWireOffsetRight &&
          deCosterWireOffsetLeft == other.deCosterWireOffsetLeft &&
          deCosterWireOffsetRight == other.deCosterWireOffsetRight &&
          standardWireOffsetLeft == other.standardWireOffsetLeft &&
          standardWireOffsetRight == other.standardWireOffsetRight &&
          strikerWireSpacing == other.strikerWireSpacing &&
          showWireGaugeLabels == other.showWireGaugeLabels;

  @override
  int get hashCode => Object.hash(
        uPhaseColor,
        vPhaseColor,
        wPhaseColor,
        strikerPlusColor,
        strikerMinusColor,
        iv3Fet1Color,
        iv3Fet2Color,
        iv3CommonColor,
        linearWireOffsetLeft,
        linearWireOffsetRight,
        deCosterWireOffsetLeft,
        deCosterWireOffsetRight,
        standardWireOffsetLeft,
        standardWireOffsetRight,
        strikerWireSpacing,
        showWireGaugeLabels,
      );
}
