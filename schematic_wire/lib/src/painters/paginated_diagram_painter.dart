// lib/ui/widgets/connection_diagram/paginated_diagram_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/diagram_config.dart' show CorridorSortStrategy;
import '../models/terminals.dart';
import '../models/connections.dart';
import '../models/pagination.dart';
import '../models/power_grid.dart';
import '../models/enums.dart' show ConnectionGroup;
import '../models/diagram_overlay_group.dart';
import '../models/channel_grouping.dart';
import '../models/block_render_keys.dart';
import 'power_grid_painter.dart' show PowerGridData;
import 'terminal_block_painter.dart' show JumperConnection;
import 'iv3mod3srl_painter.dart';
import '../models/wire_color_settings.dart';
import '../models/title_block_config.dart';
import 'title_block_painter.dart';
import 'diagram_painter_utils.dart';

part 'wiring_element_painter.dart';

/// Callback type for custom block rendering.
///
/// Receives the canvas, block data, and a context object that exposes the
/// painter's shared drawing utilities. Return true if the block was handled,
/// false to fall through to built-in rendering.
typedef BlockPainter = bool Function(
  Canvas canvas,
  TerminalBlock block,
  BlockPaintContext ctx,
);

/// Shared drawing utilities exposed to [BlockPainter] callbacks.
class BlockPaintContext {
  const BlockPaintContext._({
    required this.wireColorSettings,
    required this.powerGrid,
    required this.connections,
    required this.drawText,
    required this.drawTextCentered,
    required this.drawTextRight,
    required this.drawDashedRect,
    required this.drawDashDotRect,
  });

  final WireColorSettings wireColorSettings;
  final PowerGridData? powerGrid;
  final List<Connection> connections;

  final void Function(Canvas, String, Offset, TextStyle) drawText;
  final void Function(Canvas, String, Offset, TextStyle) drawTextCentered;
  final void Function(Canvas, String, Offset, TextStyle) drawTextRight;
  final void Function(Canvas, Rect, Paint) drawDashedRect;
  final void Function(Canvas, Rect, Paint) drawDashDotRect;
}

/// Painter for rendering a single page of a paginated wiring diagram.
///
/// Handles rendering of terminal blocks, connections, page headers,
/// footers, margins, and page numbers for print-ready output.
class PaginatedDiagramPainter extends CustomPainter {
  /// Terminal blocks to render
  final List<TerminalBlock> terminalBlocks;

  /// Connections between terminal blocks
  final List<Connection> connections;

  /// Jumper connections within terminal blocks
  final List<JumperConnection> jumpers;

  /// Current page to render
  final DiagramPage page;

  /// Pagination configuration
  final PaginationConfig config;

  /// Optional page header information
  final PageHeaderInfo? headerInfo;

  /// Wire spacing value from diagram configuration
  final double wireSpacing;

  /// Power grid information (for star/delta and capacitor determination)
  final PowerGridData? powerGrid;

  /// Callback to retrieve PKZ current (in amps) for a given Movotron and motor index.
  /// Returns 0.0 if no data is available. Used to display PKZ current labels in
  /// the Movotron cabinet rendering.
  final double Function(String movotronId, int motorIndex)? pkzCurrentFor;

  /// Wire color configuration for phase and striker wires
  final WireColorSettings wireColorSettings;

  /// Sizes for specific block render keys, used for viewport culling.
  final Map<String, Size> blockSizes;

  /// Y-offset from block top to the wire output point, keyed by BlockRenderKeys.
  /// Blocks not in this map default to 40.0.
  final Map<String, double> blockOutputYOffsets;

  /// Generic overlay groups drawn as labelled dashed rectangles.
  /// Replaces the former domain-specific motorGroups parameter.
  final List<DiagramOverlayGroup> overlayGroups;

  /// TRIAC groupings for rendering PKZ/TRIAC group boxes inside cabinet
  final List<ChannelGrouping> channelGroupings;

  /// Strategy for corridor height auto-distribution
  final CorridorSortStrategy corridorSortStrategy;

  /// Wire bundle Y offsets for dragged horizontal corridors
  final Map<String, double> bundleYOverrides;

  /// Highlighted motor group or block ID (for hover feedback)
  final String? highlightedGroupId;

  /// Highlighted wire bundle ID (for hover feedback)
  final String? highlightedBundleId;

  /// Mutable map populated during paint() with bundle label positions.
  /// Key: bundle key (sourceId_destId), Value: label rect in diagram coordinates.
  /// The widget reads this for precise CTRL+drag hit detection.
  final Map<String, Rect>? bundleLabelRects;

  /// Title block layout configuration for the page border and info block.
  final TitleBlockConfig? titleBlockConfig;

  /// Resolved field values for the title block (e.g. 'projectName' → 'St. Mary\'s').
  final Map<String, String> titleBlockFields;

  /// Custom renderers for application-specific block types.
  ///
  /// Keyed by [TerminalBlock.blockRenderKey]. When a block's key matches an
  /// entry here, that painter is called before the built-in dispatch. Returning
  /// true from the callback consumes the block; false falls through to built-in.
  final Map<String, BlockPainter> customBlockPainters;

  const PaginatedDiagramPainter({
    required this.terminalBlocks,
    required this.connections,
    required this.jumpers,
    required this.page,
    required this.config,
    this.headerInfo,
    this.wireSpacing = 25.0,
    this.powerGrid,
    this.pkzCurrentFor,
    this.wireColorSettings = const WireColorSettings(),
    this.blockSizes = const {},
    this.blockOutputYOffsets = const {},
    this.overlayGroups = const [],
    this.channelGroupings = const [],
    this.corridorSortStrategy = CorridorSortStrategy.rightmostClosest,
    this.bundleYOverrides = const {},
    this.highlightedGroupId,
    this.highlightedBundleId,
    this.bundleLabelRects,
    this.titleBlockConfig,
    this.titleBlockFields = const {},
    this.customBlockPainters = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear previous bundle label rects for fresh hit detection
    bundleLabelRects?.clear();

    // Draw page background
    _drawPageBackground(canvas, size);

    // Draw professional border frame
    if (titleBlockConfig != null) {
      TitleBlockPainter.drawBorder(canvas, size, config.borderWidth);
    } else if (config.showPageBoundaries) {
      _drawPageMargins(canvas, size);
    }

    // Draw title block (replaces old footer)
    if (titleBlockConfig != null) {
      TitleBlockPainter.drawTitleBlock(
          canvas, size, config, titleBlockConfig!, titleBlockFields);
      TitleBlockPainter.drawWireLegend(canvas, size, config);
    } else if (config.showPageNumbers) {
      _drawFooter(canvas, size);
    }

    // Clip to content area
    final contentRect = Rect.fromLTWH(
      config.contentLeft,
      config.contentTop,
      config.contentWidth,
      config.contentHeight,
    );

    canvas.save();
    canvas.clipRect(contentRect);

    // Translate canvas to align diagram viewport with content area
    // The viewport tells us which portion of the diagram to show on this page
    // Fixed: Changed sign to correctly offset viewport within content area
    canvas.translate(
      config.contentLeft + (-page.viewport.left),
      config.contentTop + (-page.viewport.top),
    );

    // Draw diagram content (terminal blocks, connections, jumpers)
    _drawDiagramContent(canvas);

    canvas.restore();

    // Draw page boundary overlay if enabled
    if (config.showPageBoundaries) {
      _drawPageBoundary(canvas, size);
    }
  }

  /// Draw page background (white for print)
  void _drawPageBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  /// Draw page margin guides
  void _drawPageMargins(Canvas canvas, Size size) {
    final marginPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw margin rectangle
    final marginRect = Rect.fromLTWH(
      config.marginX,
      config.marginY,
      config.pageWidth - (config.marginX * 2),
      config.pageHeight - (config.marginY * 2),
    );

    canvas.drawRect(marginRect, marginPaint);
  }

  /// Draw page footer with page number and legend
  void _drawFooter(Canvas canvas, Size size) {
    final footerY = config.pageHeight - config.marginY - config.footerHeight;

    // Footer border
    final footerBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(config.contentLeft, footerY),
      Offset(config.contentLeft + config.contentWidth, footerY),
      footerBorderPaint,
    );

    // Legend (left side)
    final legendX = config.contentLeft + 10;
    final legendY = footerY + 10;

    // Green circle
    final greenPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(legendX, legendY), 3, greenPaint);
    _drawText(
      canvas,
      'Wire connected',
      Offset(legendX + 8, legendY - 4),
      const TextStyle(color: Colors.black54, fontSize: 7),
    );

    // Blue circle
    final bluePaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(legendX + 80, legendY), 3, bluePaint);
    _drawText(
      canvas,
      'Jumpered',
      Offset(legendX + 88, legendY - 4),
      const TextStyle(color: Colors.black54, fontSize: 7),
    );

    // Orange circle
    final orangePaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(legendX + 140, legendY), 3, orangePaint);
    _drawText(
      canvas,
      'Not connected',
      Offset(legendX + 148, legendY - 4),
      const TextStyle(color: Colors.black54, fontSize: 7),
    );

    // Equipment status legend (second row)
    final equipmentLegendY = legendY + 15;

    // Solid box for existing equipment
    final solidBoxPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(legendX - 3, equipmentLegendY - 3, 6, 6),
      solidBoxPaint,
    );
    _drawText(
      canvas,
      'Existing equipment',
      Offset(legendX + 8, equipmentLegendY - 4),
      const TextStyle(color: Colors.black54, fontSize: 7),
    );

    // Dashed box for new equipment
    final dashedBoxPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedRect(
      canvas,
      Rect.fromLTWH(legendX + 102, equipmentLegendY - 3, 6, 6),
      dashedBoxPaint,
    );
    _drawText(
      canvas,
      'New to install',
      Offset(legendX + 115, equipmentLegendY - 4),
      const TextStyle(color: Colors.black54, fontSize: 7),
    );

    // Page number (centered)
    final pageNumberText = 'Page ${page.pageNumber} of ${page.totalPages}';
    final textStyle = const TextStyle(
      color: Colors.black54,
      fontSize: 10,
      fontWeight: FontWeight.normal,
    );

    _drawTextCentered(
      canvas,
      pageNumberText,
      Offset(
        config.contentLeft + (config.contentWidth / 2),
        footerY + 15,
      ),
      textStyle,
    );
  }

  /// Draw diagram content (terminal blocks, connections, jumpers)
  void _drawDiagramContent(Canvas canvas) {
    // Filter visible components based on current viewport
    final visibleBlocks = _getVisibleTerminalBlocks();
    final visibleConnections = _getVisibleConnections(visibleBlocks);
    final visibleJumpers = _getVisibleJumpers(visibleBlocks);

    // Calculate wire spacing offsets for connections
    final wireOffsets = _calculateWireSpacing(visibleConnections);

    // Draw overlay group boxes FIRST (at the very back, behind terminal blocks)
    for (final group in overlayGroups) {
      if (_isGroupVisible(group)) {
        _drawOverlayGroup(canvas, group);
      }
    }

    // Draw terminal blocks
    for (final block in visibleBlocks) {
      _drawTerminalBlock(canvas, block);

      // Draw highlight for single blocks (not multi-motor groups)
      if (highlightedGroupId != null && highlightedGroupId == block.id) {
        final blockPos = block.diagramPosition.toOffset();
        final isMotor = _isMotorTerminalBlock(block.allTerminals);
        final isLinear = _isLinearMotorTerminalBlock(block.allTerminals);
        final bw = isMotor
            ? 70.0
            : (isLinear ? 40.0 : block.allTerminals.length * 30.0 + 20.0);
        final bh = isMotor ? 60.0 : (isLinear ? 60.0 : 100.0);
        final highlightRect =
            Rect.fromLTWH(blockPos.dx - 2, blockPos.dy - 2, bw + 4, bh + 4);
        final highlightPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(4)),
          highlightPaint,
        );
        final highlightBorderPaint = Paint()
          ..color = Colors.blue.shade400
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(4)),
          highlightBorderPaint,
        );
      }
    }

    // Draw connections on top (so they're visible above motor blocks)
    for (int i = 0; i < visibleConnections.length; i++) {
      final connection = visibleConnections[i];
      final offset = wireOffsets[connection.id] ?? 0.0;
      _drawConnection(canvas, connection, offset);
    }

    // Draw bundle labels on horizontal corridors (highlight when hovered)
    _drawBundleLabels(canvas, visibleConnections, wireOffsets);

    // Draw jumpers on top
    for (final jumper in visibleJumpers) {
      _drawJumper(canvas, jumper);
    }
  }

  /// Calculate vertical spacing offsets for wires to prevent overlap.
  ///
  /// Separates power wires and sensor wires into different groups:
  /// - Power wires: Use standard bundle grouping and vertical spacing
  /// - Sensor wires: Use span-based vertical offsets (longer spans at bottom)
  /// Draw labels on the horizontal corridor of power wire bundles.
  ///
  /// When [highlightedBundleId] matches a bundle key, the label is drawn
  /// with a highlighted background to indicate it will move when dragged.
  void _drawBundleLabels(Canvas canvas, List<Connection> visibleConnections,
      Map<String, double> wireOffsets) {
    // Motor power wires only — exclude striker/clock (must match _calculatePowerWireOffsets)
    final motorPowerConns = visibleConnections.where((c) {
      return c.group != ConnectionGroup.communication && c.usesCorridorRouting;
    }).toList();

    // Compute auto-distribution offsets for motor power wires only
    final autoOffsets = computeCorridorDistribution(
      terminalBlocks,
      motorPowerConns,
      wireSpacing,
      strategy: corridorSortStrategy,
      blockOutputYOffsets: blockOutputYOffsets,
    );

    // Group by bundle key (same logic as _calculatePowerWireOffsets)
    final bundles = <String, List<Connection>>{};
    for (final conn in motorPowerConns) {
      final sourceId = extractBundleId(conn.sourceTerminalId);
      final destId = extractBundleId(conn.destTerminalId);
      final key = '${sourceId}_$destId';
      bundles.putIfAbsent(key, () => []).add(conn);
    }

    for (final entry in bundles.entries) {
      final bundleKey = entry.key;
      final conns = entry.value;
      if (conns.isEmpty) continue;

      final conn = conns.first;
      final sourceBlock =
          terminalBlocks.where((b) => b.id == conn.sourceDeviceId).firstOrNull;
      final destBlock =
          terminalBlocks.where((b) => b.id == conn.destDeviceId).firstOrNull;
      if (sourceBlock == null || destBlock == null) continue;

      // Approximate horizontal corridor Y (same as _findBundleAtPosition)
      final sourceKey = sourceBlock.blockRenderKey;
      final startY = sourceBlock.diagramPosition.y +
          (blockOutputYOffsets[sourceKey] ?? 40.0);
      final endY = destBlock.diagramPosition.y + 30.0;
      final autoOffset = autoOffsets[bundleKey] ?? 0.0;
      final bundleOverride = bundleYOverrides[bundleKey] ?? 0.0;
      final turnY = (startY + endY) / 2 + autoOffset + bundleOverride;

      // Label at horizontal midpoint of corridor
      final startX = sourceBlock.diagramPosition.x;
      final endX = destBlock.diagramPosition.x;
      // Corridor rect for CTRL+drag hit detection in the widget
      final corridorRect = Rect.fromLTRB(
        startX < endX ? startX : endX,
        turnY - 12,
        startX > endX ? startX : endX,
        turnY + 12,
      );
      bundleLabelRects?[bundleKey] = corridorRect;

      if (highlightedBundleId == bundleKey) {
        // Draw subtle highlight on the horizontal corridor when hovered
        final highlightPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(corridorRect, const Radius.circular(4)),
          highlightPaint,
        );
      }
    }
  }

  Map<String, double> _calculateWireSpacing(List<Connection> connections) {
    final offsets = <String, double>{};

    // Separate sensor wires from power wires
    final sensorWires = connections
        .where((c) => c.group == ConnectionGroup.communication)
        .toList();
    final powerWires = connections
        .where((c) => c.group != ConnectionGroup.communication)
        .toList();

    // Calculate sensor wire offsets using span-based method
    final sensorOffsets = _calculateSensorWireOffsets(sensorWires);
    offsets.addAll(sensorOffsets);

    // Calculate power wire offsets using existing bundle logic
    final powerOffsets = _calculatePowerWireOffsets(powerWires);
    offsets.addAll(powerOffsets);

    return offsets;
  }

  /// Calculate sensor wire vertical offsets based on horizontal span.
  ///
  /// Sorts sensor wires by horizontal span (X distance) in descending order:
  /// - Longest span at bottom (offset = 0)
  /// - Shorter spans stack above (offset = -i * 12.5)
  ///
  /// This prevents crossings by ensuring shorter wires run higher.
  Map<String, double> _calculateSensorWireOffsets(
      List<Connection> sensorWires) {
    final offsets = <String, double>{};

    if (sensorWires.isEmpty) return offsets;

    // Calculate horizontal span for each sensor wire
    final wireSpans = <Connection, double>{};
    for (final wire in sensorWires) {
      final sourceBlock =
          terminalBlocks.firstWhere((b) => b.id == wire.sourceDeviceId);
      final destBlock =
          terminalBlocks.firstWhere((b) => b.id == wire.destDeviceId);
      final span =
          (destBlock.diagramPosition.x - sourceBlock.diagramPosition.x).abs();
      wireSpans[wire] = span;
    }

    // Sort by span descending (longest first)
    final sortedWires = sensorWires.toList()
      ..sort((a, b) {
        final spanA = wireSpans[a] ?? 0.0;
        final spanB = wireSpans[b] ?? 0.0;
        return spanB.compareTo(spanA); // Descending
      });

    // Assign vertical offsets: longest at bottom (0), shorter wires stack above
    // 3px spacing matches sensor terminal spacing for consistent appearance
    const spacing = 3.0;
    for (int i = 0; i < sortedWires.length; i++) {
      final wire = sortedWires[i];
      final offset = -i * spacing; // 0, -10, -20, -30, etc.
      offsets[wire.id] = offset;
    }

    return offsets;
  }

  /// Calculate power wire offsets using span-based auto-distribution.
  ///
  /// Groups U/V/W wires by bundle, auto-distributes corridor heights based on
  /// horizontal span (longest span → highest corridor), then spreads individual
  /// wires within each bundle by phase order.
  ///
  /// Striker and clock cable wires are excluded from auto-distribution since
  /// they use their own routing methods (_drawStrikerWire, _drawClockCableWire).
  Map<String, double> _calculatePowerWireOffsets(List<Connection> powerWires) {
    final offsets = <String, double>{};

    // Separate motor power wires from striker/clock wires
    final motorPowerWires = <Connection>[];
    final otherWires = <Connection>[];
    for (final conn in powerWires) {
      if (!conn.usesCorridorRouting) {
        otherWires.add(conn);
      } else {
        motorPowerWires.add(conn);
      }
    }

    // Striker/clock wires get zero offset (their own routing handles positioning)
    for (final conn in otherWires) {
      offsets[conn.id] = 0.0;
    }

    // Group motor power connections by bundle key
    final groups = <String, List<Connection>>{};
    for (final conn in motorPowerWires) {
      final sourceBundleId = extractBundleId(conn.sourceTerminalId);
      final destBundleId = extractBundleId(conn.destTerminalId);
      final key = '${sourceBundleId}_$destBundleId';
      groups.putIfAbsent(key, () => []).add(conn);
    }

    // Get auto-distributed corridor offsets (motor wires only)
    final autoOffsets = computeCorridorDistribution(
      terminalBlocks,
      motorPowerWires,
      wireSpacing,
      strategy: corridorSortStrategy,
      blockOutputYOffsets: blockOutputYOffsets,
    );

    // Apply per-bundle distribution + user overrides + per-wire phase spread
    for (final entry in groups.entries) {
      final bundleKey = entry.key;
      final group = entry.value;

      final autoOffset = autoOffsets[bundleKey] ?? 0.0;
      final userYOverride = bundleYOverrides[bundleKey] ?? 0.0;
      final bundleBaseOffset = autoOffset + userYOverride;

      if (group.length == 1) {
        offsets[group[0].id] = bundleBaseOffset;
      } else {
        final spacing = wireSpacing;
        final totalHeight = (group.length - 1) * spacing;
        final startOffset = -totalHeight / 2;

        // Sort power wires by phase order (U, V, W)
        group.sort((a, b) {
          final aPhase = _extractPhase(a.sourceTerminalId);
          final bPhase = _extractPhase(b.sourceTerminalId);
          return _phaseOrder(aPhase).compareTo(_phaseOrder(bPhase));
        });

        for (int i = 0; i < group.length; i++) {
          offsets[group[i].id] = bundleBaseOffset + startOffset + (i * spacing);
        }
      }
    }

    return offsets;
  }

  /// Extract bundle identifier from terminal ID by removing phase/terminal suffixes.
  ///
  /// Handles both dot and underscore formats:
  /// - "movotron_1_m1_u" → "movotron_1_m1"
  /// - "motor_bell1_v1" → "motor_bell1"
  /// - "M1.U" → "M1" (label format)
  static String extractBundleId(String terminalId) {
    // Handle underscore format (actual terminal IDs)
    // Remove patterns like _u, _v, _w, _u1, _v1, _w1, _s1, _s2, _1, _2, etc.
    String result = terminalId
        .replaceAll(RegExp(r'_[uvw]$', caseSensitive: false),
            '') // Remove _u, _v, _w at end
        .replaceAll(RegExp(r'_[uvw]\d+$', caseSensitive: false),
            '') // Remove _u1, _v1, _w1, etc.
        .replaceAll(RegExp(r'_s\d+$', caseSensitive: false),
            '') // Remove _s1, _s2, etc. for sensors
        .replaceAll(RegExp(r'_\d+$'),
            ''); // Remove _1, _2, etc. for linear motor terminals

    // Also handle dot format (label format) for backwards compatibility
    result = result
        .replaceAll(RegExp(r'\.[UVW]$'), '') // Remove .U, .V, .W at end
        .replaceAll(RegExp(r'\.[UVW]\d+$'), '') // Remove .U1, .V1, .W1, etc.
        .replaceAll(
            RegExp(r'\.[S]\d+$'), ''); // Remove .S1, .S2, etc. for sensors

    return result;
  }

  /// Compute auto-distributed corridor offsets by destination height.
  ///
  /// Groups power connections by bundle key, then distributes corridor heights
  /// so motors closest to the cabinet get the highest (most negative)
  /// corridor offsets. This prevents wire crossings.
  ///
  /// Offsets are clamped so corridors stay between the Movotron output Y
  /// and the top of the motor terminal blocks.
  ///
  /// Returns Map bundleKey to offset, centered around 0.
  static Map<String, double> computeCorridorDistribution(
    List<TerminalBlock> terminalBlocks,
    List<Connection> powerConnections,
    double corridorSpacing, {
    CorridorSortStrategy strategy = CorridorSortStrategy.rightmostClosest,
    Map<String, double> blockOutputYOffsets = const {},
  }) {
    final offsets = <String, double>{};

    // Group connections by bundle key
    final bundles = <String, List<Connection>>{};
    for (final conn in powerConnections) {
      final sourceId = extractBundleId(conn.sourceTerminalId);
      final destId = extractBundleId(conn.destTerminalId);
      final key = '${sourceId}_$destId';
      bundles.putIfAbsent(key, () => []).add(conn);
    }

    if (bundles.length <= 1) {
      // Single bundle or empty — no distribution needed
      for (final key in bundles.keys) {
        offsets[key] = 0.0;
      }
      return offsets;
    }

    // Compute sort key and available vertical half-range per bundle
    final bundleSortKey = <String, double>{};
    double minHalfRange = double.infinity;

    for (final entry in bundles.entries) {
      final conn = entry.value.first;
      final sourceBlock =
          terminalBlocks.where((b) => b.id == conn.sourceDeviceId).firstOrNull;
      final destBlock =
          terminalBlocks.where((b) => b.id == conn.destDeviceId).firstOrNull;
      if (sourceBlock == null || destBlock == null) {
        bundleSortKey[entry.key] = 0.0;
        continue;
      }

      // Sort key depends on strategy (most negative → highest corridor)
      switch (strategy) {
        case CorridorSortStrategy.rightmostClosest:
          // Rightmost motor (highest X) → highest corridor
          bundleSortKey[entry.key] = -destBlock.diagramPosition.x;
        case CorridorSortStrategy.leftmostClosest:
          // Leftmost motor (lowest X) → highest corridor
          bundleSortKey[entry.key] = destBlock.diagramPosition.x;
        case CorridorSortStrategy.tallestStackClosest:
          // More terminals (taller stack) → highest corridor;
          // use X as tiebreaker when terminal counts are equal
          bundleSortKey[entry.key] = -destBlock.allTerminals.length * 10000.0 -
              destBlock.diagramPosition.x;
      }

      // Compute the vertical range between source output and dest top.
      final sourceKey = sourceBlock.blockRenderKey;
      final sourceOutputY = sourceBlock.diagramPosition.y +
          (blockOutputYOffsets[sourceKey] ?? 40.0);
      final destTopY = destBlock.diagramPosition.y;

      // Available vertical space from midpoint to each edge, with margin
      const margin = 15.0;
      final midY = (sourceOutputY + destTopY + 30.0) / 2;
      final upperBound = (midY - sourceOutputY).abs() - margin;
      final lowerBound = (destTopY - midY).abs() - margin;
      final halfRange = upperBound < lowerBound ? upperBound : lowerBound;
      if (halfRange > 0 && halfRange < minHalfRange) {
        minHalfRange = halfRange;
      }
    }

    // Sort by computed key ascending (most negative → highest corridor)
    final sortedKeys = bundles.keys.toList()
      ..sort((a, b) {
        final keyA = bundleSortKey[a] ?? 0.0;
        final keyB = bundleSortKey[b] ?? 0.0;
        return keyA.compareTo(keyB);
      });

    // Distribute offsets centered around 0
    final n = sortedKeys.length;
    for (int i = 0; i < n; i++) {
      offsets[sortedKeys[i]] = (i - (n - 1) / 2) * corridorSpacing;
    }

    // Clamp distribution to fit within the tightest vertical bounds
    if (minHalfRange.isFinite && minHalfRange > 0 && n > 1) {
      final maxOffset = ((n - 1) / 2) * corridorSpacing;
      if (maxOffset > minHalfRange) {
        final scale = minHalfRange / maxOffset;
        for (final key in offsets.keys.toList()) {
          offsets[key] = offsets[key]! * scale;
        }
      }
    }

    return offsets;
  }

  /// Extract phase letter from terminal ID.
  ///
  /// Handles both formats:
  /// - "movotron_1_m1_u" → "U"
  /// - "M1.V" → "V"
  String _extractPhase(String terminalId) {
    // Try underscore format first (actual terminal IDs)
    final underscoreMatch =
        RegExp(r'_([uvw])(\d*)$', caseSensitive: false).firstMatch(terminalId);
    if (underscoreMatch != null) {
      return underscoreMatch.group(1)!.toUpperCase();
    }

    // Handle linear motor numeric terminals: _1→U, _3→V, _5→W
    final numericMatch = RegExp(r'_(\d+)$').firstMatch(terminalId);
    if (numericMatch != null) {
      switch (numericMatch.group(1)) {
        case '1':
          return 'U';
        case '3':
          return 'V';
        case '5':
          return 'W';
      }
    }

    // Fall back to dot format (labels)
    final dotMatch = RegExp(r'\.([UVW])').firstMatch(terminalId);
    return dotMatch?.group(1) ?? '';
  }

  /// Get sort order for phase (U=0, V=1, W=2, other=3)
  int _phaseOrder(String phase) {
    switch (phase) {
      case 'U':
        return 0;
      case 'V':
        return 1;
      case 'W':
        return 2;
      default:
        return 3;
    }
  }

  /// Extract sensor number from terminal ID.
  ///
  /// Handles formats:
  /// - "movotron_1_m1_s1" → 1
  /// - "motor_bell1_s2" → 2
  /// Get terminal blocks visible in current viewport
  List<TerminalBlock> _getVisibleTerminalBlocks() {
    return terminalBlocks.where((block) {
      final blockPos = block.diagramPosition.toOffset();
      final terminals = block.allTerminals;
      final key = block.blockRenderKey;

      double blockWidth;
      double blockHeight;

      if (key != null && blockSizes.containsKey(key)) {
        final s = blockSizes[key]!;
        blockWidth = s.width;
        blockHeight = s.height;
      } else if (_isMotorTerminalBlock(terminals)) {
        blockWidth = 145.0;
        blockHeight = 120.0;
      } else {
        blockWidth = terminals.length * 30.0 + 20.0;
        blockHeight = 100.0;
      }

      final blockRect =
          Rect.fromLTWH(blockPos.dx, blockPos.dy, blockWidth, blockHeight);
      return page.viewport.overlaps(blockRect);
    }).toList();
  }

  /// Check if an overlay group is visible in the current viewport.
  bool _isGroupVisible(DiagramOverlayGroup group) {
    return page.viewport.overlaps(group.bounds);
  }

  /// Find the overlay group that contains the motor from a given terminal block.
  /// Returns null if the block doesn't belong to any overlay group.
  DiagramOverlayGroup? _findOverlayGroupForBlock(TerminalBlock block) {
    // Extract motor ID from terminal IDs (e.g., "motor_bell1_s1" → "bell1")
    for (final terminal in block.allTerminals) {
      final match = RegExp(r'^motor_(.+?)_').firstMatch(terminal.id);
      if (match != null) {
        final motorId = match.group(1)!;
        for (final group in overlayGroups) {
          if (group.memberIds.contains(motorId)) {
            return group;
          }
        }
      }
    }
    return null;
  }

  /// Get the sensor drawing position for an overlay group (inside group box, below members).
  /// Returns the base position where the first sensor terminal should be drawn.
  Offset _getGroupSensorBasePosition(DiagramOverlayGroup group) {
    if (group.contentOrigin == null) {
      return Offset.zero;
    }

    // For rotating motors: sensor below the motor row
    // For linear motors: sensor below the lowest motor in the stack
    const motorHeight = 60.0;
    final verticalSpacing = group.isLinear ? 2.0 : 10.0;

    double sensorY;
    if (group.isLinear) {
      final totalStackHeight = (motorHeight * group.memberCount) +
          (verticalSpacing * (group.memberCount - 1));
      sensorY = group.contentOrigin!.y + totalStackHeight + 5.0;
    } else {
      sensorY = group.contentOrigin!.y + motorHeight + 5.0;
    }

    return Offset(group.contentOrigin!.x, sensorY);
  }

  /// Draw a dashed bounding box with label for an overlay group.
  ///
  /// Used to visually indicate that multiple motors share a single sensor
  /// and are controlled as a group.
  void _drawOverlayGroup(Canvas canvas, DiagramOverlayGroup group) {
    final boxRect = group.bounds;

    // Draw dashed rectangle with technical drawing style pattern
    // Pattern: dash-gap-dot-gap
    final dashPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawMotorGroupDashedRect(canvas, boxRect, dashPaint);

    // Draw highlight if this group is hovered
    if (highlightedGroupId != null && highlightedGroupId == group.id) {
      final highlightPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect.inflate(2), const Radius.circular(4)),
        highlightPaint,
      );
      final highlightBorderPaint = Paint()
        ..color = Colors.blue.shade400
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect.inflate(2), const Radius.circular(4)),
        highlightBorderPaint,
      );
    }

    // Draw group label at top-left corner
    final labelStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 8,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );

    _drawText(
      canvas,
      group.label,
      Offset(boxRect.left + 4, boxRect.top - 11),
      labelStyle,
    );
  }

  /// Draw a dashed rectangle with technical drawing pattern (dash-gap-dot-gap)
  void _drawMotorGroupDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashLength = 6.0;
    const dotLength = 2.0;
    const gapLength = 3.0;

    // Draw each edge
    _drawMotorGroupDashedLine(canvas, rect.topLeft, rect.topRight, paint,
        dashLength, dotLength, gapLength);
    _drawMotorGroupDashedLine(canvas, rect.topRight, rect.bottomRight, paint,
        dashLength, dotLength, gapLength);
    _drawMotorGroupDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint,
        dashLength, dotLength, gapLength);
    _drawMotorGroupDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint,
        dashLength, dotLength, gapLength);
  }

  /// Draw a dashed line with technical drawing pattern (dash-gap-dot-gap)
  void _drawMotorGroupDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double dotLength,
    double gapLength,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final unitX = dx / length;
    final unitY = dy / length;

    // Pattern: dash, gap, dot, gap (repeating)
    final pattern = [dashLength, gapLength, dotLength, gapLength];
    var currentPos = 0.0;
    var patternIndex = 0;
    var drawing = true;

    while (currentPos < length) {
      final segmentLength = min(pattern[patternIndex], length - currentPos);

      if (drawing) {
        final segmentStart = Offset(
          start.dx + unitX * currentPos,
          start.dy + unitY * currentPos,
        );
        final segmentEnd = Offset(
          start.dx + unitX * (currentPos + segmentLength),
          start.dy + unitY * (currentPos + segmentLength),
        );
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentPos += segmentLength;
      patternIndex = (patternIndex + 1) % pattern.length;
      drawing = !drawing;
    }
  }

  /// Draw a dashed rectangle for motor channel grouping (dot-dash pattern)
  ///
  /// Uses dot-dash-dot-dash pattern to visually distinguish from motor group boxes.
  void _drawMotorChannelDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dotLength = 2.0;
    const dashLength = 4.0;
    const gapLength = 2.0;

    // Draw each edge with dot-dash pattern
    _drawMotorChannelDashedLine(canvas, rect.topLeft, rect.topRight, paint,
        dotLength, dashLength, gapLength);
    _drawMotorChannelDashedLine(canvas, rect.topRight, rect.bottomRight, paint,
        dotLength, dashLength, gapLength);
    _drawMotorChannelDashedLine(canvas, rect.bottomRight, rect.bottomLeft,
        paint, dotLength, dashLength, gapLength);
    _drawMotorChannelDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint,
        dotLength, dashLength, gapLength);
  }

  /// Draw a dashed line for motor channel grouping (dot-dash pattern)
  void _drawMotorChannelDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dotLength,
    double dashLength,
    double gapLength,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final unitX = dx / length;
    final unitY = dy / length;

    // Pattern: dot, gap, dash, gap (repeating)
    final pattern = [dotLength, gapLength, dashLength, gapLength];
    var currentPos = 0.0;
    var patternIndex = 0;
    var drawing = true;

    while (currentPos < length) {
      final segmentLength = min(pattern[patternIndex], length - currentPos);

      if (drawing) {
        final segmentStart = Offset(
          start.dx + unitX * currentPos,
          start.dy + unitY * currentPos,
        );
        final segmentEnd = Offset(
          start.dx + unitX * (currentPos + segmentLength),
          start.dy + unitY * (currentPos + segmentLength),
        );
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentPos += segmentLength;
      patternIndex = (patternIndex + 1) % pattern.length;
      drawing = !drawing;
    }
  }

  /// Get connections visible in current viewport
  List<Connection> _getVisibleConnections(List<TerminalBlock> visibleBlocks) {
    // Connection is visible if either endpoint's terminal block is visible
    final visibleBlockIds = visibleBlocks.map((b) => b.id).toSet();

    final visible = connections.where((conn) {
      return visibleBlockIds.contains(conn.sourceDeviceId) ||
          visibleBlockIds.contains(conn.destDeviceId);
    }).toList();

    return visible;
  }

  /// Get jumpers visible in current viewport
  List<JumperConnection> _getVisibleJumpers(List<TerminalBlock> visibleBlocks) {
    // Jumpers are visible if their terminal block is visible
    // Note: JumperConnection terminals are stored differently, so we check if
    // any block in viewport contains jumpers
    return jumpers.where((jumper) {
      // Simplified check: show all jumpers if any blocks are visible
      // TODO: Implement proper jumper-to-block lookup when terminal IDs are available
      return visibleBlocks.isNotEmpty;
    }).toList();
  }

  void _drawPageBoundary(Canvas canvas, Size size) {
    final boundaryPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final contentRect = Rect.fromLTWH(
      config.contentLeft,
      config.contentTop,
      config.contentWidth,
      config.contentHeight,
    );

    canvas.drawRect(contentRect, boundaryPaint);
  }

  void _drawText(
          Canvas canvas, String text, Offset position, TextStyle style) =>
      drawText(canvas, text, position, style);

  void _drawTextRight(
          Canvas canvas, String text, Offset position, TextStyle style) =>
      drawTextRight(canvas, text, position, style);

  void _drawTextCentered(
          Canvas canvas, String text, Offset position, TextStyle style) =>
      drawTextCentered(canvas, text, position, style);

  /// Get color from IEC color code string
  Color _getWireColor(String colorCode) {
    switch (colorCode.toLowerCase()) {
      case 'brown':
      case 'l1':
        return Colors.brown;
      case 'black':
      case 'l2':
        return Colors.black;
      case 'grey':
      case 'gray':
      case 'l3':
        return Colors.grey.shade700;
      case 'blue':
      case 'n':
        return Colors.blue.shade700;
      case 'green/yellow':
      case 'green-yellow':
      case 'pe':
        return Colors.green.shade700;
      case 'red':
        return Colors.red.shade700;
      // Sensor wire colors (user-configurable)
      case 'orange':
        return Colors.orange.shade700;
      case 'purple':
        return Colors.purple.shade700;
      case 'green':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Helper: Draw dashed rectangle for legend
  /// Draw a dash-dot rectangle outline (dash–dot–dash–dot pattern).
  ///
  /// Used for the outer cabinet boundary on SBSI pages.
  void _drawDashDotRect(Canvas canvas, Rect rect, Paint paint) {
    // Top edge
    _drawDashDotLine(canvas, rect.topLeft, rect.topRight, paint);
    // Right edge
    _drawDashDotLine(canvas, rect.topRight, rect.bottomRight, paint);
    // Bottom edge
    _drawDashDotLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    // Left edge
    _drawDashDotLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  /// Draw a dash-dot line between [start] and [end].
  ///
  /// Pattern: long dash (8 px) — short gap (3 px) — dot (2 px) — short gap (3 px)
  void _drawDashDotLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Pattern: [8 dash] [3 gap] [2 dot] [3 gap]  → period = 16 px
    const double dashLen = 8.0;
    const double dotLen = 2.0;
    const double gap = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final ux = dx / distance;
    final uy = dy / distance;

    // Sequence of alternating segment lengths and draw flags
    final pattern = [dashLen, gap, dotLen, gap];

    double d = 0.0;
    int pi = 0;
    bool draw = true;

    while (d < distance) {
      final segLen = pattern[pi % pattern.length].clamp(0.0, distance - d);
      final nextD = d + segLen;
      if (draw) {
        canvas.drawLine(
          Offset(start.dx + ux * d, start.dy + uy * d),
          Offset(start.dx + ux * nextD, start.dy + uy * nextD),
          paint,
        );
      }
      d = nextD;
      draw = !draw;
      pi++;
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const double dashWidth = 3.0;
    const double dashSpace = 2.0;

    // Top edge
    _drawSimpleDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Right edge
    _drawSimpleDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Bottom edge
    _drawSimpleDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dashWidth,
      dashSpace,
    );

    // Left edge
    _drawSimpleDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dashWidth,
      dashSpace,
    );
  }

  /// Helper: Draw simple dashed line between two points for legend
  void _drawSimpleDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return; // Avoid division by zero

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0.0;
    bool drawDash = true;

    while (currentDistance < distance) {
      final length = drawDash ? dashWidth : dashSpace;
      final nextDistance = (currentDistance + length).clamp(0.0, distance);

      if (drawDash) {
        final dashStart = Offset(
          start.dx + unitDx * currentDistance,
          start.dy + unitDy * currentDistance,
        );
        final dashEnd = Offset(
          start.dx + unitDx * nextDistance,
          start.dy + unitDy * nextDistance,
        );
        canvas.drawLine(dashStart, dashEnd, paint);
      }

      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  /// Draw dashed rounded rectangle outline (for cabinet borders)
  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 4.0;

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool drawDash = true;

      while (distance < metric.length) {
        final double length = drawDash ? dashWidth : dashSpace;
        final double end = distance + length;

        if (drawDash) {
          final segment = metric.extractPath(distance, end);
          canvas.drawPath(segment, paint);
        }

        distance = end;
        drawDash = !drawDash;
      }
    }
  }

  /// Build a [BlockPaintContext] that exposes this painter's shared utilities
  /// to external [BlockPainter] callbacks.
  BlockPaintContext _buildPaintContext() {
    return BlockPaintContext._(
      wireColorSettings: wireColorSettings,
      powerGrid: powerGrid,
      connections: connections,
      drawText: _drawText,
      drawTextCentered: _drawTextCentered,
      drawTextRight: _drawTextRight,
      drawDashedRect: _drawDashedRect,
      drawDashDotRect: _drawDashDotRect,
    );
  }

  @override
  bool shouldRepaint(PaginatedDiagramPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.terminalBlocks != terminalBlocks ||
        oldDelegate.connections != connections ||
        oldDelegate.jumpers != jumpers ||
        oldDelegate.config != config ||
        oldDelegate.headerInfo != headerInfo ||
        oldDelegate.wireSpacing != wireSpacing ||
        oldDelegate.corridorSortStrategy != corridorSortStrategy ||
        oldDelegate.highlightedGroupId != highlightedGroupId ||
        oldDelegate.highlightedBundleId != highlightedBundleId ||
        oldDelegate.customBlockPainters != customBlockPainters ||
        oldDelegate.overlayGroups != overlayGroups ||
        oldDelegate.channelGroupings != channelGroupings;
  }

  /// Check if a block ID belongs to a specific Movotron's IV3MOD3SRL.
  /// Matches 'TB_IV3MOD3SRL_1' and 'TB_IV3MOD3SRL_1_2' but NOT 'TB_IV3MOD3SRL_10'.
  static bool _isIV3ForMovotron(String blockId, String movotronNum) {
    final prefix = 'TB_IV3MOD3SRL_$movotronNum';
    if (blockId == prefix) return true;
    if (blockId.startsWith('${prefix}_')) return true;
    return false;
  }
}
