// lib/ui/widgets/connection_diagram/iv3mod3srl_painter.dart

import 'package:flutter/material.dart';
import '../models/terminals.dart';
import 'diagram_painter_utils.dart';

/// Painter for IV3MOD3SRL striker control board inside Movotron cabinet.
///
/// IV3MOD3SRL is a 4-FET + 2-Relay board for striker actuation and clock control.
/// Visual layout renders the board at top-right of Movotron cabinet (compact 60×120px)
/// with labeled terminal groups on the right edge for easy wire routing.
///
/// Terminal layout (all on right edge, arranged vertically):
/// - Relay terminals: 3 shared terminals (1, 2, C) where Relay 1 uses 1+C, Relay 2 uses 2+C
/// - 4× FET terminals (2-wire pairs: +/- for striker control)
///
/// Usage: Rendered inside Movotron cabinet, positioned at top-right corner.
class IV3MOD3SRLPainter {
  /// Terminal block containing IV3MOD3SRL terminals
  final TerminalBlock block;

  /// Canvas position offset for Movotron cabinet context
  final Offset cabinetPosition;

  const IV3MOD3SRLPainter({
    required this.block,
    required this.cabinetPosition,
  });

  /// Paint IV3MOD3SRL board inside Movotron cabinet.
  void paint(Canvas canvas) {
    // Board dimensions - made smaller per requirements
    const double boardWidth = 60.0;
    const double boardHeight = 120.0;

    // Position on right side of cabinet, 20px from edge
    // Movotron cabinet is 750px wide, so right edge is at cabinetPosition.dx + 750
    final boardX = cabinetPosition.dx + 750 - boardWidth - 20;
    final boardY = cabinetPosition.dy + 10; // Raised a little higher (was 20, now 10)

    final boardPos = Offset(boardX, boardY);

    // Draw board background
    final boardPaint = Paint()
      ..color = const Color(0xFF1B5E20) // Dark green PCB color
      ..style = PaintingStyle.fill;

    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boardPos.dx, boardPos.dy, boardWidth, boardHeight),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(boardRect, boardPaint);

    // Draw board outline - dashed for new equipment, solid for existing
    final boardOutlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (block.isExisting) {
      // Solid outline for existing equipment
      canvas.drawRRect(boardRect, boardOutlinePaint);
    } else {
      // Dashed outline for new equipment to install
      _drawDashedRRect(canvas, boardRect, boardOutlinePaint);
    }

    // Draw board label at top
    _drawTextCentered(
      canvas,
      'IV3MOD3SRL',
      Offset(boardPos.dx + boardWidth / 2, boardPos.dy + 8),
      const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );

    // N and L terminals are drawn at the Movotron cabinet level, not per IV3MOD3SRL board.
    // Only the C terminal and internal components are drawn here.

    final terminalPaint = Paint()
      ..color = const Color(0xFFFFD700) // Gold
      ..style = PaintingStyle.fill;

    final terminalOutlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw C terminal on LEFT SIDE of board (moved higher)
    const double leftTerminalX = 8.0;
    const double cTerminalY = 28.0; // Moved up from 36.0

    final cTerminalPos = Offset(
      boardPos.dx + leftTerminalX,
      boardPos.dy + cTerminalY,
    );

    canvas.drawCircle(cTerminalPos, 2.5, terminalPaint);
    canvas.drawCircle(cTerminalPos, 2.5, terminalOutlinePaint);
    _drawText(
      canvas,
      'C',
      Offset(cTerminalPos.dx + 6, cTerminalPos.dy - 8), // Moved higher from -2 to -8
      const TextStyle(
        color: Colors.white,
        fontSize: 4,
        fontWeight: FontWeight.bold,
      ),
    );

    // L-to-C wire is now drawn at the Movotron cabinet level (L belongs to the cabinet).

    // Draw relay output terminals on RIGHT SIDE (1, 2)
    const double rightTerminalX = boardWidth - 8; // Right edge of board
    const double relayTerminalY = 25.0;
    const double relayTerminalSpacing = 8.0;

    // Only draw relay contacts if connected to clock tower
    if (block.connectsToClockTower) {
      // Grey wire paint for relay contacts
      final relayWirePaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Output terminal positions
      final output1Pos = Offset(
        boardPos.dx + rightTerminalX,
        boardPos.dy + relayTerminalY,
      );
      final output2Pos = Offset(
        boardPos.dx + rightTerminalX,
        boardPos.dy + relayTerminalY + relayTerminalSpacing,
      );

      // Offset relay start positions vertically to avoid overlapping wires
      final relay1StartPos = Offset(cTerminalPos.dx, cTerminalPos.dy - 3);
      final relay2StartPos = Offset(cTerminalPos.dx, cTerminalPos.dy + 3);

      // Draw vertical bus showing both relays share C terminal
      canvas.drawLine(relay1StartPos, relay2StartPos, relayWirePaint);

      // Draw relay 1 contact routing (from slightly above C)
      _drawRelayContactWithSwitch(
        canvas,
        relay1StartPos,
        output1Pos,
        relayWirePaint,
      );

      // Draw relay 2 contact routing (from slightly below C)
      _drawRelayContactWithSwitch(
        canvas,
        relay2StartPos,
        output2Pos,
        relayWirePaint,
      );
    }

    // Draw 2 relay output terminal circles (1, 2)
    final relayLabels = ['1', '2'];
    for (int termIdx = 0; termIdx < 2; termIdx++) {
      final terminalPos = Offset(
        boardPos.dx + rightTerminalX,
        boardPos.dy + relayTerminalY + (termIdx * relayTerminalSpacing),
      );

      // Terminal circle (gold color for solder pad)
      final terminalPaint = Paint()
        ..color = const Color(0xFFFFD700) // Gold
        ..style = PaintingStyle.fill;

      canvas.drawCircle(terminalPos, 2.5, terminalPaint);

      // Terminal outline
      final terminalOutlinePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(terminalPos, 2.5, terminalOutlinePaint);

      // Draw terminal label to the left of terminal
      _drawText(
        canvas,
        relayLabels[termIdx],
        Offset(terminalPos.dx - 10, terminalPos.dy - 2),
        const TextStyle(
          color: Colors.white,
          fontSize: 4,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw FET terminal groups (4 pairs, below relays)
    const double fetStartY = 50.0; // Adjusted for smaller board size
    const double fetSpacing = 16.0; // Reduced spacing for smaller board
    const double fetTerminalX = boardWidth - 8.0; // Right edge of board

    for (int fetIdx = 0; fetIdx < 4; fetIdx++) {
      final fetY = boardPos.dy + fetStartY + (fetIdx * fetSpacing);

      // Draw FET label
      _drawText(
        canvas,
        'FET${fetIdx + 1}',
        Offset(boardPos.dx + 10, fetY),
        const TextStyle(
          color: Colors.white,
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      );

      // Draw 2 terminal circles for this FET (+ and -) - vertically stacked
      for (int termIdx = 0; termIdx < 2; termIdx++) {
        final terminalPos = Offset(
          boardPos.dx + fetTerminalX,
          fetY + 2 + (termIdx * 8), // Stack vertically instead of horizontally
        );

        // Terminal circle (gold color for solder pad)
        final terminalPaint = Paint()
          ..color = const Color(0xFFFFD700) // Gold
          ..style = PaintingStyle.fill;

        canvas.drawCircle(terminalPos, 2.5, terminalPaint);

        // Terminal outline
        final terminalOutlinePaint = Paint()
          ..color = Colors.black87
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(terminalPos, 2.5, terminalOutlinePaint);

        // Draw terminal polarity label (+ or -)
        _drawTextCentered(
          canvas,
          termIdx == 0 ? '+' : '-',
          Offset(terminalPos.dx + 8, terminalPos.dy), // Position label to the right
          const TextStyle(
            color: Colors.white,
            fontSize: 4,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
  }

  // Centers both horizontally and vertically on position.
  void _drawTextCentered(Canvas canvas, String text, Offset position, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) =>
      drawText(canvas, text, position, style);

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) =>
      drawDashedPath(canvas, Path()..addRRect(rrect), paint,
          dashWidth: 5.0, dashSpace: 3.0);

  /// Draw relay contact routing with switch symbol at output terminal height.
  ///
  /// Routes: C → horizontal right → vertical up → switch symbol (_/ _) at output height → output
  /// The switch symbol has both wire segments at the SAME vertical height (the output terminal height).
  void _drawRelayContactWithSwitch(
    Canvas canvas,
    Offset cTerminal,
    Offset output,
    Paint paint,
  ) {
    const double horizontalSegmentLength = 6.0; // Length of _ before and after /
    const double switchDiagonalLength = 8.0; // Length of the / diagonal

    // Step 1: Horizontal right from C terminal (moved further right)
    const double horizontalFromC = 20.0;
    final horizontalEnd = Offset(cTerminal.dx + horizontalFromC, cTerminal.dy);
    canvas.drawLine(cTerminal, horizontalEnd, paint);

    // Step 2: Vertical UP to reach the height of the output terminal
    final verticalEnd = Offset(horizontalEnd.dx, output.dy);
    canvas.drawLine(horizontalEnd, verticalEnd, paint);

    // Step 3: Draw switch symbol at output terminal height: _/ _
    // Left horizontal segment _
    final switchLeftStart = verticalEnd;
    final switchLeftEnd = Offset(
      switchLeftStart.dx + horizontalSegmentLength,
      output.dy, // Same height as output
    );
    canvas.drawLine(switchLeftStart, switchLeftEnd, paint);

    // Diagonal / (single continuous line)
    // Bottom of diagonal at wire level, top hanging in air
    final diagonalStart = switchLeftEnd;
    final diagonalEnd = Offset(
      diagonalStart.dx + switchDiagonalLength * 0.707, // cos(45°) for diagonal
      diagonalStart.dy - switchDiagonalLength * 0.707, // sin(45°) - goes UP
    );

    // Draw diagonal as single line
    canvas.drawLine(diagonalStart, diagonalEnd, paint);

    // Right horizontal segment _ (at same height as left segment)
    final switchRightStart = Offset(diagonalStart.dx + switchDiagonalLength * 0.707, output.dy);
    final switchRightEnd = Offset(
      switchRightStart.dx + horizontalSegmentLength,
      output.dy, // Same height as output
    );
    canvas.drawLine(switchRightStart, switchRightEnd, paint);

    // Step 4: Final horizontal to output terminal
    canvas.drawLine(switchRightEnd, output, paint);
  }
}
