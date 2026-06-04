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

Dependency graph: `schematic_cable → schematic_wire`; `schematic_topology` is standalone.
Each package depends only on `flutter` + `collection`.

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
