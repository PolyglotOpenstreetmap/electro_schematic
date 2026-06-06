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

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
