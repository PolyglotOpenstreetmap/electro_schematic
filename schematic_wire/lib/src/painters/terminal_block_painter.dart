// lib/ui/widgets/connection_diagram/terminal_block_painter.dart

import 'package:flutter/material.dart';
import '../models/terminals.dart';
import '../models/power_grid.dart';
import 'diagram_painter_utils.dart';
import '../models/diagram_models.dart';

/// Comprehensive terminal block visualization system for electrical diagrams.
///
/// Renders DIN-rail mounted terminal blocks with professional electrical
/// schematic styling, showing:
/// - Individual screw terminals with numbering
/// - Phase assignments with IEC 60446 color coding
/// - Wire gauge information
/// - Jumper/bridge connections
/// - Manufacturer information
///
/// Supports power input blocks, motor output blocks, control signal blocks,
/// and DC power blocks with appropriate visual distinctions.
class TerminalBlockPainter {
  /// Terminal blocks to render
  final List<TerminalBlock> terminalBlocks;

  /// Current diagram state (zoom, selection, visibility options)
  final DiagramState state;

  /// Layout configuration for spacing and positioning
  final DiagramLayout layout;

  /// Optional jumper connections between terminals
  final List<JumperConnection> jumpers;

  const TerminalBlockPainter({
    required this.terminalBlocks,
    required this.state,
    required this.layout,
    this.jumpers = const [],
  });

  /// Paint all terminal blocks to the canvas.
  void paint(Canvas canvas) {
    for (final block in terminalBlocks) {
      _paintTerminalBlock(canvas, block);
    }

    // Paint jumpers after all blocks to ensure they're on top
    for (final jumper in jumpers) {
      _paintJumper(canvas, jumper);
    }
  }

  /// Paint a single terminal block with all its components.
  void _paintTerminalBlock(Canvas canvas, TerminalBlock block) {
    final position = block.diagramPosition.toOffset();

    // Calculate block dimensions based on terminal count
    final allTerminals = block.allTerminals;
    final terminalCount = allTerminals.length;
    final blockWidth = terminalCount * (TerminalDimensions.terminalWidth +
            TerminalDimensions.terminalSpacing) +
        TerminalDimensions.terminalSpacing;
    final blockHeight = TerminalDimensions.blockHeight;

    // Draw block container
    _paintBlockContainer(canvas, position, blockWidth, blockHeight, block.name);

    // Draw manufacturer/model info if available
    if (block.description != null) {
      _paintManufacturerInfo(
        canvas,
        position,
        blockWidth,
        block.description!,
      );
    }

    // Draw each terminal
    double currentX = position.dx + TerminalDimensions.terminalSpacing;
    int terminalNumber = 1;

    for (final terminal in allTerminals) {
      final terminalPosition = Offset(currentX, position.dy + 30);

      _paintTerminal(
        canvas,
        terminalPosition,
        terminal,
        terminalNumber,
      );

      currentX += TerminalDimensions.terminalWidth +
          TerminalDimensions.terminalSpacing;
      terminalNumber++;
    }

    // Highlight if selected
    if (state.selectedComponentId == block.id) {
      _paintSelection(canvas, position, blockWidth, blockHeight);
    }
  }

  /// Paint the terminal block container with header.
  void _paintBlockContainer(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    String name,
  ) {
    // Container background
    final containerPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final containerRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      width,
      height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(containerRect, const Radius.circular(4)),
      containerPaint,
    );

    // Container outline
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(containerRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Header section with block name
    final headerPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final headerRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      width,
      20,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headerRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      headerPaint,
    );

    // Block name text
    drawTextCentered(
      canvas,
      name,
      Offset(position.dx + width / 2, position.dy + 4),
      const TextStyle(
        color: Colors.black87,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    // Separator line below header
    canvas.drawLine(
      Offset(position.dx, position.dy + 20),
      Offset(position.dx + width, position.dy + 20),
      outlinePaint,
    );
  }

  /// Paint manufacturer/model information.
  void _paintManufacturerInfo(
    Canvas canvas,
    Offset position,
    double width,
    String info,
  ) {
    drawTextCentered(
      canvas,
      info,
      Offset(position.dx + width / 2, position.dy - 12),
      TextStyle(
        color: Colors.grey.shade700,
        fontSize: 9,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Paint a single terminal with all details.
  void _paintTerminal(
    Canvas canvas,
    Offset position,
    Terminal terminal,
    int terminalNumber,
  ) {
    // Draw phase label above terminal if assigned
    if (terminal.assignedPhase != null && state.showTerminalLabels) {
      _paintPhaseLabel(canvas, position, terminal.assignedPhase!);
    }

    // Draw terminal body (screw terminal representation)
    _paintTerminalBody(canvas, position, terminal);

    // Draw terminal number below
    _paintTerminalNumber(canvas, position, terminalNumber);

    // Draw wire gauge if available
    if (terminal.description != null &&
        terminal.description!.contains('mm²')) {
      _paintWireGauge(canvas, position, terminal.description!);
    }

    // Draw connection indicator if connected
    if (terminal.isConnected) {
      _paintConnectionIndicator(canvas, position);
    }
  }

  /// Paint the terminal body (screw terminal).
  void _paintTerminalBody(Canvas canvas, Offset position, Terminal terminal) {
    // Terminal body color based on phase
    Color terminalColor = Colors.grey.shade300;
    if (terminal.assignedPhase != null) {
      terminalColor = terminal.assignedPhase!.iecColorCode.withValues(alpha: 0.3);
    }

    final bodyPaint = Paint()
      ..color = terminalColor
      ..style = PaintingStyle.fill;

    final bodyRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      TerminalDimensions.terminalWidth,
      TerminalDimensions.terminalHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      bodyPaint,
    );

    // Terminal outline
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      outlinePaint,
    );

    // Draw screw representation
    _paintScrew(canvas, position);

    // Draw PE striping if protective earth
    if (terminal.assignedPhase == PowerPhase.pe) {
      _paintPEStriping(canvas, position);
    }
  }

  /// Paint screw terminal representation.
  void _paintScrew(Canvas canvas, Offset position) {
    final screwPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // Screw head
    canvas.drawCircle(
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2,
        position.dy + 8,
      ),
      3,
      screwPaint,
    );

    // Screw slot
    final slotPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2 - 2,
        position.dy + 8,
      ),
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2 + 2,
        position.dy + 8,
      ),
      slotPaint,
    );

    // Wire insertion point
    final insertionPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        position.dx + 6,
        position.dy + 18,
        8,
        3,
      ),
      insertionPaint,
    );
  }

  /// Paint PE (protective earth) striping pattern.
  void _paintPEStriping(Canvas canvas, Offset position) {
    final stripePaint = Paint()
      ..color = PowerPhase.pe.secondaryColorCode!.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Diagonal stripes
    for (int i = 0; i < 4; i++) {
      final startX = position.dx + i * 5.0;
      canvas.drawLine(
        Offset(startX, position.dy),
        Offset(
          startX + TerminalDimensions.terminalHeight,
          position.dy + TerminalDimensions.terminalHeight,
        ),
        stripePaint,
      );
    }
  }

  /// Paint phase label above terminal.
  void _paintPhaseLabel(Canvas canvas, Offset position, PowerPhase phase) {
    drawTextCentered(
      canvas,
      phase.displayLabel,
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2,
        position.dy - 14,
      ),
      TextStyle(
        color: phase.iecColorCode,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Paint terminal number below terminal.
  void _paintTerminalNumber(Canvas canvas, Offset position, int number) {
    drawTextCentered(
      canvas,
      number.toString(),
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2,
        position.dy + TerminalDimensions.terminalHeight + 2,
      ),
      const TextStyle(
        color: Colors.black87,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Paint wire gauge information.
  void _paintWireGauge(Canvas canvas, Offset position, String gauge) {
    drawTextCentered(
      canvas,
      gauge,
      Offset(
        position.dx + TerminalDimensions.terminalWidth / 2,
        position.dy + TerminalDimensions.terminalHeight + 14,
      ),
      TextStyle(
        color: Colors.grey.shade700,
        fontSize: 8,
      ),
    );
  }

  /// Paint connection indicator for connected terminals.
  void _paintConnectionIndicator(Canvas canvas, Offset position) {
    final indicatorPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        position.dx + TerminalDimensions.terminalWidth - 3,
        position.dy + 3,
      ),
      2,
      indicatorPaint,
    );
  }

  /// Paint selection highlight around terminal block.
  void _paintSelection(
    Canvas canvas,
    Offset position,
    double width,
    double height,
  ) {
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx - 3, position.dy - 3, width + 6, height + 6),
        const Radius.circular(6),
      ),
      selectionPaint,
    );
  }

  /// Paint jumper/bridge connection between terminals.
  void _paintJumper(Canvas canvas, JumperConnection jumper) {
    // Find terminal positions
    Terminal? startTerminal;
    Terminal? endTerminal;

    for (final block in terminalBlocks) {
      startTerminal ??= block.getTerminal(jumper.startTerminalLabel);
      endTerminal ??= block.getTerminal(jumper.endTerminalLabel);

      if (startTerminal != null && endTerminal != null) break;
    }

    if (startTerminal == null || endTerminal == null) return;

    final startPos = startTerminal.diagramPosition.toOffset();
    final endPos = endTerminal.diagramPosition.toOffset();

    // Draw jumper line
    final jumperPaint = Paint()
      ..color = jumper.color ?? Colors.black87
      ..strokeWidth = jumper.thickness
      ..style = PaintingStyle.stroke;

    // Calculate jumper path (slightly curved for aesthetics)
    final path = Path();
    path.moveTo(
      startPos.dx + TerminalDimensions.terminalWidth / 2,
      startPos.dy - 5,
    );

    // Quadratic bezier for slight curve
    path.quadraticBezierTo(
      (startPos.dx + endPos.dx) / 2 + TerminalDimensions.terminalWidth / 2,
      startPos.dy - 10,
      endPos.dx + TerminalDimensions.terminalWidth / 2,
      endPos.dy - 5,
    );

    canvas.drawPath(path, jumperPaint);

    // Draw connection points
    final connectionPaint = Paint()
      ..color = jumper.color ?? Colors.black87
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        startPos.dx + TerminalDimensions.terminalWidth / 2,
        startPos.dy - 5,
      ),
      2,
      connectionPaint,
    );

    canvas.drawCircle(
      Offset(
        endPos.dx + TerminalDimensions.terminalWidth / 2,
        endPos.dy - 5,
      ),
      2,
      connectionPaint,
    );

    // Draw jumper label if provided
    if (jumper.label != null) {
      drawTextCentered(
        canvas,
        jumper.label!,
        Offset(
          (startPos.dx + endPos.dx) / 2 + TerminalDimensions.terminalWidth / 2,
          startPos.dy - 22,
        ),
        const TextStyle(
          color: Colors.black87,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}

/// Standard dimensions for terminal visualization.
///
/// Provides consistent sizing across all terminal block renderings
/// following professional electrical diagram conventions.
class TerminalDimensions {
  /// Width of a single terminal
  static const double terminalWidth = 20.0;

  /// Height of a single terminal
  static const double terminalHeight = 30.0;

  /// Spacing between terminals
  static const double terminalSpacing = 4.0;

  /// Total height of terminal block container
  static const double blockHeight = 90.0;

  const TerminalDimensions._();
}

/// Represents a jumper/bridge connection between terminals.
///
/// Used for motor star/delta configurations, bus bars, and other
/// terminal bridging requirements in electrical installations.
class JumperConnection {
  /// Label of starting terminal
  final String startTerminalLabel;

  /// Label of ending terminal
  final String endTerminalLabel;

  /// Optional label for the jumper (e.g., "Star Point")
  final String? label;

  /// Visual color for the jumper line
  final Color? color;

  /// Line thickness for the jumper
  final double thickness;

  const JumperConnection({
    required this.startTerminalLabel,
    required this.endTerminalLabel,
    this.label,
    this.color,
    this.thickness = 2.0,
  });

  /// Factory: Create star-delta motor jumper configuration.
  ///
  /// Creates standard jumpers for connecting U2-V1, V2-W1, W2-U1
  /// in motor star point configuration.
  static List<JumperConnection> motorStarJumpers({
    Color? color,
  }) {
    return [
      JumperConnection(
        startTerminalLabel: 'U2',
        endTerminalLabel: 'V1',
        color: color,
        thickness: 2.5,
      ),
      JumperConnection(
        startTerminalLabel: 'V2',
        endTerminalLabel: 'W1',
        color: color,
        thickness: 2.5,
      ),
      JumperConnection(
        startTerminalLabel: 'W2',
        endTerminalLabel: 'U1',
        color: color,
        thickness: 2.5,
      ),
    ];
  }

  /// Factory: Create delta motor jumper configuration.
  ///
  /// Creates standard jumpers for connecting U1-W2, V1-U2, W1-V2
  /// in motor delta configuration.
  static List<JumperConnection> motorDeltaJumpers({
    Color? color,
  }) {
    return [
      JumperConnection(
        startTerminalLabel: 'U1',
        endTerminalLabel: 'W2',
        color: color,
        thickness: 2.5,
      ),
      JumperConnection(
        startTerminalLabel: 'V1',
        endTerminalLabel: 'U2',
        color: color,
        thickness: 2.5,
      ),
      JumperConnection(
        startTerminalLabel: 'W1',
        endTerminalLabel: 'V2',
        color: color,
        thickness: 2.5,
      ),
    ];
  }

  /// Factory: Create power input bus bar jumper.
  ///
  /// Creates jumper connecting multiple power terminals for distribution.
  static JumperConnection busBarJumper({
    required String startLabel,
    required String endLabel,
    String? label,
    Color? color,
  }) {
    return JumperConnection(
      startTerminalLabel: startLabel,
      endTerminalLabel: endLabel,
      label: label ?? 'Bus Bar',
      color: color ?? Colors.orange,
      thickness: 3.0,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'startTerminalLabel': startTerminalLabel,
        'endTerminalLabel': endTerminalLabel,
        if (label != null) 'label': label,
        if (color != null) 'color': ((color!.a * 255).toInt() << 24) | ((color!.r * 255).toInt() << 16) | ((color!.g * 255).toInt() << 8) | (color!.b * 255).toInt(),
        'thickness': thickness,
      };

  /// JSON deserialization
  factory JumperConnection.fromJson(Map<String, dynamic> json) {
    return JumperConnection(
      startTerminalLabel: json['startTerminalLabel'] as String,
      endTerminalLabel: json['endTerminalLabel'] as String,
      label: json['label'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      thickness: (json['thickness'] as num?)?.toDouble() ?? 2.0,
    );
  }

  @override
  String toString() =>
      'JumperConnection($startTerminalLabel → $endTerminalLabel)';
}
