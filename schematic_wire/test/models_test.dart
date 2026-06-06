// packages/electro_schematic/schematic_wire/test/models_test.dart
//
// Unit tests for the Phase 3 models: CableConnector and CrossReference.

import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_wire/schematic_wire.dart';

void main() {
  group('ConnectorPort', () {
    test('round-trips through JSON', () {
      const port = ConnectorPort(
        pinLabel: 'PE',
        plugTerminalId: 'P1.PE',
        socketTerminalId: 'S1.PE',
        description: 'protective earth',
      );

      final json = port.toJson();
      final restored = ConnectorPort.fromJson(json);

      expect(restored.pinLabel, port.pinLabel);
      expect(restored.plugTerminalId, port.plugTerminalId);
      expect(restored.socketTerminalId, port.socketTerminalId);
      expect(restored.description, port.description);
    });

    test('description is omitted from JSON when null', () {
      const port = ConnectorPort(
        pinLabel: '1',
        plugTerminalId: 'P1.1',
        socketTerminalId: 'S1.1',
      );

      final json = port.toJson();
      expect(json.containsKey('description'), isFalse);
    });

    test('fromJson with no description sets it to null', () {
      final json = {
        'pinLabel': 'A',
        'plugTerminalId': 'P2.A',
        'socketTerminalId': 'S2.A',
      };
      final port = ConnectorPort.fromJson(json);
      expect(port.description, isNull);
    });
  });

  group('CableConnector', () {
    CableConnector _makeConnector() {
      return const CableConnector(
        id: 'X1',
        label: 'X1 (P1/S1)',
        plugBlockId: 'TB_MOTOR_PLUG',
        socketBlockId: 'TB_MOTOR_SOCKET',
        ports: [
          ConnectorPort(pinLabel: '1', plugTerminalId: 'P1.1', socketTerminalId: 'S1.1'),
          ConnectorPort(pinLabel: '2', plugTerminalId: 'P1.2', socketTerminalId: 'S1.2'),
          ConnectorPort(pinLabel: 'PE', plugTerminalId: 'P1.PE', socketTerminalId: 'S1.PE'),
        ],
        connectorType: 'Deutsch DT04-3P',
      );
    }

    test('round-trips through JSON', () {
      final conn = _makeConnector();
      final json = conn.toJson();
      final restored = CableConnector.fromJson(json);

      expect(restored.id, conn.id);
      expect(restored.label, conn.label);
      expect(restored.plugBlockId, conn.plugBlockId);
      expect(restored.socketBlockId, conn.socketBlockId);
      expect(restored.ports.length, conn.ports.length);
      expect(restored.connectorType, conn.connectorType);
      expect(restored.description, isNull);
    });

    test('portByPin returns matching port', () {
      final conn = _makeConnector();
      final pe = conn.portByPin('PE');
      expect(pe, isNotNull);
      expect(pe!.plugTerminalId, 'P1.PE');
    });

    test('portByPin returns null for unknown pin', () {
      final conn = _makeConnector();
      expect(conn.portByPin('X'), isNull);
    });

    test('connectorType and description are omitted when null', () {
      const conn = CableConnector(
        id: 'Y1',
        label: 'Y1',
        plugBlockId: 'A',
        socketBlockId: 'B',
        ports: [],
      );
      final json = conn.toJson();
      expect(json.containsKey('connectorType'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });
  });

  group('CrossReference', () {
    test('round-trips through JSON', () {
      const ref = CrossReference(
        id: 'xref_1',
        pageIndex: 0,
        blockId: 'TB_MOTOR_1',
        terminalId: 'motor_1_u',
        targetPageIndex: 2,
        targetBlockId: 'TB_IV3',
        targetTerminalId: 'iv3_out_u',
        direction: CrossReferenceDirection.outgoing,
        label: 'P.3 / IV3 / U',
      );

      final json = ref.toJson();
      final restored = CrossReference.fromJson(json);

      expect(restored.id, ref.id);
      expect(restored.pageIndex, ref.pageIndex);
      expect(restored.blockId, ref.blockId);
      expect(restored.terminalId, ref.terminalId);
      expect(restored.targetPageIndex, ref.targetPageIndex);
      expect(restored.targetBlockId, ref.targetBlockId);
      expect(restored.targetTerminalId, ref.targetTerminalId);
      expect(restored.direction, ref.direction);
      expect(restored.label, ref.label);
    });

    test('annotationText uses custom label when set', () {
      const ref = CrossReference(
        id: 'x',
        pageIndex: 0,
        blockId: 'TB1',
        targetPageIndex: 1,
        targetBlockId: 'TB2',
        direction: CrossReferenceDirection.outgoing,
        label: 'custom',
      );
      expect(ref.annotationText, 'custom');
    });

    test('annotationText builds from target when label is null', () {
      const ref = CrossReference(
        id: 'x',
        pageIndex: 0,
        blockId: 'TB1',
        targetPageIndex: 2,
        targetBlockId: 'TB_IV3',
        targetTerminalId: 'iv3_u',
        direction: CrossReferenceDirection.incoming,
      );
      // targetPageIndex=2 → page number 3 → "P.3"
      expect(ref.annotationText, 'P.3 / TB_IV3 / iv3_u');
    });

    test('annotationText without terminalId omits the terminal part', () {
      const ref = CrossReference(
        id: 'x',
        pageIndex: 0,
        blockId: 'TB1',
        targetPageIndex: 1,
        targetBlockId: 'TB2',
        direction: CrossReferenceDirection.outgoing,
      );
      expect(ref.annotationText, 'P.2 / TB2');
    });

    test('optional fields omitted from JSON when null', () {
      const ref = CrossReference(
        id: 'x',
        pageIndex: 0,
        blockId: 'TB1',
        targetPageIndex: 1,
        targetBlockId: 'TB2',
        direction: CrossReferenceDirection.outgoing,
      );
      final json = ref.toJson();
      expect(json.containsKey('terminalId'), isFalse);
      expect(json.containsKey('targetTerminalId'), isFalse);
      expect(json.containsKey('label'), isFalse);
    });

    test('CrossReferenceDirection enum round-trips', () {
      for (final dir in CrossReferenceDirection.values) {
        const ref = CrossReference(
          id: 'x',
          pageIndex: 0,
          blockId: 'TB1',
          targetPageIndex: 1,
          targetBlockId: 'TB2',
          direction: CrossReferenceDirection.outgoing,
        );
        final json = {
          ...ref.toJson(),
          'direction': dir.name,
        };
        final restored = CrossReference.fromJson(json);
        expect(restored.direction, dir);
      }
    });
  });
}
