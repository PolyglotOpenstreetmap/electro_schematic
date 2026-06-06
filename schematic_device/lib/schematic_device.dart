// lib/schematic_device.dart
//
// Public API barrel export for the schematic_device package.
//
// Import this file to access all public types. Call
// [SchematicDevicePackage.initialize] once at app/test startup to enable
// JSON deserialization of [DrawableNode] subtypes.

// ── Models ────────────────────────────────────────────────────────────────────
export 'src/models/device_definition.dart';
export 'src/models/device_instance.dart';
export 'src/models/drawing_level.dart';
export 'src/models/parameter_def.dart';

// ── Drawable DSL ──────────────────────────────────────────────────────────────
// drawable_node.dart re-exports condition.dart, terminal_color_binding.dart,
// color_utils.dart AND declares all concrete DrawableNode subtypes via
// `part` files (primitives.dart, composite_symbols.dart).
export 'src/drawable/color_utils.dart';
export 'src/drawable/condition.dart';
export 'src/drawable/drawable_node.dart';
export 'src/drawable/terminal_color_binding.dart';

// ── Rendering ─────────────────────────────────────────────────────────────────
export 'src/rendering/device_renderer.dart';
export 'src/rendering/render_context.dart';

// ── Bootstrap ─────────────────────────────────────────────────────────────────
import 'src/drawable/drawable_registry.dart';

/// Entry point for package-level initialization.
///
/// Call [SchematicDevicePackage.initialize] once at app startup (e.g. in
/// `main`) to register all built-in [DrawableNode] serializers.
abstract final class SchematicDevicePackage {
  /// Registers all built-in [DrawableNode] subtypes into [DrawableNodeFactory].
  ///
  /// Idempotent — safe to call multiple times.
  static void initialize() => registerBuiltinDrawableNodes();
}
