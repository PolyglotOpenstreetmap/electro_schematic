// schematic_cable — cross-section / twisted-pair painter.
//
// Draws a "solid + striped" twisted-pair / power cable inside a jacket. Drop it
// into any CustomPaint widget.
//
//   CablePainter(spec: CableSpec.twistedPairs(pairs: 2))
//   CablePainter(spec: CableSpec.power3Phase())
//   CablePainter(spec: CableSpec.multicore(signals: 5))

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/cable_spec.dart';
import 'cable_paths.dart';

class CablePainter extends CustomPainter {
  final CableSpec spec;

  /// How many sine cycles are visible in the twisted section.
  final double twistCycles;

  /// 0..1 fraction of width used for the cable jacket on each side.
  final double jacketFraction;

  const CablePainter({
    required this.spec,
    this.twistCycles = 3.0,
    this.jacketFraction = 0.18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wires = spec.wires;
    final n = wires.length;
    if (n == 0) return;

    final w = size.width;
    final h = size.height;

    // Vertical spread: wires fan out to fill height.
    final wireSpacing = h / (n + 1);

    final jacketLeft = w * jacketFraction;
    final jacketRight = w * (1 - jacketFraction);
    final twistedLeft = jacketLeft + 20;
    final twistedRight = jacketRight - 20;

    _drawJacket(canvas, size, jacketLeft, jacketRight);

    for (int i = 0; i < n; i++) {
      final wire = wires[i];
      final targetY = wireSpacing * (i + 1);

      // Twist partner index (adjacent pairs: 0↔1, 2↔3, …).
      final hasTwist = wire.isPaired;
      final partnerIdx = hasTwist ? (i.isEven ? i + 1 : i - 1) : i;
      final partnerY = hasTwist ? wireSpacing * (partnerIdx + 1) : targetY;

      _drawWire(
        canvas: canvas,
        wire: wire,
        size: size,
        startY: targetY,
        endY: targetY,
        twistedLeft: twistedLeft,
        twistedRight: twistedRight,
        twistAmplitude: hasTwist ? (partnerY - targetY).abs() / 2 : 0,
        twistPhase: hasTwist && i.isOdd ? math.pi : 0,
      );
    }

    for (int i = 0; i < n; i++) {
      final y = wireSpacing * (i + 1);
      _drawLabel(canvas, wires[i].label, Offset(jacketRight + 6, y));
    }

    if (spec.label.isNotEmpty) {
      _drawLabel(canvas, spec.label, Offset(4, h / 2),
          vertical: true, fontSize: 9);
    }
  }

  void _drawJacket(Canvas canvas, Size size, double left, double right) {
    final h = size.height;
    final rect = Rect.fromLTRB(left, h * 0.1, right, h * 0.9);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.08));

    canvas.drawRRect(rr, Paint()..color = const Color(0xFF37474F));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawWire({
    required Canvas canvas,
    required WireSpec wire,
    required Size size,
    required double startY,
    required double endY,
    required double twistedLeft,
    required double twistedRight,
    required double twistAmplitude,
    required double twistPhase,
  }) {
    const steps = 120;
    final path = Path();
    bool started = false;

    for (int s = 0; s <= steps; s++) {
      final t = s / steps; // 0..1 along twisted section
      final x = twistedLeft + t * (twistedRight - twistedLeft);

      // sin(πt) envelope: fades twist in at left, out at right.
      final envelope = math.sin(math.pi * t);
      final y = endY +
          twistAmplitude *
              envelope *
              math.sin(twistPhase + t * twistCycles * 2 * math.pi);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    final leftPath = Path()
      ..moveTo(0, startY)
      ..lineTo(twistedLeft, startY);
    final rightPath = Path()
      ..moveTo(twistedRight, endY)
      ..lineTo(size.width, endY);

    final basePaint = Paint()
      ..color = wire.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(leftPath, basePaint);
    canvas.drawPath(rightPath, basePaint);
    canvas.drawPath(path, basePaint);

    if (wire.isStriped) {
      // Dashed stripe overlay, centred mid-gap.
      drawDashedCablePath(canvas, path,
          color: wire.stripeColor!,
          strokeWidth: 1.2,
          dash: 8,
          gap: 8,
          startOffset: 4);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos,
      {bool vertical = false, double fontSize = 8}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF37474F),
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    if (vertical) {
      canvas.translate(pos.dx + tp.height, pos.dy + tp.width / 2);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset.zero);
    } else {
      tp.paint(canvas, Offset(pos.dx, pos.dy - tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CablePainter old) =>
      old.spec != spec ||
      old.twistCycles != twistCycles ||
      old.jacketFraction != jacketFraction;
}
