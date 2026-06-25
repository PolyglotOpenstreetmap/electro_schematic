// example/lib/devices/motor_with_sensors_device.dart
//
// Composite device: rotating motor + N sensors + optional brake.
//
// This is the authoring / template-path composition example.  The appearance
// uses [DrawDeviceRef] nodes (resolved at render time via
// [RenderContext.deviceResolver]) to embed child device graphics inline.
//
// Wire layout (left→right):
//   [motor block 67.5 × 60] gap [sensor 0] [sensor 1] … [brake?]
//   Sensors start at x = 70, spaced every 56 px.
//
// Symbol layout:
//   [motor circle 60 × 80] gap [sensor symbol 0] …
//   Sensors start at x = 65, spaced every 34 px.

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import 'rotating_motor_device.dart';
import 'sensor_device.dart';

abstract final class MotorWithSensorsDevice {
  static const String typeKey = 'motor_with_sensors';

  static DeviceDefinition build() {
    return DeviceDefinition(
      typeKey: typeKey,
      name: 'Motor with sensors (composite)',
      description:
          'Composite: rotating motor + parameterised number of sensors '
          '+ optional brake stub (brake device deferred). Facade terminals '
          'U/V/W delegate onto the embedded motor at wire level and use '
          'static anchors on the combined glyph at symbol level.',
      parameters: const [
        NumParamDef(
          id: 'sensorCount',
          label: 'Number of sensors',
          defaultValue: 1,
          min: 0,
          max: 4,
        ),
        BoolParamDef(
          id: 'hasBrake',
          label: 'Has brake',
          defaultValue: false,
        ),
        // Pass-through params forwarded to the child motor
        StringParamDef(
          id: 'motorRef',
          label: 'Motor article reference',
          defaultValue: '',
        ),
        NumParamDef(
          id: 'voltage',
          label: 'Supply voltage (V)',
          defaultValue: 400,
          min: 24,
          max: 690,
        ),
      ],
      // Facade terminals of the assembly. At the wire level (which contains
      // the `motor_ref_wire` DrawDeviceRef) each terminal delegates onto the
      // embedded motor's corresponding terminal; at the symbol level (no ref)
      // the static `levelAnchors[symbol]` points on the combined glyph apply.
      connectors: const [
        ConnectorDef(
          id: 'supply',
          name: 'Supply',
          placement: ConnectorPlacement.top,
          terminals: [
            TerminalDef(
              id: 'U',
              label: 'U',
              group: ElectricalGroup.power,
              anchorInConnector: Offset(7.5, 0),
              levelAnchors: {DrawingLevel.symbol: Offset(10, 0)},
              delegate: TerminalDelegate(
                  refId: 'motor_ref_wire', terminalId: RotatingMotorDevice.u1),
            ),
            TerminalDef(
              id: 'V',
              label: 'V',
              group: ElectricalGroup.power,
              anchorInConnector: Offset(25, 0),
              levelAnchors: {DrawingLevel.symbol: Offset(30, 0)},
              delegate: TerminalDelegate(
                  refId: 'motor_ref_wire', terminalId: RotatingMotorDevice.v1),
            ),
            TerminalDef(
              id: 'W',
              label: 'W',
              group: ElectricalGroup.power,
              anchorInConnector: Offset(42.5, 0),
              levelAnchors: {DrawingLevel.symbol: Offset(50, 0)},
              delegate: TerminalDelegate(
                  refId: 'motor_ref_wire', terminalId: RotatingMotorDevice.w1),
            ),
          ],
        ),
      ],
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          // Wide enough for motor + up to 4 sensors
          size: const Size(310, 70),
          drawables: [
            // ── Internal interconnect: supply feed lines into U1/V1/W1 ─────
            // (Plain drawables; the motor terminals sit at the ref offset
            // (0,5) plus the motor's own anchors at y = 8 → y = 13.)
            const DrawLine(
                start: Offset(7.5, 0),
                end: Offset(7.5, 13),
                color: Color(0xFF795548)),
            const DrawLine(
                start: Offset(25, 0),
                end: Offset(25, 13),
                color: Color(0xFF000000)),
            const DrawLine(
                start: Offset(42.5, 0),
                end: Offset(42.5, 13),
                color: Color(0xFF9E9E9E)),

            // ── Motor terminal block ───────────────────────────────────────
            DrawDeviceRef(
              id: 'motor_ref_wire',
              typeKey: RotatingMotorDevice.typeKey,
              offset: const Offset(0, 5),
              paramOverrides: {
                'motorRef': r'${motorRef}',
                'voltage': r'${voltage}',
              },
            ),

            // ── Sensor blocks (repeated horizontally) ─────────────────────
            DrawRepeat(
              id: 'sensors_wire',
              count: r'${sensorCount}',
              axis: RepeatAxis.horizontal,
              spacing: 56,
              templateChild: DrawDeviceRef(
                typeKey: SensorDevice.typeKey,
                offset: const Offset(70, 14),
              ),
            ),
          ],
        ),
        symbol: LevelAppearance(
          size: const Size(230, 80),
          drawables: [
            // ── Motor schematic circle ─────────────────────────────────────
            DrawDeviceRef(
              id: 'motor_ref_sym',
              typeKey: RotatingMotorDevice.typeKey,
              level: DrawingLevel.symbol,
              offset: Offset.zero,
              paramOverrides: {
                'motorRef': r'${motorRef}',
                'voltage': r'${voltage}',
              },
            ),

            // ── Sensor symbols (repeated horizontally) ────────────────────
            DrawRepeat(
              id: 'sensors_sym',
              count: r'${sensorCount}',
              axis: RepeatAxis.horizontal,
              spacing: 34,
              templateChild: DrawDeviceRef(
                typeKey: SensorDevice.typeKey,
                level: DrawingLevel.symbol,
                offset: const Offset(65, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
