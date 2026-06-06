// lib/src/rendering/device_renderer.dart
//
// DeviceRenderer: walks the drawable scene graph and issues Flutter Canvas
// draw calls.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../drawable/drawable_node.dart';
import '../models/device_definition.dart';
import '../models/device_instance.dart';
import 'render_context.dart';

export 'render_context.dart';

/// Renders a [DeviceInstance] onto a Flutter [Canvas].
///
/// Usage:
/// ```dart
/// const renderer = DeviceRenderer();
/// renderer.render(canvas, instance);
/// ```
class DeviceRenderer {
  const DeviceRenderer();

  /// Renders [instance] at its [DeviceInstance.position] using the appearance
  /// for [level].
  void render(
    Canvas canvas,
    DeviceInstance instance, {
    DrawingLevel level = DrawingLevel.wire,
    RenderContext context = RenderContext.empty,
  }) {
    final appearance = instance.definition.appearance.forLevel(level);
    if (appearance == null) return;

    final origin = instance.position;
    final params = _resolveParams(instance);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    for (final node in appearance.drawables) {
      _renderNode(canvas, node, params, instance, context);
    }

    canvas.restore();
  }

  // ─── Parameter resolution ──────────────────────────────────────────────────

  Map<String, dynamic> _resolveParams(DeviceInstance instance) {
    final defaults = instance.definition.defaultParams;
    return {...defaults, ...instance.paramValues};
  }

  // ─── Node dispatch ─────────────────────────────────────────────────────────

  void _renderNode(
    Canvas canvas,
    DrawableNode node,
    Map<String, dynamic> params,
    DeviceInstance instance,
    RenderContext ctx,
  ) {
    if (node.showIf != null && !node.showIf!.evaluate(params, ctx)) return;

    switch (node) {
      case DrawRect():
        _renderRect(canvas, node);
      case DrawCircle():
        _renderCircle(canvas, node, instance);
      case DrawLine():
        _renderLine(canvas, node);
      case DrawPolyline():
        _renderPolyline(canvas, node);
      case DrawText():
        _renderText(canvas, node, params, instance);
      case DrawPath():
        _renderPath(canvas, node);
      case DrawCoil():
        _renderCoil(canvas, node);
      case DrawCapacitor():
        _renderCapacitor(canvas, node);
      case DrawTerminalAnchor():
        _renderTerminalAnchor(canvas, node, instance);
      case DrawGroup():
        _renderGroup(canvas, node, params, instance, ctx);
      case DrawRepeat():
        _renderRepeat(canvas, node, params, instance, ctx);
    }
  }

  // ─── Primitive renderers ──────────────────────────────────────────────────

  void _renderRect(Canvas canvas, DrawRect node) {
    if (node.fillColor != null) {
      final paint = Paint()
        ..color = node.fillColor!
        ..style = PaintingStyle.fill;
      _drawRRect(canvas, node.rect, node.cornerRadius, paint);
    }
    if (node.strokeColor != null) {
      final paint = Paint()
        ..color = node.strokeColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.strokeWidth;
      _drawRRect(canvas, node.rect, node.cornerRadius, paint);
    }
  }

  void _drawRRect(Canvas canvas, Rect rect, double radius, Paint paint) {
    if (radius == 0) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }
  }

  void _renderCircle(
      Canvas canvas, DrawCircle node, DeviceInstance instance) {
    Color fillColor;
    if (node.fillBinding != null) {
      fillColor = _resolveTerminalColor(node.fillBinding!, instance);
    } else {
      fillColor = node.fillColor ?? Colors.transparent;
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(node.center, node.radius, fillPaint);

    if (node.strokeColor != null) {
      final strokePaint = Paint()
        ..color = node.strokeColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.strokeWidth;
      canvas.drawCircle(node.center, node.radius, strokePaint);
    }
  }

  void _renderLine(Canvas canvas, DrawLine node) {
    final paint = Paint()
      ..color = node.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = node.strokeWidth;
    canvas.drawLine(node.start, node.end, paint);
  }

  void _renderPolyline(Canvas canvas, DrawPolyline node) {
    if (node.points.isEmpty) return;
    final paint = Paint()
      ..color = node.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = node.strokeWidth;

    final path = Path()..moveTo(node.points.first.dx, node.points.first.dy);
    for (final p in node.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (node.closed && node.points.length > 2) path.close();
    canvas.drawPath(path, paint);
  }

  void _renderText(
    Canvas canvas,
    DrawText node,
    Map<String, dynamic> params,
    DeviceInstance instance,
  ) {
    Color textColor;
    if (node.colorBinding != null) {
      textColor = _resolveTerminalColor(node.colorBinding!, instance);
    } else {
      textColor = node.color;
    }

    final resolvedText = _substituteParams(node.text, params);

    final painter = TextPainter(
      text: TextSpan(
        text: resolvedText,
        style: TextStyle(
          fontSize: node.fontSize,
          fontWeight: node.bold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = _anchorOffset(node.position, node.anchor, painter.size);
    painter.paint(canvas, offset);
  }

  void _renderPath(Canvas canvas, DrawPath node) {
    final paint = Paint()
      ..color = node.color
      ..style = node.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = node.strokeWidth;

    final path = _parseSvgPath(node.svgPathData);
    canvas.drawPath(path, paint);
  }

  // ─── Composite symbol renderers ───────────────────────────────────────────

  void _renderCoil(Canvas canvas, DrawCoil node) {
    final paint = Paint()
      ..color = node.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = node.strokeWidth
      ..strokeCap = StrokeCap.round;

    final dx = node.end.dx - node.start.dx;
    final dy = node.end.dy - node.start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final count = node.arcCount ?? math.max(3, (distance / 8).round());
    if (count == 0 || distance < 1) return;

    final ux = dx / distance;
    final uy = dy / distance;

    for (var i = 0; i < count; i++) {
      final t = (i + 0.5) / count;
      final cx = node.start.dx + dx * t;
      final cy = node.start.dy + dy * t;

      canvas.save();
      canvas.translate(cx, cy);
      final angle = math.atan2(uy, ux);
      canvas.rotate(angle);

      final arcRadius = distance / count / 2;
      final arcRect = Rect.fromCircle(center: Offset.zero, radius: arcRadius);
      canvas.drawArc(arcRect, 0, math.pi, false, paint);

      canvas.restore();
    }
  }

  void _renderCapacitor(Canvas canvas, DrawCapacitor node) {
    final paint = Paint()
      ..color = node.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * node.scale
      ..strokeCap = StrokeCap.square;

    final plateLen = 10.0 * node.scale;
    final gap = 3.0 * node.scale;
    final stubLen = 8.0 * node.scale;
    final cx = node.center.dx;
    final cy = node.center.dy;

    if (node.horizontal) {
      canvas.drawLine(Offset(cx - gap, cy - plateLen / 2),
          Offset(cx - gap, cy + plateLen / 2), paint);
      canvas.drawLine(Offset(cx + gap, cy - plateLen / 2),
          Offset(cx + gap, cy + plateLen / 2), paint);
      canvas.drawLine(
          Offset(cx - gap - stubLen, cy), Offset(cx - gap, cy), paint);
      canvas.drawLine(
          Offset(cx + gap, cy), Offset(cx + gap + stubLen, cy), paint);
    } else {
      canvas.drawLine(Offset(cx - plateLen / 2, cy - gap),
          Offset(cx + plateLen / 2, cy - gap), paint);
      canvas.drawLine(Offset(cx - plateLen / 2, cy + gap),
          Offset(cx + plateLen / 2, cy + gap), paint);
      canvas.drawLine(
          Offset(cx, cy - gap - stubLen), Offset(cx, cy - gap), paint);
      canvas.drawLine(
          Offset(cx, cy + gap), Offset(cx, cy + gap + stubLen), paint);
    }
  }

  void _renderTerminalAnchor(
    Canvas canvas,
    DrawTerminalAnchor node,
    DeviceInstance instance,
  ) {
    final termDef = instance.definition.findTerminal(node.terminalDefId);
    if (termDef == null) return;

    final anchor = termDef.anchorInConnector;

    Color fillColor;
    if (node.colorBinding != null) {
      fillColor = _resolveTerminalColor(node.colorBinding!, instance);
    } else {
      final binding = TerminalColorBinding.standard(node.terminalDefId,
          isJumper: instance.isTerminalJumper(node.terminalDefId));
      fillColor = binding.resolve(
        isConnected: instance.isTerminalConnected(node.terminalDefId),
        isJumper: instance.isTerminalJumper(node.terminalDefId),
      );
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(anchor, node.radius, fillPaint);

    final strokePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(anchor, node.radius, strokePaint);
  }

  void _renderGroup(
    Canvas canvas,
    DrawGroup node,
    Map<String, dynamic> params,
    DeviceInstance instance,
    RenderContext ctx,
  ) {
    canvas.save();
    if (node.offset != null) {
      canvas.translate(node.offset!.dx, node.offset!.dy);
    }
    if (node.scale != 1.0) {
      canvas.scale(node.scale);
    }
    for (final child in node.children) {
      _renderNode(canvas, child, params, instance, ctx);
    }
    canvas.restore();
  }

  void _renderRepeat(
    Canvas canvas,
    DrawRepeat node,
    Map<String, dynamic> params,
    DeviceInstance instance,
    RenderContext ctx,
  ) {
    final resolvedCount = _resolveCount(node.count, params);
    if (resolvedCount <= 0) return;

    for (var i = 0; i < resolvedCount; i++) {
      final iterParams = {...params, 'index': i};
      final dx = node.axis == RepeatAxis.horizontal ? node.spacing * i : 0.0;
      final dy = node.axis == RepeatAxis.vertical ? node.spacing * i : 0.0;

      canvas.save();
      canvas.translate(dx, dy);
      _renderNode(canvas, node.templateChild, iterParams, instance, ctx);
      canvas.restore();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _resolveTerminalColor(
      TerminalColorBinding binding, DeviceInstance instance) {
    return binding.resolve(
      isConnected: instance.isTerminalConnected(binding.terminalDefId),
      isJumper: instance.isTerminalJumper(binding.terminalDefId),
    );
  }

  int _resolveCount(String countExpr, Map<String, dynamic> params) {
    final asInt = int.tryParse(countExpr);
    if (asInt != null) return asInt;

    final match = RegExp(r'^\$\{(\w+)\}$').firstMatch(countExpr);
    if (match != null) {
      final key = match.group(1)!;
      final value = params[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _substituteParams(String template, Map<String, dynamic> params) {
    return template.replaceAllMapped(
      RegExp(r'\$\{(\w+(?:\+\d+)?)\}'),
      (m) {
        final expr = m.group(1)!;
        // Handle simple arithmetic: "index+1"
        final arithMatch = RegExp(r'^(\w+)\+(\d+)$').firstMatch(expr);
        if (arithMatch != null) {
          final key = arithMatch.group(1)!;
          final addend = int.parse(arithMatch.group(2)!);
          final value = params[key];
          if (value is num) return (value.toInt() + addend).toString();
        }
        return params[expr]?.toString() ?? '';
      },
    );
  }

  Offset _anchorOffset(Offset position, TextAnchor anchor, Size textSize) {
    return switch (anchor) {
      TextAnchor.topLeft => position,
      TextAnchor.topCenter => position.translate(-textSize.width / 2, 0),
      TextAnchor.topRight => position.translate(-textSize.width, 0),
      TextAnchor.centerLeft => position.translate(0, -textSize.height / 2),
      TextAnchor.center =>
        position.translate(-textSize.width / 2, -textSize.height / 2),
      TextAnchor.centerRight =>
        position.translate(-textSize.width, -textSize.height / 2),
      TextAnchor.bottomLeft => position.translate(0, -textSize.height),
      TextAnchor.bottomCenter =>
        position.translate(-textSize.width / 2, -textSize.height),
      TextAnchor.bottomRight =>
        position.translate(-textSize.width, -textSize.height),
    };
  }

  Path _parseSvgPath(List<String> commands) {
    final path = Path();
    for (final cmd in commands) {
      final parts = cmd.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;
      final op = parts[0].toUpperCase();
      final nums =
          parts.skip(1).map((s) => double.tryParse(s) ?? 0.0).toList();

      switch (op) {
        case 'M':
          if (nums.length >= 2) path.moveTo(nums[0], nums[1]);
        case 'L':
          if (nums.length >= 2) path.lineTo(nums[0], nums[1]);
        case 'Q':
          if (nums.length >= 4) {
            path.quadraticBezierTo(nums[0], nums[1], nums[2], nums[3]);
          }
        case 'C':
          if (nums.length >= 6) {
            path.cubicTo(
                nums[0], nums[1], nums[2], nums[3], nums[4], nums[5]);
          }
        case 'Z':
          path.close();
      }
    }
    return path;
  }
}
