part of 'paginated_diagram_painter.dart';

// Terminal block, connection, and wire routing drawing methods.
// Part of PaginatedDiagramPainter — has full access to all private fields.

extension WiringElementPainter on PaginatedDiagramPainter {
  /// Builds a [DeviceInstance] from a [TerminalBlock] using [def] as the blueprint.
  ///
  /// Param values come from [TerminalBlock.deviceParams] (merged over definition
  /// defaults). Terminal connection state is mapped by terminal label — this
  /// assumes device definitions use the terminal label as the terminal id
  /// (the convention used by all bundled devices).
  DeviceInstance _buildDeviceInstance(TerminalBlock block, DeviceDefinition def) {
    // Map terminal connection state: label → isConnected
    final connected = <String, bool>{};
    for (final terminal in block.allTerminals) {
      connected[terminal.label] = terminal.isConnected;
    }

    // Merge block.name and block.description into params so DeviceDefinition
    // drawables can reference ${name} and ${description} without requiring
    // the service layer to duplicate this in deviceParams.
    final params = <String, dynamic>{
      'name': block.name,
      if (block.description != null && block.description!.isNotEmpty)
        'description': block.description!,
      ...?block.deviceParams,
    };

    return DeviceInstance(
      definition: def,
      position: block.diagramPosition.toOffset(),
      paramValues: params,
      terminalConnected: connected,
    );
  }

  void _drawTerminalBlock(Canvas canvas, TerminalBlock block) {
    final key = block.blockRenderKey;

    // DeviceRenderer dispatch (data-driven device definitions)
    if (key != null && deviceRegistry.containsKey(key)) {
      final instance = _buildDeviceInstance(block, deviceRegistry[key]!);
      const DeviceRenderer().render(canvas, instance,
          context: _buildRenderContext());
      return;
    }

    // Custom renderers (registered externally for app-specific block types)
    if (key != null && customBlockPainters.containsKey(key)) {
      final handled =
          customBlockPainters[key]!(canvas, block, _buildPaintContext());
      if (handled) return;
    }

    // Backward compat: detect motor type from terminal labels for data without blockRenderKey
    final terminals = block.allTerminals;
    if (_isLinearMotorTerminalBlock(terminals)) {
      const key2 = 'linear_motor';
      if (customBlockPainters.containsKey(key2)) {
        customBlockPainters[key2]!(canvas, block, _buildPaintContext());
      }
      return;
    }
    if (_isMotorTerminalBlock(terminals)) {
      if (deviceRegistry.containsKey('rotating_motor')) {
        final instance =
            _buildDeviceInstance(block, deviceRegistry['rotating_motor']!);
        const DeviceRenderer().render(canvas, instance,
            context: _buildRenderContext());
      }
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

  void _drawConnection(
      Canvas canvas, Connection connection, double verticalOffset) {
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

    final sourceTerminal =
        sourceBlock.getTerminalById(connection.sourceTerminalId);
    final destTerminal = destBlock.getTerminalById(connection.destTerminalId);
    if (sourceTerminal == null || destTerminal == null) return;

    final sourcePos = _getTerminalPosition(sourceBlock, sourceTerminal);
    final destPos = _getTerminalPosition(destBlock, destTerminal);
    if (sourcePos == null || destPos == null) return;

    // Try domain-specific routing first.
    if (customConnectionPainter != null) {
      final handled = customConnectionPainter!(
        canvas,
        connection,
        sourceBlock,
        destBlock,
        sourceTerminal,
        destTerminal,
        sourcePos,
        destPos,
        verticalOffset,
        _buildConnectionPaintContext(),
      );
      if (handled) {
        _drawWireLabel(canvas, connection, sourcePos, destPos, verticalOffset);
        return;
      }
    }

    // Generic fallback: orthogonal routing with phase or sensor color.
    final isSensorWire = connection.group == ConnectionGroup.communication;
    final strokeWidth = isSensorWire ? 1.0 : 2.5;
    final Color wireColor;
    if (!isSensorWire) {
      final phaseLabel = _isLinearMotorTerminalBlock(destBlock.allTerminals)
          ? _mapLinearTerminalToPhase(destTerminal.label)
          : destTerminal.label;
      wireColor = wireColorSettings.getPhaseColor(phaseLabel);
    } else {
      wireColor = _getWireColor(connection.wireSpec.color);
    }

    final wirePaint = Paint()
      ..color = wireColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawOrthogonalWire(canvas, sourcePos, destPos, wirePaint, verticalOffset);
    _drawWireLabel(canvas, connection, sourcePos, destPos, verticalOffset);
  }

  /// Draw the gauge/label annotation at the wire midpoint, if configured.
  void _drawWireLabel(Canvas canvas, Connection connection, Offset sourcePos,
      Offset destPos, double verticalOffset) {
    if (!wireColorSettings.showWireGaugeLabels ||
        connection.label == null ||
        connection.label!.isEmpty) return;

    final midPoint = Offset(
      (sourcePos.dx + destPos.dx) / 2,
      (sourcePos.dy + destPos.dy) / 2 + verticalOffset,
    );

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

    _drawTextCentered(
      canvas,
      connection.label!,
      midPoint,
      const TextStyle(
        color: Colors.black87,
        fontSize: 7,
        fontWeight: FontWeight.normal,
      ),
    );

    // Record label rect for hit detection (CTRL+drag bundles).
    final bundleKey =
        '${connection.sourceDeviceId}_${connection.destDeviceId}';
    bundleLabelRects?[bundleKey] =
        Rect.fromCenter(center: midPoint, width: 80, height: 16);
  }

  /// Get terminal exit point in diagram coordinates.
  ///
  /// First delegates to [customTerminalPositionResolver] (registered by the
  /// host app for device-specific layouts). Falls back to the generic
  /// standard-block grid layout.
  Offset? _getTerminalPosition(TerminalBlock block, Terminal terminal) {
    if (customTerminalPositionResolver != null) {
      final pos = customTerminalPositionResolver!(block, terminal);
      if (pos != null) return pos;
    }

    // Generic standard block: terminals in a horizontal row.
    final blockPos = block.diagramPosition.toOffset();
    final terminals = block.allTerminals;
    const terminalSpacing = 30.0;
    const terminalAreaTop = 30.0;

    final index = terminals.indexOf(terminal);
    if (index == -1) return null;

    return Offset(
      blockPos.dx + 10 + (index * terminalSpacing) + terminalSpacing / 2,
      blockPos.dy + terminalAreaTop + 20,
    );
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

  /// Draw page boundary overlay
}
