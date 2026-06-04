# Changelog

## 0.1.0

- Initial extraction from tower_configurator_flutter (formerly the in-repo
  `schematic_diagram` package; renamed to `schematic_wire` on move into the
  `electro_schematic` monorepo).
- Provides `PaginatedDiagramPainter`, `BlockPainter`/`BlockPaintContext` extension API,
  all physical models (`TerminalBlock`, `Connection`, `DiagramPage`, etc.), and
  supporting painters (`TerminalBlockPainter`, `PowerGridPainter`, `TitleBlockPainter`).
