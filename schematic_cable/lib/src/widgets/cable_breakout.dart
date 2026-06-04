// schematic_cable — cable breakout widget.

import 'package:flutter/material.dart';

import '../models/cable_spec.dart';
import '../painters/cable_breakout_painter.dart';

/// Renders a cable-to-terminal breakout schematic for [spec].
///
///   CableBreakout(spec: CableSpec.twistedPairs(pairs: 4))
///   CableBreakout(spec: CableSpec.power(PowerScheme.threePhaseNPE))
///   CableBreakout(spec: CableSpec.multicore(signals: 7))
class CableBreakout extends StatelessWidget {
  const CableBreakout({
    super.key,
    required this.spec,
    this.padding = const EdgeInsets.all(16),
    this.background = const Color(0xFFF7F5F0),
    this.stroke = const Color(0xFF1A2030),
  });

  final CableSpec spec;
  final EdgeInsets padding;
  final Color background;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: padding,
        child: CustomPaint(
          painter:
              CableBreakoutPainter(spec: spec, stroke: stroke, paper: background),
          size: Size.infinite,
        ),
      ),
    );
  }
}
