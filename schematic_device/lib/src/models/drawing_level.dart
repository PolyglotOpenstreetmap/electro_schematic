// lib/src/models/drawing_level.dart
//
// DrawingLevel enum — shared between models and drawable DSL.

/// Which diagram surface to render at.
///
/// Levels are an orthogonal axis to device composition: a single
/// [DeviceDefinition] supplies a [LevelAppearance] for each level it supports.
enum DrawingLevel {
  wire,
  cable,
  symbol,
  topology;

  static DrawingLevel fromJson(String name) =>
      DrawingLevel.values.byName(name);
}
