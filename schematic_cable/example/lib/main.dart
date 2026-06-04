import 'package:flutter/material.dart';
import 'package:schematic_cable/schematic_cable.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schematic Cable Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final specs = <CableSpec>[
      CableSpec.twistedPairs(pairs: 4),
      CableSpec.power(PowerScheme.threePhaseNPE),
      CableSpec.multicore(signals: 5),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Schematic Cable Example')),
      body: ListView(
        children: [
          for (final spec in specs) ...[
            SizedBox(
              height: 140,
              child: CustomPaint(painter: CablePainter(spec: spec)),
            ),
            SizedBox(height: 200, child: CableBreakout(spec: spec)),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
