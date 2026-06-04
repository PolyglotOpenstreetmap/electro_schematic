import 'package:flutter/material.dart';
import 'package:schematic_topology/schematic_topology.dart';

void main() => runApp(const ExampleApp());

class DemoNode implements SchematicNode {
  DemoNode(this.id, this.position, this.size);
  @override
  final String id;
  @override
  final Offset position;
  @override
  final Size size;
  @override
  Size get renderSize => size;
}

class DemoEdge implements SchematicEdge {
  DemoEdge(this.id, this.sourceNodeId, this.destNodeId);
  @override
  final String id;
  @override
  final String sourceNodeId;
  @override
  final String destNodeId;
  @override
  ConnectionSide get exitSide => ConnectionSide.center;
  @override
  ConnectionSide get entrySide => ConnectionSide.center;
  @override
  List<Offset>? get waypoints => null;
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _controller = TransformationController();
  final _nodes = [
    DemoNode('a', const Offset(80, 80), const Size(120, 64)),
    DemoNode('b', const Offset(360, 220), const Size(120, 64)),
  ];
  late final _edges = [DemoEdge('e1', 'a', 'b')];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Schematic Topology Example')),
        body: SchematicTopologyCanvas<DemoNode, DemoEdge>(
          canvasSize: const Size(1200, 800),
          transformationController: _controller,
          nodes: _nodes,
          edges: _edges,
          styleResolver: (e) => const EdgeStyle(color: Colors.blue, label: 'link'),
          nodeBuilder: (node, isSelected) => Card(
            color: isSelected ? Colors.blue.shade100 : null,
            child: SizedBox(
              width: node.size.width,
              height: node.size.height,
              child: Center(child: Text(node.id)),
            ),
          ),
          backgroundPainter: const SchematicGridPainter(pageSize: Size(1200, 800)),
          selectedNodeIds: const {},
          selectedNodeId: null,
          isDraggingConnection: false,
          dragStartNodeId: null,
          dragCurrentPosition: null,
          dragStartPosition: null,
          hoveredNodeId: null,
          hoveredSide: null,
          isRubberBanding: false,
          selectionStart: null,
          selectionEnd: null,
          onConnectionDragStart: (_, __, ___) {},
          onConnectionDragEnd: () {},
          onConnectionDragUpdate: (_) {},
          onHoverChanged: (_, __) {},
          onCanvasTap: (_) {},
          onPanStart: (_) {},
          onPanUpdate: (_) {},
          onPanEnd: () {},
        ),
      ),
    );
  }
}
