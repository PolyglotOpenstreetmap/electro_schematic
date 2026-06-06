// example/lib/devices/sensor_device.dart
//
// Minimal atomic sensor device (proximity / wheel encoder).
//
// Wire level: small rectangular terminal block with 4 numbered terminals.
// Symbol level: small circle with "S" label and a top lead wire.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

abstract final class SensorDevice {
  static const String typeKey = 'sensor';

  // Terminal IDs (4-wire rotating sensor)
  static const String t1 = '1'; // brown  — supply+
  static const String t2 = '2'; // orange — output A
  static const String t3 = '3'; // purple — output B (or supply−)
  static const String t4 = '4'; // green  — shield / PE

  static const Color _ink = Color(0xDD000000);
  static const Color _grey = Color(0xFFF5F5F5);

  static DeviceDefinition build() {
    return DeviceDefinition(
      typeKey: typeKey,
      name: 'Sensor (proximity / wheel encoder)',
      description:
          'Inductive proximity or wheel-encoder sensor. '
          '4-wire output (rotating motor); 3-wire variant is a later refinement.',
      parameters: const [
        StringParamDef(
          id: 'sensorRef',
          label: 'Sensor reference',
          defaultValue: '',
        ),
      ],
      connectors: [
        ConnectorDef(
          id: 'main',
          name: 'Sensor terminals',
          placement: ConnectorPlacement.top,
          terminals: [
            TerminalDef(
              id: t1,
              label: '1',
              group: ElectricalGroup.power,
              anchorInConnector: const Offset(8, 8),
            ),
            TerminalDef(
              id: t2,
              label: '2',
              group: ElectricalGroup.control,
              anchorInConnector: const Offset(20, 8),
            ),
            TerminalDef(
              id: t3,
              label: '3',
              group: ElectricalGroup.control,
              anchorInConnector: const Offset(32, 8),
            ),
            TerminalDef(
              id: t4,
              label: '4',
              group: ElectricalGroup.control,
              anchorInConnector: const Offset(44, 8),
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          size: const Size(52, 32),
          drawables: [
            // Body
            const DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 52, 32),
              cornerRadius: 3,
              fillColor: _grey,
              strokeColor: _ink,
              strokeWidth: 1.0,
            ),
            // Terminal dots
            DrawTerminalAnchor(terminalDefId: t1, radius: 2.0),
            DrawTerminalAnchor(terminalDefId: t2, radius: 2.0),
            DrawTerminalAnchor(terminalDefId: t3, radius: 2.0),
            DrawTerminalAnchor(terminalDefId: t4, radius: 2.0),
            // Terminal labels
            const DrawText(
              text: '1',
              position: Offset(8, 14),
              anchor: TextAnchor.topCenter,
              fontSize: 7,
              color: _ink,
            ),
            const DrawText(
              text: '2',
              position: Offset(20, 14),
              anchor: TextAnchor.topCenter,
              fontSize: 7,
              color: _ink,
            ),
            const DrawText(
              text: '3',
              position: Offset(32, 14),
              anchor: TextAnchor.topCenter,
              fontSize: 7,
              color: _ink,
            ),
            const DrawText(
              text: '4',
              position: Offset(44, 14),
              anchor: TextAnchor.topCenter,
              fontSize: 7,
              color: _ink,
            ),
            // Reference label
            const DrawText(
              id: 'ref_label',
              text: r'${sensorRef}',
              position: Offset(26, 30),
              anchor: TextAnchor.bottomCenter,
              fontSize: 6,
              color: _ink,
            ),
          ],
        ),
        symbol: LevelAppearance(
          size: const Size(30, 38),
          drawables: [
            // Top lead
            const DrawLine(
              id: 'sym_lead',
              start: Offset(15, 0),
              end: Offset(15, 10),
              color: _ink,
              strokeWidth: 1.0,
            ),
            // Circle body
            const DrawCircle(
              id: 'sym_body',
              center: Offset(15, 23),
              radius: 12,
              fillColor: Color(0xFFFFFFFF),
              strokeColor: _ink,
              strokeWidth: 1.0,
            ),
            // S label
            const DrawText(
              id: 'sym_label',
              text: 'S',
              position: Offset(15, 23),
              anchor: TextAnchor.center,
              fontSize: 11,
              bold: true,
              color: _ink,
            ),
          ],
        ),
      ),
    );
  }
}
