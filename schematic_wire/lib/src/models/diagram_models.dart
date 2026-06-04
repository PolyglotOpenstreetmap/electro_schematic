// lib/models/physical/diagram_models.dart

import 'dart:ui';

/// Layout configuration for connection diagrams.
///
/// Defines how components and connections should be arranged visually.
class DiagramLayout {
  /// Layout mode (horizontal, vertical, auto)
  final String mode;

  /// Spacing between components in pixels
  final double componentSpacing;

  /// Spacing between connection lines in pixels
  final double connectionSpacing;

  /// Whether to show grid
  final bool showGrid;

  /// Grid size in pixels
  final double gridSize;

  /// Whether to snap components to grid
  final bool snapToGrid;

  const DiagramLayout({
    this.mode = 'auto',
    this.componentSpacing = 100.0,
    this.connectionSpacing = 20.0,
    this.showGrid = true,
    this.gridSize = 20.0,
    this.snapToGrid = true,
  });

  /// Factory: Compact layout for small diagrams
  factory DiagramLayout.compact() {
    return const DiagramLayout(
      mode: 'auto',
      componentSpacing: 60.0,
      connectionSpacing: 10.0,
      showGrid: false,
      snapToGrid: false,
    );
  }

  /// Factory: Spacious layout for detailed diagrams
  factory DiagramLayout.spacious() {
    return const DiagramLayout(
      mode: 'auto',
      componentSpacing: 150.0,
      connectionSpacing: 30.0,
      showGrid: true,
      gridSize: 25.0,
      snapToGrid: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'componentSpacing': componentSpacing,
        'connectionSpacing': connectionSpacing,
        'showGrid': showGrid,
        'gridSize': gridSize,
        'snapToGrid': snapToGrid,
      };

  factory DiagramLayout.fromJson(Map<String, dynamic> json) {
    return DiagramLayout(
      mode: json['mode'] as String? ?? 'auto',
      componentSpacing:
          (json['componentSpacing'] as num?)?.toDouble() ?? 100.0,
      connectionSpacing:
          (json['connectionSpacing'] as num?)?.toDouble() ?? 20.0,
      showGrid: json['showGrid'] as bool? ?? true,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 20.0,
      snapToGrid: json['snapToGrid'] as bool? ?? true,
    );
  }

  DiagramLayout copyWith({
    String? mode,
    double? componentSpacing,
    double? connectionSpacing,
    bool? showGrid,
    double? gridSize,
    bool? snapToGrid,
  }) {
    return DiagramLayout(
      mode: mode ?? this.mode,
      componentSpacing: componentSpacing ?? this.componentSpacing,
      connectionSpacing: connectionSpacing ?? this.connectionSpacing,
      showGrid: showGrid ?? this.showGrid,
      gridSize: gridSize ?? this.gridSize,
      snapToGrid: snapToGrid ?? this.snapToGrid,
    );
  }
}

/// Rendering state for diagram display.
///
/// Tracks zoom, pan, selection, and rendering options.
class DiagramState {
  /// Current zoom level (1.0 = 100%)
  final double zoom;

  /// Pan offset for viewport
  final Offset panOffset;

  /// Currently selected component ID (null if none)
  final String? selectedComponentId;

  /// Currently hovered component ID (null if none)
  final String? hoveredComponentId;

  /// Whether to show component labels
  final bool showLabels;

  /// Whether to show wire colors
  final bool showWireColors;

  /// Whether to show terminal labels
  final bool showTerminalLabels;

  /// View type (schematic, wiring, installation)
  final String viewType;

  const DiagramState({
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.selectedComponentId,
    this.hoveredComponentId,
    this.showLabels = true,
    this.showWireColors = true,
    this.showTerminalLabels = true,
    this.viewType = 'schematic',
  });

  /// Factory: Default initial state
  factory DiagramState.initial() {
    return const DiagramState();
  }

  Map<String, dynamic> toJson() => {
        'zoom': zoom,
        'panOffset': {'dx': panOffset.dx, 'dy': panOffset.dy},
        'selectedComponentId': selectedComponentId,
        'hoveredComponentId': hoveredComponentId,
        'showLabels': showLabels,
        'showWireColors': showWireColors,
        'showTerminalLabels': showTerminalLabels,
        'viewType': viewType,
      };

  factory DiagramState.fromJson(Map<String, dynamic> json) {
    final panOffsetJson = json['panOffset'] as Map<String, dynamic>?;
    return DiagramState(
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      panOffset: panOffsetJson != null
          ? Offset(
              (panOffsetJson['dx'] as num).toDouble(),
              (panOffsetJson['dy'] as num).toDouble(),
            )
          : Offset.zero,
      selectedComponentId: json['selectedComponentId'] as String?,
      hoveredComponentId: json['hoveredComponentId'] as String?,
      showLabels: json['showLabels'] as bool? ?? true,
      showWireColors: json['showWireColors'] as bool? ?? true,
      showTerminalLabels: json['showTerminalLabels'] as bool? ?? true,
      viewType: json['viewType'] as String? ?? 'schematic',
    );
  }

  DiagramState copyWith({
    double? zoom,
    Offset? panOffset,
    String? selectedComponentId,
    String? hoveredComponentId,
    bool? showLabels,
    bool? showWireColors,
    bool? showTerminalLabels,
    String? viewType,
  }) {
    return DiagramState(
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      selectedComponentId: selectedComponentId ?? this.selectedComponentId,
      hoveredComponentId: hoveredComponentId ?? this.hoveredComponentId,
      showLabels: showLabels ?? this.showLabels,
      showWireColors: showWireColors ?? this.showWireColors,
      showTerminalLabels: showTerminalLabels ?? this.showTerminalLabels,
      viewType: viewType ?? this.viewType,
    );
  }

  /// Clear selection
  DiagramState clearSelection() {
    return copyWith(selectedComponentId: null);
  }

  /// Zoom in by 10%
  DiagramState zoomIn() {
    return copyWith(zoom: (zoom * 1.1).clamp(0.1, 5.0));
  }

  /// Zoom out by 10%
  DiagramState zoomOut() {
    return copyWith(zoom: (zoom / 1.1).clamp(0.1, 5.0));
  }

  /// Reset zoom and pan
  DiagramState resetView() {
    return copyWith(zoom: 1.0, panOffset: Offset.zero);
  }
}

/// Rendering statistics for diagram.
///
/// Tracks performance metrics and rendering information.
class DiagramRenderStats {
  /// Number of components rendered
  final int componentCount;

  /// Number of connections rendered
  final int connectionCount;

  /// Last render time in milliseconds
  final int renderTimeMs;

  /// Viewport size in pixels
  final Size viewportSize;

  /// Calculated diagram bounds
  final Rect diagramBounds;

  const DiagramRenderStats({
    required this.componentCount,
    required this.connectionCount,
    required this.renderTimeMs,
    required this.viewportSize,
    required this.diagramBounds,
  });

  /// Factory: Initial empty stats
  factory DiagramRenderStats.empty() {
    return const DiagramRenderStats(
      componentCount: 0,
      connectionCount: 0,
      renderTimeMs: 0,
      viewportSize: Size.zero,
      diagramBounds: Rect.zero,
    );
  }

  Map<String, dynamic> toJson() => {
        'componentCount': componentCount,
        'connectionCount': connectionCount,
        'renderTimeMs': renderTimeMs,
        'viewportSize': {
          'width': viewportSize.width,
          'height': viewportSize.height
        },
        'diagramBounds': {
          'left': diagramBounds.left,
          'top': diagramBounds.top,
          'right': diagramBounds.right,
          'bottom': diagramBounds.bottom,
        },
      };

  @override
  String toString() =>
      'DiagramRenderStats($componentCount components, $connectionCount connections, ${renderTimeMs}ms)';
}
