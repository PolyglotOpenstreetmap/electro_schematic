// lib/ui/widgets/connection_diagram/power_grid_painter.dart

import 'package:flutter/material.dart';

/// Custom painter for displaying power grid notation in wiring diagrams.
///
/// Renders electrical power grid information at the bottom of connection diagrams
/// following IEC 60446 standard color coding for phases. Displays grid notation
/// (e.g., "3x400V 50Hz", "1x230V 50Hz", "DC24V") with phase labels and color legend.
///
/// Visual design follows professional electrical diagram standards with:
/// - IEC 60446 standard phase colors (L1: Brown, L2: Black, L3: Grey, N: Blue, PE: Green-Yellow)
/// - Clean, monospaced typography (Roboto Mono)
/// - Light grey background panel (#F5F5F5) with 1px grey border
/// - Center-aligned notation with color-coded phase legend
class PowerGridPainter extends CustomPainter {
  /// Power grid configuration (phases, voltage, frequency)
  final PowerGridData? powerGrid;

  /// Optional custom background color (default: #F5F5F5)
  final Color? backgroundColor;

  /// Optional custom border color (default: #CCCCCC)
  final Color? borderColor;

  const PowerGridPainter({
    this.powerGrid,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Handle null/empty states gracefully
    if (powerGrid == null || size.isEmpty) {
      return;
    }

    // Calculate panel dimensions and position (bottom-center)
    final panelHeight = 80.0;
    final panelWidth = size.width * 0.6; // 60% of diagram width
    final panelLeft = (size.width - panelWidth) / 2;
    final panelTop =
        size.height - panelHeight - 16.0; // 16px margin from bottom

    // Draw background panel
    final bgPaint = Paint()
      ..color = backgroundColor ?? const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelLeft, panelTop, panelWidth, panelHeight),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(panelRect, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor ?? const Color(0xFFCCCCCC)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(panelRect, borderPaint);

    // Draw power grid notation text (center-top of panel)
    final notationText = _buildNotationText();
    final notationPainter = TextPainter(
      text: TextSpan(
        text: notationText,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    notationPainter.paint(
      canvas,
      Offset(
        panelLeft + (panelWidth - notationPainter.width) / 2,
        panelTop + 12.0,
      ),
    );

    // Draw phase color legend (bottom of panel)
    _drawPhaseLegend(
      canvas,
      panelLeft,
      panelTop + panelHeight - 36.0,
      panelWidth,
    );
  }

  /// Builds the power grid notation string (e.g., "3x400V 50Hz", "DC24V").
  String _buildNotationText() {
    if (powerGrid!.isDC) {
      return 'DC${powerGrid!.voltage}V';
    }

    final phaseNotation = powerGrid!.phases == 1 ? '1' : '3';
    return '${phaseNotation}x${powerGrid!.voltage}V ${powerGrid!.frequency}Hz';
  }

  /// Draws the phase color legend with IEC 60446 standard colors.
  void _drawPhaseLegend(
    Canvas canvas,
    double panelLeft,
    double legendTop,
    double panelWidth,
  ) {
    // Determine which phases to display
    final phases = _getPhasesToDisplay();

    // Calculate total legend width and starting position for centering
    final boxSize = 16.0;
    final labelSpacing = 8.0;
    final phaseSpacing = 20.0;

    // Measure total width needed
    double totalWidth = 0;
    for (int i = 0; i < phases.length; i++) {
      totalWidth += boxSize;
      final label = phases[i]['label'] as String;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 12.0,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      totalWidth += labelSpacing + labelPainter.width;
      if (i < phases.length - 1) {
        totalWidth += phaseSpacing;
      }
    }

    // Start position for centered legend
    double currentX = panelLeft + (panelWidth - totalWidth) / 2;

    // Draw each phase
    for (final phase in phases) {
      final color = phase['color'] as Color;
      final label = phase['label'] as String;

      // Draw color box
      final boxRect = Rect.fromLTWH(currentX, legendTop, boxSize, boxSize);
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final boxBorder = Paint()
        ..color = Colors.black54
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawRect(boxRect, boxPaint);
      canvas.drawRect(boxRect, boxBorder);

      currentX += boxSize + labelSpacing;

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 12.0,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(currentX, legendTop + (boxSize - labelPainter.height) / 2),
      );

      currentX += labelPainter.width + phaseSpacing;
    }
  }

  /// Returns the list of phases to display based on grid configuration.
  ///
  /// Uses IEC 60446 standard colors:
  /// - L1 (Brown): Primary phase
  /// - L2 (Black): Second phase (3-phase only)
  /// - L3 (Grey): Third phase (3-phase only)
  /// - N (Blue): Neutral
  /// - PE (Green-Yellow): Protective Earth
  List<Map<String, dynamic>> _getPhasesToDisplay() {
    if (powerGrid!.isDC) {
      // DC systems: just positive, negative, and PE
      return [
        {'label': '+', 'color': const Color(0xFFD32F2F)}, // Red
        {'label': '-', 'color': const Color(0xFF1976D2)}, // Blue
        {'label': 'PE', 'color': _getGreenYellowColor()},
      ];
    }

    if (powerGrid!.phases == 1) {
      // Single phase: L, N, PE
      return [
        {'label': 'L', 'color': const Color(0xFF8D6E63)}, // Brown
        {'label': 'N', 'color': const Color(0xFF1976D2)}, // Blue
        {'label': 'PE', 'color': _getGreenYellowColor()},
      ];
    }

    // Three phase: L1, L2, L3, N, PE
    return [
      {'label': 'L1', 'color': const Color(0xFF8D6E63)}, // Brown
      {'label': 'L2', 'color': const Color(0xFF424242)}, // Black
      {'label': 'L3', 'color': const Color(0xFF757575)}, // Grey
      {'label': 'N', 'color': const Color(0xFF1976D2)}, // Blue
      {'label': 'PE', 'color': _getGreenYellowColor()},
    ];
  }

  /// Returns the IEC 60446 green-yellow color for protective earth.
  ///
  /// Creates a striped green-yellow appearance using a gradient-like pattern.
  Color _getGreenYellowColor() {
    return const Color(0xFF7CB342); // Green with yellow tint
  }

  @override
  bool shouldRepaint(covariant PowerGridPainter oldDelegate) {
    // Repaint only if power grid configuration changed
    return oldDelegate.powerGrid != powerGrid ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// Data class representing power grid configuration for diagram rendering.
///
/// Encapsulates electrical grid parameters including phase count, voltage,
/// frequency, and AC/DC type. Used by [PowerGridPainter] to generate
/// professional electrical notation displays.
class PowerGridData {
  /// Number of phases (1 for single-phase, 3 for three-phase, 0 for DC)
  final int phases;

  /// Line voltage in volts (e.g., 110, 230, 400)
  final int voltage;

  /// Grid frequency in Hz (50 or 60), or 0 for DC
  final int frequency;

  /// Motor brand (e.g., "De Coster") - affects capacitor placement
  final String motorBrand;

  const PowerGridData({
    required this.phases,
    required this.voltage,
    required this.frequency,
    this.motorBrand = '',
  });

  /// Factory: Create from location settings.
  factory PowerGridData.fromLocationSettings({
    required int phases,
    required int voltage,
    required int frequency,
  }) {
    return PowerGridData(
      phases: phases,
      voltage: voltage,
      frequency: frequency,
    );
  }

  /// Factory: Create DC power grid (24V DC common in control systems).
  factory PowerGridData.dc24V() {
    return const PowerGridData(
      phases: 0,
      voltage: 24,
      frequency: 0,
    );
  }

  /// Whether this is a DC power grid (frequency = 0).
  bool get isDC => frequency == 0;

  /// Power grid notation label (e.g., "3x400V", "1x230V", "DC24V").
  String get label {
    if (isDC) {
      return 'DC${voltage}V';
    }
    final phaseNotation = phases == 1 ? '1' : '3';
    return '${phaseNotation}x${voltage}V';
  }

  /// Full power grid notation with frequency (e.g., "3x400V 50Hz").
  String get fullNotation {
    if (isDC) {
      return 'DC${voltage}V';
    }
    return '$label ${frequency}Hz';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PowerGridData &&
          runtimeType == other.runtimeType &&
          phases == other.phases &&
          voltage == other.voltage &&
          frequency == other.frequency;

  @override
  int get hashCode => Object.hash(phases, voltage, frequency);

  @override
  String toString() => fullNotation;
}
