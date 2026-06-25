# schematic_device

A domain-agnostic Flutter package for defining and rendering electrical devices
in schematic diagrams.  Replaces hardcoded `_draw*` painter methods with a
data-driven **DeviceDefinition → DeviceRenderer** pipeline.

## Features

- **`DeviceDefinition`** — blueprint: connectors, terminals, parameters, and a
  multi-level appearance (wire / cable / topology / symbol).
- **Drawable DSL** — a sealed `DrawableNode` scene-graph built from composable
  primitives (`DrawRect`, `DrawCircle`, `DrawLine`, `DrawPolyline`, `DrawText`,
  `DrawPath`) and electrical symbols (`DrawCoil`, `DrawCapacitor`,
  `DrawTerminalAnchor`, `DrawGroup`, `DrawRepeat`, `DrawDeviceRef`).
- **`DeviceRenderer`** — stateless recursive tree-walker; renders any
  `DeviceInstance` onto a Flutter `Canvas` in microseconds.
- **Recursive composition** — `DrawDeviceRef` and `DeviceInstance.children`
  let you nest devices (e.g. motor + sensor block + terminal strip) without
  bespoke code.
- **Parametric terminals** — `DrawRepeat` scales a terminal strip to any count
  from a single `DeviceDefinition`.
- **Conditions** — `DrawGroup(showIf: …)` and `DrawableNode.showIf` support
  star/delta jumpers, capacitor presence, and other parameter-driven
  visibility rules.
- **JSON round-trip** — every node serializes/deserializes; definitions can be
  stored as assets, shipped over an API, or authored in `schematic_designer`.

## Quick start

```dart
import 'package:schematic_device/schematic_device.dart';

// 1. Register built-in serializers (call once, e.g. in main()).
SchematicDevicePackage.initialize();

// 2. Build a definition.
final relay = DeviceDefinition(
  typeKey: 'my_relay',
  parameters: [],
  connectors: [
    ConnectorDef(
      id: 'coil',
      placement: ConnectorPlacement.top,
      terminals: [
        TerminalDef(id: 'A1', label: 'A1', anchorInConnector: const Offset(10, 0)),
        TerminalDef(id: 'A2', label: 'A2', anchorInConnector: const Offset(30, 0)),
      ],
    ),
  ],
  appearance: DeviceAppearance(
    wire: LevelAppearance(nodes: [
      DrawRect(rect: const Rect.fromLTWH(0, 0, 40, 60), strokeColor: Colors.black),
      DrawCoil(start: const Offset(10, 10), end: const Offset(10, 50), color: Colors.black),
    ]),
  ),
);

// 3. Place an instance.
final instance = DeviceInstance(
  definition: relay,
  position: const Offset(100, 80),
);

// 4. Render.
const renderer = DeviceRenderer();
renderer.render(canvas, instance); // inside CustomPainter.paint()
```

## Conditions (parameter-driven visibility)

```dart
// Show the star jumper only when the motorRef starts with 'IV'.
DrawGroup(
  showIf: ParamStartsWithCondition('motorRef', 'IV'),
  children: [
    DrawLine(start: Offset(0, 0), end: Offset(20, 0), color: Colors.blue),
  ],
)
```

## Recursive composition

```dart
// Motor assembly: references a separate SensorBlock definition by typeKey.
DrawDeviceRef(
  typeKey: 'sensor_block',
  offset: Offset(0, 70),
)
```

The renderer resolves `'sensor_block'` through `RenderContext.deviceResolver`
and renders it inline, with cycle and depth guards.

## Composite devices: combined vs exploded levels

An assembly can render as **one combined symbol** at some drawing levels and
**split into its component devices** at others. The convention is purely
declarative:

- A **combined** level is a `LevelAppearance` containing only plain drawables
  (the assembly's glyph).
- An **exploded** level is a `LevelAppearance` whose drawables include
  `DrawDeviceRef`s to the component devices, plus plain `DrawLine`s for the
  internal interconnect.

`DeviceDefinition.isCompositeAt(level)` reports which kind a level is.

### Facade terminals

External terminals of the assembly need different geometry per level. Each
`TerminalDef` supports:

- `levelAnchors` — per-level static anchor overrides (e.g. the terminal's
  position on the combined glyph), falling back to `anchorInConnector`;
- `delegate: TerminalDelegate(refId, terminalId)` — at levels whose appearance
  contains the `DrawDeviceRef` with that `id`, the terminal resolves to the
  referenced child's terminal position (transformed through the ref's and any
  enclosing `DrawGroup`s' offset/scale).

```dart
TerminalDef(
  id: 'U',
  label: 'U',
  group: ElectricalGroup.power,
  anchorInConnector: Offset(7.5, 0),                    // generic fallback
  levelAnchors: {DrawingLevel.symbol: Offset(10, 0)},   // on the glyph
  delegate: TerminalDelegate(refId: 'motor_ref_wire', terminalId: 'U1'),
)
```

### Resolving wire endpoints

`TerminalGeometry` answers "where is terminal X at level L" so wires attached
to logical terminals re-anchor automatically when the level changes:

```dart
final p = TerminalGeometry.resolveForInstance(
  instance, 'U', DrawingLevel.wire,
  resolver: registry.lookup,
);
```

### Per-instance override

`DeviceInstance.forcedLevel` force-expands or force-collapses one placed
instance regardless of the diagram's level: an instance with
`forcedLevel: DrawingLevel.wire` on a symbol-level sheet renders its exploded
wire appearance (and `TerminalGeometry` reports the matching delegated
positions).

See `example/lib/devices/motor_with_sensors_device.dart` for a complete
assembly with facade terminals, delegation, and internal wiring.

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
