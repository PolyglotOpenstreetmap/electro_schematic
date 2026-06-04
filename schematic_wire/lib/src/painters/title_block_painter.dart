// lib/ui/widgets/connection_diagram/title_block_painter.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/pagination.dart';
import '../models/title_block_config.dart';

/// Shared utility for drawing professional engineering drawing borders
/// and title blocks on diagram pages.
///
/// Used by both [PaginatedDiagramPainter] and [SerialBusDiagramPainter]
/// to ensure consistent page framing across all diagram types.
class TitleBlockPainter {
  TitleBlockPainter._();

  /// Draw a professional border frame around the entire page.
  static void drawBorder(Canvas canvas, Size pageSize, double borderWidth) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Inset by half the border width so the stroke is fully inside the page
    final inset = borderWidth / 2;
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, pageSize.width - borderWidth,
          pageSize.height - borderWidth),
      borderPaint,
    );
  }

  /// Draw the title block grid in the bottom-right corner of the page.
  ///
  /// [fieldValues] maps field keys (e.g. 'projectName') to their resolved
  /// display strings (e.g. "St. Mary's Church").
  static void drawTitleBlock(
    Canvas canvas,
    Size pageSize,
    PaginationConfig config,
    TitleBlockConfig titleConfig,
    Map<String, String> fieldValues,
  ) {
    final bw = config.borderWidth;
    final tbWidth = config.titleBlockWidth;
    final tbHeight = config.titleBlockHeight;

    // Position: bottom-right, inside the border
    final tbLeft = pageSize.width - bw - tbWidth;
    final tbTop = pageSize.height - bw - tbHeight;
    final tbRect = Rect.fromLTWH(tbLeft, tbTop, tbWidth, tbHeight);

    // Background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(tbRect, bgPaint);

    // Outer border of the title block
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(tbRect, borderPaint);

    // Row heights: divide into 3 equal rows
    final rowHeight = tbHeight / 3;
    final row0Top = tbTop;
    final row1Top = tbTop + rowHeight;
    final row2Top = tbTop + rowHeight * 2;

    // Horizontal dividers
    final dividerPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(tbLeft, row1Top), Offset(tbLeft + tbWidth, row1Top), dividerPaint);
    canvas.drawLine(
        Offset(tbLeft, row2Top), Offset(tbLeft + tbWidth, row2Top), dividerPaint);

    // Vertical divider for bottom row (split into 2 columns)
    final bottomColSplit = tbLeft + tbWidth / 2;
    canvas.drawLine(
        Offset(bottomColSplit, row2Top),
        Offset(bottomColSplit, tbTop + tbHeight),
        dividerPaint);

    // Render cells
    final cellPadding = 4.0;

    // Top row (full width)
    _drawCellContent(
      canvas,
      Rect.fromLTWH(tbLeft, row0Top, tbWidth, rowHeight),
      titleConfig.topRow,
      fieldValues,
      cellPadding,
    );

    // Middle row (full width)
    _drawCellContent(
      canvas,
      Rect.fromLTWH(tbLeft, row1Top, tbWidth, rowHeight),
      titleConfig.middleRow,
      fieldValues,
      cellPadding,
    );

    // Bottom-left
    _drawCellContent(
      canvas,
      Rect.fromLTWH(tbLeft, row2Top, tbWidth / 2, rowHeight),
      titleConfig.bottomLeft,
      fieldValues,
      cellPadding,
    );

    // Bottom-right
    _drawCellContent(
      canvas,
      Rect.fromLTWH(bottomColSplit, row2Top, tbWidth / 2, rowHeight),
      titleConfig.bottomRight,
      fieldValues,
      cellPadding,
    );
  }

  /// Draw the wire legend in the bottom-left area of the page (below content).
  static void drawWireLegend(Canvas canvas, Size pageSize, PaginationConfig config) {
    final bw = config.borderWidth;
    final legendY = pageSize.height - bw - config.titleBlockHeight + 6;
    final legendX = bw + 10;

    final labelStyle = TextStyle(
      color: Colors.black54,
      fontSize: 7,
    );

    // Wire connection status legend
    _drawLegendDot(canvas, Offset(legendX, legendY), Colors.green.shade700);
    _drawSmallText(canvas, 'Wire connected', Offset(legendX + 8, legendY - 4), labelStyle);

    _drawLegendDot(canvas, Offset(legendX + 80, legendY), Colors.blue.shade600);
    _drawSmallText(canvas, 'Jumpered', Offset(legendX + 88, legendY - 4), labelStyle);

    _drawLegendDot(canvas, Offset(legendX + 140, legendY), Colors.orange.shade700);
    _drawSmallText(canvas, 'Not connected', Offset(legendX + 148, legendY - 4), labelStyle);

    // Equipment status legend (second row)
    final row2Y = legendY + 15;

    // Solid box for existing equipment
    final solidBoxPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(legendX - 3, row2Y - 3, 6, 6),
      solidBoxPaint,
    );
    _drawSmallText(canvas, 'Existing equipment', Offset(legendX + 8, row2Y - 4), labelStyle);

    // Dashed box for new equipment
    final dashedBoxPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedRect(canvas, Rect.fromLTWH(legendX + 102, row2Y - 3, 6, 6), dashedBoxPaint);
    _drawSmallText(canvas, 'New to install', Offset(legendX + 115, row2Y - 4), labelStyle);
  }

  // ── Private helpers ──────────────────────────────────────────────

  static void _drawCellContent(
    Canvas canvas,
    Rect cellRect,
    TitleBlockCell cell,
    Map<String, String> fieldValues,
    double padding,
  ) {
    if (cell.fields.isEmpty) return;

    final style = const TextStyle(
      color: Colors.black87,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    // Resolve field values
    final texts = cell.fields
        .map((key) => fieldValues[key] ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    if (texts.isEmpty) return;

    final textY = cellRect.top + (cellRect.height / 2) - 5;

    switch (cell.alignment) {
      case CellAlignment.left:
        final combined = texts.join('  ');
        _drawSmallText(canvas, combined,
            Offset(cellRect.left + padding, textY), style);

      case CellAlignment.center:
        final combined = texts.join('  ');
        _drawCenteredText(canvas, combined,
            Offset(cellRect.left + cellRect.width / 2, textY), style);

      case CellAlignment.right:
        final combined = texts.join('  ');
        _drawRightText(canvas, combined,
            Offset(cellRect.right - padding, textY), style);

      case CellAlignment.spaceBetween:
        if (texts.length >= 2) {
          _drawSmallText(canvas, texts[0],
              Offset(cellRect.left + padding, textY), style);
          _drawRightText(canvas, texts[1],
              Offset(cellRect.right - padding, textY), style);
        } else {
          _drawSmallText(canvas, texts[0],
              Offset(cellRect.left + padding, textY), style);
        }
    }
  }

  static void _drawLegendDot(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, paint);
  }

  static void _drawSmallText(
      Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  static void _drawCenteredText(
      Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(position.dx - textPainter.width / 2, position.dy));
  }

  static void _drawRightText(
      Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(position.dx - textPainter.width, position.dy));
  }

  static void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashLen = 2.0;
    const gapLen = 2.0;

    void drawDashedLine(Offset start, Offset end) {
      final dist =
          ((end.dx - start.dx).abs() + (end.dy - start.dy).abs()).toDouble();
      final unitX = dist > 0 ? (end.dx - start.dx) / dist : 0.0;
      final unitY = dist > 0 ? (end.dy - start.dy) / dist : 0.0;

      double d = 0;
      while (d < dist) {
        final segEnd = (d + dashLen).clamp(0, dist);
        canvas.drawLine(
          Offset(start.dx + unitX * d, start.dy + unitY * d),
          Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
          paint,
        );
        d += dashLen + gapLen;
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }
}
