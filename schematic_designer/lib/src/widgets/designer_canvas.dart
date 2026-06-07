// lib/src/widgets/designer_canvas.dart
//
// DesignerCanvas: CustomPaint-based canvas with zoom, node selection, and drag.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:schematic_device/schematic_device.dart';

import '../notifier/designer_notifier.dart';
import '../utils/node_bounds.dart';

/// The central canvas widget: handles pan detection (drag), tap selection,
/// palette placement, and renders via [_CanvasPainter].
class DesignerCanvas extends StatefulWidget {
  final DesignerNotifier notifier;
  final String? activePaletteType;
  final void Function(Offset deviceLocalPos) onTap;

  const DesignerCanvas({
    super.key,
    required this.notifier,
    required this.activePaletteType,
    required this.onTap,
  });

  @override
  State<DesignerCanvas> createState() => _DesignerCanvasState();
}

class _DesignerCanvasState extends State<DesignerCanvas> {
  double _zoom = 2.0;

  // Drag tracking
  String? _draggingId;
  Offset? _dragStartDevicePos;
  bool _didDrag = false;

  static const double _canvasPad = 16.0;

  Offset _toDeviceCoords(Offset widgetPos) {
    return (widgetPos - const Offset(_canvasPad, _canvasPad)) / _zoom;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final state = widget.notifier.state;
        final definition = widget.notifier.exportDefinition();

        return Stack(
          children: [
            // Canvas with gesture detection
            GestureDetector(
              onTapUp: (details) {
                if (_didDrag) {
                  _didDrag = false;
                  return;
                }
                widget.onTap(_toDeviceCoords(details.localPosition));
              },
              onPanStart: (details) {
                if (widget.activePaletteType != null) return;
                final devicePos = _toDeviceCoords(details.localPosition);
                final hit = NodeBoundsHelper.hitTest(
                    state.drawables, devicePos, definition);
                if (hit?.id != null) {
                  _draggingId = hit!.id;
                  _dragStartDevicePos = devicePos;
                  _didDrag = false;
                  widget.notifier.beginDrag(_draggingId!);
                }
              },
              onPanUpdate: (details) {
                final id = _draggingId;
                final start = _dragStartDevicePos;
                if (id == null || start == null) return;
                _didDrag = true;
                final currentDevicePos =
                    _toDeviceCoords(details.localPosition);
                final totalDelta = currentDevicePos - start;
                widget.notifier.updateDrag(id, totalDelta);
              },
              onPanEnd: (_) {
                if (_draggingId != null) {
                  widget.notifier.endDrag();
                  _draggingId = null;
                  _dragStartDevicePos = null;
                }
              },
              child: CustomPaint(
                painter: _CanvasPainter(
                  state: state,
                  definition: definition,
                  zoom: _zoom,
                  pad: _canvasPad,
                  renderContext: widget.notifier.renderContext,
                ),
                size: Size.infinite,
              ),
            ),
            // Zoom controls (bottom-right)
            Positioned(
              right: 8,
              bottom: 8,
              child: _ZoomControls(
                zoom: _zoom,
                onZoomIn: () => setState(
                    () => _zoom = math.min(8.0, _zoom + 0.5)),
                onZoomOut: () => setState(
                    () => _zoom = math.max(0.5, _zoom - 0.5)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Zoom controls ────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onZoomOut,
            tooltip: 'Zoom out',
            visualDensity: VisualDensity.compact,
          ),
          Text('${(zoom * 100).round()}%',
              style: const TextStyle(fontSize: 11)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onZoomIn,
            tooltip: 'Zoom in',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Canvas painter ───────────────────────────────────────────────────────────

class _CanvasPainter extends CustomPainter {
  final dynamic state; // DesignerState
  final DeviceDefinition definition;
  final double zoom;
  final double pad;
  final RenderContext renderContext;

  _CanvasPainter({
    required this.state,
    required this.definition,
    required this.zoom,
    required this.pad,
    required this.renderContext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEEEEE),
    );

    // Outer grid (grey lines every 20 px in widget coords — before scaling)
    _drawOuterGrid(canvas, size);

    // Save and apply zoom transform with padding offset
    canvas.save();
    canvas.translate(pad, pad);
    canvas.scale(zoom);

    final deviceSize = state.canvasSize as Size;

    // White device background
    canvas.drawRect(
      Offset.zero & deviceSize,
      Paint()..color = Colors.white,
    );

    // Device grid (light-blue dots every 10 px in device coords)
    _drawDeviceGrid(canvas, deviceSize);

    // Device border (grey dashed)
    _drawDashedRect(
        canvas, Offset.zero & deviceSize, const Color(0xFFAAAAAA), 0.5);

    // Render the active level with default param values so showIf / templates
    // evaluate meaningfully.  Composite refs resolve via renderContext when a
    // resolver was injected into the notifier.
    const renderer = DeviceRenderer();
    final instance = DeviceInstance(
      definition: definition,
      position: Offset.zero,
      paramValues: definition.defaultParams,
    );
    renderer.render(
      canvas,
      instance,
      level: state.activeLevel as DrawingLevel,
      context: renderContext,
    );

    // Selection highlight
    final selectedId = state.selectedId as String?;
    if (selectedId != null) {
      _drawSelectionHighlight(canvas, selectedId, definition);
    }

    canvas.restore();
  }

  void _drawOuterGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDeviceGrid(Canvas canvas, Size deviceSize) {
    final paint = Paint()
      ..color = const Color(0xFFBBDDFF)
      ..strokeWidth = 0.5 / zoom;
    const step = 10.0;
    for (double x = 0; x <= deviceSize.width; x += step) {
      for (double y = 0; y <= deviceSize.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.5 / zoom, paint);
      }
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    const dashLen = 4.0;
    const gapLen = 3.0;
    _drawDashedPath(canvas, Path()..addRect(rect), paint, dashLen, gapLen);
  }

  void _drawSelectionHighlight(
      Canvas canvas, String id, DeviceDefinition def) {
    final drawables = state.drawables as List<DrawableNode>;
    DrawableNode? node;
    for (final d in drawables) {
      if (d.id == id) {
        node = d;
        break;
      }
    }
    if (node == null) return;

    final bounds = NodeBoundsHelper.boundsOf(node, def);
    if (bounds == null) return;

    final highlightRect = bounds.inflate(3);
    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;
    _drawDashedPath(
        canvas, Path()..addRect(highlightRect), paint, 5.0, 3.0);

    // Corner circles
    final dotPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.fill;
    final r = 2.5 / zoom;
    for (final corner in [
      highlightRect.topLeft,
      highlightRect.topRight,
      highlightRect.bottomLeft,
      highlightRect.bottomRight,
    ]) {
      canvas.drawCircle(corner, r, dotPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      double dashLength, double gapLength) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final end = math.min(
            distance + (drawing ? dashLength : gapLength), metric.length);
        if (drawing) {
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance = end;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.state != state ||
      old.definition != definition ||
      old.zoom != zoom;
}
