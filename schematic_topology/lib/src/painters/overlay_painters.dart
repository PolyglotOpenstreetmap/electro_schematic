// schematic_topology — generic overlay painters (grid, drag line, selection box).

import 'dart:math';
import 'package:flutter/material.dart';

/// A plain grid + page-border background. Title blocks / domain chrome are left
/// to the host app (compose a separate background painter for those).
class SchematicGridPainter extends CustomPainter {
  const SchematicGridPainter({
    required this.pageSize,
    this.fineStep = 10,
    this.majorStep = 100,
    this.borderWidth = 3.0,
  });

  final Size pageSize;
  final double fineStep;
  final double majorStep;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final pageW = pageSize.width;
    final pageH = pageSize.height;
    final pageRect = Rect.fromLTWH(0, 0, pageW, pageH);

    canvas.drawRect(
        pageRect, Paint()..color = Colors.white..style = PaintingStyle.fill);

    final finePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    for (double x = 0; x < pageW; x += fineStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, pageH), finePaint);
    }
    for (double y = 0; y < pageH; y += fineStep) {
      canvas.drawLine(Offset(0, y), Offset(pageW, y), finePaint);
    }

    final majorPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    for (double x = 0; x < pageW; x += majorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, pageH), majorPaint);
    }
    for (double y = 0; y < pageH; y += majorStep) {
      canvas.drawLine(Offset(0, y), Offset(pageW, y), majorPaint);
    }

    canvas.drawRect(
        pageRect,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth);
  }

  @override
  bool shouldRepaint(covariant SchematicGridPainter old) =>
      pageSize != old.pageSize ||
      fineStep != old.fineStep ||
      majorStep != old.majorStep ||
      borderWidth != old.borderWidth;
}

/// The dashed line + arrowhead shown while dragging a new connection.
class SchematicDragConnectionPainter extends CustomPainter {
  const SchematicDragConnectionPainter({
    required this.startPosition,
    required this.endPosition,
    required this.color,
  });

  final Offset startPosition;
  final Offset endPosition;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final distance = (endPosition - startPosition).distance;
    if (distance == 0) return;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final dashPath = Path();
    for (var i = 0; i < dashCount; i++) {
      final s = (i * (dashWidth + dashSpace)) / distance;
      final e = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;
      dashPath.moveTo(
        startPosition.dx + (endPosition.dx - startPosition.dx) * s,
        startPosition.dy + (endPosition.dy - startPosition.dy) * s,
      );
      dashPath.lineTo(
        startPosition.dx + (endPosition.dx - startPosition.dx) * e,
        startPosition.dy + (endPosition.dy - startPosition.dy) * e,
      );
    }
    canvas.drawPath(dashPath, paint);

    const arrowSize = 10.0;
    final angle = (endPosition - startPosition).direction;
    final arrowPath = Path()
      ..moveTo(endPosition.dx, endPosition.dy)
      ..lineTo(
        endPosition.dx - arrowSize * 1.5 * (1 + 0.5 * (angle.abs() / pi)),
        endPosition.dy - arrowSize,
      )
      ..lineTo(
        endPosition.dx - arrowSize * 1.5 * (1 + 0.5 * (angle.abs() / pi)),
        endPosition.dy + arrowSize,
      )
      ..close();
    canvas.save();
    canvas.translate(endPosition.dx, endPosition.dy);
    canvas.rotate(angle);
    canvas.translate(-endPosition.dx, -endPosition.dy);
    canvas.drawPath(arrowPath, Paint()
      ..color = color
      ..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SchematicDragConnectionPainter old) =>
      startPosition != old.startPosition || endPosition != old.endPosition;
}

/// The rubber-band multi-select rectangle.
class SchematicSelectionRectPainter extends CustomPainter {
  const SchematicSelectionRectPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant SchematicSelectionRectPainter old) =>
      rect != old.rect;
}
