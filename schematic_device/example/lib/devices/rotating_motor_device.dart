// example/lib/devices/rotating_motor_device.dart
//
// Sample DeviceDefinition: a star/delta 3-phase rotating motor terminal block.
//
// Faithfully expresses what _drawMotorTerminalBlock does in
// wiring_element_painter.dart, but as a pure data structure with no Dart
// drawing code.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

/// Factory for the rotating motor terminal-block device definition.
abstract final class RotatingMotorDevice {
  static const String typeKey = 'rotating_motor';

  // ── Terminal ids ──────────────────────────────────────────────────────────
  static const String u1 = 'U1';
  static const String v1 = 'V1';
  static const String w1 = 'W1';
  static const String w2 = 'W2';
  static const String u2 = 'U2';
  static const String v2 = 'V2';

  // Grid geometry matching the painter: 3 cols × 2 rows, spacing 17.5
  static const double _colSpacing = 17.5;
  static const double _rowSpacing = 17.5;
  static const double _originX = 7.5;
  static const double _originY = 8.0;

  static Offset _termPos(int col, int row) => Offset(
        _originX + col * _colSpacing,
        _originY + row * _rowSpacing,
      );

  // Row 0: U1(col=0), V1(col=1), W1(col=2)
  static final Offset _posU1 = _termPos(0, 0);
  static final Offset _posV1 = _termPos(1, 0);
  static final Offset _posW1 = _termPos(2, 0);
  // Row 1: W2(col=0), U2(col=1), V2(col=2)  ← shifted order
  static final Offset _posW2 = _termPos(0, 1);
  static final Offset _posU2 = _termPos(1, 1);
  static final Offset _posV2 = _termPos(2, 1);

  static const Color _black87 = Color(0xDD000000);
  static const Color _grey100 = Color(0xFFF5F5F5);
  static const Color _connected = Color(0xFF4CAF50);
  static const Color _jumper = Color(0xFF1976D2);
  static const Color _unconnected = Color(0xFFEF6C00);

  static TerminalColorBinding _binding(String terminalId,
      {bool isJumper = false}) {
    return TerminalColorBinding(
      terminalDefId: terminalId,
      connectedColor: _connected,
      jumperColor: isJumper ? _jumper : null,
      unconnectedColor: _unconnected,
    );
  }

  static DeviceDefinition build() {
    return DeviceDefinition(
      typeKey: typeKey,
      name: '3-phase rotating motor terminal block',
      description:
          'Star/delta motor winding terminals with coil symbols and '
          'optional capacitor for single-phase variants.',
      parameters: [
        const StringParamDef(
          id: 'motorRef',
          label: 'Motor article reference',
          defaultValue: '',
        ),
        const NumParamDef(
          id: 'voltage',
          label: 'Supply voltage (V)',
          defaultValue: 400,
          min: 24,
          max: 690,
        ),
        const EnumParamDef(
          id: 'motorType',
          label: 'Motor winding type',
          values: ['standard', 'decoster'],
          defaultValue: 'standard',
        ),
      ],
      connectors: [
        ConnectorDef(
          id: 'main',
          name: 'Motor terminals',
          placement: ConnectorPlacement.top,
          terminals: [
            TerminalDef(
              id: u1,
              label: 'U1',
              group: ElectricalGroup.power,
              anchorInConnector: _posU1,
            ),
            TerminalDef(
              id: v1,
              label: 'V1',
              group: ElectricalGroup.power,
              anchorInConnector: _posV1,
            ),
            TerminalDef(
              id: w1,
              label: 'W1',
              group: ElectricalGroup.power,
              anchorInConnector: _posW1,
            ),
            TerminalDef(
              id: w2,
              label: 'W2',
              group: ElectricalGroup.power,
              anchorInConnector: _posW2,
              isJumper: true,
            ),
            TerminalDef(
              id: u2,
              label: 'U2',
              group: ElectricalGroup.power,
              anchorInConnector: _posU2,
              isJumper: true,
            ),
            TerminalDef(
              id: v2,
              label: 'V2',
              group: ElectricalGroup.power,
              anchorInConnector: _posV2,
              isJumper: true,
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          size: const Size(67.5, 60),
          drawables: [
            // ── Block body ────────────────────────────────────────────────
            const DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 67.5, 60),
              cornerRadius: 4,
              fillColor: _grey100,
              strokeColor: _black87,
              strokeWidth: 1.5,
            ),

            // ── Terminal anchors (row 0) ───────────────────────────────────
            DrawTerminalAnchor(
              terminalDefId: u1,
              radius: 2.5,
              colorBinding: _binding(u1),
            ),
            DrawTerminalAnchor(
              terminalDefId: v1,
              radius: 2.5,
              colorBinding: _binding(v1),
            ),
            DrawTerminalAnchor(
              terminalDefId: w1,
              radius: 2.5,
              colorBinding: _binding(w1),
            ),

            // ── Terminal anchors (row 1 — jumper terminals) ────────────────
            DrawTerminalAnchor(
              terminalDefId: w2,
              radius: 2.5,
              colorBinding: _binding(w2, isJumper: true),
            ),
            DrawTerminalAnchor(
              terminalDefId: u2,
              radius: 2.5,
              colorBinding: _binding(u2, isJumper: true),
            ),
            DrawTerminalAnchor(
              terminalDefId: v2,
              radius: 2.5,
              colorBinding: _binding(v2, isJumper: true),
            ),

            // ── Terminal labels (right-aligned, 5.5px left of center) ─────
            ..._terminalLabels(),

            // ── Motor coils ───────────────────────────────────────────────
            DrawCoil(
              id: 'coil_u',
              start: _posU1,
              end: _posU2,
              color: _black87,
              strokeWidth: 1.5,
            ),
            DrawCoil(
              id: 'coil_v',
              start: _posV1,
              end: _posV2,
              color: _black87,
              strokeWidth: 1.5,
            ),
            DrawCoil(
              id: 'coil_w',
              start: _posW1,
              end: _posW2,
              color: _black87,
              strokeWidth: 1.5,
            ),

            // ── Motor reference label (bottom center) ─────────────────────
            const DrawText(
              id: 'motor_ref_label',
              text: r'${motorRef}',
              position: Offset(33.75, 54),
              anchor: TextAnchor.bottomCenter,
              fontSize: 8,
              color: _black87,
            ),

            // ── Star jumpers (show when voltage >= 300 V, i.e. NOT delta) ─
            DrawGroup(
              id: 'star_jumpers',
              showIf: const NotCondition(
                  ParamLessThanCondition('voltage', 300)),
              children: _starJumpers(),
            ),

            // ── Delta jumpers (show when voltage < 300 V) ─────────────────
            DrawGroup(
              id: 'delta_jumpers',
              showIf: const ParamLessThanCondition('voltage', 300),
              children: _deltaJumpers(),
            ),

            // ── Capacitor (show when motorRef starts with 'IV21') ─────────
            DrawGroup(
              id: 'capacitor_group',
              showIf: const ParamStartsWithCondition('motorRef', 'IV21'),
              children: [
                DrawCapacitor(
                  center: Offset(
                    (_posU1.dx + _posV1.dx) / 2,
                    _posU1.dy - 12,
                  ),
                  horizontal: true,
                  scale: 0.8,
                  color: _black87,
                ),
                DrawLine(
                  start: Offset((_posU1.dx + _posV1.dx) / 2 - 8,
                      _posU1.dy - 12),
                  end: _posU1,
                  color: _black87,
                ),
                DrawLine(
                  start: Offset((_posU1.dx + _posV1.dx) / 2 + 8,
                      _posV1.dy - 12),
                  end: _posV1,
                  color: _black87,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<DrawText> _terminalLabels() {
    const labelOffset = -5.5;
    return [
      DrawText(
          text: 'U1',
          position: Offset(_posU1.dx + labelOffset, _posU1.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
      DrawText(
          text: 'V1',
          position: Offset(_posV1.dx + labelOffset, _posV1.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
      DrawText(
          text: 'W1',
          position: Offset(_posW1.dx + labelOffset, _posW1.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
      DrawText(
          text: 'W2',
          position: Offset(_posW2.dx + labelOffset, _posW2.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
      DrawText(
          text: 'U2',
          position: Offset(_posU2.dx + labelOffset, _posU2.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
      DrawText(
          text: 'V2',
          position: Offset(_posV2.dx + labelOffset, _posV2.dy),
          anchor: TextAnchor.centerRight,
          fontSize: 7),
    ];
  }

  static const Color _starColor = Color(0xFF555555);

  // Star connection: W2, U2, V2 connected to a central star point
  static List<DrawableNode> _starJumpers() {
    const starPt = Offset(33.75, 37);
    return [
      DrawLine(start: _posW2, end: starPt, color: _starColor, strokeWidth: 1),
      DrawLine(start: _posU2, end: starPt, color: _starColor, strokeWidth: 1),
      DrawLine(start: _posV2, end: starPt, color: _starColor, strokeWidth: 1),
    ];
  }

  // Delta connection: U2→V1, V2→W1, W2→U1 (simplified short lines)
  static const Color _deltaColor = Color(0xFF333399);

  static List<DrawableNode> _deltaJumpers() {
    return [
      DrawLine(
          start: _posW2,
          end: _posU1,
          color: _deltaColor,
          strokeWidth: 1),
      DrawLine(
          start: _posU2,
          end: _posV1,
          color: _deltaColor,
          strokeWidth: 1),
      DrawLine(
          start: _posV2,
          end: _posW1,
          color: _deltaColor,
          strokeWidth: 1),
    ];
  }
}
