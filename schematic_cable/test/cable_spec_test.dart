import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_cable/schematic_cable.dart';

void main() {
  group('CableSpec.twistedPairs', () {
    test('produces 2 conductors per pair', () {
      final spec = CableSpec.twistedPairs(pairs: 4);
      expect(spec.wireCount, 8);
    });

    test('ring wire is striped and paired; tip is paired, not striped', () {
      final spec = CableSpec.twistedPairs(pairs: 1);
      final tip = spec.wires[0];
      final ring = spec.wires[1];
      expect(tip.isPaired, isTrue);
      expect(tip.isStriped, isFalse);
      expect(ring.isPaired, isTrue);
      expect(ring.isStriped, isTrue);
      expect(tip.pairId, ring.pairId);
    });
  });

  group('CableSpec.power', () {
    test('threePhaseNPE has L1 L2 L3 N PE', () {
      final spec = CableSpec.power(PowerScheme.threePhaseNPE);
      expect(spec.wireCount, 5);
      expect(spec.wires.last.label, 'PE');
      expect(spec.wires.last.isStriped, isTrue); // green/yellow earth
    });

    test('power3Phase without N or PE has 3 conductors', () {
      final spec = CableSpec.power3Phase(withN: false, withPE: false);
      expect(spec.wireCount, 3);
    });

    test('power1Phase with PE has L N PE', () {
      final spec = CableSpec.power1Phase();
      expect(spec.wireCount, 3);
    });
  });

  group('CableSpec.multicore', () {
    test('signals + common', () {
      final spec = CableSpec.multicore(signals: 5);
      expect(spec.wireCount, 6);
      expect(spec.wires.last.label, 'COM');
    });

    test('without common', () {
      final spec = CableSpec.multicore(signals: 5, withCommon: false);
      expect(spec.wireCount, 5);
    });
  });

  group('WireSpec equality', () {
    test('value equality', () {
      const a = WireSpec(color: Color(0xFF112233), label: 'L1');
      const b = WireSpec(color: Color(0xFF112233), label: 'L1');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
