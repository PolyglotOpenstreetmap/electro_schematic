// schematic_cable — cable model
//
// A consolidated, domain-agnostic description of a cable as an ordered list of
// conductors ([WireSpec]) plus a jacket label ([CableSpec]). Consumed by both
// `CablePainter` (cross-section) and `CableBreakout`/`CableBreakoutPainter`
// (cable-to-terminal breakout).

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONDUCTOR
// ─────────────────────────────────────────────────────────────────────────────

/// A single conductor in a cable.
///
/// [stripeColor] is non-null for a striped conductor (e.g. the "ring" wire of a
/// twisted pair, or a PE green/yellow) — drawn as a base [color] with a
/// contrasting dashed stripe overlay.
///
/// [pairId] groups conductors into twisted pairs (null = not paired). Wires
/// sharing a [pairId] are rendered with a twist in the cross-section painter.
@immutable
class WireSpec {
  const WireSpec({
    required this.color,
    required this.label,
    this.stripeColor,
    this.subLabel,
    this.pairId,
  });

  final Color color;
  final Color? stripeColor;
  final String label; // e.g. "TX+", "L1", "PE", "S3"
  final String? subLabel; // e.g. "tip" / "ring" / pin number
  final int? pairId; // which twisted pair this wire belongs to (null = none)

  bool get isStriped => stripeColor != null;
  bool get isPaired => pairId != null;

  @override
  bool operator ==(Object other) =>
      other is WireSpec &&
      other.color == color &&
      other.stripeColor == stripeColor &&
      other.label == label &&
      other.subLabel == subLabel &&
      other.pairId == pairId;

  @override
  int get hashCode => Object.hash(color, stripeColor, label, subLabel, pairId);
}

// ─────────────────────────────────────────────────────────────────────────────
// CABLE
// ─────────────────────────────────────────────────────────────────────────────

/// Describes a whole cable: jacket label + ordered list of conductors.
@immutable
class CableSpec {
  const CableSpec({required this.wires, this.label = 'CABLE'});

  final List<WireSpec> wires;
  final String label;

  int get wireCount => wires.length;

  // ───────────── Factories for common cable types ─────────────

  /// `pairs` twisted pairs using the T568 / telecom convention.
  factory CableSpec.twistedPairs({
    required int pairs,
    String label = 'CABLE · TP',
  }) {
    assert(pairs >= 1);
    final wires = <WireSpec>[];
    for (var p = 0; p < pairs; p++) {
      final base = telecomPairColor(p);
      final names = _pairNames(p);
      wires.add(WireSpec(color: base, label: names.$1, subLabel: 'tip', pairId: p));
      wires.add(WireSpec(
        color: const Color(0xFFEFEFE6), // white "ring"
        stripeColor: base,
        label: names.$2,
        subLabel: 'ring',
        pairId: p,
      ));
    }
    return CableSpec(wires: wires, label: '$label · ${pairs}P');
  }

  /// Power cable. Picks colors per IEC 60446 / HD 308 S2, or the US/CA
  /// convention when [northAmerican] is true.
  factory CableSpec.power(
    PowerScheme scheme, {
    bool northAmerican = false,
    String? label,
  }) {
    return CableSpec(
      wires: _powerWires(scheme, northAmerican: northAmerican),
      label: label ?? 'CABLE · ${scheme.shortName}',
    );
  }

  /// Convenience: three-phase power, optionally with N and PE.
  factory CableSpec.power3Phase({bool withN = true, bool withPE = true}) {
    final scheme = withN
        ? (withPE ? PowerScheme.threePhaseNPE : PowerScheme.l1l2l3n)
        : PowerScheme.l1l2l3;
    return CableSpec.power(scheme);
  }

  /// Convenience: single-phase power (L + N), optionally with PE.
  factory CableSpec.power1Phase({bool withPE = true}) =>
      CableSpec.power(withPE ? PowerScheme.lnpe : PowerScheme.ln);

  /// Multicore signal cable: [signals] independently coded signal wires plus an
  /// optional common (return / shield drain) as the last wire.
  factory CableSpec.multicore({
    required int signals,
    bool withCommon = true,
    String commonLabel = 'COM',
    Color commonColor = const Color(0xFF1A1A1A),
    String label = 'CABLE · MC',
  }) {
    assert(signals >= 1);
    final wires = <WireSpec>[
      for (var i = 0; i < signals; i++)
        WireSpec(color: multicoreSignalColor(i), label: 'S${i + 1}'),
      if (withCommon) WireSpec(color: commonColor, label: commonLabel),
    ];
    return CableSpec(
      wires: wires,
      label: withCommon ? '$label · ${signals}+1' : '$label · $signals-core',
    );
  }

  /// Fully custom — pass the conductors yourself.
  factory CableSpec.custom({required List<WireSpec> wires, String label = 'CABLE'}) =>
      CableSpec(wires: wires, label: label);
}

// ─────────────────────────────────────────────────────────────────────────────
// POWER SCHEMES
// ─────────────────────────────────────────────────────────────────────────────

enum PowerScheme {
  ln, // L + N
  lnpe, // L + N + PE
  l1l2l3, // L1 + L2 + L3 (delta)
  l1l2l3n, // L1 + L2 + L3 + N
  threePhaseNPE, // L1 + L2 + L3 + N + PE
}

extension PowerSchemeName on PowerScheme {
  String get shortName => switch (this) {
        PowerScheme.ln => 'L+N',
        PowerScheme.lnpe => 'L+N+PE',
        PowerScheme.l1l2l3 => '3∅',
        PowerScheme.l1l2l3n => '3∅+N',
        PowerScheme.threePhaseNPE => '3∅+N+PE',
      };
}

List<WireSpec> _powerWires(PowerScheme scheme, {required bool northAmerican}) {
  const iecL1 = Color(0xFF8B5A2B); // brown
  const iecL2 = Color(0xFF1A1A1A); // black
  const iecL3 = Color(0xFF9A9A9A); // gray
  const iecN = Color(0xFF3866B8); // blue
  const naL1 = Color(0xFF1A1A1A); // black
  const naL2 = Color(0xFFC64545); // red
  const naL3 = Color(0xFF3866B8); // blue
  const naN = Color(0xFFEFEFE6); // white
  const peBase = Color(0xFF3F8F4A);
  const peStripe = Color(0xFFE6C84A);

  final l1 = northAmerican ? naL1 : iecL1;
  final l2 = northAmerican ? naL2 : iecL2;
  final l3 = northAmerican ? naL3 : iecL3;
  final n = northAmerican ? naN : iecN;

  WireSpec live(String name, Color c) => WireSpec(color: c, label: name);
  WireSpec neutral() => WireSpec(color: n, label: 'N');
  const earth = WireSpec(color: peBase, stripeColor: peStripe, label: 'PE');

  return switch (scheme) {
    PowerScheme.ln => [live('L', l1), neutral()],
    PowerScheme.lnpe => [live('L', l1), neutral(), earth],
    PowerScheme.l1l2l3 => [live('L1', l1), live('L2', l2), live('L3', l3)],
    PowerScheme.l1l2l3n => [live('L1', l1), live('L2', l2), live('L3', l3), neutral()],
    PowerScheme.threePhaseNPE => [
        live('L1', l1),
        live('L2', l2),
        live('L3', l3),
        neutral(),
        earth,
      ],
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR PALETTES (public so callers can build custom specs in the same style)
// ─────────────────────────────────────────────────────────────────────────────

/// Twisted-pair base colors (telecom convention): blue, orange, green, brown…
const List<Color> telecomPairPalette = <Color>[
  Color(0xFF3866B8), // blue
  Color(0xFFE08A3A), // orange
  Color(0xFF3F8F4A), // green
  Color(0xFFA06B3A), // brown
  Color(0xFF5A6478), // slate
];

/// Multicore signal palette (one entry per signal, cycles when exhausted).
const List<Color> multicoreSignalPalette = <Color>[
  Color(0xFFB48A5B), // brown
  Color(0xFFC64545), // red
  Color(0xFFE08A3A), // orange
  Color(0xFFE6C84A), // yellow
  Color(0xFF3F8F4A), // green
  Color(0xFF3866B8), // blue
  Color(0xFF7A4AA8), // violet
  Color(0xFF9A9A9A), // gray
  Color(0xFF1A1A1A), // black
  Color(0xFFEFEFE6), // white
];

/// Telecom pair base color for pair index [p] (cycles via HSL past the palette).
Color telecomPairColor(int p) {
  if (p < telecomPairPalette.length) return telecomPairPalette[p];
  final hue = (p * 47) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.45).toColor();
}

/// Multicore signal color for signal index [i] (cycles through the palette).
Color multicoreSignalColor(int i) =>
    multicoreSignalPalette[i % multicoreSignalPalette.length];

(String, String) _pairNames(int p) {
  const names = [
    ('TX+', 'TX−'),
    ('RX+', 'RX−'),
    ('CLK+', 'CLK−'),
    ('D+', 'D−'),
    ('AUX+', 'AUX−'),
  ];
  if (p < names.length) return names[p];
  return ('P${p + 1}+', 'P${p + 1}−');
}
