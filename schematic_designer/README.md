# schematic_designer

A Flutter graphical editor for authoring `DeviceDefinition`s from
[schematic_device](../schematic_device/README.md) — draw shapes on a canvas,
configure properties in a JSON panel, undo/redo, and export a ready-to-use
device definition.

## Features

- **`DeviceDesigner` widget** — fully assembled editor: toolbar, node list,
  canvas, and properties panel in one drop-in widget.
- **Node palette** — add `DrawRect`, `DrawCircle`, `DrawLine`, `DrawText`,
  `DrawCoil`, `DrawCapacitor` nodes from a popup menu.
- **Drag-to-move** — click and drag nodes directly on the canvas; zoom from
  0.5× to 8× with the mouse wheel.
- **Properties panel** — live JSON editor; parse errors are surfaced as a
  snackbar without corrupting the undo stack.
- **Undo / redo** — full history with keyboard shortcuts (`Ctrl+Z` / `Ctrl+Y`).
- **JSON export / import** — round-trip through `DrawableNodeFactory` from
  `schematic_device`; exported JSON can be pasted straight into a
  `DeviceDefinition.appearance`.
- **Live preview** — side-by-side rendering via `DeviceRenderer` so you see
  the result as you author.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';
import 'package:schematic_designer/schematic_designer.dart';

void main() {
  SchematicDevicePackage.initialize(); // required for JSON round-trip
  runApp(const MyApp());
}

class MyEditorPage extends StatefulWidget {
  const MyEditorPage({super.key});
  @override
  State<MyEditorPage> createState() => _MyEditorPageState();
}

class _MyEditorPageState extends State<MyEditorPage> {
  // The notifier owns all editor state and the undo/redo history.
  late final DesignerNotifier notifier = DesignerNotifier(
    DesignerState.empty('my_relay', 'My Relay'), // or .fromDefinition(existing)
    resolver: DeviceRegistry.lookup,             // needed for composite previews
    knownTypeKeys: const ['sensor_block'],       // offered by the device-ref tool
  );

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: DeviceDesigner(notifier: notifier));
  }
}
```

To read the authored definition back out, listen to the `notifier` and call its
export method (or read `notifier.state`); the editor mutates that single source of truth.

## Running the example

```bash
cd packages/electro_schematic/schematic_designer/example
flutter run -d linux   # or -d macos / -d chrome
```

The example pre-populates a "SimpleRelay" device (body, coil winding, label,
terminal stubs) and shows a live `DeviceRenderer` preview on the right.

## Authoring across levels

A `DeviceDefinition` carries a separate appearance for each
[`DrawingLevel`](../schematic_device/#drawing-levels) it supports (`symbol`,
`wire`, `cable`, `topology`). The designer edits **one level at a time**:

- **Level switcher** — the `LevelSwitcher` widget (in the toolbar) shows every
  level, marks which are populated, and switches the active level. Under the
  hood it calls `notifier.setActiveLevel(level)`; `notifier.addLevel`,
  `removeLevel`, and `copyLevel(from, to)` manage which levels exist (copying is
  the fastest way to seed a new level from an existing one).
- **Active-level canvas** — the canvas always draws
  `state.appearances[state.activeLevel]`. Nodes you add, drag, or delete affect
  only that level, so the same device can be a compact glyph at `symbol` and a
  full terminal layout at `wire`.

### Connectors & composite assemblies

The left panel has **NODES** and **CONNECTORS** tabs. The `ConnectorsPanel`
(CONNECTORS tab) authors the per-level wiring of facade terminals so a composite
device can render combined at one level and exploded at another:

- **Per-level anchor override** — tick the active-level checkbox on a terminal to
  pin its position for that level (`setTerminalLevelAnchor`), e.g. where the
  terminal sits on the combined `symbol` glyph; unticked levels fall back to the
  terminal's generic anchor.
- **Delegation** — point a facade terminal at a child device's terminal via the
  dropdowns (`setTerminalDelegate(refId, terminalId)`). At levels whose appearance
  contains that `DrawDeviceRef`, the terminal resolves to the child's position
  (so wires re-anchor automatically when the assembly explodes).
- **Device-ref & terminal tools** — the palette gains a *Device ref* tool (drops a
  `DrawDeviceRef` to a `knownTypeKeys` type) and a *Terminal* tool (adds a
  `TerminalDef` + matching `DrawTerminalAnchor` in one undo step). Facade terminals
  are overlaid as orange rings (positioned via `TerminalGeometry`), and a
  **combined / exploded** chip in the toolbar reports the active level's kind.

> Composite previews and delegation require a `resolver` on the notifier (see the
> quick start). Without it, `DrawDeviceRef`s render as placeholders.

See [`schematic_device` › Composite devices](../schematic_device/#composite-devices-combined-vs-exploded-levels)
for the underlying model.

## Architecture

| Class | Role |
|---|---|
| `DesignerState` | Immutable snapshot: list of nodes + selected node id |
| `DesignerHistory` | Undo/redo stacks; `push` / `checkpoint` / `updateSilent` |
| `DesignerNotifier` | `ChangeNotifier` driving the UI; exposes `add`, `remove`, `drag*`, `undo`, `redo`, `export`, `import` |
| `DeviceDesigner` | Assembled widget (toolbar + `NodeList` + `DesignerCanvas` + `PropertiesPanel`) |
| `DesignerCanvas` | `GestureDetector` + `CustomPaint`; handles zoom and drag |
| `LevelSwitcher` | Toolbar control to add/remove/copy and switch the active `DrawingLevel` |
| `ConnectorsPanel` | CONNECTORS tab — per-level terminal anchors and facade delegation |
| `NodeBoundsHelper` | Hit-testing + bounds for all `DrawableNode` subtypes (incl. `DrawDeviceRef`) |

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
