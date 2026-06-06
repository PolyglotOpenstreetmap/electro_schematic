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
import 'package:schematic_device/schematic_device.dart';
import 'package:schematic_designer/schematic_designer.dart';

void main() {
  SchematicDevicePackage.initialize(); // required for JSON round-trip
  runApp(const MyApp());
}

class MyEditorPage extends StatelessWidget {
  const MyEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DeviceDesigner(
        initialNodes: const [], // start blank, or pre-populate
        onExport: (jsonString) {
          // jsonString is a JSON array of DrawableNode maps
          debugPrint(jsonString);
        },
      ),
    );
  }
}
```

## Running the example

```bash
cd packages/electro_schematic/schematic_designer/example
flutter run -d linux   # or -d macos / -d chrome
```

The example pre-populates a "SimpleRelay" device (body, coil winding, label,
terminal stubs) and shows a live `DeviceRenderer` preview on the right.

## Architecture

| Class | Role |
|---|---|
| `DesignerState` | Immutable snapshot: list of nodes + selected node id |
| `DesignerHistory` | Undo/redo stacks; `push` / `checkpoint` / `updateSilent` |
| `DesignerNotifier` | `ChangeNotifier` driving the UI; exposes `add`, `remove`, `drag*`, `undo`, `redo`, `export`, `import` |
| `DeviceDesigner` | Assembled widget (toolbar + `NodeList` + `DesignerCanvas` + `PropertiesPanel`) |
| `DesignerCanvas` | `GestureDetector` + `CustomPaint`; handles zoom and drag |
| `NodeBoundsHelper` | Hit-testing + bounds for all 11 `DrawableNode` subtypes |

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
