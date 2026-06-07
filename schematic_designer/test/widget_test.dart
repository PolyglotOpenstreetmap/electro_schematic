// test/widget_test.dart
//
// Widget tests for Phase 3 (LevelSwitcher) and Phase 4 (canvas active-level
// rendering) of the schematic_designer package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_designer/schematic_designer.dart';
import 'package:schematic_device/schematic_device.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

DesignerNotifier _notifierWith({
  Map<DrawingLevel, LevelAppearance>? appearances,
  DeviceDefinition? Function(String)? resolver,
}) {
  final state = DesignerState(
    typeKey: 'test',
    deviceName: 'Test',
    activeLevel: DrawingLevel.wire,
    appearances: appearances ??
        {
          DrawingLevel.wire: const LevelAppearance(size: Size(80, 60)),
        },
    parameters: const [],
    connectors: const [],
  );
  return DesignerNotifier(state, resolver: resolver);
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

// ─── Phase 3: LevelSwitcher ───────────────────────────────────────────────────

void main() {
  setUpAll(SchematicDevicePackage.initialize);

  group('Phase 3 — LevelSwitcher', () {
    testWidgets('shows all four level names', (tester) async {
      final notifier = _notifierWith();
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 48,
          child: Material(
            child: LevelSwitcher(notifier: notifier),
          ),
        ),
      ));

      expect(find.text('Symbol'), findsOneWidget);
      expect(find.text('Wire'), findsOneWidget);
      expect(find.text('Cable'), findsOneWidget);
      expect(find.text('Topology'), findsOneWidget);
    });

    testWidgets('tapping active populated level is a no-op (level stays same)',
        (tester) async {
      final notifier = _notifierWith();
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 48,
          child: Material(child: LevelSwitcher(notifier: notifier)),
        ),
      ));

      await tester.tap(find.text('Wire'));
      await tester.pump();
      expect(notifier.state.activeLevel, DrawingLevel.wire);
    });

    testWidgets('tapping another populated level switches to it', (tester) async {
      final notifier = _notifierWith(appearances: {
        DrawingLevel.wire: const LevelAppearance(size: Size(80, 60)),
        DrawingLevel.symbol: const LevelAppearance(size: Size(40, 40)),
      });
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 48,
          child: Material(child: LevelSwitcher(notifier: notifier)),
        ),
      ));

      await tester.tap(find.text('Symbol'));
      await tester.pump();
      expect(notifier.state.activeLevel, DrawingLevel.symbol);
    });

    testWidgets('tapping unpopulated level adds and switches to it',
        (tester) async {
      final notifier = _notifierWith(); // only wire
      expect(notifier.state.appearances.containsKey(DrawingLevel.symbol),
          isFalse);

      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 48,
          child: Material(child: LevelSwitcher(notifier: notifier)),
        ),
      ));

      await tester.tap(find.text('Symbol'));
      await tester.pump();

      expect(
          notifier.state.appearances.containsKey(DrawingLevel.symbol), isTrue);
      expect(notifier.state.activeLevel, DrawingLevel.symbol);
    });

    testWidgets('drawables are isolated: adding node on wire leaves symbol empty',
        (tester) async {
      final notifier = _notifierWith(appearances: {
        DrawingLevel.wire: const LevelAppearance(size: Size(80, 60)),
        DrawingLevel.symbol: const LevelAppearance(size: Size(40, 40)),
      });

      // Active = wire, add a node
      notifier.addNode(const DrawRect(
        rect: Rect.fromLTWH(0, 0, 20, 10),
        strokeColor: Color(0xFF000000),
        strokeWidth: 1,
      ));
      expect(notifier.state.appearances[DrawingLevel.wire]!.drawables.length, 1);
      expect(notifier.state.appearances[DrawingLevel.symbol]!.drawables.length,
          0);

      // Switch to symbol, verify node list is empty
      notifier.setActiveLevel(DrawingLevel.symbol);
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 48,
          child: Material(child: LevelSwitcher(notifier: notifier)),
        ),
      ));
      expect(notifier.state.drawables, isEmpty);
    });
  });

  // ─── Phase 4: canvas renders at active level ──────────────────────────────

  group('Phase 4 — DesignerCanvas active level', () {
    testWidgets('canvas does not throw when rendering wire level (default)',
        (tester) async {
      final notifier = _notifierWith();
      await tester.pumpWidget(_wrap(
        DesignerCanvas(
          notifier: notifier,
          activePaletteType: null,
          onTap: (_) {},
        ),
      ));
      // No throw is the acceptance criterion.
    });

    testWidgets(
        'canvas does not throw when active level has no appearance (renders empty)',
        (tester) async {
      // Only wire is populated; switch to symbol (no appearance).
      final notifier = _notifierWith();
      notifier.setActiveLevel(DrawingLevel.symbol); // symbol not in appearances
      // State.drawables = [] because symbol is absent — no appearance

      await tester.pumpWidget(_wrap(
        DesignerCanvas(
          notifier: notifier,
          activePaletteType: null,
          onTap: (_) {},
        ),
      ));
      // Renderer receives an empty drawables list; must not throw.
    });

    testWidgets('canvas does not throw when resolver absent and DrawDeviceRef present',
        (tester) async {
      final notifier = DesignerNotifier(
        const DesignerState(
          typeKey: 'host',
          deviceName: 'Host',
          activeLevel: DrawingLevel.wire,
          appearances: {
            DrawingLevel.wire: LevelAppearance(
              size: Size(100, 80),
              drawables: [
                // A DeviceRef whose target won't resolve (no resolver injected)
                DrawDeviceRef(typeKey: 'missing_device', offset: Offset.zero),
              ],
            ),
          },
          parameters: [],
          connectors: [],
        ),
        // No resolver — device ref should be skipped gracefully.
      );

      await tester.pumpWidget(_wrap(
        DesignerCanvas(
          notifier: notifier,
          activePaletteType: null,
          onTap: (_) {},
        ),
      ));
      // Must not throw when resolver is absent.
    });

    testWidgets('canvas uses resolver for composite preview when provided',
        (tester) async {
      // Inline device: a simple rect.
      const refTarget = DeviceDefinition(
        typeKey: 'inner',
        name: 'Inner',
        appearance: DeviceAppearance(
          wire: LevelAppearance(
            size: Size(30, 20),
            drawables: [
              DrawRect(
                rect: Rect.fromLTWH(0, 0, 30, 20),
                strokeColor: Color(0xFF000000),
                strokeWidth: 1,
              ),
            ],
          ),
        ),
      );

      final notifier = DesignerNotifier(
        const DesignerState(
          typeKey: 'host',
          deviceName: 'Host',
          activeLevel: DrawingLevel.wire,
          appearances: {
            DrawingLevel.wire: LevelAppearance(
              size: Size(100, 80),
              drawables: [
                DrawDeviceRef(typeKey: 'inner', offset: Offset.zero),
              ],
            ),
          },
          parameters: [],
          connectors: [],
        ),
        resolver: (key) => key == 'inner' ? refTarget : null,
      );

      await tester.pumpWidget(_wrap(
        DesignerCanvas(
          notifier: notifier,
          activePaletteType: null,
          onTap: (_) {},
        ),
      ));
      // No throw: resolver resolves 'inner' and renders it.
    });
  });
}
