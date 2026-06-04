// lib/models/diagram_config.dart

import 'dart:convert';
import 'wire_color_settings.dart';

/// Persistent configuration for wiring diagram display and export

/// Strategy for sorting corridor heights in auto-distribution.
enum CorridorSortStrategy {
  /// Rightmost motors (highest Y) get corridors closest to Movotron cabinet.
  rightmostClosest,

  /// Leftmost motors (lowest Y) get corridors closest to Movotron cabinet.
  leftmostClosest,

  /// Tallest motor stack gets corridors closest to Movotron cabinet.
  tallestStackClosest,
}

class DiagramConfig {
  /// Current page index (0-based)
  final int currentPage;

  /// Current zoom level (0.5 = 50%, 1.0 = 100%, 2.0 = 200%)
  final double zoomLevel;

  /// Horizontal scroll offset
  final double scrollOffsetX;

  /// Vertical scroll offset
  final double scrollOffsetY;

  /// Page overlap percentage (0.0 - 0.5)
  final double pageOverlap;

  /// Show grid lines for debugging
  final bool showGrid;

  /// Show page boundaries
  final bool showPageBoundaries;

  /// Auto-fit to page width
  final bool autoFitWidth;

  /// Wire spacing in pixels (vertical spacing between parallel wires)
  final double wireSpacing;

  /// Wire color configuration for phase and striker wires
  final WireColorSettings wireColorSettings;

  /// Strategy for auto-distributing corridor heights
  final CorridorSortStrategy corridorSortStrategy;

  const DiagramConfig({
    this.currentPage = 0,
    this.zoomLevel = 1.0,
    this.scrollOffsetX = 0.0,
    this.scrollOffsetY = 0.0,
    this.pageOverlap = 0.1,
    this.showGrid = false,
    this.showPageBoundaries = true,
    this.autoFitWidth = true,
    this.wireSpacing = 25.0,
    this.wireColorSettings = const WireColorSettings(),
    this.corridorSortStrategy = CorridorSortStrategy.rightmostClosest,
  });

  /// Create default configuration
  factory DiagramConfig.defaults() {
    return const DiagramConfig();
  }

  /// Create copy with updated fields
  DiagramConfig copyWith({
    int? currentPage,
    double? zoomLevel,
    double? scrollOffsetX,
    double? scrollOffsetY,
    double? pageOverlap,
    bool? showGrid,
    bool? showPageBoundaries,
    bool? autoFitWidth,
    double? wireSpacing,
    WireColorSettings? wireColorSettings,
    CorridorSortStrategy? corridorSortStrategy,
  }) {
    return DiagramConfig(
      currentPage: currentPage ?? this.currentPage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollOffsetX: scrollOffsetX ?? this.scrollOffsetX,
      scrollOffsetY: scrollOffsetY ?? this.scrollOffsetY,
      pageOverlap: pageOverlap ?? this.pageOverlap,
      showGrid: showGrid ?? this.showGrid,
      showPageBoundaries: showPageBoundaries ?? this.showPageBoundaries,
      autoFitWidth: autoFitWidth ?? this.autoFitWidth,
      wireSpacing: wireSpacing ?? this.wireSpacing,
      wireColorSettings: wireColorSettings ?? this.wireColorSettings,
      corridorSortStrategy:
          corridorSortStrategy ?? this.corridorSortStrategy,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'zoomLevel': zoomLevel,
      'scrollOffsetX': scrollOffsetX,
      'scrollOffsetY': scrollOffsetY,
      'pageOverlap': pageOverlap,
      'showGrid': showGrid,
      'showPageBoundaries': showPageBoundaries,
      'autoFitWidth': autoFitWidth,
      'wireSpacing': wireSpacing,
      'wireColorSettings': wireColorSettings.toJson(),
      'corridorSortStrategy': corridorSortStrategy.name,
    };
  }

  /// Create from JSON
  factory DiagramConfig.fromJson(Map<String, dynamic> json) {
    return DiagramConfig(
      currentPage: json['currentPage'] as int? ?? 0,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      scrollOffsetX: (json['scrollOffsetX'] as num?)?.toDouble() ?? 0.0,
      scrollOffsetY: (json['scrollOffsetY'] as num?)?.toDouble() ?? 0.0,
      pageOverlap: (json['pageOverlap'] as num?)?.toDouble() ?? 0.1,
      showGrid: json['showGrid'] as bool? ?? false,
      showPageBoundaries: json['showPageBoundaries'] as bool? ?? true,
      autoFitWidth: json['autoFitWidth'] as bool? ?? true,
      wireSpacing: (json['wireSpacing'] as num?)?.toDouble() ?? 25.0,
      wireColorSettings: json['wireColorSettings'] != null
          ? WireColorSettings.fromJson(
              json['wireColorSettings'] as Map<String, dynamic>)
          : const WireColorSettings(),
      corridorSortStrategy: CorridorSortStrategy.values.firstWhere(
        (e) => e.name == json['corridorSortStrategy'],
        orElse: () => CorridorSortStrategy.rightmostClosest,
      ),
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory DiagramConfig.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DiagramConfig.fromJson(json);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiagramConfig &&
        other.currentPage == currentPage &&
        other.zoomLevel == zoomLevel &&
        other.scrollOffsetX == scrollOffsetX &&
        other.scrollOffsetY == scrollOffsetY &&
        other.pageOverlap == pageOverlap &&
        other.showGrid == showGrid &&
        other.showPageBoundaries == showPageBoundaries &&
        other.autoFitWidth == autoFitWidth &&
        other.wireSpacing == wireSpacing &&
        other.wireColorSettings == wireColorSettings &&
        other.corridorSortStrategy == corridorSortStrategy;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPage,
      zoomLevel,
      scrollOffsetX,
      scrollOffsetY,
      pageOverlap,
      showGrid,
      showPageBoundaries,
      autoFitWidth,
      wireSpacing,
      wireColorSettings,
      corridorSortStrategy,
    );
  }

  @override
  String toString() {
    return 'DiagramConfig('
        'page: $currentPage, '
        'zoom: ${(zoomLevel * 100).toInt()}%, '
        'scroll: ($scrollOffsetX, $scrollOffsetY), '
        'overlap: ${(pageOverlap * 100).toInt()}%, '
        'showGrid: $showGrid, '
        'showBoundaries: $showPageBoundaries, '
        'autoFit: $autoFitWidth'
        ')';
  }
}
