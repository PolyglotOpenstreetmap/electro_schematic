part of 'paginated_diagram_painter.dart';

// Terminal block, connection, and wire routing drawing methods.
// Part of PaginatedDiagramPainter — has full access to all private fields.

extension WiringElementPainter on PaginatedDiagramPainter {
  void _drawTerminalBlock(Canvas canvas, TerminalBlock block) {
    final key = block.blockRenderKey;

    // Custom renderers (registered externally for app-specific block types)
    if (key != null && customBlockPainters.containsKey(key)) {
      final handled =
          customBlockPainters[key]!(canvas, block, _buildPaintContext());
      if (handled) return;
    }

    // Built-in dispatch by render key
    if (key == BlockRenderKeys.movotron) {
      _drawMovotronTerminalBlock(canvas, block);
      return;
    }
    if (key == BlockRenderKeys.pkz) {
      _drawPKZTerminalBlock(canvas, block);
      return;
    }
    if (key == BlockRenderKeys.triac) {
      _drawTRIACTerminalBlock(canvas, block);
      return;
    }
    if (key == BlockRenderKeys.striker) {
      _drawStrikerTerminalBlock(canvas, block);
      return;
    }
    if (key == BlockRenderKeys.iv3mod3srl) {
      // Rendered inside Movotron cabinet by IV3MOD3SRLPainter — skip here
      return;
    }

    // Fallback: detect motor type from terminal labels
    final terminals = block.allTerminals;
    if (_isLinearMotorTerminalBlock(terminals)) {
      _drawLinearMotorTerminalBlock(canvas, block);
      return;
    }
    if (_isMotorTerminalBlock(terminals)) {
      _drawMotorTerminalBlock(canvas, block);
      return;
    }
    _drawStandardTerminalBlock(canvas, block);
  }

  /// Check if terminal block is a motor block (U1-W2 pattern or DeCoster U-V-W pattern)
  bool _isMotorTerminalBlock(List<Terminal> terminals) {
    final labels = terminals.map((t) => t.label).toSet();

    // Standard motor: U1, V1, W1, U2, V2, W2
    final isStandardMotor = labels.contains('U1') &&
        labels.contains('V1') &&
        labels.contains('W1') &&
        labels.contains('U2') &&
        labels.contains('V2') &&
        labels.contains('W2');

    // DeCoster motor: U, V, W (without numbers)
    final isDeCosterMotor = labels.contains('U') &&
        labels.contains('V') &&
        labels.contains('W') &&
        !labels.contains('U1');

    return isStandardMotor || isDeCosterMotor;
  }

  /// Check if terminal block is a linear motor block (1-6 pattern)
  bool _isLinearMotorTerminalBlock(List<Terminal> terminals) {
    final labels = terminals.map((t) => t.label).toSet();
    // Linear motors have numbered terminals 1-6 (excluding sensors)
    return labels.contains('1') &&
        labels.contains('2') &&
        labels.contains('3') &&
        labels.contains('4') &&
        labels.contains('5') &&
        labels.contains('6');
  }

  /// Map linear motor terminal labels (1,3,5) to phase letters (U,V,W)
  String _mapLinearTerminalToPhase(String label) {
    switch (label) {
      case '1':
        return 'U';
      case '3':
        return 'V';
      case '5':
        return 'W';
      default:
        return label;
    }
  }

  /// Draw capacitor symbol at specified position
  void _drawCapacitor(Canvas canvas, Offset position,
      {bool horizontal = true, double scale = 1.0}) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0 * scale
      ..style = PaintingStyle.stroke;

    if (horizontal) {
      // Two vertical parallel lines
      canvas.drawLine(Offset(position.dx - 5 * scale, position.dy - 10 * scale),
          Offset(position.dx - 5 * scale, position.dy + 10 * scale), paint);
      canvas.drawLine(Offset(position.dx + 5 * scale, position.dy - 10 * scale),
          Offset(position.dx + 5 * scale, position.dy + 10 * scale), paint);

      // Connection points
      canvas.drawLine(Offset(position.dx - 10 * scale, position.dy),
          Offset(position.dx - 5 * scale, position.dy), paint);
      canvas.drawLine(Offset(position.dx + 5 * scale, position.dy),
          Offset(position.dx + 10 * scale, position.dy), paint);
    }

    // Draw "C" label
    _drawTextCentered(
      canvas,
      'C',
      Offset(position.dx, position.dy + 15 * scale),
      TextStyle(
        color: Colors.black87,
        fontSize: 8 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Draw motor terminal block in 3×2 grid layout
  void _drawMotorTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    // Motor block dimensions (50% smaller)
    const terminalSpacing = 17.5; // Was 35.0
    const gridCols = 3;
    const gridRows = 2;
    const blockWidth = gridCols * terminalSpacing + 15.0; // Was 30.0
    const blockHeight = 60.0; // Was 120.0
    const terminalAreaTop = 8.0; // Moved up from 15.0

    final blockRect = Rect.fromLTWH(
      blockPos.dx,
      blockPos.dy,
      blockWidth,
      blockHeight,
    );

    // Draw block container
    final blockPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      blockPaint,
    );

    // Draw block outline
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Extract motor ref and weight from description
    // Description format: "IV..., XXkg bell, ..."
    String? motorRef;
    if (block.description != null) {
      final parts = block.description!.split(',');
      if (parts.isNotEmpty) {
        motorRef = parts[0].trim();
      }
    }

    // Draw motor label INSIDE the block at the bottom (under W2, U2, V2)
    if (motorRef != null) {
      _drawTextCentered(
        canvas,
        motorRef,
        Offset(blockPos.dx + blockWidth / 2,
            blockPos.dy + blockHeight - 10), // Moved up from -7
        const TextStyle(
          color: Colors.black87,
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw grid lines for visual clarity (50% smaller)
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.25 // Was 0.5
      ..style = PaintingStyle.stroke;

    // Vertical grid lines
    for (int col = 1; col < gridCols; col++) {
      final x = blockPos.dx + 7.5 + (col * terminalSpacing); // Was 15
      canvas.drawLine(
        Offset(x, blockPos.dy + terminalAreaTop),
        Offset(x, blockPos.dy + terminalAreaTop + (gridRows * terminalSpacing)),
        gridPaint,
      );
    }

    // Horizontal grid line
    final midY = blockPos.dy + terminalAreaTop + terminalSpacing;
    canvas.drawLine(
      Offset(blockPos.dx + 7.5, midY), // Was 15
      Offset(blockPos.dx + 7.5 + (gridCols * terminalSpacing), midY), // Was 15
      gridPaint,
    );

    // Detect DeCoster motor (U, V, W without numbers)
    final labels = terminals.map((t) => t.label).toSet();
    final isDeCosterMotor = labels.contains('U') &&
        labels.contains('V') &&
        labels.contains('W') &&
        !labels.contains('U1');

    if (isDeCosterMotor) {
      // DeCoster motor: Draw only U, V, W at sparse grid positions 1, 3, 5
      // Position map: U at (0,0), V at (2,0), W at (1,1)
      final deCosterTerminals = [
        {'label': 'U', 'col': 0, 'row': 0}, // Position 1
        {'label': 'V', 'col': 2, 'row': 0}, // Position 3
        {'label': 'W', 'col': 1, 'row': 1}, // Position 5
      ];

      // Calculate terminal positions for Delta/Triangle coil drawing
      final uX =
          blockPos.dx + 7.5 + (0 * terminalSpacing) + terminalSpacing / 2;
      final vX =
          blockPos.dx + 7.5 + (2 * terminalSpacing) + terminalSpacing / 2;
      final wX =
          blockPos.dx + 7.5 + (1 * terminalSpacing) + terminalSpacing / 2;
      final topY = blockPos.dy + terminalAreaTop + terminalSpacing / 2;
      final bottomY =
          blockPos.dy + terminalAreaTop + terminalSpacing + terminalSpacing / 2;

      // Draw Delta/Triangle configuration: three coils forming a closed triangle
      // U to V (top coil)
      _drawCoilSymbol(
        canvas,
        Offset(uX + 2.5, topY), // Start just outside U terminal
        Offset(vX - 2.5, topY), // End just outside V terminal
        Colors.grey.shade600,
        1.5,
      );

      // V to W (right coil)
      _drawCoilSymbol(
        canvas,
        Offset(vX - 2.5, topY + 2.5), // Start just below V terminal
        Offset(wX + 2.5, bottomY - 2.5), // End just above W terminal
        Colors.grey.shade600,
        1.5,
      );

      // W to U (left coil)
      _drawCoilSymbol(
        canvas,
        Offset(wX - 2.5, bottomY - 2.5), // Start just above W terminal
        Offset(uX + 2.5, topY + 2.5), // End just below U terminal
        Colors.grey.shade600,
        1.5,
      );

      for (final termInfo in deCosterTerminals) {
        final terminal = terminals.firstWhere(
          (t) => t.label == termInfo['label'],
          orElse: () => terminals.first,
        );

        final col = termInfo['col'] as int;
        final row = termInfo['row'] as int;

        final terminalX =
            blockPos.dx + 7.5 + (col * terminalSpacing) + terminalSpacing / 2;
        final terminalY = blockPos.dy +
            terminalAreaTop +
            (row * terminalSpacing) +
            terminalSpacing / 2;

        // DeCoster terminals: Green if connected, Orange if not
        final terminalColor = terminal.isConnected
            ? Colors.green.shade700
            : Colors.orange.shade700;

        drawFilledCircleWithOutline(
            canvas, Offset(terminalX, terminalY), 2.5, terminalColor,
            strokeWidth: 0.75);

        // Draw terminal label to the LEFT of terminal
        _drawTextRight(
          canvas,
          terminal.label,
          Offset(terminalX - 5.5, terminalY - 3),
          const TextStyle(
            color: Colors.black87,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      // Draw capacitor for DeCoster motors (IV21*), positioned above and between U and V
      // Placed clearly outside/above the motor symbol border
      if (motorRef != null && motorRef.startsWith('IV21')) {
        // Position capacitor between U and V terminals, above the motor block outline
        final capacitorX = (uX + vX) / 2;
        final capacitorY = topY - 33;

        _drawCapacitor(
          canvas,
          Offset(capacitorX, capacitorY),
          horizontal: true,
          scale: 0.5,
        );

        // Draw horizontal connection wires from capacitor to U and V terminals
        final capacitorConnectionPaint = Paint()
          ..color = Colors.black87
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // Left wire: capacitor left terminal → horizontal → down to U
        final path1 = Path();
        path1.moveTo(capacitorX - 5.0, capacitorY);
        path1.lineTo(uX, capacitorY);
        path1.lineTo(uX, topY - 2.5);
        canvas.drawPath(path1, capacitorConnectionPaint);

        // Right wire: capacitor right terminal → horizontal → down to V
        final path2 = Path();
        path2.moveTo(capacitorX + 5.0, capacitorY);
        path2.lineTo(vX, capacitorY);
        path2.lineTo(vX, topY - 2.5);
        canvas.drawPath(path2, capacitorConnectionPaint);
      }
    } else {
      // Standard motor: Order terminals in grid: U1 V1 W1 (top row), W2 U2 V2 (bottom row - shifted)
      final terminalOrder = ['U1', 'V1', 'W1', 'W2', 'U2', 'V2'];

      for (int i = 0; i < terminalOrder.length; i++) {
        final terminal = terminals.firstWhere(
          (t) => t.label == terminalOrder[i],
          orElse: () => terminals[i], // Fallback to index if label not found
        );

        final col = i % gridCols;
        final row = i ~/ gridCols;

        final terminalX = blockPos.dx +
            7.5 +
            (col * terminalSpacing) +
            terminalSpacing / 2; // Was 15
        final terminalY = blockPos.dy +
            terminalAreaTop +
            (row * terminalSpacing) +
            terminalSpacing / 2;

        // Draw terminal circle with color coding
        // Green = Connected to wire from Movotron
        // Blue = Part of jumper configuration (W2, U2, V2 - new order)
        // Orange = Not connected
        final isJumperTerminal = terminal.label == 'U2' ||
            terminal.label == 'V2' ||
            terminal.label == 'W2';

        Color terminalColor;
        if (terminal.isConnected) {
          terminalColor = Colors.green.shade700; // Connected to wire
        } else if (isJumperTerminal) {
          terminalColor = Colors.blue.shade600; // Jumpered together
        } else {
          terminalColor = Colors.orange.shade700; // Not connected
        }

        drawFilledCircleWithOutline(canvas, Offset(terminalX, terminalY), 2.5,
            terminalColor, // Was 5.0 (50% smaller)
            strokeWidth: 0.75); // Was 1.5 (50% smaller)

        // Draw terminal label to the LEFT of terminal
        _drawTextRight(
          canvas,
          terminal.label,
          Offset(
              terminalX - 5.5,
              terminalY -
                  3), // Right-aligned, ends 5.5px left of terminal center
          const TextStyle(
            color: Colors.black87,
            fontSize: 7, // Readable size
            fontWeight: FontWeight.bold,
          ),
        );
      }

      // Draw motor coils diagonally between U1-U2, V1-V2, W1-W2 (standard motors only)
      _drawMotorCoils(
          canvas, blockPos, terminalSpacing, terminalAreaTop, terminalOrder);

      // Draw star or delta configuration jumpers based on grid voltage (standard motors only)
      // Determine configuration from power grid (passed through page data)
      // For now, we'll check voltage from the description or use a heuristic
      // TODO: Pass power grid info to painter for proper determination
      // Simplified logic: 3-phase 400V → Star, 3-phase 230V → Delta
      final useDelta = powerGrid != null && powerGrid!.voltage < 300;

      if (useDelta) {
        _drawDeltaJumpers(canvas, blockPos, terminalSpacing, terminalAreaTop);
      } else {
        _drawStarJumpers(canvas, blockPos, terminalSpacing, terminalAreaTop);
      }
    }

    // Draw PE terminal if present (at bottom right)
    final peTerminal = terminals.firstWhere(
      (t) => t.label == 'PE' || t.assignedPhase == PowerPhase.pe,
      orElse: () => terminals.last,
    );

    if (peTerminal.assignedPhase == PowerPhase.pe) {
      final peX = blockPos.dx + blockWidth - 10; // Was -20 (50% smaller)
      final peY = blockPos.dy + blockHeight - 7.5; // Was -15 (50% smaller)

      final pePaint = Paint()
        ..color = Colors.green.shade700
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(peX, peY), 2.0, pePaint); // Was 4.0 (50% smaller)

      _drawTextCentered(
        canvas,
        'PE',
        Offset(peX, peY - 5), // Was -10 (50% smaller)
        const TextStyle(
          color: Colors.green,
          fontSize: 3.5, // Was 7 (50% smaller)
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw sensor terminals below the motor group (bottom-left)
    // Reversed order (S4, S3, S2, S1 from left to right) so wires don't cross
    final sensorTerminals = terminals
        .where((t) => t.group == ConnectionGroup.communication)
        .toList()
        .reversed
        .toList();

    if (sensorTerminals.isNotEmpty) {
      const sensorSpacing = 3.0; // Equal horizontal and vertical spacing

      // Find the motor group for this block to position sensors below group
      final group = _findOverlayGroupForBlock(block);
      Offset sensorBase;
      if (group != null) {
        sensorBase = _getGroupSensorBasePosition(group);
      } else {
        // Fallback: below this motor block
        sensorBase = Offset(blockPos.dx + 5, blockPos.dy + blockHeight + 10.0);
      }

      for (int i = 0; i < sensorTerminals.length; i++) {
        final terminal = sensorTerminals[i];
        // Horizontal layout: increasing X, same Y (wires arrive horizontally)
        final sensorX = sensorBase.dx + (i * sensorSpacing);
        final sensorY = sensorBase.dy;

        // Draw sensor terminal
        final sensorColor = terminal.isConnected
            ? Colors.green.shade700
            : Colors.orange.shade700;
        drawFilledCircleWithOutline(
            canvas, Offset(sensorX, sensorY), 1.5, sensorColor,
            strokeWidth: 0.5);

        // Draw terminal label to the left of terminal
        _drawText(
          canvas,
          terminal.label,
          Offset(sensorX - 8, sensorY - 2),
          const TextStyle(
            color: Colors.black87,
            fontSize: 3,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    // Capacitor for IV21* motors is now drawn in the DeCoster section above
  }

  /// Draw linear motor terminal block with 6 vertical terminals.
  ///
  /// Linear motors (IV7xxx) have:
  /// - 6 numbered terminals (1-6) arranged vertically as circles
  /// - Coils between 1-2, 3-4, 5-6
  /// - Star config (default): Bridge 2-4-6 on left, U→1, V→3, W→5 from right
  /// - Delta config: Bridge 1-6, 2-3, 4-5 on left, U→1, V→3, W→5 from right
  /// - Capacitor if article number ends with 'C'
  void _drawLinearMotorTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    final description = block.description ?? '';

    // Linear motor block dimensions (50% scale to match rotating motors)
    const double blockWidth = 40.0;
    const double blockHeight = 60.0;
    const double terminalRadius = 3.0;
    const double terminalSpacing = 7.5;
    const double terminalsStartY = 12.0;

    // Draw main block rectangle
    final blockRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight),
      const Radius.circular(4.0),
    );
    final blockPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(blockRect, blockPaint);

    final blockBorderPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(blockRect, blockBorderPaint);

    // Draw block name at top
    _drawTextCentered(
      canvas,
      block.name,
      Offset(blockPos.dx + blockWidth / 2, blockPos.dy + 3),
      const TextStyle(
        color: Colors.black87,
        fontSize: 6,
        fontWeight: FontWeight.bold,
      ),
    );

    // Get motor terminals (1-6) and sensor terminals
    final motorTerminals = terminals
        .where((t) => ['1', '2', '3', '4', '5', '6'].contains(t.label))
        .toList();
    motorTerminals.sort((a, b) => a.label.compareTo(b.label));

    final sensorTerminals = terminals
        .where((t) => t.group == ConnectionGroup.communication)
        .toList();

    // Terminal X positions
    const double terminalX = 28.0; // Right side for connections

    // Draw terminals (1-6) vertically
    for (int i = 0; i < motorTerminals.length && i < 6; i++) {
      final terminal = motorTerminals[i];
      final terminalY = blockPos.dy + terminalsStartY + (i * terminalSpacing);

      // Draw terminal circle (filled white)
      drawFilledCircleWithOutline(
          canvas,
          Offset(blockPos.dx + terminalX, terminalY),
          terminalRadius,
          Colors.white);

      // Draw terminal number inside circle (2px up for visual centering)
      _drawTextCentered(
        canvas,
        terminal.label,
        Offset(blockPos.dx + terminalX, terminalY - 2),
        const TextStyle(
          color: Colors.black87,
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw coils between terminals (1-2, 3-4, 5-6)
    final coilPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int coilIdx = 0; coilIdx < 3; coilIdx++) {
      final terminal1Y =
          blockPos.dy + terminalsStartY + (coilIdx * 2 * terminalSpacing);
      final terminal2Y = terminal1Y + terminalSpacing;
      final coilX = blockPos.dx + terminalX - terminalRadius - 3;

      // Draw zigzag coil
      final coilPath = Path();
      coilPath.moveTo(coilX, terminal1Y);
      const zigzagWidth = 2.0;
      const zigzagCount = 3;
      final zigzagHeight = (terminal2Y - terminal1Y) / zigzagCount;
      for (int z = 0; z < zigzagCount; z++) {
        final y = terminal1Y + z * zigzagHeight;
        coilPath.lineTo(coilX - zigzagWidth, y + zigzagHeight / 2);
        coilPath.lineTo(coilX, y + zigzagHeight);
      }
      canvas.drawPath(coilPath, coilPaint);

      // Draw horizontal connections from coil endpoints to terminal circle edges
      canvas.drawLine(
        Offset(coilX, terminal1Y),
        Offset(blockPos.dx + terminalX - terminalRadius, terminal1Y),
        coilPaint,
      );
      canvas.drawLine(
        Offset(coilX, terminal2Y),
        Offset(blockPos.dx + terminalX - terminalRadius, terminal2Y),
        coilPaint,
      );
    }

    // Draw bridge configuration based on grid voltage
    // Star (400V grid): 2-4-6 bridged together (star point)
    // Delta (230V grid): 1-6, 2-3, 4-5 bridged (closed triangle)
    final bridgePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const bridgeX = 15.0;
    final useDelta = powerGrid != null && powerGrid!.voltage < 300;

    if (useDelta) {
      // Delta configuration with phase-colored bridges
      final bridgeY1 = blockPos.dy + terminalsStartY + (0 * terminalSpacing);
      final bridgeY2 = blockPos.dy + terminalsStartY + (1 * terminalSpacing);
      final bridgeY3 = blockPos.dy + terminalsStartY + (2 * terminalSpacing);
      final bridgeY4 = blockPos.dy + terminalsStartY + (3 * terminalSpacing);
      final bridgeY5 = blockPos.dy + terminalsStartY + (4 * terminalSpacing);
      final bridgeY6 = blockPos.dy + terminalsStartY + (5 * terminalSpacing);

      // Bridge 1→6 (U phase color): vertical bar on LEFT side
      final uBridgePaint = Paint()
        ..color = wireColorSettings.getPhaseColor('U')
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final bridge16X = blockPos.dx + bridgeX;
      // Horizontal from terminal 1 left edge to bridge bar
      canvas.drawLine(
        Offset(blockPos.dx + terminalX - terminalRadius, bridgeY1),
        Offset(bridge16X, bridgeY1),
        uBridgePaint,
      );
      // Horizontal from terminal 6 left edge to bridge bar
      canvas.drawLine(
        Offset(blockPos.dx + terminalX - terminalRadius, bridgeY6),
        Offset(bridge16X, bridgeY6),
        uBridgePaint,
      );
      // Vertical connector between 1 and 6
      canvas.drawLine(
        Offset(bridge16X, bridgeY1),
        Offset(bridge16X, bridgeY6),
        uBridgePaint,
      );

      // Bridge 3→2 (V phase color): upside-down L hook on RIGHT side
      final vBridgePaint = Paint()
        ..color = wireColorSettings.getPhaseColor('V')
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final hookX = blockPos.dx + 52.0;
      final termRightEdge = blockPos.dx + terminalX + terminalRadius;
      // From terminal 3 right edge → go RIGHT to hook X
      canvas.drawLine(
        Offset(termRightEdge, bridgeY3),
        Offset(hookX, bridgeY3),
        vBridgePaint,
      );
      // Go UP from Y3 to Y2
      canvas.drawLine(
        Offset(hookX, bridgeY3),
        Offset(hookX, bridgeY2),
        vBridgePaint,
      );
      // Go LEFT back to terminal 2 right edge
      canvas.drawLine(
        Offset(hookX, bridgeY2),
        Offset(termRightEdge, bridgeY2),
        vBridgePaint,
      );

      // Bridge 5→4 (W phase color): upside-down L hook on RIGHT side
      final wBridgePaint = Paint()
        ..color = wireColorSettings.getPhaseColor('W')
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      // From terminal 5 right edge → go RIGHT to hook X
      canvas.drawLine(
        Offset(termRightEdge, bridgeY5),
        Offset(hookX, bridgeY5),
        wBridgePaint,
      );
      // Go UP from Y5 to Y4
      canvas.drawLine(
        Offset(hookX, bridgeY5),
        Offset(hookX, bridgeY4),
        wBridgePaint,
      );
      // Go LEFT back to terminal 4 right edge
      canvas.drawLine(
        Offset(hookX, bridgeY4),
        Offset(termRightEdge, bridgeY4),
        wBridgePaint,
      );
    } else {
      // Star configuration: Bridge terminals 2, 4, 6 (indices 1, 3, 5)
      final bridgeY2 = blockPos.dy + terminalsStartY + (1 * terminalSpacing);
      final bridgeY4 = blockPos.dy + terminalsStartY + (3 * terminalSpacing);
      final bridgeY6 = blockPos.dy + terminalsStartY + (5 * terminalSpacing);

      // Vertical bridge line connecting 2-4-6
      canvas.drawLine(
        Offset(blockPos.dx + bridgeX, bridgeY2),
        Offset(blockPos.dx + bridgeX, bridgeY6),
        bridgePaint,
      );

      // Horizontal connections from bridge to terminals
      for (final y in [bridgeY2, bridgeY4, bridgeY6]) {
        canvas.drawLine(
          Offset(blockPos.dx + bridgeX, y),
          Offset(blockPos.dx + terminalX - terminalRadius, y),
          bridgePaint,
        );
      }
    }

    // Draw configuration symbol (Star Y or Delta triangle)
    final symbolX = blockPos.dx + 4.0; // Left side of block
    final symbolY = blockPos.dy + 6.0; // Above first terminal
    if (useDelta) {
      // Delta configuration - draw triangle symbol
      _drawText(
        canvas,
        '△', // Triangle character for Delta configuration
        Offset(symbolX, symbolY),
        const TextStyle(
          color: Colors.blue,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Star configuration - draw Y symbol
      _drawText(
        canvas,
        '\u2144', // ⅄ Unicode character for Y-shaped star configuration
        Offset(symbolX, symbolY),
        const TextStyle(
          color: Colors.blue,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw sensor terminals below the motor group (bottom-left)
    if (sensorTerminals.isNotEmpty) {
      const sensorSpacing = 3.0; // Equal horizontal and vertical spacing

      // Find the motor group for this block to position sensors below group
      final group = _findOverlayGroupForBlock(block);
      Offset sensorBase;
      if (group != null) {
        sensorBase = _getGroupSensorBasePosition(group);
      } else {
        // Fallback: below this motor block
        sensorBase = Offset(blockPos.dx + 5, blockPos.dy + blockHeight + 10.0);
      }

      for (int i = 0; i < sensorTerminals.length; i++) {
        final terminal = sensorTerminals[i];
        // Horizontal layout: increasing X, same Y (wires arrive horizontally)
        final sensorX = sensorBase.dx + (i * sensorSpacing);
        final sensorY = sensorBase.dy;

        drawFilledCircleWithOutline(
            canvas, Offset(sensorX, sensorY), 1.5, Colors.orange,
            strokeWidth: 0.5);

        // Draw terminal label to the left of terminal
        _drawText(
          canvas,
          terminal.label,
          Offset(sensorX - 8, sensorY - 2),
          const TextStyle(
            color: Colors.black87,
            fontSize: 3,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    // Capacitor for linear motors is drawn on the wire path in _drawConnection

    // Draw motor description below block
    if (description.isNotEmpty) {
      _drawText(
        canvas,
        description,
        Offset(blockPos.dx, blockPos.dy + blockHeight + 5),
        const TextStyle(
          color: Colors.black54,
          fontSize: 6,
        ),
      );
    }
  }

  /// Draw Movotron (motor controller) terminal block.
  /// Shows input terminals (L1/L2/L3) at top and ALL output terminals (motors + sensors) at bottom.
  void _drawMovotronTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    // Movotron block dimensions (2/3 of page width for A4 landscape)
    const blockWidth = 750.0; // 2/3 of 1123px page width
    const blockHeight =
        260.0; // Taller to accommodate 2 stacked IV3MOD3SRL modules
    const inputY = 40.0; // Input terminals at top
    const triacY =
        195.0; // TRIAC rectangles lower in cabinet (moved down 30px from 165)
    const triacHeight = 45.0; // TRIAC rectangle height (reduced)
    const terminalSpacing = 50.0;

    final blockRect = Rect.fromLTWH(
      blockPos.dx,
      blockPos.dy,
      blockWidth,
      blockHeight,
    );

    // Draw block container with distinct color
    final blockPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(6)),
      blockPaint,
    );

    // Draw dashed border around cabinet
    final dashedBorderPaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedRRect(
      canvas,
      RRect.fromRectAndRadius(blockRect, const Radius.circular(6)),
      dashedBorderPaint,
    );

    // Draw block name
    _drawText(
      canvas,
      block.name,
      Offset(blockPos.dx + 10, blockPos.dy + 5),
      const TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    // Separator lines removed per user request

    // Draw "INPUT" label at top
    _drawText(
      canvas,
      'INPUT',
      Offset(blockPos.dx + 10, blockPos.dy + 25),
      TextStyle(
        color: Colors.blue.shade700,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw "SENSORS" label on left half bottom
    _drawText(
      canvas,
      'SENSORS',
      Offset(blockPos.dx + 10, blockPos.dy + 90),
      TextStyle(
        color: Colors.blue.shade700,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw "MOTORS" label on right half bottom
    _drawText(
      canvas,
      'MOTORS',
      Offset(blockPos.dx + blockWidth / 2 + 10, blockPos.dy + 90),
      TextStyle(
        color: Colors.blue.shade700,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw input terminals (L1, L2, L3 or just L for single-phase)
    final inputTerminals = terminals
        .where((t) => t.label.contains('L') && !t.label.contains('PE'))
        .toList();

    for (int i = 0; i < inputTerminals.length; i++) {
      final terminal = inputTerminals[i];
      final terminalX = blockPos.dx + 60 + (i * terminalSpacing);
      final terminalY = blockPos.dy + inputY;

      // Draw terminal circle
      final terminalColor =
          terminal.isConnected ? Colors.green.shade700 : Colors.orange.shade700;
      drawFilledCircleWithOutline(
          canvas, Offset(terminalX, terminalY), 6.0, terminalColor,
          strokeWidth: 1.5);

      // Draw terminal label
      _drawTextCentered(
        canvas,
        terminal.label,
        Offset(terminalX, terminalY - 14),
        const TextStyle(
          color: Colors.black87,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Get motor output terminals and group by motor number for board calculation
    final outputTerminals = terminals
        .where((t) => RegExp(r'M\d+\.[UVW]').hasMatch(t.label))
        .toList();

    // Group terminals by motor number for TRIAC and board drawing
    final motorGroups = <int, List<Terminal>>{};
    for (final terminal in outputTerminals) {
      final match = RegExp(r'M(\d+)\.[UVW]').firstMatch(terminal.label);
      if (match != null) {
        final motorNum = int.parse(match.group(1)!);
        motorGroups.putIfAbsent(motorNum, () => []).add(terminal);
      }
    }

    // Get sensor terminals count to determine if second board is needed
    final sensorTerminalsCount =
        terminals.where((t) => t.group == ConnectionGroup.communication).length;

    // Draw Movotron board nodes at bottom-left of cabinet
    // 1 board for ≤16 sensor terminals (4 motors × 4 sensors), 2 boards for >16
    final needsTwoBoards = sensorTerminalsCount > 16;

    const movotronBoardWidth = 60.0;
    const movotronBoardHeight = 50.0;
    const movotronBoardY =
        200.0; // Position at bottom area (adjusted for taller cabinet)
    const movotronBoardStartX = 20.0;
    const movotronBoardSpacing = 70.0;

    // Draw first Movotron board
    final board1X = blockPos.dx + movotronBoardStartX;
    final board1Y = blockPos.dy + movotronBoardY;
    final board1Rect = Rect.fromLTWH(
        board1X, board1Y, movotronBoardWidth, movotronBoardHeight);

    final boardPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(board1Rect, const Radius.circular(4)),
      boardPaint,
    );

    final boardOutlinePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(board1Rect, const Radius.circular(4)),
      boardOutlinePaint,
    );

    _drawTextCentered(
      canvas,
      'Movotron',
      Offset(
          board1X + movotronBoardWidth / 2, board1Y + movotronBoardHeight / 4),
      const TextStyle(
        color: Colors.black87,
        fontSize: 7,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw second Movotron board if needed (>4 motors)
    if (needsTwoBoards) {
      final board2X = blockPos.dx + movotronBoardStartX + movotronBoardSpacing;
      final board2Y = blockPos.dy + movotronBoardY;
      final board2Rect = Rect.fromLTWH(
          board2X, board2Y, movotronBoardWidth, movotronBoardHeight);

      canvas.drawRRect(
        RRect.fromRectAndRadius(board2Rect, const Radius.circular(4)),
        boardPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(board2Rect, const Radius.circular(4)),
        boardOutlinePaint,
      );

      _drawTextCentered(
        canvas,
        'Movotron',
        Offset(board2X + movotronBoardWidth / 2,
            board2Y + movotronBoardHeight / 4),
        const TextStyle(
          color: Colors.black87,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw sensor terminals ON Movotron boards (not at bottom edge)
    // Labels: 1-, 1+, 1D, 1P, 2-, 2+, 2D, 2P, etc.
    // Reversed by motor: rightmost motor terminals on left, leftmost on right
    final sensorTerminals = terminals
        .where((t) => t.group == ConnectionGroup.communication)
        .toList();

    // Group by motor number (first digit of label), then reverse the groups
    final sensorsByMotor = <int, List<Terminal>>{};
    for (final terminal in sensorTerminals) {
      final match = RegExp(r'^(\d+)').firstMatch(terminal.label);
      if (match != null) {
        final motorNum = int.parse(match.group(1)!);
        sensorsByMotor.putIfAbsent(motorNum, () => []).add(terminal);
      }
    }

    // Sort motors in descending order (3, 2, 1) and flatten
    final sortedMotorNums = sensorsByMotor.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final reorderedSensorTerminals = <Terminal>[];
    for (final motorNum in sortedMotorNums) {
      reorderedSensorTerminals.addAll(sensorsByMotor[motorNum]!);
    }

    // Position sensor terminals ON the Movotron boards
    // First 4 motors (up to 16 terminals) on board 1, rest on board 2
    const sensorSpacing = 3.0;
    const terminalsPerBoard = 16; // 4 motors × 4 sensors each

    for (int i = 0; i < reorderedSensorTerminals.length; i++) {
      final terminal = reorderedSensorTerminals[i];

      // Determine which board this terminal belongs to
      final boardIndex = i ~/ terminalsPerBoard; // 0 or 1
      final terminalIndexOnBoard = i % terminalsPerBoard;

      final boardX =
          boardIndex == 0 ? board1X : (board1X + movotronBoardSpacing);
      final terminalX = boardX + 5 + (terminalIndexOnBoard * sensorSpacing);
      final terminalY = board1Y + movotronBoardHeight; // Bottom edge of board

      // Draw sensor terminal as square (smaller than power terminals)
      final terminalPaint = Paint()
        ..color = terminal.isConnected
            ? Colors.green.shade700
            : Colors.orange.shade700
        ..style = PaintingStyle.fill;

      final terminalRect = Rect.fromCenter(
        center: Offset(terminalX, terminalY),
        width: 6.0,
        height: 6.0,
      );
      canvas.drawRect(terminalRect, terminalPaint);

      // Draw terminal outline
      final terminalOutlinePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(terminalRect, terminalOutlinePaint);

      // Draw terminal label rotated -90 degrees (inside board, above terminal)
      canvas.save();
      canvas.translate(terminalX, terminalY - 5);
      canvas
          .rotate(-1.5708); // -90 degrees in radians (flipped 180 from before)
      final labelPainter = TextPainter(
        text: TextSpan(
          text: terminal.label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
          canvas, Offset(-labelPainter.width / 2, -labelPainter.height));
      canvas.restore();
    }

    const triacWidth = 50.0; // Narrower TRIAC boxes
    const triacGap = 10.0; // Gap between TRIACs
    const triacRightMargin = 20.0; // Margin from right edge of cabinet

    // Calculate right edge for TRIAC positioning
    // If IV3MOD3SRL exists, use its left edge (670px from cabinet left)
    // Otherwise use cabinet right edge minus margin
    // IV3MOD3SRL boards are now stacked vertically, so width doesn't change
    final movotronNum = block.id.replaceAll('TB_MOVOTRON_', '');
    final hasIV3MOD3SRL = terminalBlocks.any(
        (b) => PaginatedDiagramPainter._isIV3ForMovotron(b.id, movotronNum));
    final triacRightEdge = hasIV3MOD3SRL
        ? blockPos.dx +
            650.0 - // Moved 20px left: was 670, now 650
            triacGap // 750 - 60 (IV3 width) - 20 (IV3 margin) - 20 (left shift)
        : blockPos.dx +
            blockWidth -
            triacRightMargin -
            20.0; // Also shift 20px left when no IV3

    // Draw motor channel grouping boxes FIRST (behind PKZ/TRIAC)
    // Use channelGroupings for proper channel-based grouping
    const pkzHeight = 40.0;
    const channelPadding = 6.0;

    // Find TRIAC groupings for this Movotron
    final movotronGroupings =
        channelGroupings.where((g) => g.blockId == block.id).toList();

    // Build set of all grouped channel indices
    final groupedChannels = <int>{};
    for (final grouping in movotronGroupings) {
      groupedChannels.addAll(grouping.channelIndices);
    }

    // All channel indices for this Movotron (1-based)
    final triacMotorNums = motorGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final totalChannels = triacMotorNums.length;

    // Draw group boxes for ChannelGroupings (encompass multiple PKZ/TRIAC combos)
    for (final grouping in movotronGroupings) {
      if (grouping.channelIndices.length > 1) {
        // Get sorted channel indices (descending to match TRIAC drawing order)
        final groupChannels = grouping.channelIndices.toList()
          ..sort((a, b) => b.compareTo(a));

        // Convert channel indices to TRIAC positions
        // TRIACs are drawn right-to-left, so channel 1 is rightmost
        final firstChannelIdx = totalChannels - groupChannels.first;
        final lastChannelIdx = totalChannels - groupChannels.last;

        // Calculate bounding box for all channels in group
        final leftTriacX = triacRightEdge -
            ((firstChannelIdx + 1) * triacWidth) -
            (firstChannelIdx * triacGap);
        final rightTriacX = triacRightEdge -
            ((lastChannelIdx + 1) * triacWidth) -
            (lastChannelIdx * triacGap);
        final channelTriacTop = blockPos.dy + triacY;
        final channelPkzY = channelTriacTop - pkzHeight - 10;

        final groupBoxRect = Rect.fromLTWH(
          rightTriacX - channelPadding,
          channelPkzY - channelPadding,
          (leftTriacX - rightTriacX) + triacWidth + (2 * channelPadding),
          pkzHeight + 10 + triacHeight + (2 * channelPadding),
        );

        final groupBoxPaint = Paint()
          ..color = Colors.blueGrey.shade400
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        _drawMotorChannelDashedRect(canvas, groupBoxRect, groupBoxPaint);

        // Draw group label
        final label = grouping.displayName ?? 'Group';
        _drawTextCentered(
          canvas,
          label,
          Offset(groupBoxRect.center.dx, groupBoxRect.top - 6),
          TextStyle(
            color: Colors.blueGrey.shade600,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    // Draw individual boxes for ungrouped channels
    int channelIndex = 0;
    for (final motorNum in triacMotorNums) {
      // Check if this channel is part of a group
      final channelIdx =
          totalChannels - channelIndex; // Convert to 1-based channel index
      final isGrouped = groupedChannels.contains(channelIdx);

      if (!isGrouped) {
        // Motor not in any group - draw individual box
        final channelTriacX = triacRightEdge -
            ((channelIndex + 1) * triacWidth) -
            (channelIndex * triacGap);
        final channelTriacTop = blockPos.dy + triacY;
        final channelPkzY = channelTriacTop - pkzHeight - 10;

        final channelBoxRect = Rect.fromLTWH(
          channelTriacX - channelPadding,
          channelPkzY - channelPadding,
          triacWidth + (2 * channelPadding),
          pkzHeight + 10 + triacHeight + (2 * channelPadding),
        );

        final channelBoxPaint = Paint()
          ..color = Colors.blueGrey.shade400
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        _drawMotorChannelDashedRect(canvas, channelBoxRect, channelBoxPaint);

        _drawTextCentered(
          canvas,
          'M$motorNum',
          Offset(channelBoxRect.center.dx, channelBoxRect.top - 6),
          TextStyle(
            color: Colors.blueGrey.shade600,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      channelIndex++;
    }

    // Draw TRIAC rectangles for each motor (right to left)
    // Sort descending so Motor 1 ends up leftmost, Motor N rightmost
    int triacIndex = 0;
    for (final motorNum in motorGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a))) {
      // Position from right edge, moving left for each TRIAC
      final triacX = triacRightEdge -
          ((triacIndex + 1) * triacWidth) -
          (triacIndex * triacGap);
      final triacTop = blockPos.dy + triacY;

      // Draw TRIAC rectangle
      final triacRect = Rect.fromLTWH(
        triacX,
        triacTop,
        triacWidth,
        triacHeight,
      );

      final triacPaint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(triacRect, const Radius.circular(4)),
        triacPaint,
      );

      final triacOutlinePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(triacRect, const Radius.circular(4)),
        triacOutlinePaint,
      );

      // Draw PKZ box ABOVE this TRIAC (inside cabinet, moves with cabinet)
      const pkzWidth = 50.0;
      const pkzHeight = 40.0;
      final pkzX = triacX + (triacWidth - pkzWidth) / 2; // Center above TRIAC
      final pkzY = triacTop - pkzHeight - 10; // 10px gap above TRIAC

      final pkzRect = Rect.fromLTWH(pkzX, pkzY, pkzWidth, pkzHeight);

      // Draw PKZ background
      final pkzPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(pkzRect, const Radius.circular(4)),
        pkzPaint,
      );

      // Draw PKZ outline
      final pkzOutlinePaint = Paint()
        ..color = Colors.grey.shade700
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(pkzRect, const Radius.circular(4)),
        pkzOutlinePaint,
      );

      // Draw PKZ label with amperage
      final pkzAmps = pkzCurrentFor?.call(block.id, motorNum) ?? 0.0;

      if (pkzAmps > 0) {
        _drawTextCentered(
          canvas,
          'PKZ',
          Offset(pkzX + pkzWidth / 2, pkzY + pkzHeight / 2 - 5),
          const TextStyle(
            color: Colors.black87,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        );
        _drawTextCentered(
          canvas,
          '${pkzAmps.toStringAsFixed(1)}A',
          Offset(pkzX + pkzWidth / 2, pkzY + pkzHeight / 2 + 5),
          TextStyle(
            color: Colors.red.shade700,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      // Draw "TRIAC" label
      _drawTextCentered(
        canvas,
        'TRIAC',
        Offset(triacX + triacWidth / 2, triacTop + 10),
        const TextStyle(
          color: Colors.black87,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );

      triacIndex++;
    }

    // Draw motor output terminals (orange squares) at bottom of TRIACs
    // These are the actual connection points for the motor wires
    for (int i = 0; i < outputTerminals.length; i++) {
      final terminal = outputTerminals[i];

      // Find which motor this terminal belongs to
      final match = RegExp(r'M(\d+)\.[UVW]').firstMatch(terminal.label);
      if (match == null) continue;

      final motorNum = int.parse(match.group(1)!);
      final wireType = match.group(0)!.split('.')[1]; // U, V, or W

      // Find the TRIAC index for this motor (descending order)
      final sortedMotorNums = motorGroups.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      final triacIdx = sortedMotorNums.indexOf(motorNum);
      if (triacIdx == -1) continue;

      // Calculate position at bottom of TRIAC (same positioning as TRIAC drawing)
      final triacX = triacRightEdge -
          ((triacIdx + 1) * triacWidth) -
          (triacIdx * triacGap);
      final triacTop = blockPos.dy + triacY;
      final triacBottom = triacTop + triacHeight;

      // Position U, V, W terminals horizontally within TRIAC (fit within 50px width)
      final wireIndex = wireType == 'U' ? 0 : (wireType == 'V' ? 1 : 2);
      const terminalStartX = 8.0; // Left margin within TRIAC
      const terminalSpacingX = 14.0; // Spacing between U, V, W
      final terminalX =
          triacX + terminalStartX + (wireIndex * terminalSpacingX);
      final terminalY = triacBottom;

      // Draw terminal as square (orange for unconnected, green for connected)
      final terminalPaint = Paint()
        ..color = terminal.isConnected
            ? Colors.green.shade700
            : Colors.orange.shade700
        ..style = PaintingStyle.fill;

      final terminalRect = Rect.fromCenter(
        center: Offset(terminalX, terminalY),
        width: 10.0,
        height: 10.0,
      );
      canvas.drawRect(terminalRect, terminalPaint);

      // Draw terminal outline
      final terminalOutlinePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRect(terminalRect, terminalOutlinePaint);

      // Draw terminal label above terminal (U, V, W) - positioned higher
      _drawTextCentered(
        canvas,
        wireType,
        Offset(terminalX, terminalY - 18),
        const TextStyle(
          color: Colors.black87,
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Capacitors are drawn on the wire path (in _drawConnection), not inside TRIAC nodes

    // Check if there are IV3MOD3SRL blocks for this Movotron
    // Find ALL IV3MOD3SRL blocks that belong to this Movotron
    // Pattern: TB_MOVOTRON_1 -> TB_IV3MOD3SRL_1, TB_IV3MOD3SRL_1_2, etc.
    final movotronNumber = block.id.replaceAll('TB_MOVOTRON_', '');
    final iv3mod3srlBlocks = terminalBlocks
        .where(
          (b) =>
              PaginatedDiagramPainter._isIV3ForMovotron(b.id, movotronNumber),
        )
        .toList();

    // Render all IV3MOD3SRL boards inside this Movotron cabinet
    // Stack vertically with first board at top
    for (int i = 0; i < iv3mod3srlBlocks.length; i++) {
      final iv3Block = iv3mod3srlBlocks[i];

      // Vertical offset for multiple boards: first board at top,
      // second board below with spacing
      const double boardHeight = 120.0;
      const double boardSpacing = 10.0;
      final yOffset = i * (boardHeight + boardSpacing);

      final iv3Painter = IV3MOD3SRLPainter(
        block: iv3Block,
        cabinetPosition: Offset(blockPos.dx, blockPos.dy + yOffset),
      );
      iv3Painter.paint(canvas);
    }

    // Draw cabinet-level L and N terminals (shared across all IV3MOD3SRL boards)
    if (iv3mod3srlBlocks.isNotEmpty) {
      _drawCabinetLevelLN(canvas, blockPos, iv3mod3srlBlocks);
    }
  }

  /// Draw L and N terminals at the Movotron cabinet level.
  ///
  /// L and N belong to the Movotron cabinet, not to individual IV3MOD3SRL boards.
  /// There is always exactly 1 L and 1 N per cabinet. The L wire connects to the
  /// C terminal of each IV3MOD3SRL board via an L-shaped route.
  void _drawCabinetLevelLN(
    Canvas canvas,
    Offset cabinetPos,
    List<TerminalBlock> iv3Blocks,
  ) {
    const double boardWidth = 60.0;
    const double boardHeight = 120.0;
    const double boardSpacing = 10.0;

    // N terminal: centered above the first IV3MOD3SRL board
    const double nTerminalX = 750.0 - boardWidth - 20.0 + (boardWidth / 2);
    const double nTerminalY = 5.0;

    // L terminal: to the left of the IV3MOD3SRL board area
    const double lTerminalX = 750.0 - boardWidth - 20.0 - 12.0;
    const double lTerminalY = 5.0;

    const terminalFillColor = Color(0xFFFFD700); // Gold

    final wirePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw N terminal
    final nPos = Offset(cabinetPos.dx + nTerminalX, cabinetPos.dy + nTerminalY);
    drawFilledCircleWithOutline(canvas, nPos, 2.5, terminalFillColor,
        strokeWidth: 0.5);
    _drawText(
      canvas,
      'N',
      Offset(nPos.dx - 10, nPos.dy - 2),
      const TextStyle(
          color: Colors.black87, fontSize: 6, fontWeight: FontWeight.bold),
    );

    // Draw L terminal
    final lPos = Offset(cabinetPos.dx + lTerminalX, cabinetPos.dy + lTerminalY);
    drawFilledCircleWithOutline(canvas, lPos, 2.5, terminalFillColor,
        strokeWidth: 0.5);
    _drawText(
      canvas,
      'L',
      Offset(lPos.dx - 10, lPos.dy - 2),
      const TextStyle(
          color: Colors.black87, fontSize: 6, fontWeight: FontWeight.bold),
    );

    // Draw L wire to C terminal(s) of each IV3MOD3SRL board.
    // L runs vertically down, then branches horizontally to each board's C terminal.
    // C terminal position on each board: boardX + 8, boardY + 28 (relative to board)
    const double cTerminalXOnBoard = 8.0;
    const double cTerminalYOnBoard = 28.0;

    // Vertical trunk from L terminal going down
    // Find the lowest C terminal Y to know how far down to draw the trunk
    double maxCTerminalY = 0;
    final cPositions = <Offset>[];
    for (int i = 0; i < iv3Blocks.length; i++) {
      final boardX = cabinetPos.dx + 750 - boardWidth - 20;
      final boardY = cabinetPos.dy + 10 + (i * (boardHeight + boardSpacing));
      final cPos =
          Offset(boardX + cTerminalXOnBoard, boardY + cTerminalYOnBoard);
      cPositions.add(cPos);
      if (cPos.dy > maxCTerminalY) maxCTerminalY = cPos.dy;
    }

    // Draw vertical trunk from L down to the level of the lowest C terminal
    final trunkBottom = Offset(lPos.dx, maxCTerminalY);
    canvas.drawLine(lPos, trunkBottom, wirePaint);

    // Draw horizontal branches from trunk to each C terminal
    for (final cPos in cPositions) {
      final branchStart = Offset(lPos.dx, cPos.dy);
      canvas.drawLine(branchStart, cPos, wirePaint);
    }
  }

  /// Draw PKZ (motor protection) terminal block inside Movotron cabinet.
  /// NOTE: This method is no longer used - PKZ blocks are not generated separately.
  /// PKZ boxes are drawn directly inside Movotron cabinet by _drawMovotronTerminalBlock.
  /// This method is kept for backwards compatibility in case old data still references PKZ blocks.
  void _drawPKZTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();

    // PKZ dimensions
    const blockWidth = 50.0;
    const blockHeight = 40.0;

    // Draw block background (grey like TRIAC)
    final blockPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Draw block outline
    final outlinePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight),
        const Radius.circular(4),
      ),
      outlinePaint,
    );

    // Draw block name (e.g., "PKZ 6.3A")
    _drawTextCentered(
      canvas,
      block.name,
      Offset(blockPos.dx + blockWidth / 2, blockPos.dy + blockHeight / 2),
      const TextStyle(
        color: Colors.black87,
        fontSize: 7,
        fontWeight: FontWeight.bold,
      ),
    );

    // Note: PKZ blocks do not show visible terminals - they are just visual boxes
    // The terminals still exist in the data model for wire connections but are not rendered
  }

  /// Draw TRIAC (motor switching) terminal block inside Movotron cabinet.
  /// NOTE: This method is no longer used - TRIAC blocks are not generated separately.
  /// TRIACs are drawn directly inside Movotron cabinet by _drawMovotronTerminalBlock.
  /// This method is kept for backwards compatibility in case old data still references TRIAC blocks.
  void _drawTRIACTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();

    // TRIAC dimensions
    const blockWidth = 50.0;
    const blockHeight = 40.0;

    // Draw block background (grey)
    final blockPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Draw block outline
    final outlinePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight),
        const Radius.circular(4),
      ),
      outlinePaint,
    );

    // Draw block name (e.g., "TRIAC 1")
    _drawTextCentered(
      canvas,
      block.name,
      Offset(blockPos.dx + blockWidth / 2, blockPos.dy + blockHeight / 2),
      const TextStyle(
        color: Colors.black87,
        fontSize: 7,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw terminals
    for (final terminal in block.allTerminals) {
      final termPos = blockPos + terminal.diagramPosition.toOffset();

      // Draw terminal circle
      drawFilledCircleWithOutline(
          canvas,
          termPos,
          3.0,
          terminal.isConnected
              ? Colors.green.shade700
              : Colors.orange.shade700);
    }
  }

  /// Draw motor coils diagonally between terminal pairs
  /// U1-U2: gray, V1-V2: gray, W1-W2: lighter gray
  void _drawMotorCoils(Canvas canvas, Offset blockPos, double terminalSpacing,
      double terminalAreaTop, List<String> terminalOrder) {
    // Terminal positions
    // Top row: U1(0), V1(1), W1(2)
    // Bottom row: W2(3), U2(4), V2(5)

    final u1X = blockPos.dx + 7.5 + (0 * terminalSpacing) + terminalSpacing / 2;
    final v1X = blockPos.dx + 7.5 + (1 * terminalSpacing) + terminalSpacing / 2;
    final w1X = blockPos.dx + 7.5 + (2 * terminalSpacing) + terminalSpacing / 2;
    final topY = blockPos.dy + terminalAreaTop + terminalSpacing / 2;

    final w2X = blockPos.dx + 7.5 + (0 * terminalSpacing) + terminalSpacing / 2;
    final u2X = blockPos.dx + 7.5 + (1 * terminalSpacing) + terminalSpacing / 2;
    final v2X = blockPos.dx + 7.5 + (2 * terminalSpacing) + terminalSpacing / 2;
    final bottomY =
        blockPos.dy + terminalAreaTop + terminalSpacing + terminalSpacing / 2;

    // Draw coil for U1-U2 (gray)
    _drawCoilSymbol(
      canvas,
      Offset(u1X, topY),
      Offset(u2X, bottomY),
      Colors.grey.shade600,
      1.0,
    );

    // Draw coil for V1-V2 (gray)
    _drawCoilSymbol(
      canvas,
      Offset(v1X, topY),
      Offset(v2X, bottomY),
      Colors.grey.shade600,
      1.0,
    );

    // Draw coil for W1-W2 (lighter gray)
    _drawCoilSymbol(
      canvas,
      Offset(w1X, topY),
      Offset(w2X, bottomY),
      Colors.grey.shade400,
      1.0,
    );
  }

  /// Draw a coil symbol (zigzag) between two points
  void _drawCoilSymbol(Canvas canvas, Offset start, Offset end, Color color,
      double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create zigzag coil pattern
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    const turns = 3; // Number of coil turns
    final segmentDx = dx / (turns * 2);
    final segmentDy = dy / (turns * 2);
    const zigWidth = 2.0; // Half-width of zigzag

    for (int i = 0; i < turns * 2; i++) {
      final x = start.dx + (segmentDx * i) + (segmentDx / 2);
      final y = start.dy + (segmentDy * i) + (segmentDy / 2);
      final offset = (i % 2 == 0) ? zigWidth : -zigWidth;

      // Calculate perpendicular offset
      final perpX = -dy / (dx * dx + dy * dy).abs();
      final perpY = dx / (dx * dx + dy * dy).abs();

      path.lineTo(x + perpX * offset, y + perpY * offset);
    }

    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  /// Draw delta configuration jumpers (closed triangle)
  /// Delta: U1-W2, V1-U2, W1-V2
  void _drawDeltaJumpers(Canvas canvas, Offset blockPos, double terminalSpacing,
      double terminalAreaTop) {
    // Terminal positions
    // Top row: U1(0), V1(1), W1(2)
    // Bottom row: W2(0), U2(1), V2(2) - new order
    final u1X = blockPos.dx + 7.5 + (0 * terminalSpacing) + terminalSpacing / 2;
    final v1X = blockPos.dx + 7.5 + (1 * terminalSpacing) + terminalSpacing / 2;
    final w1X = blockPos.dx + 7.5 + (2 * terminalSpacing) + terminalSpacing / 2;
    final topY = blockPos.dy + terminalAreaTop + terminalSpacing / 2;

    final w2X = blockPos.dx + 7.5 + (0 * terminalSpacing) + terminalSpacing / 2;
    final u2X = blockPos.dx + 7.5 + (1 * terminalSpacing) + terminalSpacing / 2;
    final v2X = blockPos.dx + 7.5 + (2 * terminalSpacing) + terminalSpacing / 2;
    final bottomY =
        blockPos.dy + terminalAreaTop + terminalSpacing + terminalSpacing / 2;

    final jumperPaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw delta jumpers: U1-W2, V1-U2, W1-V2
    canvas.drawLine(
        Offset(u1X, topY + 4), Offset(w2X, bottomY - 4), jumperPaint);
    canvas.drawLine(
        Offset(v1X, topY + 4), Offset(u2X, bottomY - 4), jumperPaint);
    canvas.drawLine(
        Offset(w1X, topY + 4), Offset(v2X, bottomY - 4), jumperPaint);

    // Label (using Unicode triangle for DELTA configuration)
    // Position between U1 and W2 labels on the left side, out of the way of motor coils and bridge
    final symbolX = blockPos.dx + 2.0; // Left edge, between U1 and W2 labels
    final symbolY = blockPos.dy +
        24.0; // Fixed position (keeps symbol at original location)
    _drawText(
      canvas,
      '△', // Triangle character for Delta configuration
      Offset(symbolX, symbolY - 3),
      const TextStyle(
        color: Colors.blue,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Draw star configuration jumper bars (physical connector plates)
  /// Bottom row order is now W2, U2, V2 (shifted)
  void _drawStarJumpers(Canvas canvas, Offset blockPos, double terminalSpacing,
      double terminalAreaTop) {
    // Calculate positions for W2, U2, V2 terminals (bottom row - new order)
    final w2X = blockPos.dx +
        7.5 +
        (0 * terminalSpacing) +
        terminalSpacing / 2; // Was 15
    final u2X = blockPos.dx +
        7.5 +
        (1 * terminalSpacing) +
        terminalSpacing / 2; // Was 15
    final v2X = blockPos.dx +
        7.5 +
        (2 * terminalSpacing) +
        terminalSpacing / 2; // Was 15
    final y =
        blockPos.dy + terminalAreaTop + terminalSpacing + terminalSpacing / 2;

    // Draw horizontal bus bar connecting W2-U2-V2
    final busBarPaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 2.0 // Was 4.0 (50% smaller)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Main bus bar
    canvas.drawLine(
      Offset(w2X, y + 4), // Was y + 8
      Offset(v2X, y + 4), // Was y + 8
      busBarPaint,
    );

    // Vertical drops to each terminal
    final dropPaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 1.5 // Was 3.0 (50% smaller)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w2X, y), Offset(w2X, y + 4), dropPaint); // Was y + 8
    canvas.drawLine(Offset(u2X, y), Offset(u2X, y + 4), dropPaint); // Was y + 8
    canvas.drawLine(Offset(v2X, y), Offset(v2X, y + 4), dropPaint); // Was y + 8

    // Draw bus bar outline for 3D effect
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5 // Was 5.0 (50% smaller)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w2X, y + 4), // Was y + 8
      Offset(v2X, y + 4), // Was y + 8
      outlinePaint,
    );

    // Re-draw the colored bar on top
    canvas.drawLine(
      Offset(w2X, y + 4), // Was y + 8
      Offset(v2X, y + 4), // Was y + 8
      busBarPaint,
    );

    // Label (using Unicode Y-turn character for STAR configuration)
    // Position between U1 and W2 labels on the left side, out of the way of motor coils
    final symbolX = blockPos.dx + 2.0; // Left edge, between U1 and W2 labels
    final symbolY = blockPos.dy +
        24.0; // Fixed position (keeps symbol at original location)
    _drawText(
      canvas,
      '\u2144', // ⅄ Unicode character for Y-shaped star configuration
      Offset(symbolX, symbolY - 3),
      const TextStyle(
        color: Colors.blue,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Draw striker terminal block with 2 terminals (+ and -).
  ///
  /// Strikers are simple 2-terminal blocks for bell striker actuators.
  /// Shows striker symbol (|||) and bell weight on right side.
  ///
  /// When connected to an SBSI cabinet ([block.id] contains 'SBSI'), the
  /// terminals are drawn **horizontally at the top** so that the two wires
  /// can arrive from above.  All other strikers use the original vertical
  /// layout (terminals on the left side).
  void _drawStrikerTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    // Striker block dimensions - compact layout
    const double blockWidth = 80.0;
    const double blockHeight = 40.0;

    // Draw block container
    final blockRect = Rect.fromLTWH(
      blockPos.dx,
      blockPos.dy,
      blockWidth,
      blockHeight,
    );

    final blockPaint = Paint()
      ..color = Colors.purple.shade50
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      blockPaint,
    );

    // Draw block outline
    final outlinePaint = Paint()
      ..color = Colors.purple.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Extract bell weight from block name (format: "Striker N - XXkg")
    String weightText = '';
    final weightMatch = RegExp(r'(\d+)kg').firstMatch(block.name);
    if (weightMatch != null) {
      weightText = '${weightMatch.group(1)}kg';
    }

    // Get striker ref from description (if it's a product ref, not a long description)
    String strikerRef = '';
    if (block.description != null &&
        block.description!.isNotEmpty &&
        !block.description!.contains('Striker for') &&
        block.description!.length < 20) {
      strikerRef = block.description!;
    }

    // Draw striker ref (e.g., III309) centred in block body
    if (strikerRef.isNotEmpty) {
      _drawTextCentered(
        canvas,
        strikerRef,
        Offset(blockPos.dx + blockWidth / 2, blockPos.dy + 16),
        TextStyle(
          color: Colors.purple.shade700,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw bell weight below striker ref
    if (weightText.isNotEmpty) {
      final yPos = strikerRef.isNotEmpty ? 27.0 : 20.0;
      _drawTextCentered(
        canvas,
        weightText,
        Offset(blockPos.dx + blockWidth / 2, blockPos.dy + yPos),
        const TextStyle(
          color: Colors.black87,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Draw terminals (T1 and T2) vertically on the left side of the block.
    // Wires arrive from the left (from IV3MOD3SRL FET outputs).
    const double termX = 0.0;
    const double t1Y = blockHeight / 3; // ≈ 13.3
    const double t2Y = 2 * blockHeight / 3; // ≈ 26.7

    for (int i = 0; i < terminals.length && i < 2; i++) {
      final terminal = terminals[i];
      final double tx = blockPos.dx + termX;
      final double ty = blockPos.dy + (i == 0 ? t1Y : t2Y);

      drawFilledCircleWithOutline(
          canvas,
          Offset(tx, ty),
          4.0,
          terminal.isConnected
              ? Colors.green.shade700
              : Colors.purple.shade300);
    }
  }

  /// Draw striker terminal block for SBSI-connected strikers.
  ///
  /// Uses a **horizontal** terminal layout: T1 and T2 are side-by-side at
  /// the top of the block so that wires arriving from the SBSI cabinet
  /// above can connect straight down.
  ///
  /// Layout:
  ///   ○   ○          ← T1 (left), T2 (right) at the very top
  ///  ┌──────────────┐
  ///  │  III309      │  ← striker ref (product code)
  ///  │   450kg      │  ← bell weight
  ///  └──────────────┘

  void _drawStandardTerminalBlock(Canvas canvas, TerminalBlock block) {
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    // Calculate block dimensions
    final terminalSpacing = 30.0;
    final blockWidth = terminals.length * terminalSpacing + 20.0;
    const blockHeight = 100.0;
    const terminalAreaTop = 30.0;

    final blockRect = Rect.fromLTWH(
      blockPos.dx,
      blockPos.dy,
      blockWidth,
      blockHeight,
    );

    // Draw block container
    final blockPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      blockPaint,
    );

    // Draw block outline
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Draw block name
    _drawText(
      canvas,
      block.name,
      Offset(blockPos.dx + 10, blockPos.dy + 5),
      const TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    // Draw individual terminals
    for (int i = 0; i < terminals.length; i++) {
      final terminal = terminals[i];
      final terminalX =
          blockPos.dx + 10 + (i * terminalSpacing) + terminalSpacing / 2;
      final terminalY = blockPos.dy + terminalAreaTop + 20;

      // Draw terminal circle
      drawFilledCircleWithOutline(canvas, Offset(terminalX, terminalY), 6.0,
          terminal.isConnected ? Colors.green.shade700 : Colors.orange.shade700,
          strokeWidth: 1.5);

      // Draw terminal label
      _drawTextCentered(
        canvas,
        terminal.label,
        Offset(terminalX, terminalY + 12),
        const TextStyle(
          color: Colors.black87,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );

      // Draw phase indicator if applicable
      if (terminal.assignedPhase != null) {
        final phaseColor = _getPhaseColor(terminal.assignedPhase!);
        final phasePaint = Paint()
          ..color = phaseColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(
          Offset(terminalX, terminalY),
          8.0,
          phasePaint,
        );
      }
    }
  }

  /// Get color for power phase
  Color _getPhaseColor(PowerPhase phase) {
    switch (phase) {
      case PowerPhase.l1:
        return Colors.brown;
      case PowerPhase.l2:
        return Colors.black;
      case PowerPhase.l3:
        return Colors.grey.shade700;
      case PowerPhase.n:
        return Colors.blue.shade700;
      case PowerPhase.pe:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Draw a single connection with absolute positioning and optional vertical offset.
  ///
  /// The [verticalOffset] parameter is used to space multiple parallel wires
  /// vertically to prevent overlap on horizontal segments.
  void _drawConnection(
      Canvas canvas, Connection connection, double verticalOffset) {
    // Debug IV3-to-Clock and Movotron-to-Clock connections early
    final isIV3ToClockConnDebug =
        (connection.sourceDeviceId.contains('IV3MOD3SRL') ||
                connection.sourceDeviceId.contains('TB_MOVOTRON')) &&
            connection.destDeviceId.contains('MOVOTRON_CLOCK_CONN');

    if (isIV3ToClockConnDebug) {
      debugPrint('🔍 _drawConnection called for Clock: ${connection.id}');
      debugPrint('   Source device: ${connection.sourceDeviceId}');
      debugPrint('   Dest device: ${connection.destDeviceId}');
    }

    // Find source and destination terminal blocks
    final sourceBlock = terminalBlocks.firstWhere(
      (b) => b.id == connection.sourceDeviceId,
      orElse: () => throw StateError(
          'Source block ${connection.sourceDeviceId} not found'),
    );

    final destBlock = terminalBlocks.firstWhere(
      (b) => b.id == connection.destDeviceId,
      orElse: () =>
          throw StateError('Dest block ${connection.destDeviceId} not found'),
    );

    if (isIV3ToClockConnDebug) {
      debugPrint('   ✓ Blocks found');
    }

    final sourceTerminal =
        sourceBlock.getTerminalById(connection.sourceTerminalId);
    final destTerminal = destBlock.getTerminalById(connection.destTerminalId);

    if (sourceTerminal == null || destTerminal == null) {
      if (isIV3ToClockConnDebug) {
        debugPrint(
            '   ✗ Terminal lookup failed: source=$sourceTerminal, dest=$destTerminal');
      }
      return;
    }

    if (isIV3ToClockConnDebug) {
      debugPrint(
          '   ✓ Terminals found: ${sourceTerminal.label} → ${destTerminal.label}');
    }

    // Calculate absolute terminal positions based on block type
    final sourcePos = _getTerminalPosition(sourceBlock, sourceTerminal);
    final destPos = _getTerminalPosition(destBlock, destTerminal);

    if (sourcePos == null || destPos == null) {
      if (isIV3ToClockConnDebug) {
        debugPrint(
            '   ✗ Position calculation failed: sourcePos=$sourcePos, destPos=$destPos');
      }
      return;
    }

    if (isIV3ToClockConnDebug) {
      debugPrint('   ✓ Positions calculated: $sourcePos → $destPos');
    }

    // Draw connection line with wire color and thickness based on group
    // Sensor wires are thinner (1.0) than power wires (2.5)
    final isSensorWire = connection.group == ConnectionGroup.communication;
    final strokeWidth = isSensorWire ? 1.0 : 2.5;

    // Check if this is an IV3MOD3SRL-to-striker connection
    final isIV3ToStriker = connection.sourceDeviceId.contains('IV3MOD3SRL') &&
        connection.destDeviceId.contains('STRIKER');

    // Check if this is an Apollo VISERIEELF FET-to-striker connection.
    final isApolloFetToStriker =
        connection.sourceDeviceId == 'APOLLO_FET_BOARD' &&
            connection.destDeviceId.contains('APOLLO_STRIKER');

    // Check if this is an SBSI cabinet-to-SBSI-striker connection.
    // Source is an SBSI plate block (e.g. 'SBSI_1'); dest is an SBSI striker
    // block (e.g. 'TB_SBSI_STRIKER_*').  Wires enter from above, using the
    // user-configured striker colours (T1 = C/common, T2 = switched output).
    final isSBSIToStriker = connection.sourceDeviceId.startsWith('SBSI_') &&
        connection.destDeviceId.contains('SBSI_STRIKER');

    // Check if this is an SBSI relay → SBSI clock tower connection.
    // Wires route down from relay slot, through corridor, to clock tower terminals.
    final isSBSIToClock = connection.sourceDeviceId.startsWith('SBSI_') &&
        connection.destDeviceId == 'TB_CLOCK_TOWER';

    // Check if this is an IV3MOD3SRL-to-clock-connection (relay) connection
    // Also includes Movotron.N → Clock.C neutral wire connection
    final isIV3ToClockConn =
        (connection.sourceDeviceId.contains('IV3MOD3SRL') ||
                connection.sourceDeviceId.contains('TB_MOVOTRON')) &&
            connection.destDeviceId.contains('MOVOTRON_CLOCK_CONN');

    // Check if this is an Apollo relay → Apollo clock tower connection.
    // Wires route downward from the relay terminal row to the clock block above.
    final isApolloToClock = connection.sourceDeviceId == 'APOLLO_RELAYS' &&
        connection.destDeviceId == 'TB_MOVOTRON_CLOCK_CONN_APOLLO';

    // Debug Movotron→Clock connections
    if (connection.id.contains('conn_movotron_clock')) {
      debugPrint('🔵 Clock connection check for ${connection.id}:');
      debugPrint(
          '   Source contains IV3: ${connection.sourceDeviceId.contains('IV3MOD3SRL')}');
      debugPrint(
          '   Source contains MOVOTRON: ${connection.sourceDeviceId.contains('TB_MOVOTRON')}');
      debugPrint(
          '   Dest contains CLOCK_CONN: ${connection.destDeviceId.contains('MOVOTRON_CLOCK_CONN')}');
      debugPrint('   isIV3ToClockConn: $isIV3ToClockConn');
    }

    // Debug IV3-to-Clock connections
    if (isIV3ToClockConn) {
      debugPrint('Drawing IV3→Clock connection: ${connection.id}');
      debugPrint(
          '  Source: ${connection.sourceDeviceId}.${connection.sourceTerminalId} at $sourcePos');
      debugPrint(
          '  Dest: ${connection.destDeviceId}.${connection.destTerminalId} at $destPos');
    }

    // Determine wire color based on terminal type and configured settings
    Color wireColor;
    if (isIV3ToStriker) {
      // Striker wires: use configured striker colors based on polarity
      final fetMatch = RegExp(r'fet(\d+)_(plus|minus)')
          .firstMatch(connection.sourceTerminalId);
      final isPlus = fetMatch != null ? fetMatch.group(2) == 'plus' : true;
      wireColor = wireColorSettings.getStrikerColor(isPlus);
    } else if (isApolloFetToStriker) {
      // Apollo FET → striker: M+ common = T1 (−), M{n} output = T2 (+)
      final isPositive = connection.sourceTerminalId.contains('m_out');
      wireColor = wireColorSettings.getStrikerColor(isPositive);
    } else if (isSBSIToStriker) {
      // SBSI→striker: T1 = C/common (striker−), T2 = output (striker+)
      final isPositive = destTerminal.label == 'T2';
      wireColor = wireColorSettings.getStrikerColor(isPositive);
    } else if (isSBSIToClock) {
      // SBSI relay → clock tower: use same colours as IV3 relay-to-clock
      if (connection.destTerminalId.contains('1a')) {
        wireColor = wireColorSettings.iv3Fet1Color;
      } else if (connection.destTerminalId.contains('1b')) {
        wireColor = wireColorSettings.iv3Fet2Color;
      } else {
        wireColor = wireColorSettings.iv3CommonColor; // _c
      }
    } else if (isIV3ToClockConn) {
      // Relay wires to clock connection: use configured IV3 relay colors
      // 1A (relay 1) → iv3Fet1Color (black)
      // 1B (relay 2) → iv3Fet2Color (brown)
      // C (common) → iv3CommonColor (blue)
      if (connection.destTerminalId.contains('1a')) {
        wireColor = wireColorSettings.iv3Fet1Color;
      } else if (connection.destTerminalId.contains('1b')) {
        wireColor = wireColorSettings.iv3Fet2Color;
      } else if (connection.destTerminalId.endsWith('_c')) {
        wireColor = wireColorSettings.iv3CommonColor;
      } else {
        // Fallback
        wireColor = Colors.black;
      }
    } else if (isApolloToClock) {
      // Apollo relay → clock tower: same colour mapping as IV3/SBSI relay-to-clock
      if (connection.destTerminalId == 'apollo_clock_1a') {
        wireColor = wireColorSettings.iv3Fet1Color;
      } else if (connection.destTerminalId == 'apollo_clock_1b') {
        wireColor = wireColorSettings.iv3Fet2Color;
      } else {
        wireColor = wireColorSettings.iv3CommonColor; // C (common)
      }
    } else if ((connection.sourceDeviceId == 'TEMPORA_RELAYS' ||
            connection.sourceDeviceId == 'APOLLO_RELAYS') &&
        connection.destDeviceId.startsWith('TB_III6SV')) {
      // Relay block → III6SV converter:
      //   S / S1 / S2 (relay outputs)   → grey   (switched live from relay contacts)
      //   L (mains live supply)         → black
      //   N (mains neutral supply)      → blue
      // Note: no external wire goes to III6SV.C; the C↔N return path is a local
      // bridge at the III6SV, and the L'→C feed is a local bridge at the clock
      // relay block — both shown graphically, not as routed wires.
      final dLabel = destTerminal.label;
      if (dLabel == 'L') {
        wireColor = Colors.black;
      } else if (dLabel == 'N') {
        wireColor = Colors.blue.shade700;
      } else {
        wireColor = Colors.grey.shade500; // S, S1, S2
      }
    } else if (!isSensorWire) {
      // Motor phase wires (U, V, W): use configured phase colors
      // Linear motor terminals use numeric labels (1→U, 3→V, 5→W)
      final phaseLabel = _isLinearMotorTerminalBlock(destBlock.allTerminals)
          ? _mapLinearTerminalToPhase(destTerminal.label)
          : destTerminal.label;
      wireColor = wireColorSettings.getPhaseColor(phaseLabel);
    } else {
      // Sensor wires: keep default color from wireSpec
      wireColor = _getWireColor(connection.wireSpec.color);
    }

    final wirePaint = Paint()
      ..color = wireColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw routing based on wire type
    // IV3MOD3SRL-to-striker: horizontal exit from FET, then route to striker
    // IV3MOD3SRL-to-clock: horizontal exit from relay/N terminals, then route to clock
    // Sensor wires use horizontal routing near motors, power wires use orthogonal routing
    if (isIV3ToStriker) {
      // Extract FET number (1-4) and polarity from source terminal ID
      // Terminal IDs: iv3mod3srl_1_fet1_plus, iv3mod3srl_1_fet2_minus, etc.
      final fetMatch = RegExp(r'fet(\d+)_(plus|minus)')
          .firstMatch(connection.sourceTerminalId);
      final fetNum = fetMatch != null ? int.parse(fetMatch.group(1)!) : 1;
      final isPlus = fetMatch != null ? fetMatch.group(2) == 'plus' : true;
      // Unique wire index: FET1+=0, FET1-=1, FET2+=2, FET2-=3, ...
      final wireIndex = (fetNum - 1) * 2 + (isPlus ? 0 : 1);
      _drawStrikerWire(
          canvas, sourcePos, destPos, wirePaint, verticalOffset, wireIndex);
    } else if (isSBSIToStriker) {
      // SBSI→striker: route through a shared horizontal corridor so the user
      // can drag it as a bundle (same mechanism as motor wire bundles).

      // Bundle key: one per SBSI plate so all wires from plate N share a corridor.
      final plateMatch =
          RegExp(r'^SBSI_(\d+)').firstMatch(connection.sourceDeviceId);
      final plateNum = plateMatch?.group(1) ?? '1';
      final bundleKey = 'sbsi_${plateNum}_wires';

      // Per-wire stacking: separate the horizontal segments of parallel wires by
      // a few pixels based on the output position within its slot.
      // Terminal IDs: sbsi_1_slot{S}_(comm|out{N})
      final termMatch = RegExp(r'slot\d+_(comm|out(\d+))')
          .firstMatch(connection.sourceTerminalId);
      final outStr = termMatch?.group(1) ?? 'out1';
      final outIdx = outStr == 'comm'
          ? 0
          : outStr == 'out4'
              ? 1
              : outStr == 'out3'
                  ? 2
                  : outStr == 'out2'
                      ? 3
                      : 4; // out1
      const double wireSpacing = 8.0;

      // Base corridor Y: just below the cabinet outline (238 px from block origin),
      // plus a small gap, plus user-dragged override.
      const double sbsiCabinetBottom = 238.0;
      const double defaultGap = 15.0;
      final userOverride = bundleYOverrides[bundleKey] ?? 0.0;
      final bundleY = sourceBlock.diagramPosition.y +
          sbsiCabinetBottom +
          defaultGap +
          outIdx * wireSpacing +
          userOverride;

      _drawSBSIStrikerWire(canvas, sourcePos, destPos, wirePaint, bundleY);
    } else if (isSBSIToClock) {
      // SBSI relay → clock tower: same corridor routing as SBSI→striker wires.
      // Wire index per destination terminal: C=0, 1B=1, 1A=2.
      final wireIdx = connection.destTerminalId.endsWith('_c')
          ? 0
          : connection.destTerminalId.contains('_1b')
              ? 1
              : 2; // _1a
      const double wireSpacing = 4.0;
      const double sbsiCabinetBottom = 238.0;
      const double defaultGap = 10.0;
      final userOverride = bundleYOverrides['sbsi_clock_wires'] ?? 0.0;
      final bundleY = sourceBlock.diagramPosition.y +
          sbsiCabinetBottom +
          defaultGap +
          wireIdx * wireSpacing +
          userOverride;
      _drawSBSIStrikerWire(canvas, sourcePos, destPos, wirePaint, bundleY);
    } else if (isApolloFetToStriker) {
      // Apollo VISERIEELF FET → striker: striker is directly below its FET terminal.
      // Use a simple L-shaped route through a mid-point corridor.
      // Stagger M+ (common) and M{n} (output) wires by a small amount.
      final isCommon = connection.sourceTerminalId.contains('m_plus');
      const double wireSpacing = 4.0;
      final bundleY =
          (sourcePos.dy + destPos.dy) / 2 + (isCommon ? 0.0 : wireSpacing);
      _drawSBSIStrikerWire(canvas, sourcePos, destPos, wirePaint, bundleY);
    } else if (isApolloToClock) {
      // Apollo relay → clock: L-shaped routing with a short corridor just below
      // the relay terminal row (relay exits at y+178, clock block at y+228).
      // Stagger the three parallel wires by 4 px each.
      final wireIdx = connection.destTerminalId == 'apollo_clock_1a'
          ? 0
          : connection.destTerminalId == 'apollo_clock_1b'
              ? 1
              : 2; // apollo_clock_c
      const double wireSpacing = 4.0;
      final bundleY =
          sourceBlock.diagramPosition.y + 200.0 + wireIdx * wireSpacing;
      _drawSBSIStrikerWire(canvas, sourcePos, destPos, wirePaint, bundleY);
    } else if (isIV3ToClockConn) {
      // IV3MOD3SRL to Clock Cable: horizontal exit, then route to clock
      // Wire index: 0=terminal 1, 1=terminal 2, 2=N terminal
      // Support both IV3 relay terminals (_r1, _r2) and Movotron N terminal (_n)
      final wireIndex = connection.sourceTerminalId.contains('_r1')
          ? 0
          : connection.sourceTerminalId.contains('_r2')
              ? 1
              : 2;
      _drawClockCableWire(
          canvas, sourcePos, destPos, wirePaint, verticalOffset, wireIndex);
    } else if (isSensorWire) {
      _drawHorizontalWire(canvas, sourcePos, destPos, wirePaint, verticalOffset,
          sourceBlock.diagramPosition.y);
    } else {
      // Check if this is a connection to a linear motor (needs special routing with spacing)
      final isLinearMotor = _isLinearMotorTerminalBlock(destBlock.allTerminals);

      // Calculate stacking offset to prevent crossing
      // Key insight: The wire on the OUTSIDE of the turn should be on TOP
      // - Going RIGHT: rightmost wire on top (continues straight), leftmost on bottom
      // - Going LEFT: leftmost wire on top (continues straight), rightmost on bottom
      final goingRight = destPos.dx > sourcePos.dx;
      double baseStackingOffset = 0.0;

      if (isLinearMotor) {
        // Linear motor: U→1, V→3, W→5
        // Same stacking rules as standard motors for horizontal bundle ordering.
        // Wires need horizontal spacing when dropping down to terminals.
        double horizontalSpacing = 0.0;

        // Find motor index within its group for bundle offset spacing.
        // Top motor (index 0) has its vertical bundle closest to the motor,
        // subsequent motors offset further right to prevent overlap.
        int motorIndexInGroup = 0;
        for (final group in overlayGroups) {
          if (group.memberCount > 1 && group.isLinear) {
            for (int mi = 0; mi < group.memberIds.length; mi++) {
              final motorIdPrefix = 'motor_${group.memberIds[mi]}';
              if (connection.destTerminalId.startsWith(motorIdPrefix)) {
                motorIndexInGroup = mi;
                break;
              }
            }
          }
        }

        // Bundle offset: top motor (index 0) closest to motor,
        // each subsequent motor's bundle is offset further right by 24px.
        // The 3-wire spread per motor is [-8, 0, 8] = 16px total, so 24px
        // spacing ensures an 8px gap between adjacent motors' vertical drops.
        final bundleGroupOffset = motorIndexInGroup * 24.0;

        // Vertical corridor separation: each motor's wire bundle gets pushed
        // further from the midpoint to prevent the U wire of the lower motor
        // overlapping with the W wire of the motor above.
        // Each additional motor shifts its corridor by 25px (enough to clear
        // the 3-wire stacking of the motor above).
        final corridorVerticalShift = motorIndexInGroup * 25.0;

        if (goingRight) {
          final offset =
              wireColorSettings.getMotorOffsetRight(MotorCategory.linear) +
                  20.0;
          if (destTerminal.label == '1') {
            baseStackingOffset = offset + corridorVerticalShift;
            horizontalSpacing = -8.0 + bundleGroupOffset;
          } else if (destTerminal.label == '3') {
            baseStackingOffset = 0.0 + corridorVerticalShift;
            horizontalSpacing = 0.0 + bundleGroupOffset;
          } else if (destTerminal.label == '5') {
            baseStackingOffset = -offset + corridorVerticalShift;
            horizontalSpacing = 8.0 + bundleGroupOffset;
          }
        } else {
          final offset =
              wireColorSettings.getMotorOffsetLeft(MotorCategory.linear) - 20.0;
          if (destTerminal.label == '1') {
            baseStackingOffset = -offset + corridorVerticalShift;
            horizontalSpacing = -8.0 + bundleGroupOffset;
          } else if (destTerminal.label == '3') {
            baseStackingOffset = 0.0 + corridorVerticalShift;
            horizontalSpacing = 0.0 + bundleGroupOffset;
          } else if (destTerminal.label == '5') {
            baseStackingOffset = offset + corridorVerticalShift;
            horizontalSpacing = 8.0 + bundleGroupOffset;
          }
        }

        _drawLinearMotorWire(canvas, sourcePos, destPos, wirePaint,
            verticalOffset, baseStackingOffset, horizontalSpacing);
      } else {
        // Check if this is a DeCoster motor (3 terminals: U, V, W)
        final isDeCosterMotor =
            destBlock.allTerminals.any((t) => t.label == 'U') &&
                destBlock.allTerminals.any((t) => t.label == 'V') &&
                destBlock.allTerminals.any((t) => t.label == 'W') &&
                !destBlock.allTerminals.any((t) => t.label == 'U1');

        if (isDeCosterMotor) {
          // DeCoster motor: U (col 0), V (col 2), W (col 1, row 1)
          // All 3 wires share the same horizontal corridor.
          // V is the anchor wire (0 offset). U and W spread relative to V.
          // The slider offset controls the spread between wires, not a
          // uniform shift of the entire bundle.
          final deCosterSpacing = wireSpacing / 4;
          final deCosterOffset = goingRight
              ? wireColorSettings.getMotorOffsetRight(MotorCategory.deCoster)
              : wireColorSettings.getMotorOffsetLeft(MotorCategory.deCoster);
          final effectiveSpacing = deCosterSpacing + deCosterOffset;

          // Use the V terminal Y (row 0) as reference for consistent turnY
          // across all 3 wires, so they share the same horizontal corridor.
          final vTerminal = destBlock.getTerminal('V');
          final vTerminalPos = vTerminal != null
              ? _getTerminalPosition(destBlock, vTerminal)
              : null;
          final referenceEndY = vTerminalPos?.dy ?? destPos.dy;

          if (destTerminal.label == 'W') {
            // W wire: shares horizontal corridor with U and V, then routes
            // past V terminal to reach W in row 1.
            if (goingRight) {
              baseStackingOffset =
                  -effectiveSpacing; // W top (swapped for right)
            } else {
              baseStackingOffset = effectiveSpacing; // W bottom (natural)
            }

            // Calculate the shared corridor turnY (same formula as _drawOrthogonalWire)
            final turnY = (sourcePos.dy + referenceEndY) / 2 +
                verticalOffset +
                baseStackingOffset;

            // Route past V terminal to avoid crossing
            final clearanceX = (vTerminalPos?.dx ?? destPos.dx) + 5.0;

            // Draw: down from TRIAC → horizontal in corridor → past V → down to W → left to W
            final path = Path();
            path.moveTo(sourcePos.dx, sourcePos.dy);
            path.lineTo(sourcePos.dx, turnY);
            path.lineTo(clearanceX, turnY);
            path.lineTo(clearanceX, destPos.dy);
            path.lineTo(destPos.dx, destPos.dy);

            canvas.drawPath(path, wirePaint);
          } else {
            // DeCoster motor U and V wires: V anchors at 0, U spreads out
            if (destTerminal.label == 'U') {
              baseStackingOffset =
                  goingRight ? effectiveSpacing : -effectiveSpacing;
            } else if (destTerminal.label == 'V') {
              baseStackingOffset = 0.0; // V is the anchor
            }

            _drawOrthogonalWire(canvas, sourcePos, destPos, wirePaint,
                verticalOffset, baseStackingOffset, referenceEndY);
          }
        } else {
          // Standard rotating motor: U→U1, V→V1, W→W1
          // Stacking offsets separate the horizontal corridor for each wire.
          // Key insight: Reverse U and W positions in horizontal bundle when going RIGHT
          // to prevent visual wire crossing.
          //
          // Going LEFT (motor left of TRIAC):
          //   Natural order works: U top (-offset), V middle (0), W bottom (+offset)
          //   Wires travel cleanly without crossing.
          //
          // Going RIGHT (motor right of TRIAC):
          //   SWAP U and W in horizontal bundle: U bottom (+offset), V middle (0), W top (-offset)
          //   Creates one crossover at TRIAC, then wires remain cleanly separated.
          if (goingRight) {
            // Right motor: add 20 to slider value (-20..+20 → 0..40)
            final offset =
                wireColorSettings.getMotorOffsetRight(MotorCategory.standard) +
                    20.0;
            if (destTerminal.label == 'U1') {
              baseStackingOffset =
                  offset; // U travels in BOTTOM position (swapped!)
            } else if (destTerminal.label == 'V1') {
              baseStackingOffset = 0.0; // V stays in middle
            } else if (destTerminal.label == 'W1') {
              baseStackingOffset =
                  -offset; // W travels in TOP position (swapped!)
            }
          } else {
            // Left motor: subtract 20 from slider value (-20..+20 → -40..0)
            final offset =
                wireColorSettings.getMotorOffsetLeft(MotorCategory.standard) -
                    20.0;
            if (destTerminal.label == 'U1') {
              baseStackingOffset = -offset; // U on top (natural order)
            } else if (destTerminal.label == 'V1') {
              baseStackingOffset = 0.0; // V in middle
            } else if (destTerminal.label == 'W1') {
              baseStackingOffset = offset; // W on bottom (natural order)
            }
          }

          _drawOrthogonalWire(canvas, sourcePos, destPos, wirePaint,
              verticalOffset, baseStackingOffset);
        }
      }
    }

    // Draw capacitor on wire path for motors with capacitor.
    // Capacitor is needed for single-phase non-DeCoster motors.
    // Triggered when drawing the V wire (between U and V, just below TRIAC).
    // DeCoster motors have capacitor drawn inside _drawMotorTerminalBlock (above motor symbol).
    if (!isSensorWire &&
        !isIV3ToStriker &&
        !isSBSIToStriker &&
        !isSBSIToClock &&
        !isIV3ToClockConn &&
        !isApolloToClock) {
      final isVWire = destTerminal.label == 'V1' ||
          destTerminal.label == 'V' ||
          destTerminal.label == '3';
      if (isVWire) {
        // Determine capacitor need from power grid (single-phase) and motor brand.
        // This is more reliable than parsing the article number suffix from
        // the description, which can be fragile (e.g. 'MOTOR' suffix).
        final destDescription = destBlock.description ?? '';
        final descParts = destDescription.split(',');
        final articleNumber = descParts.isNotEmpty ? descParts[0].trim() : '';
        final isDeCoster = articleNumber.startsWith('IV21') ||
            destDescription.toLowerCase().contains('de coster') ||
            destDescription.toLowerCase().contains('decoster');
        final needsCapacitor =
            powerGrid != null && powerGrid!.phases == 1 && !isDeCoster;

        if (needsCapacitor) {
          // Find U wire source position to center capacitor between U and V
          final uTerminalLabel = destTerminal.label == 'V1'
              ? 'U1'
              : destTerminal.label == 'V'
                  ? 'U'
                  : '1';
          final uTerminal = destBlock.getTerminal(uTerminalLabel);
          Offset? uSourcePos;
          if (uTerminal != null) {
            // Find the U wire's source terminal on the TRIAC
            for (final conn in connections) {
              if (conn.destDeviceId == connection.destDeviceId &&
                  conn.destTerminalId == uTerminal.id) {
                final uSourceBlock = terminalBlocks.firstWhere(
                  (b) => b.id == conn.sourceDeviceId,
                );
                final uSourceTerminal =
                    uSourceBlock.getTerminalById(conn.sourceTerminalId);
                if (uSourceTerminal != null) {
                  uSourcePos =
                      _getTerminalPosition(uSourceBlock, uSourceTerminal);
                }
                break;
              }
            }
          }

          if (uSourcePos != null) {
            // Position capacitor between U and V source positions, just below TRIAC
            final capX = (uSourcePos.dx + sourcePos.dx) / 2;
            final capY = sourcePos.dy + 30;
            _drawCapacitor(canvas, Offset(capX, capY),
                horizontal: true, scale: 0.5);

            // Draw leads from capacitor to U and V wire paths
            final capLeadPaint = Paint()
              ..color = Colors.black87
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke;
            canvas.drawLine(Offset(capX - 5, capY), Offset(uSourcePos.dx, capY),
                capLeadPaint);
            canvas.drawLine(Offset(capX + 5, capY), Offset(sourcePos.dx, capY),
                capLeadPaint);
          }
        }
      }
    }

    // Draw wire label at midpoint (adjusted for offset)
    if (wireColorSettings.showWireGaugeLabels &&
        connection.label != null &&
        connection.label!.isNotEmpty) {
      final midPoint = Offset(
        (sourcePos.dx + destPos.dx) / 2,
        (sourcePos.dy + destPos.dy) / 2 + verticalOffset,
      );

      // Draw label background
      final labelBgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: midPoint, width: 80, height: 16),
          const Radius.circular(2),
        ),
        labelBgPaint,
      );

      // Draw label text (label already includes gauge in "3x 2.5mm²" format)
      _drawTextCentered(
        canvas,
        connection.label!,
        Offset(midPoint.dx, midPoint.dy - 6),
        const TextStyle(
          color: Colors.black87,
          fontSize: 7,
          fontWeight: FontWeight.normal,
        ),
      );
    }
  }

  /// Get terminal position based on block type (grid or linear layout)
  Offset? _getTerminalPosition(TerminalBlock block, Terminal terminal) {
    Offset blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;

    // ── Apollo / Tempora single-line relay blocks ─────────────────────────
    // Terminals are stored with diagramPosition.x = termsStartX + globalTi*24.
    // Wire exit point = bottom of the wire stub below the terminal square.
    if (block.id == 'APOLLO_RELAYS' ||
        block.id == 'APOLLO_FET_BOARD' ||
        block.id == 'TEMPORA_RELAYS') {
      const double sqSize = 18.0;
      const double stubLen = 30.0;
      const double termRowY = 130.0; // relay terminal row top
      const double supplyY = 190.0; // supply terminal top (bottom-right)
      const double supplyStub = 20.0;

      // Supply terminals exit downward from their own row
      if (terminal.id == 'TEMPORA_SUPPLY_L' ||
          terminal.id == 'TEMPORA_SUPPLY_N') {
        return Offset(
          blockPos.dx + terminal.diagramPosition.x + sqSize / 2,
          blockPos.dy + supplyY + sqSize + supplyStub,
        );
      }

      final wireBottomY = termRowY + sqSize + stubLen; // 178.0
      return Offset(
        blockPos.dx + terminal.diagramPosition.x + sqSize / 2,
        blockPos.dy + wireBottomY,
      );
    }

    // ── III6SV relay-to-DC converter blocks ──────────────────────────────
    // Top terminals (y=0): wires arrive from above → connect at y=0.
    // Bottom terminals (y=blockH): wires depart downward → connect at y=blockH.
    if (block.id.startsWith('TB_III6SV')) {
      return Offset(
        blockPos.dx + terminal.diagramPosition.x,
        blockPos.dy + terminal.diagramPosition.y,
      );
    }

    // IMPORTANT: Check Clock Cable BEFORE Movotron (more specific check first)
    // Check if this is a CLOCK CABLE block
    if (block.id.contains('MOVOTRON_CLOCK_CONN')) {
      // Apollo clock block: terminals are drawn horizontally at the TOP
      // (_drawApolloClockBlock layout: 1A at x=20, 1B at x=40, C at x=60, y=0)
      if (block.id.contains('APOLLO')) {
        const double blockWidth = 80.0;
        const double termSpacing = 20.0;
        // Terminal order in _createApolloClockTowerBlock: 0='1A', 1='1B', 2='C'
        final terminalIndex = terminals.indexWhere((t) => t.id == terminal.id);
        if (terminalIndex == -1) return null;
        final xOffset =
            blockWidth / 2 - termSpacing + terminalIndex * termSpacing;
        return Offset(blockPos.dx + xOffset, blockPos.dy); // y = 0 (top edge)
      }

      debugPrint(
          '🔍 Clock Cable position calc for terminal: ${terminal.id} (${terminal.label})');
      debugPrint(
          '   Block terminals: ${terminals.map((t) => '${t.id}(${t.label})').join(', ')}');

      // Clock cable terminals are drawn at (blockPos.dx + 15, blockPos.dy + 14 + i*12)
      // matching _drawClockCableTerminalBlock layout (terminals on left side)
      // Terminal order: C on top, then 1A, then 1B
      const double terminalX = 15.0;
      const double terminalStartY = 14.0;
      const double terminalSpacing = 12.0;

      // Find terminal by ID instead of object reference
      final terminalIndex = terminals.indexWhere((t) => t.id == terminal.id);
      debugPrint('   Terminal index: $terminalIndex');
      if (terminalIndex == -1) {
        debugPrint('   ✗ Terminal not found in block terminals list!');
        return null;
      }

      // Map terminal index to display position
      // Terminal indices: 1A=0, 1B=1, C=2
      // Display positions: C=0 (top), 1A=1 (middle), 1B=2 (bottom)
      int displayPosition;
      if (terminalIndex == 2) {
        displayPosition = 0; // C on top
      } else if (terminalIndex == 0) {
        displayPosition = 1; // 1A in middle
      } else {
        displayPosition = 2; // 1B at bottom
      }

      return Offset(
        blockPos.dx + terminalX,
        blockPos.dy + terminalStartY + (displayPosition * terminalSpacing),
      );
    }

    // Check if this is a Movotron block
    if (block.id.contains('MOVOTRON')) {
      const blockWidth = 750.0; // Match updated Movotron width
      const terminalSpacing = 50.0;
      const inputY = 40.0;
      const sensorSpacing = 3.0; // Sensor terminal spacing (10px)

      // Check if this is an input terminal (L1, L2, L3)
      if (terminal.label.contains('L') && !terminal.label.contains('PE')) {
        final inputTerminals = terminals
            .where((t) => t.label.contains('L') && !t.label.contains('PE'))
            .toList();
        final index = inputTerminals.indexOf(terminal);
        if (index == -1) return null;

        return Offset(
          blockPos.dx + 60 + (index * terminalSpacing),
          blockPos.dy + inputY,
        );
      }

      // Check if this is a sensor terminal (1-, 1+, 1D, 1P, etc.) - ON MOVOTRON BOARDS
      // Reversed by motor: rightmost motor terminals on left, leftmost motor terminals on right
      final sensorMatch = RegExp(r'^(\d+)[+\-DP]$').firstMatch(terminal.label);
      if (sensorMatch != null) {
        final sensorTerminals = terminals
            .where((t) => t.group == ConnectionGroup.communication)
            .toList();

        // Group by motor number (first digit), then reverse the groups
        final sensorsByMotor = <int, List<Terminal>>{};
        for (final term in sensorTerminals) {
          final match = RegExp(r'^(\d+)').firstMatch(term.label);
          if (match != null) {
            final motorNum = int.parse(match.group(1)!);
            sensorsByMotor.putIfAbsent(motorNum, () => []).add(term);
          }
        }

        // Sort motors in descending order (M3, M2, M1) and flatten
        final sortedMotorNums = sensorsByMotor.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final reorderedSensorTerminals = <Terminal>[];
        for (final motorNum in sortedMotorNums) {
          reorderedSensorTerminals.addAll(sensorsByMotor[motorNum]!);
        }

        final index = reorderedSensorTerminals.indexOf(terminal);
        if (index == -1) return null;

        // Position terminals ON Movotron boards (must match drawing code)
        const movotronBoardY = 200.0;
        const movotronBoardHeight = 50.0;
        const movotronBoardStartX = 20.0;
        const movotronBoardSpacing = 70.0;
        const terminalsPerBoard = 16; // 4 motors × 4 sensors each

        final boardIndex = index ~/ terminalsPerBoard; // 0 or 1
        final terminalIndexOnBoard = index % terminalsPerBoard;

        final boardX = blockPos.dx +
            movotronBoardStartX +
            (boardIndex * movotronBoardSpacing);
        final terminalX = boardX + 5 + (terminalIndexOnBoard * sensorSpacing);
        final terminalY = blockPos.dy + movotronBoardY + movotronBoardHeight;

        return Offset(terminalX, terminalY);
      }

      // Check if this is a motor output terminal (M1.U, M1.V, M1.W, M2.U, ...) - AT TRIAC BOTTOM
      final motorMatch = RegExp(r'M(\d+)\.([UVW])').firstMatch(terminal.label);
      if (motorMatch != null) {
        final motorNum = int.parse(motorMatch.group(1)!);
        final wireType = motorMatch.group(2)!; // U, V, or W

        // Group terminals by motor number to find TRIAC index
        final motorGroups = <int, List<Terminal>>{};
        for (final term in terminals) {
          final match = RegExp(r'M(\d+)\.[UVW]').firstMatch(term.label);
          if (match != null) {
            final num = int.parse(match.group(1)!);
            motorGroups.putIfAbsent(num, () => []).add(term);
          }
        }

        // Sort descending so Motor 1 TRIAC is leftmost, Motor N rightmost
        final sortedMotorNums = motorGroups.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final triacIdx = sortedMotorNums.indexOf(motorNum);
        if (triacIdx == -1) return null;

        // TRIAC dimensions and spacing (must match _drawMovotronTerminalBlock)
        const triacY =
            195.0; // Lowered to match drawing code (moved down 30px from 165)
        const triacHeight = 45.0; // Reduced height
        const triacWidth = 50.0;
        const triacGap = 10.0;
        const triacRightMargin = 20.0;

        // Check if IV3MOD3SRL exists to determine right edge
        // IV3MOD3SRL boards are stacked vertically, so width is constant
        final movotronNum = block.id.replaceAll('TB_MOVOTRON_', '');
        final hasIV3MOD3SRL = terminalBlocks.any((b) =>
            PaginatedDiagramPainter._isIV3ForMovotron(b.id, movotronNum));
        final triacRightEdge = hasIV3MOD3SRL
            ? blockPos.dx +
                650.0 -
                triacGap // Fixed: was 670, now 650 to match drawing code
            : blockPos.dx +
                blockWidth -
                triacRightMargin -
                20.0; // Also shift 20px left when no IV3

        // Calculate TRIAC position (right to left, same as drawing code)
        final triacX = triacRightEdge -
            ((triacIdx + 1) * triacWidth) -
            (triacIdx * triacGap);
        final triacBottom = blockPos.dy + triacY + triacHeight;

        // Position U, V, W terminals within TRIAC (matching drawing code)
        final wireIndex = wireType == 'U' ? 0 : (wireType == 'V' ? 1 : 2);
        const terminalStartX = 8.0;
        const terminalSpacingX = 14.0;
        final terminalX =
            triacX + terminalStartX + (wireIndex * terminalSpacingX);
        final terminalY = triacBottom;

        return Offset(terminalX, terminalY);
      }

      return null;
    }

    // Check if this is an SBSI cabinet block (source of SBSI→striker wires).
    // Terminal positions must match _drawSBSITerminalBlock wire-stub endpoints.
    if (block.id.startsWith('SBSI_') && !block.id.contains('STRIKER')) {
      // Layout constants (must match _drawSBSITerminalBlock)
      const double margin = 40.0;
      const double pageW = 1587.0;
      const double contentW = pageW - 2 * margin; // 1507.0
      const double slotW = contentW / 6; // ≈173.833
      const double sqSize = 18.0;
      const double sqGap = 6.0;
      const int numTerms = 5;
      const double totalTermW =
          numTerms * sqSize + (numTerms - 1) * sqGap; // 114.0
      // Wire stubs end at: origin.dy + margin + yWireBot - 4
      //   terminal bottom = margin + yTermRow + 4 + sqSize
      //   yTermRow = titleH+busH+sepH+cardRectH+4+slotNumH = 36+60+12+36+4+18 = 166
      //   terminal bottom = 40 + 166 + 4 + 18 = 228
      //   Wires exit at the terminal bottom (cabinet bottom is 10px further down).
      const double wireBottomY = 228.0;

      // Bus terminals:  titleH=36, busH=60 → busTermY = 36+(60-18)/2 = 57
      const double busTermY = 57.0;
      const double busTotalW = 6 * sqSize + 5 * sqGap; // 138.0
      const double busStartX = margin + (contentW - busTotalW) / 2; // 492.5

      final termId = terminal.id;

      // ── Bus terminals (TXC+/-, TXD+/-, +12V, GND) ───────────────────────
      const busLabels = ['txcp', 'txcm', 'txdp', 'txdm', 'v12', 'gnd'];
      final busIdx = busLabels.indexWhere((l) => termId.endsWith('_$l'));
      if (busIdx != -1) {
        final busX = busStartX + busIdx * (sqSize + sqGap) + sqSize / 2;
        return Offset(
            blockPos.dx + busX, blockPos.dy + margin + busTermY + sqSize);
      }

      // ── Slot terminals (COMM, OUT1–OUT4) ────────────────────────────────
      // Terminal ID format: sbsi_{plate}_slot{N}_{label}
      final slotMatch = RegExp(r'slot(\d+)_(\w+)').firstMatch(termId);
      if (slotMatch != null) {
        final slotNum = int.parse(slotMatch.group(1)!); // 1-based
        final label = slotMatch.group(2)!;
        final si = slotNum - 1; // 0-based column index

        // Terminal order in the painter: COMM(0), OUT4(1), OUT3(2), OUT2(3), OUT1(4)
        const termOrder = ['comm', 'out4', 'out3', 'out2', 'out1'];
        final ti = termOrder.indexOf(label);
        if (ti == -1) return null;

        final colCenterX = margin + si * slotW + slotW / 2;
        final termLeft = colCenterX - totalTermW / 2;
        final wireX = termLeft + ti * (sqSize + sqGap) + sqSize / 2;

        return Offset(blockPos.dx + wireX, blockPos.dy + wireBottomY);
      }

      return null;
    }

    // Check if this is an IV3MOD3SRL block (rendered inside Movotron cabinet)
    if (block.id.startsWith('TB_IV3MOD3SRL_')) {
      // IV3MOD3SRL is rendered by IV3MOD3SRLPainter inside the parent Movotron cabinet.
      // Find the parent Movotron block to get the cabinet position.
      // Extract movotron number and board index from ID
      // Format: TB_IV3MOD3SRL_1 or TB_IV3MOD3SRL_1_1, TB_IV3MOD3SRL_1_2
      final idParts = block.id.replaceAll('TB_IV3MOD3SRL_', '').split('_');
      final movotronNumber = idParts[0];
      final boardIndex = idParts.length > 1 ? int.parse(idParts[1]) - 1 : 0;

      final movotronBlock = terminalBlocks.firstWhere(
        (b) => b.id == 'TB_MOVOTRON_$movotronNumber',
        orElse: () => block, // Fallback to block itself
      );

      final cabinetPos = movotronBlock.diagramPosition.toOffset();

      // Board position matches IV3MOD3SRLPainter layout:
      // Boards are stacked vertically with spacing
      // boardX = cabinetPos.dx + 750 - 60 - 20 = cabinetPos.dx + 670
      // boardY = cabinetPos.dy + 10 + (boardIndex * (boardHeight + spacing)) - raised 10px higher
      const double boardX = 750.0 - 60.0 - 20.0; // 670.0
      const double boardHeight = 120.0;
      const double boardSpacing = 10.0;
      final boardY = 10.0 +
          (boardIndex * (boardHeight + boardSpacing)); // Raised from 20 to 10

      // N terminal is ABOVE the IV3MOD3SRL board (external, drawn by IV3MOD3SRLPainter)
      // Position relative to CABINET, not to board (matches IV3MOD3SRLPainter line 109)
      if (terminal.label == 'N') {
        const double boardWidth = 60.0;
        final double nTerminalX =
            boardX + (boardWidth / 2); // Centered above board
        const double nTerminalY = 5.0; // 5px from cabinet top (NOT from board!)

        return Offset(
          cabinetPos.dx + nTerminalX,
          cabinetPos.dy + nTerminalY, // Fixed: removed boardY offset
        );
      }

      // L terminal is also ABOVE the board (external, drawn by IV3MOD3SRLPainter)
      // Position relative to CABINET, not to board (matches IV3MOD3SRLPainter line 123)
      if (terminal.label == 'L') {
        const double lTerminalX =
            boardX - 12.0; // 10-15px to the left of board's left edge
        const double lTerminalY = 5.0; // Same height as N terminal

        return Offset(
          cabinetPos.dx + lTerminalX,
          cabinetPos.dy + lTerminalY, // Fixed: removed boardY offset
        );
      }

      // C terminal is on LEFT SIDE of the board (moved higher)
      if (terminal.label == 'C' && !terminal.id.contains('_r')) {
        const double leftTerminalX = 8.0;
        const double cTerminalY = 28.0; // Moved up from 36.0

        return Offset(
          cabinetPos.dx + boardX + leftTerminalX,
          cabinetPos.dy + boardY + cTerminalY,
        );
      }

      // Relay output terminals on RIGHT SIDE (1, 2)
      if (terminal.id.contains('_r1') || terminal.id.contains('_r2')) {
        const double rightTerminalX = 60.0 - 8.0; // Right edge of board
        const double relayStartY = 25.0;
        const double relaySpacing = 8.0;

        final relayIndex = terminal.id.contains('_r1') ? 0 : 1;

        return Offset(
          cabinetPos.dx + boardX + rightTerminalX,
          cabinetPos.dy + boardY + relayStartY + (relayIndex * relaySpacing),
        );
      }

      // Check if this is a FET terminal (fet1_plus, fet1_minus, etc.)
      final fetMatch = RegExp(r'fet(\d+)_(plus|minus)').firstMatch(terminal.id);
      if (fetMatch != null) {
        final fetNum = int.parse(fetMatch.group(1)!);
        final isPlus = fetMatch.group(2) == 'plus';
        const double rightTerminalX = 60.0 - 8.0; // Right edge of board
        const double fetStartY = 50.0;
        const double fetSpacing = 16.0;
        final fetY = fetStartY + ((fetNum - 1) * fetSpacing);
        final termOffset =
            isPlus ? 2.0 : 10.0; // +2 for plus, +10 for minus (8px apart)
        return Offset(
          cabinetPos.dx + boardX + rightTerminalX,
          cabinetPos.dy + boardY + fetY + termOffset,
        );
      }

      return null;
    }

    // Check if this is the SBSI clock tower block.
    // Terminals C, 1B, 1A are drawn horizontally at the top of the block,
    // matching _drawSBSIClockTowerBlock layout.
    if (block.id == 'TB_CLOCK_TOWER') {
      const double blockWidth = 80.0;
      const double termSpacing = 24.0;
      final double cX = blockWidth / 2 - termSpacing; // 16
      final double ibX = blockWidth / 2; // 40
      final double iaX = blockWidth / 2 + termSpacing; // 64
      const double termY = 0.0;
      final double termX = terminal.id.endsWith('_c')
          ? cX
          : terminal.id.contains('_1b')
              ? ibX
              : iaX; // _1a
      return Offset(blockPos.dx + termX, blockPos.dy + termY);
    }

    // Check if this is a STRIKER block
    if (block.id.contains('STRIKER')) {
      if (block.id.contains('SBSI') || block.id.contains('APOLLO_STRIKER')) {
        // SBSI/Apollo striker: horizontal terminals at the TOP of the block.
        // Matches _drawSBSIStrikerBlock layout:
        //   T1 at blockWidth/2 - 12,  T2 at blockWidth/2 + 12,  y = 0
        const double blockWidth = 53.0;
        const double termSpacing = 24.0;
        final double t1X = blockWidth / 2 - termSpacing / 2;
        final double t2X = blockWidth / 2 + termSpacing / 2;
        const double termY = 0.0;

        final index = terminals.indexOf(terminal);
        if (index == -1) return null;
        final xOffset = index == 0 ? t1X : t2X;
        return Offset(blockPos.dx + xOffset, blockPos.dy + termY);
      }

      // Non-SBSI striker (IV3MOD3SRL): vertical terminals on the LEFT side.
      // Wires arrive from the left, matching _drawStrikerTerminalBlock.
      const double blockHeight = 40.0;
      const double t1Y = blockHeight / 3; // ≈ 13.3
      const double t2Y = 2 * blockHeight / 3; // ≈ 26.7

      final index = terminals.indexOf(terminal);
      if (index == -1) return null;
      return Offset(blockPos.dx, blockPos.dy + (index == 0 ? t1Y : t2Y));
    }

    // Check if this is a linear motor block (1-6 terminals)
    final isLinearMotorBlock = _isLinearMotorTerminalBlock(terminals);
    if (isLinearMotorBlock) {
      // Check if this is a sensor terminal (positioned below motor group, left side)
      if (terminal.group == ConnectionGroup.communication) {
        final sensorTerminals = terminals
            .where((t) => t.group == ConnectionGroup.communication)
            .toList();
        final index = sensorTerminals.indexOf(terminal);
        if (index == -1) return null;

        // Position sensors below the motor group bounding box
        final group = _findOverlayGroupForBlock(block);
        if (group != null) {
          final basePos = _getGroupSensorBasePosition(group);
          const sensorSpacing = 3.0;
          return Offset(basePos.dx, basePos.dy + (index * sensorSpacing));
        }
        // Fallback for ungrouped: below linear motor block
        const sensorY = 70.0;
        const sensorSpacing = 3.0;
        final sensorX = blockPos.dx + 5 + (index * sensorSpacing);
        return Offset(sensorX, blockPos.dy + sensorY);
      }

      // Linear motor terminals (1-6) positioned vertically
      const terminalX = 28.0;
      const terminalRadius = 3.0;
      const terminalSpacing = 7.5;
      const terminalsStartY = 12.0;

      // Get terminal index (1-6)
      final terminalNum = int.tryParse(terminal.label);
      if (terminalNum == null || terminalNum < 1 || terminalNum > 6) {
        return null;
      }

      final terminalY =
          blockPos.dy + terminalsStartY + ((terminalNum - 1) * terminalSpacing);
      // Wire connects to right edge of terminal circle, not center
      return Offset(blockPos.dx + terminalX + terminalRadius, terminalY);
    }

    // Check if this is a motor block
    final isMotorBlock = _isMotorTerminalBlock(terminals);
    if (isMotorBlock) {
      // Check if this is a sensor terminal
      if (terminal.group == ConnectionGroup.communication) {
        // Reversed order (S4, S3, S2, S1 from left to right)
        final sensorTerminals = terminals
            .where((t) => t.group == ConnectionGroup.communication)
            .toList()
            .reversed
            .toList();
        final index = sensorTerminals.indexOf(terminal);
        if (index == -1) return null;

        // Position sensors below the motor group bounding box
        final group = _findOverlayGroupForBlock(block);
        if (group != null) {
          final basePos = _getGroupSensorBasePosition(group);
          const sensorSpacing = 3.0;
          return Offset(basePos.dx, basePos.dy + (index * sensorSpacing));
        }
        // Fallback for ungrouped: below motor block
        const sensorSpacing = 3.0;
        const sensorY = 70.0;
        final sensorX = blockPos.dx + 5 + (index * sensorSpacing);
        return Offset(sensorX, blockPos.dy + sensorY);
      }

      // Check if this is a DeCoster motor (3 terminals: U, V, W)
      final isDeCosterMotor = terminals.any((t) => t.label == 'U') &&
          terminals.any((t) => t.label == 'V') &&
          terminals.any((t) => t.label == 'W') &&
          !terminals.any((t) => t.label == 'U1');

      if (isDeCosterMotor) {
        // DeCoster motor sparse 3×2 grid: positions 1, 3, 5
        const terminalSpacing = 17.5;
        const terminalAreaTop = 8.0; // Match _drawMotorTerminalBlock

        final positionMap = {
          'U': {'col': 0, 'row': 0}, // Position 1
          'V': {'col': 2, 'row': 0}, // Position 3
          'W': {'col': 1, 'row': 1}, // Position 5
        };

        final pos = positionMap[terminal.label];
        if (pos == null) return null;

        return Offset(
          blockPos.dx +
              7.5 +
              (pos['col']! * terminalSpacing) +
              terminalSpacing / 2,
          blockPos.dy +
              terminalAreaTop +
              (pos['row']! * terminalSpacing) +
              terminalSpacing / 2,
        );
      }

      // Standard motor block uses 3×2 grid layout (50% smaller)
      const terminalSpacing = 17.5; // Was 35.0
      const terminalAreaTop = 8.0; // Match _drawMotorTerminalBlock

      // Map terminal label to grid position
      // Order: U1 V1 W1 (top row), W2 U2 V2 (bottom row - shifted)
      final terminalOrder = ['U1', 'V1', 'W1', 'W2', 'U2', 'V2'];
      final index = terminalOrder.indexOf(terminal.label);

      if (index == -1) return null; // Terminal not in standard motor layout

      final col = index % 3;
      final row = index ~/ 3;

      return Offset(
        blockPos.dx +
            7.5 +
            (col * terminalSpacing) +
            terminalSpacing / 2, // Was 15
        blockPos.dy +
            terminalAreaTop +
            (row * terminalSpacing) +
            terminalSpacing / 2,
      );
    } else {
      // Standard block uses linear layout (power input)
      const terminalSpacing = 30.0;
      const terminalAreaTop = 30.0;

      final index = terminals.indexOf(terminal);
      if (index == -1) return null;

      return Offset(
        blockPos.dx + 10 + (index * terminalSpacing) + terminalSpacing / 2,
        blockPos.dy + terminalAreaTop + 20,
      );
    }
  }

  /// Draw orthogonal wire routing (90-degree bends) with anti-crossing stacking.
  ///
  /// TRIAC terminals are already horizontally spaced (U, V, W at different X positions).
  /// All wires turn horizontal at the SAME Y level (no staircase), with slight
  /// vertical stacking to prevent crossing.
  ///
  /// Routing:
  /// 1. Go down from TRIAC terminal (all at different X positions)
  /// 2. All turn horizontal at same Y level (with tiny vertical offsets for stacking)
  /// 3. Continue horizontal to motor terminal X position
  /// 4. Drop vertically to terminal
  ///
  /// The [verticalOffset] is for page-level spacing of parallel wires.
  /// The [stackingOffset] creates tiny vertical stacking to prevent double crossing.

  void _drawOrthogonalWire(Canvas canvas, Offset start, Offset end, Paint paint,
      double verticalOffset,
      [double stackingOffset = 0.0, double? referenceEndY]) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // All wires turn horizontal at same Y level, with slight vertical stacking
    // Use referenceEndY if provided (ensures all wires in a bundle use same baseline)
    final effectiveEndY = referenceEndY ?? end.dy;
    final turnY =
        (start.dy + effectiveEndY) / 2 + verticalOffset + stackingOffset;

    // Step 1: Go down to turning point (maintaining TRIAC X position)
    path.lineTo(start.dx, turnY);

    // Step 2: Turn horizontal to motor terminal X position
    path.lineTo(end.dx, turnY);

    // Step 3: Drop vertically to terminal
    final endExtension = turnY < end.dy ? -3.0 : 3.0;
    path.lineTo(end.dx, end.dy + endExtension);

    canvas.drawPath(path, paint);
  }

  /// Draw wire routing from IV3MOD3SRL relay/N terminals to clock cable block.
  ///
  /// Wires exit horizontally from IV3MOD3SRL terminals,
  /// then route to the clock cable terminal on the right side.
  ///
  /// Routing:
  /// 1. Start at IV3 terminal (relay or N terminal)
  /// 2. Go horizontally right past the cabinet edge
  /// 3. Turn vertically to align with clock cable terminal Y
  /// 4. Go horizontally to reach clock cable terminal
  void _drawClockCableWire(Canvas canvas, Offset start, Offset end, Paint paint,
      double verticalOffset, int wireIndex) {
    final path = Path();
    path.moveTo(start.dx, start.dy + verticalOffset);

    // Similar to striker wires, exit horizontally from IV3MOD3SRL
    const double cabinetClearance = 35.0; // Minimum clearance from cabinet
    const double clockMargin = 60.0; // Distance from clock where wires bend
    const double wireSpacing = 8.0; // Horizontal spacing for the 3 wires
    const int maxWires = 3; // 3 clock wires (1, 2, N)

    // Stack wires vertically for better separation
    final goingDown = end.dy > start.dy;
    final spacingIndex = goingDown ? (maxWires - 1 - wireIndex) : wireIndex;

    // Calculate bend point relative to clock cable position
    // ADD spacing (not subtract) to offset wires horizontally
    final bendX = (end.dx - clockMargin + (spacingIndex * wireSpacing))
        .clamp(start.dx + cabinetClearance, end.dx - 10.0);

    // Step 1: Go horizontally right past the cabinet
    path.lineTo(bendX, start.dy + verticalOffset);

    // Step 2: Turn vertically to align with clock cable terminal Y
    path.lineTo(bendX, end.dy);

    // Step 3: Go horizontally to clock cable terminal
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  /// Draw wire routing from IV3MOD3SRL FET terminals to striker blocks.
  ///
  /// Wires exit horizontally from the right edge of the IV3MOD3SRL board,
  /// then route to the striker terminal on the right side of the cabinet.
  ///
  /// Routing:
  /// 1. Start at FET terminal (right edge of IV3MOD3SRL inside cabinet)
  /// 2. Go horizontally right past the cabinet edge
  /// 3. Turn vertically to align with striker terminal Y
  /// 4. Go horizontally to reach striker terminal
  void _drawStrikerWire(Canvas canvas, Offset start, Offset end, Paint paint,
      double verticalOffset, int wireIndex) {
    final path = Path();
    path.moveTo(start.dx, start.dy + verticalOffset);

    // FET terminals are ~28px inside the Movotron cabinet right edge.
    // Wires go straight horizontally from cabinet exit, then bend close to striker.
    // Position the bend near the striker (margin from striker) for cleaner routing.
    const double cabinetClearance = 35.0; // Minimum clearance from cabinet
    const double strikerMargin = 80.0; // Distance from striker where wires bend
    final double wireSpacingPx = wireColorSettings.strikerWireSpacing;
    const int maxWires = 8; // 4 FETs × 2 polarities

    // When going DOWN (end below start), the wire with the longest vertical
    // drop must bend at the innermost X (closest to the striker) so shorter
    // drops wrap around it. This prevents the double-crossing effect where
    // wires cross on the way down and again on the horizontal return.
    // When going UP the natural order already nests correctly.
    final goingDown = end.dy > start.dy;
    final spacingIndex = goingDown ? (maxWires - 1 - wireIndex) : wireIndex;

    // Calculate bend point relative to striker position (closer to striker)
    // Use max to ensure bend is at least past cabinet clearance
    // ADD spacing (not subtract) to offset wires horizontally
    final bendX = (end.dx - strikerMargin + (spacingIndex * wireSpacingPx))
        .clamp(start.dx + cabinetClearance, end.dx - 10.0);

    // Step 1: Go horizontally right past the cabinet, each wire to its own X
    path.lineTo(bendX, start.dy + verticalOffset);

    // Step 2: Turn vertically to align with striker terminal Y
    path.lineTo(bendX, end.dy);

    // Step 3: Go horizontally to striker terminal
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  /// Draw wire routing from SBSI slot terminal down to an SBSI striker block.
  ///
  /// The source is at the bottom of an SBSI wire stub (already routed downward
  /// inside the cabinet drawing) and the destination is at the top of a
  /// horizontal-terminal striker block.  Routing is a simple L-shape:
  ///
  ///   1. Continue straight down from [start] to an intermediate Y midway
  ///      between source and dest.
  ///   2. Turn horizontal to align with [end.dx].
  ///   3. Drop straight down to [end].
  /// Route a wire from an SBSI cabinet terminal to a striker block.
  ///
  /// [bundleY] is the Y coordinate of the shared horizontal corridor for this
  /// SBSI plate.  All wires from the same plate pass through this corridor so
  /// the user can drag it as a group (same mechanism as motor bundles).
  ///
  /// If [bundleY] is already past [end] (user dragged it too far), falls back
  /// to a midpoint bend to avoid routing wires upward.
  void _drawSBSIStrikerWire(
      Canvas canvas, Offset start, Offset end, Paint paint, double bundleY) {
    // Clamp corridor Y so the wire never routes upward from corridor to dest.
    final safeY = bundleY.clamp(start.dy, end.dy);

    if ((start.dx - end.dx).abs() < 2.0) {
      // Already vertically aligned — straight line.
      canvas.drawLine(start, end, paint);
      return;
    }

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(start.dx, safeY) // straight down to corridor
      ..lineTo(end.dx, safeY) // horizontal along corridor
      ..lineTo(end.dx, end.dy); // drop to terminal

    canvas.drawPath(path, paint);
  }

  /// Draw wire routing for linear motors with ] shaped approach.
  ///
  /// TRIAC terminals are horizontally spaced (U, V, W at different X positions).
  /// Linear motor terminals 1, 3, 5 are vertically stacked (same X, different Y).
  ///
  /// Routing strategy (creates ] shape to the right of motor):
  /// 1. Go down from TRIAC terminal (all wires at different X)
  /// 2. All turn horizontal at SAME Y level (with slight vertical stacking)
  /// 3. Extend horizontally past motor's right edge
  /// 4. Drop down vertically to the RIGHT of motor (wires horizontally spaced)
  /// 5. Come back left horizontally to reach terminal
  ///
  /// The [stackingOffset] prevents crossing at horizontal turn.
  /// The [verticalOffset] is for page-level spacing of parallel wires.
  /// The [horizontalSpacing] creates separation when dropping down.
  void _drawLinearMotorWire(
      Canvas canvas,
      Offset start,
      Offset end,
      Paint paint,
      double verticalOffset,
      double stackingOffset,
      double horizontalSpacing) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Step 1: All wires go down to same Y level, with slight vertical stacking
    final turnY = (start.dy + end.dy) / 2 + verticalOffset + stackingOffset;
    path.lineTo(start.dx, turnY);

    // Step 2: Extend horizontally past motor's right edge
    // Each wire gets horizontal spacing for clear separation
    // Base distance of 20px ensures even leftmost wire (U, -8px) is outside motor
    final motorRightEdge = end.dx;
    final dropX = motorRightEdge + 20.0 + horizontalSpacing;
    path.lineTo(dropX, turnY);

    // Step 3: Drop down vertically to terminal Y level (forming ] shape)
    // Wires are spaced horizontally during this vertical drop
    path.lineTo(dropX, end.dy);

    // Step 4: Come back left to reach terminal
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  /// Draw horizontal wire routing for sensor connections.
  ///
  /// Purely orthogonal routing (only right angles, no diagonals):
  /// - Drop vertically from Movotron terminal
  /// - Run horizontally at specific height (determined by verticalOffset)
  /// - Rise vertically to motor sensor terminal
  ///
  /// The [verticalOffset] parameter determines the vertical height of the horizontal segment.
  /// More negative offset = runs lower (closer to page bottom margin).
  ///
  /// [sourceBlockY] is the diagram-space Y of the source (Movotron) block's top-left corner.
  /// The horizontal corridor is placed near the bottom of that block's 764 px logical "page"
  /// so the wire always routes correctly regardless of which rendering page is active.
  void _drawHorizontalWire(Canvas canvas, Offset start, Offset end, Paint paint,
      [double verticalOffset = 0.0, double sourceBlockY = 0.0]) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // The horizontal corridor runs near the bottom of the source block's logical page
    // (each Movotron occupies a 764 px slice in diagram coordinates).
    // Using the source block's page bottom keeps the corridor consistent across
    // multi-page layouts where the rendering page boundary may differ.
    const movotronPageHeight = 764.0;
    const bottomClearance = 21.0;
    final bottomY = sourceBlockY + movotronPageHeight - bottomClearance;

    // Calculate horizontal segment Y position
    // verticalOffset determines which "layer" this wire runs at
    final horizontalY = bottomY + verticalOffset;

    // Step 1: Draw vertical drop from Movotron to horizontal run level
    path.lineTo(start.dx, horizontalY);

    // Step 2: Draw horizontal run to be directly under destination
    path.lineTo(end.dx, horizontalY);

    // Step 3: Draw vertical rise to motor sensor terminal - extend to terminal edge
    // Wires drawn on top now, sensor terminals have radius 1.5px, extend 2px to connect
    // If wire going DOWN (horizontalY < end.dy): extend UPWARD (negative) to reach from above
    // If wire going UP (horizontalY > end.dy): extend DOWNWARD (positive) to reach from below
    final endExtension = horizontalY < end.dy
        ? -2.0 // Wire going down, extend upward to reach terminal edge
        : 2.0; // Wire going up, extend downward to reach terminal edge
    path.lineTo(end.dx, end.dy + endExtension);

    canvas.drawPath(path, paint);
  }

  /// Draw a single jumper connection for star/delta motor configurations
  void _drawJumper(Canvas canvas, JumperConnection jumper) {
    // For now, jumpers are drawn as simple arcs between terminals
    // In a motor 3×2 grid:
    // Star: U2-V2-W2 connected together (bottom row star point)
    // Delta: U1-W2, V1-U2, W1-V2 (diagonal connections)

    // TODO: Implement full jumper rendering
    // This requires finding the motor block and calculating terminal positions
    // For now, jumper configuration is shown as text indicator on motor blocks
  }

  /// Draw a custom connection with configurable style (single or triple lines).
  // void _drawCustomConnection(Canvas canvas, CustomConnection connection) {
  //   // Find source and destination blocks
  //   final sourceBlock = terminalBlocks.firstWhere(
  //     (b) => b.id == connection.sourceBlockId,
  //     orElse: () => terminalBlocks.first,
  //   );

  //   final destBlock = terminalBlocks.firstWhere(
  //     (b) => b.id == connection.destBlockId,
  //     orElse: () => terminalBlocks.first,
  //   );

  //   // Get connection endpoints
  //   Offset sourcePos;
  //   Offset destPos;

  //   if (connection.sourceTerminalId != null) {
  //     final terminal =
  //         sourceBlock.getTerminalById(connection.sourceTerminalId!);
  //     sourcePos = _getTerminalPosition(sourceBlock, terminal!) ??
  //         sourceBlock.diagramPosition.toOffset();
  //   } else {
  //     // Use block center
  //     final terminals = sourceBlock.allTerminals;
  //     final isMotor = _isMotorTerminalBlock(terminals);
  //     final blockWidth = isMotor ? 145.0 : terminals.length * 30.0 + 20.0;
  //     sourcePos = Offset(
  //       sourceBlock.diagramPosition.x + blockWidth / 2,
  //       sourceBlock.diagramPosition.y + 60,
  //     );
  //   }

  //   if (connection.destTerminalId != null) {
  //     final terminal = destBlock.getTerminalById(connection.destTerminalId!);
  //     destPos = _getTerminalPosition(destBlock, terminal!) ??
  //         destBlock.diagramPosition.toOffset();
  //   } else {
  //     // Use block center
  //     final terminals = destBlock.allTerminals;
  //     final isMotor = _isMotorTerminalBlock(terminals);
  //     final blockWidth = isMotor ? 145.0 : terminals.length * 30.0 + 20.0;
  //     destPos = Offset(
  //       destBlock.diagramPosition.x + blockWidth / 2,
  //       destBlock.diagramPosition.y + 60,
  //     );
  //   }

  //   // Draw connection based on style
  //   switch (connection.style) {
  //     case ConnectionStyle.single:
  //       _drawSingleLine(canvas, sourcePos, destPos, connection.color,
  //           connection.strokeWidth);
  //       break;
  //     case ConnectionStyle.triple:
  //       _drawTripleLine(canvas, sourcePos, destPos, connection.color,
  //           connection.strokeWidth);
  //       break;
  //     case ConnectionStyle.dashed:
  //       _drawDashedLine(canvas, sourcePos, destPos, connection.color,
  //           connection.strokeWidth);
  //       break;
  //   }

  //   // Draw label if present
  //   if (connection.label != null && connection.label!.isNotEmpty) {
  //     final midPoint = Offset(
  //       (sourcePos.dx + destPos.dx) / 2,
  //       (sourcePos.dy + destPos.dy) / 2,
  //     );

  //     // Draw label background
  //     final labelBgPaint = Paint()
  //       ..color = Colors.white.withValues(alpha: 0.9)
  //       ..style = PaintingStyle.fill;

  //     canvas.drawRRect(
  //       RRect.fromRectAndRadius(
  //         Rect.fromCenter(center: midPoint, width: 100, height: 18),
  //         const Radius.circular(3),
  //       ),
  //       labelBgPaint,
  //     );

  //     // Draw label text
  //     _drawTextCentered(
  //       canvas,
  //       connection.label!,
  //       Offset(midPoint.dx, midPoint.dy - 6),
  //       const TextStyle(
  //         color: Colors.black87,
  //         fontSize: 8,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     );
  //   }
  // }

  // /// Draw single line connection
  // void _drawSingleLine(
  //     Canvas canvas, Offset start, Offset end, Color color, double strokeWidth,
  //     [double verticalOffset = 0.0]) {
  //   final paint = Paint()
  //     ..color = color
  //     ..strokeWidth = strokeWidth
  //     ..style = PaintingStyle.stroke
  //     ..strokeCap = StrokeCap.round;

  //   _drawOrthogonalWire(canvas, start, end, paint, verticalOffset);
  // }

  /// Draw triple parallel lines (for 3-phase power connections)
  // void _drawTripleLine(
  //     Canvas canvas, Offset start, Offset end, Color color, double strokeWidth,
  //     [double verticalOffset = 0.0]) {
  //   // Calculate perpendicular offset for parallel lines
  //   final dx = end.dx - start.dx;
  //   final dy = end.dy - start.dy;
  //   final length = (dx * dx + dy * dy);
  //   if (length == 0) return;

  //   // Perpendicular unit vector
  //   final perpX = -dy / length;
  //   final perpY = dx / length;

  //   // Spacing between parallel lines
  //   const spacing = 5.0;

  //   final paint = Paint()
  //     ..color = color
  //     ..strokeWidth = strokeWidth
  //     ..style = PaintingStyle.stroke
  //     ..strokeCap = StrokeCap.round;

  //   // Draw three parallel lines
  //   for (int i = -1; i <= 1; i++) {
  //     final offset = i * spacing;
  //     final startOffset = Offset(
  //       start.dx + perpX * offset,
  //       start.dy + perpY * offset,
  //     );
  //     final endOffset = Offset(
  //       end.dx + perpX * offset,
  //       end.dy + perpY * offset,
  //     );

  //     _drawOrthogonalWire(
  //         canvas, startOffset, endOffset, paint, verticalOffset);
  //   }
  // }

  /// Draw dashed line connection
  // void _drawDashedLine(
  //     Canvas canvas, Offset start, Offset end, Color color, double strokeWidth,
  //     [double verticalOffset = 0.0]) {
  //   final paint = Paint()
  //     ..color = color
  //     ..strokeWidth = strokeWidth
  //     ..style = PaintingStyle.stroke
  //     ..strokeCap = StrokeCap.round;

  //   const dashWidth = 8.0;
  //   const dashSpace = 4.0;

  //   final path = Path();
  //   path.moveTo(start.dx, start.dy);

  //   // Calculate midpoint for orthogonal routing and apply vertical offset
  //   final midY = (start.dy + end.dy) / 2 + verticalOffset;

  //   // Vertical segment down from start
  //   _drawDashedSegment(canvas, Offset(start.dx, start.dy),
  //       Offset(start.dx, midY), paint, dashWidth, dashSpace);

  //   // Horizontal segment across (this is where spacing is applied)
  //   _drawDashedSegment(canvas, Offset(start.dx, midY), Offset(end.dx, midY),
  //       paint, dashWidth, dashSpace);

  //   // Vertical segment down to end
  //   _drawDashedSegment(canvas, Offset(end.dx, midY), Offset(end.dx, end.dy),
  //       paint, dashWidth, dashSpace);
  // }

  /// Draw page boundary overlay
}
