# schematic_wire

A generic Flutter package for rendering paginated schematic wiring diagrams, plus
low-level wire path/stroke primitives reused by `schematic_cable`.

## Features

- **Paginated renderer** — renders A4/A3 pages with viewport clipping, print margins, and page numbering
- **Terminal block painting** — standard, motor, TRIAC, and custom block types
- **Wire corridor routing** — automatic horizontal bundle corridors with configurable spacing
- **Wire primitives** — `WireSpec`, dashed-stroke/twisted-pair/smooth-path builders (shared with `schematic_cable`)
- **Pan/zoom** — interactive viewport with rubber-band selection (via widget in the host app)
- **PDF export** — via `PaginatedDiagramPainter` with a `ui.PictureRecorder`
- **Extension point** — register custom block painters via `customBlockPainters` for domain-specific block types
- **Overlay groups** — labelled dashed bounding boxes for multi-motor groups

## Usage

```dart
import 'package:schematic_wire/schematic_wire.dart';

// Build your terminal blocks and connections, then paint:
CustomPaint(
  painter: PaginatedDiagramPainter(
    terminalBlocks: myBlocks,
    connections: myConnections,
    jumpers: myJumpers,
    page: currentPage,
    config: PaginationConfig(),
    customBlockPainters: myDomainPainters,  // optional
  ),
)
```

## Extension: custom block painters

```dart
Map<String, BlockPainter> buildMyPainters() => {
  'myCustomBlock': (canvas, block, ctx) {
    // draw using ctx.drawText, ctx.drawTextCentered, etc.
    return true; // consumed
  },
};
```

## License

GPLv3 — see the repository root [LICENSE](../LICENSE).
