// example/lib/devices/simple_terminal_strip_device.dart
//
// Sample DeviceDefinition: a generic N-terminal vertical strip.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

/// Factory for a generic terminal strip device definition.
///
/// The strip renders a variable number of terminals in a vertical column.
/// Terminal count is driven by the 'count' parameter (1–32).
abstract final class SimpleTerminalStripDevice {
  static const String typeKey = 'simple_terminal_strip';

  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _unconnected = Color(0xFFEF6C00);

  /// Builds the device definition.
  ///
  /// Because [DrawRepeat] handles N-terminal expansion at render time,
  /// the definition itself is small regardless of how many terminals the
  /// instance ends up rendering.
  static DeviceDefinition build() {
    return const DeviceDefinition(
      typeKey: typeKey,
      name: 'Generic terminal strip',
      description:
          'A vertical strip of N screw terminals. Terminal count is '
          'set via the "count" parameter.',
      parameters: [
        NumParamDef(
          id: 'count',
          label: 'Terminal count',
          defaultValue: 4,
          min: 1,
          max: 32,
        ),
        StringParamDef(
          id: 'label',
          label: 'Block label',
          defaultValue: 'TB',
        ),
      ],
      connectors: [
        // A single connector with a representative terminal definition.
        // At runtime the renderer uses DrawRepeat to place N circles.
        ConnectorDef(
          id: 'terminals',
          name: 'Terminals',
          placement: ConnectorPlacement.left,
          terminals: [
            TerminalDef(
              id: 'T1',
              label: 'T1',
              group: ElectricalGroup.control,
              anchorInConnector: Offset(15, 10),
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          // Height computed by the renderer dynamically — default based on 4
          // terminals. The block rectangle is drawn by a DrawRect whose
          // bottom is parameterised indirectly via the repeat region.
          size: Size(30, 70),
          drawables: [
            // ── Block outline ─────────────────────────────────────────────
            // We draw a fixed-height outline here for the default count=4.
            // For a fully dynamic outline height, Phase 2 would add a
            // "computed size" mechanism.
            DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 30, 70),
              fillColor: _white,
              strokeColor: _black,
              strokeWidth: 1.0,
            ),

            // ── Block label (top center) ──────────────────────────────────
            DrawText(
              id: 'block_label',
              text: r'${label}',
              position: Offset(15, 5),
              anchor: TextAnchor.topCenter,
              fontSize: 8,
              bold: true,
              color: _black,
            ),

            // ── Terminal dots (repeated) ──────────────────────────────────
            DrawRepeat(
              id: 'terminal_dots',
              count: r'${count}',
              axis: RepeatAxis.vertical,
              spacing: 15,
              templateChild: DrawGroup(
                children: [
                  // Terminal circle
                  DrawCircle(
                    center: Offset(15, 10),
                    radius: 4.0,
                    fillColor: _unconnected,
                    strokeColor: _black,
                    strokeWidth: 0.8,
                  ),
                  // Terminal number label
                  DrawText(
                    text: r'T${index+1}',
                    position: Offset(6, 10),
                    anchor: TextAnchor.centerRight,
                    fontSize: 7,
                    color: _black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a [DeviceInstance] for this strip with the given terminal count.
  static DeviceInstance createInstance({
    int count = 4,
    String label = 'TB',
    Offset position = Offset.zero,
  }) {
    return DeviceInstance(
      definition: build(),
      position: position,
      paramValues: {'count': count, 'label': label},
    );
  }
}
