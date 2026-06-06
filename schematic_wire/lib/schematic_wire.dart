// packages/electro_schematic/schematic_wire/lib/schematic_wire.dart
//
// Public API for the schematic_wire package.

// ── Models ──────────────────────────────────────────────────────────────────
export 'src/models/base.dart';

export 'src/models/channel_grouping.dart';
export 'src/models/connections.dart';
export 'src/models/connector.dart';
export 'src/models/cross_reference.dart';
export 'src/models/custom_layout.dart';
export 'src/models/diagram_config.dart';
// DiagramLayout is also defined in custom_layout.dart; hide the duplicate here.
export 'src/models/diagram_models.dart' hide DiagramLayout;
export 'src/models/diagram_overlay_group.dart';
export 'src/models/enums.dart';
export 'src/models/outputs.dart';
export 'src/models/pagination.dart';
export 'src/models/power_grid.dart';
export 'src/models/terminals.dart';
export 'src/models/title_block_config.dart';
export 'src/models/wire_color_settings.dart';
export 'src/models/wiring_overview_models.dart';

// ── Painters ─────────────────────────────────────────────────────────────────
export 'src/painters/diagram_painter_utils.dart';
export 'src/painters/paginated_diagram_painter.dart';
export 'src/painters/power_grid_painter.dart';
export 'src/painters/terminal_block_painter.dart';
export 'src/painters/title_block_painter.dart';
