import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_topology/schematic_topology.dart';

class _Node implements SchematicNode {
  _Node(this.id, this.position, this.size);
  @override
  final String id;
  @override
  final Offset position;
  @override
  final Size size;
  @override
  Size get renderSize => size;
}

void main() {
  const router = SchematicConnectionRouter();
  final node = _Node('n', const Offset(100, 100), const Size(100, 60));

  group('getConnectionPoint', () {
    test('center returns node center', () {
      final p = router.getConnectionPoint(node, ConnectionSide.center);
      expect(p, const Offset(150, 130));
    });

    test('right edge with single (non-multicore) offset', () {
      final p = router.getConnectionPoint(node, ConnectionSide.right);
      // right border x = 200, center y 130 minus 15 default offset
      expect(p, const Offset(200, 115));
    });

    test('top edge with multicore offset', () {
      final p =
          router.getConnectionPoint(node, ConnectionSide.top, isMulticore: true);
      expect(p, const Offset(165, 100));
    });
  });

  group('generate90DegreeRoute', () {
    test('no corners when either side is center', () {
      final wp = router.generate90DegreeRoute(
          Offset.zero, const Offset(10, 10), ConnectionSide.center, ConnectionSide.right);
      expect(wp, isEmpty);
    });

    test('two waypoints for same-orientation horizontal sides', () {
      final wp = router.generate90DegreeRoute(const Offset(0, 0),
          const Offset(100, 50), ConnectionSide.right, ConnectionSide.left);
      expect(wp.length, 2);
      expect(wp[0].dx, 50); // midX
      expect(wp[1].dx, 50);
    });
  });

  group('findNonOverlappingPosition', () {
    test('returns desired position when no overlap', () {
      final p = router.findNonOverlappingPosition(
          const Offset(500, 500), const Size(50, 50),
          existingNodes: [node]);
      expect(p, const Offset(500, 500));
    });
  });
}
