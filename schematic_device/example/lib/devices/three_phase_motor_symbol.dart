// example/lib/devices/three_phase_motor_symbol.dart
//
// IEC 60617 schematic symbol for a 3-phase asynchronous motor.
//
// The symbol shows the standard circle body (M / 3~) with three vertical
// phase leads entering the circle from above.  Terminal entry points are
// computed so that each lead lands exactly on the circle perimeter:
//
//   U at x=14 → entry (14, 38)   [sqrt(20²−16²) = 12 below centre y=50]
//   V at x=30 → entry (30, 30)   [top of circle]
//   W at x=46 → entry (46, 38)   [symmetric to U]
//
// Canvas: 60 × 72

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

abstract final class ThreePhaseMotorSymbol {
  static const String typeKey = 'motor_3ph_symbol';

  // Terminal ids
  static const String u = 'U';
  static const String v = 'V';
  static const String w = 'W';

  // Geometry
  static const Offset _center = Offset(30, 50);
  static const double _radius = 20;
  static const Color _ink = Color(0xDD000000);

  // Terminal connection points (top edge, y=0)
  static const Offset _uTerm = Offset(14, 0);
  static const Offset _vTerm = Offset(30, 0);
  static const Offset _wTerm = Offset(46, 0);

  // Points on the circle perimeter where leads enter
  // For a point (x, ?) on circle centre (30,50) radius 20:
  //   y = 50 − sqrt(20² − (x−30)²)  [upper half]
  static const Offset _uEntry = Offset(14, 38); // sqrt(400−256)=12 → y=50−12
  static const Offset _vEntry = Offset(30, 30); // sqrt(400−0)=20   → y=50−20
  static const Offset _wEntry = Offset(46, 38); // symmetric to U

  static DeviceDefinition build() {
    return DeviceDefinition(
      typeKey: typeKey,
      name: '3-phase motor (schematic symbol)',
      description:
          'IEC schematic symbol — circle with M/3~ and three phase leads.',
      parameters: [
        const StringParamDef(
          id: 'ref',
          label: 'Motor reference',
          defaultValue: 'M1',
        ),
      ],
      connectors: const [
        ConnectorDef(
          id: 'phases',
          name: 'Phase inputs (U V W)',
          placement: ConnectorPlacement.top,
          terminals: [
            TerminalDef(
              id: u,
              label: 'U',
              group: ElectricalGroup.power,
              anchorInConnector: _uTerm,
            ),
            TerminalDef(
              id: v,
              label: 'V',
              group: ElectricalGroup.power,
              anchorInConnector: _vTerm,
            ),
            TerminalDef(
              id: w,
              label: 'W',
              group: ElectricalGroup.power,
              anchorInConnector: _wTerm,
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          size: const Size(60, 72),
          drawables: [
            // ── Phase leads (enter circle from above) ─────────────────────
            const DrawLine(
              id: 'lead_u',
              start: _uTerm,
              end: _uEntry,
              color: _ink,
              strokeWidth: 1.5,
            ),
            const DrawLine(
              id: 'lead_v',
              start: _vTerm,
              end: _vEntry,
              color: _ink,
              strokeWidth: 1.5,
            ),
            const DrawLine(
              id: 'lead_w',
              start: _wTerm,
              end: _wEntry,
              color: _ink,
              strokeWidth: 1.5,
            ),

            // ── Motor circle body ─────────────────────────────────────────
            const DrawCircle(
              id: 'body',
              center: _center,
              radius: _radius,
              fillColor: Color(0xFFFFFFFF),
              strokeColor: _ink,
              strokeWidth: 1.5,
            ),

            // ── Labels inside circle ──────────────────────────────────────
            const DrawText(
              id: 'label_m',
              text: 'M',
              position: Offset(30, 46),
              anchor: TextAnchor.center,
              fontSize: 14,
              bold: true,
              color: _ink,
            ),
            const DrawText(
              id: 'label_3ph',
              text: '3~',
              position: Offset(30, 57),
              anchor: TextAnchor.center,
              fontSize: 9,
              color: _ink,
            ),

            // ── Reference label (below circle) ────────────────────────────
            const DrawText(
              id: 'label_ref',
              text: r'${ref}',
              position: Offset(30, 72),
              anchor: TextAnchor.bottomCenter,
              fontSize: 7,
              color: _ink,
            ),

            // ── Terminal anchors ──────────────────────────────────────────
            DrawTerminalAnchor(
              terminalDefId: u,
              radius: 2.5,
              colorBinding: _binding(u),
            ),
            DrawTerminalAnchor(
              terminalDefId: v,
              radius: 2.5,
              colorBinding: _binding(v),
            ),
            DrawTerminalAnchor(
              terminalDefId: w,
              radius: 2.5,
              colorBinding: _binding(w),
            ),
          ],
        ),
      ),
    );
  }

  static TerminalColorBinding _binding(String id) => TerminalColorBinding(
        terminalDefId: id,
        connectedColor: const Color(0xFF4CAF50),
        unconnectedColor: const Color(0xFFEF6C00),
      );
}
