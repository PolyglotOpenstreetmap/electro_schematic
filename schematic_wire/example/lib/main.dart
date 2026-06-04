import 'package:flutter/material.dart';
import 'package:schematic_wire/schematic_wire.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schematic Diagram Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal demonstration: a single-page A4 landscape diagram with two
    // standard terminal blocks connected by a wire.
    const config = PaginationConfig();
    final page = _buildPage(config);
    final blocks = _buildBlocks();
    final connections = _buildConnections();

    return Scaffold(
      appBar: AppBar(title: const Text('Schematic Diagram Example')),
      body: Center(
        child: SizedBox(
          width: config.pageWidth,
          height: config.pageHeight,
          child: CustomPaint(
            size: Size(config.pageWidth, config.pageHeight),
            painter: PaginatedDiagramPainter(
              terminalBlocks: blocks,
              connections: connections,
              jumpers: const [],
              page: page,
              config: config,
            ),
          ),
        ),
      ),
    );
  }

  static DiagramPage _buildPage(PaginationConfig config) {
    return DiagramPage(
      pageNumber: 1,
      totalPages: 1,
      viewport: Rect.fromLTWH(0, 0, config.contentWidth, config.contentHeight),
      columnIndex: 0,
      rowIndex: 0,
    );
  }

  List<TerminalBlock> _buildBlocks() => const [];

  List<Connection> _buildConnections() => const [];
}
