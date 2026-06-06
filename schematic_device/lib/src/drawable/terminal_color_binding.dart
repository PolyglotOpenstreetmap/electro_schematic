// lib/src/drawable/terminal_color_binding.dart
//
// Color binding driven by terminal connection state.

import 'package:flutter/material.dart';

import 'color_utils.dart';

/// Resolves a fill/stroke color based on a named terminal's connection state.
///
/// The three possible states and their colors:
/// - **connected** — a wire is attached to the terminal
/// - **jumper**    — terminal is a jumper bridge (isJumper=true) and NOT connected externally
/// - **unconnected** — default
class TerminalColorBinding {
  final String terminalDefId;
  final Color connectedColor;
  final Color? jumperColor;
  final Color unconnectedColor;

  const TerminalColorBinding({
    required this.terminalDefId,
    required this.connectedColor,
    this.jumperColor,
    required this.unconnectedColor,
  });

  /// Default terminal binding using standard schematic colors.
  factory TerminalColorBinding.standard(String terminalDefId,
      {bool isJumper = false}) {
    return TerminalColorBinding(
      terminalDefId: terminalDefId,
      connectedColor: const Color(0xFF4CAF50),    // green
      jumperColor: isJumper ? const Color(0xFF1976D2) : null,  // blue
      unconnectedColor: const Color(0xFFEF6C00),  // orange
    );
  }

  /// Resolve the color given connection and jumper state.
  Color resolve({required bool isConnected, required bool isJumper}) {
    if (isConnected) return connectedColor;
    if (isJumper && jumperColor != null) return jumperColor!;
    return unconnectedColor;
  }

  Map<String, dynamic> toJson() => {
        'type': 'terminal',
        'terminalRef': terminalDefId,
        'connected': colorToHexCompact(connectedColor),
        if (jumperColor != null) 'jumper': colorToHexCompact(jumperColor!),
        'unconnected': colorToHexCompact(unconnectedColor),
      };

  factory TerminalColorBinding.fromJson(Map<String, dynamic> json) {
    return TerminalColorBinding(
      terminalDefId: json['terminalRef'] as String,
      connectedColor: colorFromHex(json['connected'] as String),
      jumperColor: json['jumper'] != null
          ? colorFromHex(json['jumper'] as String)
          : null,
      unconnectedColor: colorFromHex(json['unconnected'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalColorBinding &&
          terminalDefId == other.terminalDefId &&
          connectedColor == other.connectedColor &&
          jumperColor == other.jumperColor &&
          unconnectedColor == other.unconnectedColor;

  @override
  int get hashCode =>
      Object.hash(terminalDefId, connectedColor, jumperColor, unconnectedColor);
}
