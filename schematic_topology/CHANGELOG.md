# Changelog

## 0.1.0

- Initial extraction from tower_configurator_flutter. Generic graph-editor
  engine: `SchematicTopologyCanvas`, `SchematicConnectionPainter`,
  `SchematicConnectionRouter`, overlay painters, and `SchematicNodeCard`.
- Decoupled from domain via `SchematicNode`/`SchematicEdge` interfaces and an
  injected `EdgeStyleResolver`.
