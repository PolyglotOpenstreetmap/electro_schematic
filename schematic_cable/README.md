# schematic_cable

A generic Flutter package for rendering cables — twisted-pair / power / multicore
cross-sections and cable-to-terminal breakout schematics.

## Features

- **`CableSpec` / `WireSpec`** — domain-agnostic model: a cable is an ordered list
  of conductors with colors, optional stripes, labels, and twisted-pair grouping.
- **Factories** — `CableSpec.twistedPairs`, `CableSpec.power` (+ `power3Phase` /
  `power1Phase`), `CableSpec.multicore`, `CableSpec.custom`.
- **`CablePainter`** — cross-section view with twisted pairs and a jacket.
- **`CableBreakout` / `CableBreakoutPainter`** — cable fanning out to labelled terminals.
- **`PowerScheme`** — IEC 60446 / HD 308 S2 (and North American) color conventions.
- **Public palettes** — `telecomPairPalette`, `multicoreSignalPalette` for custom specs.

## Usage

```dart
import 'package:schematic_cable/schematic_cable.dart';

// Cross-section:
CustomPaint(painter: CablePainter(spec: CableSpec.twistedPairs(pairs: 4)));

// Breakout:
CableBreakout(spec: CableSpec.power(PowerScheme.threePhaseNPE));

// Multicore:
CableBreakout(spec: CableSpec.multicore(signals: 7));
```

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
