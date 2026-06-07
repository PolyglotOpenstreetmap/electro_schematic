// example/lib/devices/motor_devices.dart
//
// DSL DeviceDefinition builders for the three motor types represented in the
// tower-configurator wiring diagrams:
//   • rotatingMotorDef  — standard 3-phase (U1/V1/W1 / W2/U2/V2 3×2 grid)
//   • linearMotorDef    — linear induction motor (1-6 vertical terminals)
//   • deCosterMotorDef  — DeCoster 3-phase (U/V/W sparse grid, no jumpers)
//
// Each definition carries both a wire level (terminal-block view) and a
// symbol level (IEC 60617 motor circle, matching the wiring-overview painter).

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Shared palette ───────────────────────────────────────────────────────────

const Color _k87 = Color(0xDD000000);
const Color _kFill = Color(0xFFF5F5F5);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kConnected = Color(0xFF4CAF50);
const Color _kUnconnected = Color(0xFFEF6C00);
const Color _kJumper = Color(0xFF1976D2);
const Color _kStar = Color(0xFF1565C0);
const Color _kDelta = Color(0xFFC62828);

TerminalColorBinding _bind(String id, {bool isJumper = false}) =>
    TerminalColorBinding(
      terminalDefId: id,
      connectedColor: _kConnected,
      jumperColor: isJumper ? _kJumper : null,
      unconnectedColor: _kUnconnected,
    );

// ─── Shared symbol level (IEC 60617 — M in circle) ───────────────────────────
//
// This is what the wiring-overview painter shows for ALL motor types.
// Wire lead entry points: U at x=14, V at x=30, W at x=46.
// Circle: centre (30,50) r=20.  Canvas: 60×80.

LevelAppearance _motorSymbolLevel({bool showYD = true}) {
  return LevelAppearance(
    size: const Size(60, 80),
    drawables: [
      // Phase leads from top into circle perimeter
      const DrawLine(
          id: 'sym_u',
          start: Offset(14, 0),
          end: Offset(14, 38),
          color: _k87,
          strokeWidth: 1.5),
      const DrawLine(
          id: 'sym_v',
          start: Offset(30, 0),
          end: Offset(30, 30),
          color: _k87,
          strokeWidth: 1.5),
      const DrawLine(
          id: 'sym_w',
          start: Offset(46, 0),
          end: Offset(46, 38),
          color: _k87,
          strokeWidth: 1.5),
      // Motor body
      const DrawCircle(
          id: 'sym_body',
          center: Offset(30, 50),
          radius: 20,
          fillColor: _kWhite,
          strokeColor: _k87,
          strokeWidth: 1.5),
      // M label
      const DrawText(
          id: 'sym_m',
          text: 'M',
          position: Offset(30, 46),
          anchor: TextAnchor.center,
          fontSize: 14,
          bold: true,
          color: _k87),
      // 3~ for 3-phase, ~ for single-phase
      DrawText(
          id: 'sym_3ph',
          text: '3~',
          position: const Offset(30, 57),
          anchor: TextAnchor.center,
          fontSize: 9,
          color: _k87,
          showIf: const NotCondition(ParamLessThanCondition('phases', 2))),
      DrawText(
          id: 'sym_1ph',
          text: '~',
          position: const Offset(30, 57),
          anchor: TextAnchor.center,
          fontSize: 9,
          color: _k87,
          showIf: const ParamLessThanCondition('phases', 2)),
      // Y/D winding indicator (only for rotating and linear — not DeCoster)
      if (showYD) ...[
        DrawGroup(
          id: 'sym_star_ind',
          showIf: AndCondition([
            const NotCondition(ParamLessThanCondition('voltage', 300)),
            const NotCondition(ParamLessThanCondition('phases', 2)),
          ]),
          children: const [
            DrawText(
                text: 'Y',
                position: Offset(54, 44),
                anchor: TextAnchor.center,
                fontSize: 8,
                bold: true,
                color: _kStar),
          ],
        ),
        DrawGroup(
          id: 'sym_delta_ind',
          showIf: AndCondition([
            const ParamLessThanCondition('voltage', 300),
            const NotCondition(ParamLessThanCondition('phases', 2)),
          ]),
          children: const [
            DrawText(
                text: 'D',
                position: Offset(54, 44),
                anchor: TextAnchor.center,
                fontSize: 8,
                bold: true,
                color: _kDelta),
          ],
        ),
      ],
      // Motor reference label below circle
      const DrawText(
          id: 'sym_ref',
          text: r'${motorRef}',
          position: Offset(30, 72),
          anchor: TextAnchor.bottomCenter,
          fontSize: 7,
          color: _k87),
    ],
  );
}

// ─── Shared parameter list ─────────────────────────────────────────────────────

const List<ParameterDef> _motorParams = [
  StringParamDef(id: 'motorRef', label: 'Motor reference', defaultValue: 'M1'),
  NumParamDef(
      id: 'voltage',
      label: 'Supply voltage (V)',
      defaultValue: 400,
      min: 24,
      max: 690),
  NumParamDef(id: 'phases', label: 'Phase count', defaultValue: 3, min: 1, max: 3),
];

// ═══════════════════════════════════════════════════════════════════════════════
// 1.  Standard rotating motor  (U1 / V1 / W1 over W2 / U2 / V2 — 3×2 grid)
// ═══════════════════════════════════════════════════════════════════════════════

DeviceDefinition rotatingMotorDef() {
  // Terminal positions: origin (7.5, 8), spacing 17.5 × 17.5
  // Layout:  U1  V1  W1    (row 0)
  //          W2  U2  V2    (row 1)
  const ox = 7.5;
  const oy = 8.0;
  const sp = 17.5; // column & row spacing

  const posU1 = Offset(ox, oy);
  const posV1 = Offset(ox + sp, oy);
  const posW1 = Offset(ox + sp * 2, oy);
  const posW2 = Offset(ox, oy + sp);
  const posU2 = Offset(ox + sp, oy + sp);
  const posV2 = Offset(ox + sp * 2, oy + sp);

  // Star-point is to the right of the 3×2 grid
  const starPt = Offset(ox + sp * 2.5, oy + sp * 0.5);

  const r = 2.5; // terminal dot radius
  const labelDx = -5.5; // label offset: left of terminal

  return DeviceDefinition(
    typeKey: 'rotating_motor',
    name: '3-phase rotating motor',
    description:
        'Star/delta terminal block: U1/V1/W1 row, W2/U2/V2 row, coils, conditional jumpers.',
    parameters: _motorParams,
    connectors: [
      ConnectorDef(
        id: 'main',
        name: 'Motor terminals',
        placement: ConnectorPlacement.top,
        terminals: const [
          TerminalDef(id: 'U1', label: 'U1', group: ElectricalGroup.power, anchorInConnector: posU1),
          TerminalDef(id: 'V1', label: 'V1', group: ElectricalGroup.power, anchorInConnector: posV1),
          TerminalDef(id: 'W1', label: 'W1', group: ElectricalGroup.power, anchorInConnector: posW1),
          TerminalDef(id: 'W2', label: 'W2', group: ElectricalGroup.power, anchorInConnector: posW2, isJumper: true),
          TerminalDef(id: 'U2', label: 'U2', group: ElectricalGroup.power, anchorInConnector: posU2, isJumper: true),
          TerminalDef(id: 'V2', label: 'V2', group: ElectricalGroup.power, anchorInConnector: posV2, isJumper: true),
        ],
      ),
    ],
    appearance: DeviceAppearance(
      wire: LevelAppearance(
        size: const Size(67.5, 60),
        drawables: [
          // Body
          const DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 67.5, 60),
              cornerRadius: 4,
              fillColor: _kFill,
              strokeColor: _k87,
              strokeWidth: 1.5),
          // Terminal dots
          DrawTerminalAnchor(terminalDefId: 'U1', radius: r, colorBinding: _bind('U1')),
          DrawTerminalAnchor(terminalDefId: 'V1', radius: r, colorBinding: _bind('V1')),
          DrawTerminalAnchor(terminalDefId: 'W1', radius: r, colorBinding: _bind('W1')),
          DrawTerminalAnchor(terminalDefId: 'W2', radius: r, colorBinding: _bind('W2', isJumper: true)),
          DrawTerminalAnchor(terminalDefId: 'U2', radius: r, colorBinding: _bind('U2', isJumper: true)),
          DrawTerminalAnchor(terminalDefId: 'V2', radius: r, colorBinding: _bind('V2', isJumper: true)),
          // Terminal labels (left of each dot)
          ..._rotLabels(posU1, posV1, posW1, posW2, posU2, posV2, labelDx),
          // Diagonal coils connecting winding ends (U1→U2, V1→V2, W1→W2)
          DrawCoil(id: 'coil_u', start: posU1, end: posU2, color: _k87, strokeWidth: 1.5),
          DrawCoil(id: 'coil_v', start: posV1, end: posV2, color: _k87, strokeWidth: 1.5),
          DrawCoil(id: 'coil_w', start: posW1, end: posW2, color: _k87, strokeWidth: 1.5),
          // Motor reference label at bottom centre
          const DrawText(
              id: 'rot_ref',
              text: r'${motorRef}',
              position: Offset(33.75, 54),
              anchor: TextAnchor.bottomCenter,
              fontSize: 8,
              color: _k87),
          // Star jumpers (voltage ≥ 300 V): W2, U2, V2 → common star point
          DrawGroup(
            id: 'star_jumpers',
            showIf: const NotCondition(ParamLessThanCondition('voltage', 300)),
            children: [
              DrawLine(start: posW2, end: starPt, color: _kStar, strokeWidth: 1),
              DrawLine(start: posU2, end: starPt, color: _kStar, strokeWidth: 1),
              DrawLine(start: posV2, end: starPt, color: _kStar, strokeWidth: 1),
            ],
          ),
          // Delta jumpers (voltage < 300 V): W2→U1, U2→V1, V2→W1
          DrawGroup(
            id: 'delta_jumpers',
            showIf: const ParamLessThanCondition('voltage', 300),
            children: [
              DrawLine(start: posW2, end: posU1, color: _kDelta, strokeWidth: 1),
              DrawLine(start: posU2, end: posV1, color: _kDelta, strokeWidth: 1),
              DrawLine(start: posV2, end: posW1, color: _kDelta, strokeWidth: 1),
            ],
          ),
        ],
      ),
      symbol: _motorSymbolLevel(showYD: true),
    ),
  );
}

List<DrawText> _rotLabels(
    Offset u1, Offset v1, Offset w1, Offset w2, Offset u2, Offset v2, double dx) {
  return [
    DrawText(text: 'U1', position: Offset(u1.dx + dx, u1.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
    DrawText(text: 'V1', position: Offset(v1.dx + dx, v1.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
    DrawText(text: 'W1', position: Offset(w1.dx + dx, w1.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
    DrawText(text: 'W2', position: Offset(w2.dx + dx, w2.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
    DrawText(text: 'U2', position: Offset(u2.dx + dx, u2.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
    DrawText(text: 'V2', position: Offset(v2.dx + dx, v2.dy), anchor: TextAnchor.centerRight, fontSize: 7, color: _k87),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2.  Linear induction motor  (terminals 1-6, vertical, x=28 in 40×60 body)
// ═══════════════════════════════════════════════════════════════════════════════
//
// IV7xxx series.  Coils between pairs 1-2, 3-4, 5-6.
// Star (≥300 V): bridge connects terminals 2, 4, 6 on the left at x=10.
// Delta (<300 V): bridge connects 1↔6, 2↔3, 4↔5.

DeviceDefinition linearMotorDef() {
  const tx = 28.0; // terminal x (within 40-wide body)
  const t0y = 12.0; // first terminal y
  const tsp = 7.5; // vertical spacing between terminals

  // Terminal positions
  const t1 = Offset(tx, t0y);
  const t2 = Offset(tx, t0y + tsp);
  const t3 = Offset(tx, t0y + tsp * 2);
  const t4 = Offset(tx, t0y + tsp * 3);
  const t5 = Offset(tx, t0y + tsp * 4);
  const t6 = Offset(tx, t0y + tsp * 5);

  // Star bridge x-coordinate (to the left)
  const bx = 10.0;
  const r = 2.5;

  return DeviceDefinition(
    typeKey: 'linear_motor',
    name: 'Linear induction motor',
    description:
        'IV7xxx — 6 numbered terminals, pairs 1-2/3-4/5-6 are individual phase windings.',
    parameters: _motorParams,
    connectors: [
      ConnectorDef(
        id: 'main',
        name: 'Motor terminals',
        placement: ConnectorPlacement.right,
        terminals: const [
          TerminalDef(id: 'T1', label: '1', group: ElectricalGroup.power, anchorInConnector: t1),
          TerminalDef(id: 'T2', label: '2', group: ElectricalGroup.power, anchorInConnector: t2, isJumper: true),
          TerminalDef(id: 'T3', label: '3', group: ElectricalGroup.power, anchorInConnector: t3),
          TerminalDef(id: 'T4', label: '4', group: ElectricalGroup.power, anchorInConnector: t4, isJumper: true),
          TerminalDef(id: 'T5', label: '5', group: ElectricalGroup.power, anchorInConnector: t5),
          TerminalDef(id: 'T6', label: '6', group: ElectricalGroup.power, anchorInConnector: t6, isJumper: true),
        ],
      ),
    ],
    appearance: DeviceAppearance(
      wire: LevelAppearance(
        size: const Size(40, 60),
        drawables: [
          // Body
          const DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 40, 60),
              cornerRadius: 4,
              fillColor: _kFill,
              strokeColor: _k87,
              strokeWidth: 1.5),
          // Terminal dots
          DrawTerminalAnchor(terminalDefId: 'T1', radius: r, colorBinding: _bind('T1')),
          DrawTerminalAnchor(terminalDefId: 'T2', radius: r, colorBinding: _bind('T2', isJumper: true)),
          DrawTerminalAnchor(terminalDefId: 'T3', radius: r, colorBinding: _bind('T3')),
          DrawTerminalAnchor(terminalDefId: 'T4', radius: r, colorBinding: _bind('T4', isJumper: true)),
          DrawTerminalAnchor(terminalDefId: 'T5', radius: r, colorBinding: _bind('T5')),
          DrawTerminalAnchor(terminalDefId: 'T6', radius: r, colorBinding: _bind('T6', isJumper: true)),
          // Terminal labels (right of each dot)
          ..._linLabels([t1, t2, t3, t4, t5, t6]),
          // Phase-winding coils between pairs (vertical → arcs point left)
          DrawCoil(id: 'coil_12', start: t1, end: t2, color: _k87, strokeWidth: 1.5, arcCount: 2),
          DrawCoil(id: 'coil_34', start: t3, end: t4, color: _k87, strokeWidth: 1.5, arcCount: 2),
          DrawCoil(id: 'coil_56', start: t5, end: t6, color: _k87, strokeWidth: 1.5, arcCount: 2),
          // Motor reference label
          const DrawText(
              id: 'lin_ref',
              text: r'${motorRef}',
              position: Offset(20, 58),
              anchor: TextAnchor.bottomCenter,
              fontSize: 8,
              color: _k87),
          // Star bridge (voltage ≥ 300 V): connects terminals 2, 4, 6 on left
          DrawGroup(
            id: 'star_bridge',
            showIf: const NotCondition(ParamLessThanCondition('voltage', 300)),
            children: [
              // Horizontal lines from each even terminal to bridge bar
              DrawLine(start: t2, end: Offset(bx, t2.dy), color: _kStar, strokeWidth: 1),
              DrawLine(start: t4, end: Offset(bx, t4.dy), color: _kStar, strokeWidth: 1),
              DrawLine(start: t6, end: Offset(bx, t6.dy), color: _kStar, strokeWidth: 1),
              // Vertical bar tying all three together
              DrawLine(
                  start: Offset(bx, t2.dy),
                  end: Offset(bx, t6.dy),
                  color: _kStar,
                  strokeWidth: 1),
            ],
          ),
          // Delta bridge (voltage < 300 V): connects 1↔6, 2↔3, 4↔5
          DrawGroup(
            id: 'delta_bridge',
            showIf: const ParamLessThanCondition('voltage', 300),
            children: [
              // Gather terminal pairs to a vertical bar, then cross-connect
              // Pair 1-6: outer, pair 2-3: middle, pair 4-5: inner
              DrawLine(start: t1, end: Offset(bx - 2, t1.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: t6, end: Offset(bx - 2, t6.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: Offset(bx - 2, t1.dy), end: Offset(bx - 2, t6.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: t2, end: Offset(bx + 2, t2.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: t3, end: Offset(bx + 2, t3.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: Offset(bx + 2, t2.dy), end: Offset(bx + 2, t3.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: t4, end: Offset(bx, t4.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: t5, end: Offset(bx, t5.dy), color: _kDelta, strokeWidth: 1),
              DrawLine(start: Offset(bx, t4.dy), end: Offset(bx, t5.dy), color: _kDelta, strokeWidth: 1),
            ],
          ),
        ],
      ),
      symbol: _motorSymbolLevel(showYD: true),
    ),
  );
}

List<DrawText> _linLabels(List<Offset> positions) {
  return List.generate(
    positions.length,
    (i) => DrawText(
      text: '${i + 1}',
      position: Offset(positions[i].dx + 5, positions[i].dy),
      anchor: TextAnchor.centerLeft,
      fontSize: 7,
      bold: true,
      color: _k87,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3.  DeCoster 3-phase motor  (U / V / W sparse grid — internally connected)
// ═══════════════════════════════════════════════════════════════════════════════
//
// IV21xxx series.  Only 3 terminals exposed — U at position 1 (top-left),
// V at position 3 (top-right), W at position 5 (centre of lower row).
// The star connection is made inside the motor; no external jumpers.

DeviceDefinition deCosterMotorDef() {
  // Sparse 3×2 grid with same origin and spacing as the rotating motor,
  // but only occupying positions 1 (U), 3 (V), 5 (W).
  const ox = 7.5;
  const oy = 8.0;
  const sp = 17.5;

  const posU = Offset(ox, oy); // position 1 (col 0, row 0)
  const posV = Offset(ox + sp * 2, oy); // position 3 (col 2, row 0)
  const posW = Offset(ox + sp, oy + sp); // position 5 (col 1, row 1)

  const r = 2.5;
  const labelDx = -5.5;

  // Coil end points: each winding drops into the motor body below the terminal
  const coilLen = 18.0;
  final posUend = Offset(posU.dx, posU.dy + coilLen);
  final posVend = Offset(posV.dx, posV.dy + coilLen);
  final posWend = Offset(posW.dx, posW.dy + coilLen);

  return DeviceDefinition(
    typeKey: 'decoster_motor',
    name: 'DeCoster motor (IV21)',
    description:
        'Single-capacitor 3-phase motor — 3 terminals (U/V/W) only; internally star-connected.',
    parameters: _motorParams,
    connectors: [
      ConnectorDef(
        id: 'main',
        name: 'Motor terminals',
        placement: ConnectorPlacement.top,
        terminals: const [
          TerminalDef(id: 'U', label: 'U', group: ElectricalGroup.power, anchorInConnector: posU),
          TerminalDef(id: 'V', label: 'V', group: ElectricalGroup.power, anchorInConnector: posV),
          TerminalDef(id: 'W', label: 'W', group: ElectricalGroup.power, anchorInConnector: posW),
        ],
      ),
    ],
    appearance: DeviceAppearance(
      wire: LevelAppearance(
        size: const Size(67.5, 60),
        drawables: [
          // Body (same footprint as rotating motor — direct swap in schematic)
          const DrawRect(
              id: 'body',
              rect: Rect.fromLTWH(0, 0, 67.5, 60),
              cornerRadius: 4,
              fillColor: _kFill,
              strokeColor: _k87,
              strokeWidth: 1.5),
          // Sparse terminal positions: 1 (U), gap, 3 (V)    — top row
          //                                  5 (W)           — bottom row
          DrawTerminalAnchor(terminalDefId: 'U', radius: r, colorBinding: _bind('U')),
          DrawTerminalAnchor(terminalDefId: 'V', radius: r, colorBinding: _bind('V')),
          DrawTerminalAnchor(terminalDefId: 'W', radius: r, colorBinding: _bind('W')),
          // Terminal labels
          DrawText(text: 'U', position: Offset(posU.dx + labelDx, posU.dy), anchor: TextAnchor.centerRight, fontSize: 7, bold: true, color: _k87),
          DrawText(text: 'V', position: Offset(posV.dx + labelDx, posV.dy), anchor: TextAnchor.centerRight, fontSize: 7, bold: true, color: _k87),
          DrawText(text: 'W', position: Offset(posW.dx + labelDx, posW.dy), anchor: TextAnchor.centerRight, fontSize: 7, bold: true, color: _k87),
          // Phase-winding coils dropping into motor body (one per terminal)
          DrawCoil(id: 'coil_u', start: posU, end: posUend, color: _k87, strokeWidth: 1.5, arcCount: 2),
          DrawCoil(id: 'coil_v', start: posV, end: posVend, color: _k87, strokeWidth: 1.5, arcCount: 2),
          DrawCoil(id: 'coil_w', start: posW, end: posWend, color: _k87, strokeWidth: 1.5, arcCount: 2),
          // Internal star connection (dashed, to show it's inside the motor)
          DrawLine(start: posUend, end: posWend, color: const Color(0x66000000), strokeWidth: 0.75),
          DrawLine(start: posVend, end: posWend, color: const Color(0x66000000), strokeWidth: 0.75),
          // "Internal ★" label for clarity
          const DrawText(
              id: 'dc_internal',
              text: '★ internal',
              position: Offset(33.75, 42),
              anchor: TextAnchor.center,
              fontSize: 6,
              color: Color(0x88000000)),
          // Motor reference label at bottom
          const DrawText(
              id: 'dc_ref',
              text: r'${motorRef}',
              position: Offset(33.75, 54),
              anchor: TextAnchor.bottomCenter,
              fontSize: 8,
              color: _k87),
        ],
      ),
      // Symbol level: same IEC circle — DeCoster is still a rotating motor
      // No Y/D indicator (connection type is fixed internally)
      symbol: _motorSymbolLevel(showYD: false),
    ),
  );
}
