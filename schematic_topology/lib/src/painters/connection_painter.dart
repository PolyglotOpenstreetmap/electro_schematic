// schematic_topology — bezier connection painter with pluggable edge styling.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/connection_side.dart';
import '../models/edge_style.dart';
import '../models/schematic_edge.dart';
import '../models/schematic_node.dart';

class _BezierData {
  final Offset start, cp1, cp2, end;
  const _BezierData({
    required this.start,
    required this.cp1,
    required this.cp2,
    required this.end,
  });
}

/// Draws edges as bezier curves between nodes. The visual style of each edge
/// (color, stroke, dash, label) is provided by [styleResolver]; returning
/// `null` from the resolver hides that edge.
class SchematicConnectionPainter extends CustomPainter {
  SchematicConnectionPainter({
    required this.edges,
    required this.nodes,
    required this.styleResolver,
  });

  final List<SchematicEdge> edges;
  final List<SchematicNode> nodes;
  final EdgeStyleResolver styleResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final groups = <String, List<SchematicEdge>>{};
    for (final e in edges) {
      final key = '${e.sourceNodeId}_${e.destNodeId}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    final toDraw = <({SchematicEdge edge, EdgeStyle style, _BezierData bezier})>[];
    for (final group in groups.values) {
      for (var i = 0; i < group.length; i++) {
        final e = group[i];
        final style = styleResolver(e);
        if (style == null) continue;
        final src = nodes.firstWhereOrNull((n) => n.id == e.sourceNodeId);
        final dst = nodes.firstWhereOrNull((n) => n.id == e.destNodeId);
        if (src == null || dst == null) continue;
        double offset = 0;
        if (group.length > 1) {
          final total = (group.length - 1) * 8.0;
          offset = -total / 2 + i * 8.0;
        }
        toDraw.add((edge: e, style: style, bezier: _buildBezier(src, dst, e, offset)));
      }
    }

    for (final d in toDraw) {
      _drawShadow(canvas, d.bezier);
    }
    for (final d in toDraw) {
      _drawConnection(canvas, d.style, d.bezier);
    }
  }

  _BezierData _buildBezier(
      SchematicNode src, SchematicNode dst, SchematicEdge e, double parallelOffset) {
    final srcSize = src.renderSize;
    final dstSize = dst.renderSize;
    final srcCenter = Offset(
        src.position.dx + srcSize.width / 2, src.position.dy + srcSize.height / 2);
    final dstCenter = Offset(
        dst.position.dx + dstSize.width / 2, dst.position.dy + dstSize.height / 2);

    final start = _getConnectionPoint(
        src, e.exitSide, srcCenter, dstCenter, parallelOffset);
    final end = _getConnectionPoint(
        dst, e.entrySide, dstCenter, srcCenter, parallelOffset);

    final dist = (end - start).distance;
    final strength = max(50.0, dist * 0.4);
    final cp1 = start + _sideDir(e.exitSide, start, dstCenter) * strength;
    final cp2 = end + _sideDir(e.entrySide, end, srcCenter) * strength;

    return _BezierData(start: start, cp1: cp1, cp2: cp2, end: end);
  }

  Offset _sideDir(ConnectionSide side, Offset port, Offset toward) {
    switch (side) {
      case ConnectionSide.top:
        return const Offset(0, -1);
      case ConnectionSide.bottom:
        return const Offset(0, 1);
      case ConnectionSide.left:
        return const Offset(-1, 0);
      case ConnectionSide.right:
        return const Offset(1, 0);
      case ConnectionSide.center:
        final d = toward - port;
        final dist = d.distance;
        return dist == 0 ? const Offset(1, 0) : d / dist;
    }
  }

  Offset _getConnectionPoint(SchematicNode node, ConnectionSide side,
      Offset nodeCenter, Offset otherCenter, double parallelOffset) {
    final s = node.renderSize;
    switch (side) {
      case ConnectionSide.top:
        return Offset(nodeCenter.dx + parallelOffset, node.position.dy);
      case ConnectionSide.bottom:
        return Offset(nodeCenter.dx + parallelOffset, node.position.dy + s.height);
      case ConnectionSide.left:
        return Offset(node.position.dx, nodeCenter.dy + parallelOffset);
      case ConnectionSide.right:
        return Offset(node.position.dx + s.width, nodeCenter.dy + parallelOffset);
      case ConnectionSide.center:
        final dx = otherCenter.dx - nodeCenter.dx;
        final dy = otherCenter.dy - nodeCenter.dy;
        if (dx.abs() > dy.abs()) {
          return dx > 0
              ? Offset(node.position.dx + s.width, nodeCenter.dy + parallelOffset)
              : Offset(node.position.dx, nodeCenter.dy + parallelOffset);
        } else {
          return dy > 0
              ? Offset(nodeCenter.dx + parallelOffset, node.position.dy + s.height)
              : Offset(nodeCenter.dx + parallelOffset, node.position.dy);
        }
    }
  }

  void _drawShadow(Canvas canvas, _BezierData b) {
    canvas.drawPath(
      Path()
        ..moveTo(b.start.dx, b.start.dy)
        ..cubicTo(b.cp1.dx, b.cp1.dy, b.cp2.dx, b.cp2.dy, b.end.dx, b.end.dy),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawConnection(Canvas canvas, EdgeStyle style, _BezierData b) {
    final color = style.color;
    final path = Path()
      ..moveTo(b.start.dx, b.start.dy)
      ..cubicTo(b.cp1.dx, b.cp1.dy, b.cp2.dx, b.cp2.dy, b.end.dx, b.end.dy);

    canvas.drawCircle(b.start, 3, Paint()..color = color);
    _drawStyledPath(canvas, path, style);
    canvas.drawCircle(b.end, 3, Paint()..color = color.withValues(alpha: 0.5));
    _drawArrowhead(canvas, b.end, b.cp2, color);
    if (style.label != null && style.label!.isNotEmpty) {
      _drawLabelPill(canvas, _bezierAt(b, 0.5), style.label!, color);
    }
  }

  void _drawStyledPath(Canvas canvas, Path path, EdgeStyle style) {
    if (style.dash == null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = style.color
          ..strokeWidth = style.strokeWidth
          ..style = PaintingStyle.stroke,
      );
    } else {
      final dash = style.dash!;
      _drawDashedStroke(canvas, path, style.color, style.strokeWidth,
          dash.first, dash.length > 1 ? dash[1] : dash.first);
    }
  }

  void _drawDashedStroke(Canvas canvas, Path path, Color color,
      double strokeWidth, double dashLen, double gapLen) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final period = dashLen + gapLen;
    for (final metric in path.computeMetrics()) {
      double pos = 0;
      while (pos < metric.length) {
        canvas.drawPath(
            metric.extractPath(pos, min(pos + dashLen, metric.length)), paint);
        pos += period;
      }
    }
  }

  Offset _bezierAt(_BezierData b, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * b.start.dx +
          3 * mt * mt * t * b.cp1.dx +
          3 * mt * t * t * b.cp2.dx +
          t * t * t * b.end.dx,
      mt * mt * mt * b.start.dy +
          3 * mt * mt * t * b.cp1.dy +
          3 * mt * t * t * b.cp2.dy +
          t * t * t * b.end.dy,
    );
  }

  void _drawArrowhead(Canvas canvas, Offset tip, Offset from, Color color) {
    const arrowSize = 10.0;
    final angle = atan2(tip.dy - from.dy, tip.dx - from.dx);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - arrowSize * cos(angle - pi / 6),
          tip.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(tip.dx - arrowSize * cos(angle + pi / 6),
          tip.dy - arrowSize * sin(angle + pi / 6))
      ..close();
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.translate(-tip.dx, -tip.dy);
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.fill);
    canvas.restore();
  }

  void _drawLabelPill(Canvas canvas, Offset center, String label, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const hPad = 5.0;
    const vPad = 2.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center,
          width: tp.width + hPad * 2,
          height: tp.height + vPad * 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    canvas.drawRRect(
        pillRect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SchematicConnectionPainter old) =>
      edges != old.edges ||
      nodes != old.nodes ||
      styleResolver != old.styleResolver;
}
