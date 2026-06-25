# electro_schematic

Reusable Flutter packages for rendering electrical schematics — wiring diagrams,
cables, and topology graphs. Extracted from the Tower Configurator app so the
rendering/geometry engine can be shared across projects, with all domain
(bell-tower) business logic kept in the host app.

## Packages

| Package | Purpose |
|---------|---------|
| [`schematic_wire`](schematic_wire/) | Paginated wiring-diagram renderer — terminal blocks, wire routing, power grids, title blocks, pagination, PDF export. Also hosts low-level wire path/stroke primitives. Domain block types plug in via the `customBlockPainters` extension point. |
| [`schematic_cable`](schematic_cable/) | Cable rendering — cross-section (twisted pairs / power / multicore) and cable-to-terminal breakout diagrams. Builds on `schematic_wire` primitives. |
| [`schematic_topology`](schematic_topology/) | Generic graph/topology editor — interactive canvas (pan/zoom/drag-to-connect/rubber-band), connection painter, 90° routing geometry, node-card hover detection. Decoupled from any domain via `SchematicNode`/`SchematicEdge` interfaces + an injected `EdgeStyleResolver`. |
| [`schematic_device`](schematic_device/) | Data-driven device definitions — a `DeviceDefinition` DSL plus a stateless `DeviceRenderer` that replaces hand-written `_draw*` painter methods. Multi-level appearances, recursive composition, parametric terminals, JSON round-trip. |
| [`schematic_designer`](schematic_designer/) | Graphical editor (drop-in Flutter widget) for authoring `DeviceDefinition`s — draw on a canvas, switch drawing levels, configure connectors/terminals, undo/redo, and export JSON. |

Dependency graph: `schematic_wire → schematic_device`; `schematic_designer → schematic_device`;
`schematic_cable` and `schematic_topology` are standalone. Every package depends only on
`flutter` + `collection` (plus the edges above).

## Drawing levels

A device is drawn differently depending on the *surface* it appears on. `schematic_device`
models this with the `DrawingLevel` enum, and a single `DeviceDefinition` carries one
`LevelAppearance` per level it supports (`appearance.forLevel(level)`) — so the *same*
definition renders correctly on every sheet:

| Level | Surface | Typical appearance |
|---|---|---|
| `symbol` | One-line / schematic-symbol sheet | Compact glyph — the whole device as a single icon |
| `wire` | Detailed wiring diagram | Full terminal blocks and internal wiring |
| `cable` | Cable / harness view | Cable cross-sections and breakouts |
| `topology` | Node / connectivity graph | The device as one node in a topology graph |

Levels are **orthogonal to composition**: a composite assembly can appear as a single
**combined** glyph at `symbol` level and **explode** into its component devices at `wire`
level. The combined/exploded convention, facade-terminal delegation, and automatic wire
re-anchoring (`TerminalGeometry`) are documented in
[`schematic_device`](schematic_device/#composite-devices-combined-vs-exploded-levels).
To author multi-level devices visually, see [`schematic_designer`](schematic_designer/#authoring-across-levels).

## How a host app consumes these

The packages are consumed as a **git submodule** plus `path:` dependencies, which
keeps pub resolution identical to in-repo packages and allows editing app + package
code in one hot-reload session.

```bash
# In the host app repo:
git submodule add <repo-url> packages/electro_schematic
git submodule update --init
```

```yaml
# host app pubspec.yaml
dependencies:
  schematic_wire:     { path: packages/electro_schematic/schematic_wire }
  schematic_cable:    { path: packages/electro_schematic/schematic_cable }
  schematic_topology: { path: packages/electro_schematic/schematic_topology }
```

> **CI / fresh clones:** clone with `--recurse-submodules`, or run
> `git submodule update --init` before `flutter pub get`, otherwise the `path:`
> targets are missing.

### Pinned releases

For reproducible builds, switch each entry from a `path:` dep to a git-pinned dep:

```yaml
schematic_wire:
  git: { url: <repo-url>, ref: v0.1.0, path: schematic_wire }
```

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
