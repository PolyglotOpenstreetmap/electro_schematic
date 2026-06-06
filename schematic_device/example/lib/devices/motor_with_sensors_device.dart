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
          '+ optional brake stub (brake device deferred).',
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
      connectors: const [], // composite exposes no terminals of its own here
      appearance: DeviceAppearance(
        wire: LevelAppearance(
          // Wide enough for motor + up to 4 sensors
          size: const Size(310, 70),
          drawables: [
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
