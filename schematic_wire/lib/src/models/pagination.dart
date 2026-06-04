// lib/models/physical/pagination.dart

import 'package:flutter/foundation.dart';
import 'dart:ui' show Rect, Offset;
import 'base.dart';
import 'terminals.dart';
import 'connections.dart';

/// A4 page size constants in millimeters and points.
///
/// A4 standard: 210mm × 297mm (portrait orientation)
/// Points: 595.28pt × 841.89pt @ 72 DPI
class A4PageSize {
  /// Width in millimeters (portrait)
  static const double widthMM = 210.0;

  /// Height in millimeters (portrait)
  static const double heightMM = 297.0;

  /// Width in points @ 72 DPI (portrait)
  static const double widthPt = 595.28;

  /// Height in points @ 72 DPI (portrait)
  static const double heightPt = 841.89;

  /// Width in pixels @ 96 DPI (portrait) - Flutter logical pixels
  static const double widthPx = 794.0;

  /// Height in pixels @ 96 DPI (portrait) - Flutter logical pixels
  static const double heightPx = 1123.0;

  /// Standard margins in millimeters
  static const double marginMM = 1.3;

  /// Standard margins in points @ 72 DPI
  static const double marginPt = 3.75; // ~1.3mm

  /// Standard margins in pixels @ 96 DPI - Flutter logical pixels
  static const double marginPx = 5.0; // ~1.3mm

  /// Printable area width (210mm - 30mm margins)
  static const double printableWidthMM = widthMM - (marginMM * 2);

  /// Printable area height (297mm - 30mm margins)
  static const double printableHeightMM = heightMM - (marginMM * 2);

  /// Printable area width in pixels @ 96 DPI
  static const double printableWidthPx = widthPx - (marginPx * 2);

  /// Printable area height in pixels @ 96 DPI
  static const double printableHeightPx = heightPx - (marginPx * 2);

  /// Header height in pixels
  static const double headerHeightPx = 80.0;

  /// Footer height in pixels
  static const double footerHeightPx = 20.0;

  /// Content area height (printable - header - footer)
  static const double contentHeightPx =
      printableHeightPx - headerHeightPx - footerHeightPx;
}

/// A3 page size constants in millimeters and points.
///
/// A3 standard: 297mm × 420mm (portrait orientation)
/// Points: 841.89pt × 1190.55pt @ 72 DPI
class A3PageSize {
  /// Width in millimeters (portrait)
  static const double widthMM = 297.0;

  /// Height in millimeters (portrait)
  static const double heightMM = 420.0;

  /// Width in points @ 72 DPI (portrait)
  static const double widthPt = 841.89;

  /// Height in points @ 72 DPI (portrait)
  static const double heightPt = 1190.55;

  /// Width in pixels @ 96 DPI (portrait) - Flutter logical pixels
  static const double widthPx = 1123.0;

  /// Height in pixels @ 96 DPI (portrait) - Flutter logical pixels
  static const double heightPx = 1587.0;

  /// Standard margins in millimeters
  static const double marginMM = A4PageSize.marginMM;

  /// Standard margins in pixels @ 96 DPI
  static const double marginPx = A4PageSize.marginPx;

  /// Header height in pixels
  static const double headerHeightPx = A4PageSize.headerHeightPx;

  /// Footer height in pixels
  static const double footerHeightPx = A4PageSize.footerHeightPx;
}

/// Configuration for pagination layout and behavior.
///
/// Controls how wiring diagrams are split across multiple pages,
/// including margins, headers, footers, and page overlap.
class PaginationConfig {
  /// Page width in logical pixels (Flutter coordinates)
  final double pageWidth;

  /// Page height in logical pixels (Flutter coordinates)
  final double pageHeight;

  /// Left/right margin in logical pixels
  final double marginX;

  /// Top/bottom margin in logical pixels
  final double marginY;

  /// Header height in logical pixels
  final double headerHeight;

  /// Footer height in logical pixels
  final double footerHeight;

  /// Border width for page frame (in pixels)
  final double borderWidth;

  /// Width of the title block in the bottom-right corner
  final double titleBlockWidth;

  /// Height of the title block in the bottom-right corner
  final double titleBlockHeight;

  /// Overlap between pages to ensure continuity (in pixels)
  final double pageOverlap;

  /// Whether to show page boundaries in diagram view
  final bool showPageBoundaries;

  /// Whether to add page numbers
  final bool showPageNumbers;

  /// Whether to add headers with project info
  final bool showHeaders;

  const PaginationConfig({
    this.pageWidth = A4PageSize.widthPx,
    this.pageHeight = A4PageSize.heightPx,
    this.marginX = A4PageSize.marginPx,
    this.marginY = A4PageSize.marginPx,
    this.headerHeight = A4PageSize.headerHeightPx,
    this.footerHeight = A4PageSize.footerHeightPx,
    this.borderWidth = 3.0,
    this.titleBlockWidth = 250.0,
    this.titleBlockHeight = 90.0,
    this.pageOverlap = 20.0,
    this.showPageBoundaries = true,
    this.showPageNumbers = true,
    this.showHeaders = true,
  });

  /// Standard A4 portrait configuration
  factory PaginationConfig.a4Portrait() {
    return const PaginationConfig();
  }

  /// Standard A4 landscape configuration
  factory PaginationConfig.a4Landscape() {
    return const PaginationConfig(
      pageWidth: A4PageSize.heightPx,
      pageHeight: A4PageSize.widthPx,
    );
  }

  /// Standard A3 landscape configuration
  factory PaginationConfig.a3Landscape() {
    return const PaginationConfig(
      pageWidth: A3PageSize.heightPx,
      pageHeight: A3PageSize.widthPx,
    );
  }

  /// Usable content width (page width - margins)
  double get contentWidth => pageWidth - (marginX * 2);

  /// Usable content height (page height - margins - header - title block)
  double get contentHeight => pageHeight - (marginY * 2) - headerHeight - titleBlockHeight;

  /// Top position of content area (after margin + header)
  double get contentTop => marginY + headerHeight;

  /// Left position of content area (after margin)
  double get contentLeft => marginX;

  /// Copy with modifications
  PaginationConfig copyWith({
    double? pageWidth,
    double? pageHeight,
    double? marginX,
    double? marginY,
    double? headerHeight,
    double? footerHeight,
    double? borderWidth,
    double? titleBlockWidth,
    double? titleBlockHeight,
    double? pageOverlap,
    bool? showPageBoundaries,
    bool? showPageNumbers,
    bool? showHeaders,
  }) {
    return PaginationConfig(
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      marginX: marginX ?? this.marginX,
      marginY: marginY ?? this.marginY,
      headerHeight: headerHeight ?? this.headerHeight,
      footerHeight: footerHeight ?? this.footerHeight,
      borderWidth: borderWidth ?? this.borderWidth,
      titleBlockWidth: titleBlockWidth ?? this.titleBlockWidth,
      titleBlockHeight: titleBlockHeight ?? this.titleBlockHeight,
      pageOverlap: pageOverlap ?? this.pageOverlap,
      showPageBoundaries: showPageBoundaries ?? this.showPageBoundaries,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      showHeaders: showHeaders ?? this.showHeaders,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaginationConfig &&
        other.pageWidth == pageWidth &&
        other.pageHeight == pageHeight &&
        other.marginX == marginX &&
        other.marginY == marginY &&
        other.headerHeight == headerHeight &&
        other.footerHeight == footerHeight &&
        other.borderWidth == borderWidth &&
        other.titleBlockWidth == titleBlockWidth &&
        other.titleBlockHeight == titleBlockHeight &&
        other.pageOverlap == pageOverlap &&
        other.showPageBoundaries == showPageBoundaries &&
        other.showPageNumbers == showPageNumbers &&
        other.showHeaders == showHeaders;
  }

  @override
  int get hashCode {
    return Object.hash(
      pageWidth,
      pageHeight,
      marginX,
      marginY,
      headerHeight,
      footerHeight,
      borderWidth,
      titleBlockWidth,
      titleBlockHeight,
      pageOverlap,
      showPageBoundaries,
      showPageNumbers,
      showHeaders,
    );
  }
}

/// Represents a single page in a paginated diagram.
///
/// Each page has a viewport that defines which portion of the
/// complete diagram is visible on this page.
class DiagramPage {
  /// Page number (1-indexed for display)
  final int pageNumber;

  /// Total number of pages
  final int totalPages;

  /// Viewport bounds in diagram coordinates (what portion of diagram to show)
  final Rect viewport;

  /// Column in page grid (0-indexed)
  final int columnIndex;

  /// Row in page grid (0-indexed)
  final int rowIndex;

  const DiagramPage({
    required this.pageNumber,
    required this.totalPages,
    required this.viewport,
    required this.columnIndex,
    required this.rowIndex,
  });

  /// Whether this is the first page
  bool get isFirst => pageNumber == 1;

  /// Whether this is the last page
  bool get isLast => pageNumber == totalPages;

  /// Grid position label (e.g., "A1", "B2")
  String get gridLabel {
    final col = String.fromCharCode(65 + columnIndex); // A, B, C, ...
    final row = rowIndex + 1;
    return '$col$row';
  }

  @override
  String toString() => 'Page $pageNumber/$totalPages (Grid $gridLabel)';
}

/// Manager for calculating and organizing diagram pages.
///
/// This class analyzes the wiring diagram content and determines
/// how to split it across multiple A4 pages for optimal printing
/// and viewing.
class DiagramPagination {
  /// Pagination configuration
  final PaginationConfig config;

  /// Total bounds of the diagram content in diagram coordinates
  final Rect contentBounds;

  /// Terminal blocks to check for page content
  final List<TerminalBlock> terminalBlocks;

  /// Connections to check for page content
  final List<Connection> connections;

  /// Calculated pages
  final List<DiagramPage> _pages = [];

  /// Number of columns in page grid
  late final int _columnCount;

  /// Number of rows in page grid
  late final int _rowCount;

  DiagramPagination({
    required this.config,
    required this.contentBounds,
    required this.terminalBlocks,
    required this.connections,
  }) {
    _calculatePages();
  }

  /// Get all pages
  List<DiagramPage> get pages => List.unmodifiable(_pages);

  /// Total number of pages
  int get pageCount => _pages.length;

  /// Number of columns in page grid
  int get columnCount => _columnCount;

  /// Number of rows in page grid
  int get rowCount => _rowCount;

  /// Calculate page layout based on content bounds and config.
  void _calculatePages() {
    // Calculate how many pages needed in each direction
    _columnCount = (contentBounds.width / config.contentWidth).ceil();
    _rowCount = (contentBounds.height / config.contentHeight).ceil();

    debugPrint('DiagramPagination: Content ${contentBounds.width}×${contentBounds.height} '
        'requires ${_columnCount}×${_rowCount} grid ($_columnCount columns, $_rowCount rows)');
    debugPrint('DiagramPagination: Input data: ${terminalBlocks.length} terminal blocks, ${connections.length} connections');

    // Generate pages in row-major order (left-to-right, top-to-bottom)
    // Only include pages that have content
    int pageNumber = 1;
    int totalPotentialPages = _columnCount * _rowCount;

    for (int row = 0; row < _rowCount; row++) {
      for (int col = 0; col < _columnCount; col++) {
        // Calculate viewport for this page
        final viewportLeft = contentBounds.left + (col * config.contentWidth);
        final viewportTop = contentBounds.top + (row * config.contentHeight);

        final viewport = Rect.fromLTWH(
          viewportLeft,
          viewportTop,
          config.contentWidth,
          config.contentHeight,
        );

        // Check if this viewport has any content
        debugPrint('DiagramPagination: Checking grid ${String.fromCharCode(65 + col)}${row + 1} '
            'viewport: ${viewport.left.toStringAsFixed(0)},${viewport.top.toStringAsFixed(0)} '
            '${viewport.width.toStringAsFixed(0)}×${viewport.height.toStringAsFixed(0)}');

        final hasContent = _hasContentInViewport(viewport);

        if (hasContent) {
          final page = DiagramPage(
            pageNumber: pageNumber,
            totalPages: totalPotentialPages, // Will be updated after filtering
            viewport: viewport,
            columnIndex: col,
            rowIndex: row,
          );

          _pages.add(page);

          debugPrint('  ✓ Including page $pageNumber (${page.gridLabel}) - HAS CONTENT');

          pageNumber++;
        } else {
          debugPrint('  ✗ SKIPPING empty page at grid (${String.fromCharCode(65 + col)}${row + 1})');
        }
      }
    }

    // Update totalPages for all pages now that we know the actual count
    final actualPageCount = _pages.length;
    for (int i = 0; i < _pages.length; i++) {
      _pages[i] = DiagramPage(
        pageNumber: i + 1,
        totalPages: actualPageCount,
        viewport: _pages[i].viewport,
        columnIndex: _pages[i].columnIndex,
        rowIndex: _pages[i].rowIndex,
      );
    }

    debugPrint('DiagramPagination: Filtered to $actualPageCount pages with content (from $totalPotentialPages potential pages)');
  }

  /// Check if a viewport contains any diagram content.
  ///
  /// Returns true if the viewport intersects with any terminal blocks.
  /// NOTE: We only check for terminal blocks, not connections passing through,
  /// to avoid including pages that only have wires crossing them.
  bool _hasContentInViewport(Rect viewport) {
    int blocksFound = 0;

    // Check if any terminal blocks are in this viewport
    for (final block in terminalBlocks) {
      final blockPos = block.diagramPosition.toOffset();
      final terminals = block.allTerminals;

      // Determine accurate block size based on type
      double blockWidth;
      double blockHeight;

      if (block.id.contains('MOVOTRON')) {
        // Movotron blocks are wider with input/output sections
        blockWidth = 300.0;
        blockHeight = 210.0;
      } else if (_isMotorTerminalBlock(terminals)) {
        // Motor blocks are 3×2 grid
        blockWidth = 145.0;
        blockHeight = 120.0;
      } else {
        // Standard linear terminal blocks
        blockWidth = terminals.length * 30.0 + 20.0;
        blockHeight = 100.0;
      }

      // Calculate block center point
      final blockCenter = Offset(
        blockPos.dx + blockWidth / 2,
        blockPos.dy + blockHeight / 2,
      );

      // Only count blocks whose center is within the viewport
      // This avoids including pages where blocks are just barely overlapping
      if (viewport.contains(blockCenter)) {
        blocksFound++;
        debugPrint('    - Block ${block.id} center at (${blockCenter.dx.toStringAsFixed(0)},${blockCenter.dy.toStringAsFixed(0)})');
      }
    }

    if (blocksFound > 0) {
      debugPrint('  → Found $blocksFound terminal blocks in viewport');
      return true;
    }

    // No content found in this viewport
    debugPrint('  → Empty page (no terminal blocks)');
    return false;
  }

  /// Check if terminal block is a motor block (U1-W2, DeCoster U-V-W, or linear 1-6)
  bool _isMotorTerminalBlock(List<Terminal> terminals) {
    if (terminals.length < 6) return false;

    final labels = terminals.map((t) => t.label).toSet();

    // Standard rotating motor: U1, V1, W1, U2, V2, W2
    final isStandardMotor = labels.contains('U1') &&
        labels.contains('V1') &&
        labels.contains('W1') &&
        labels.contains('U2') &&
        labels.contains('V2') &&
        labels.contains('W2');

    // DeCoster motor: U, V, W (without numbers)
    final isDeCosterMotor = labels.contains('U') &&
        labels.contains('V') &&
        labels.contains('W') &&
        !labels.contains('U1');

    // Linear motor: numbered terminals 1-6
    final isLinearMotor = labels.contains('1') &&
        labels.contains('2') &&
        labels.contains('3') &&
        labels.contains('4') &&
        labels.contains('5') &&
        labels.contains('6');

    return isStandardMotor || isDeCosterMotor || isLinearMotor;
  }

  /// Get page by number (1-indexed)
  DiagramPage? getPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _pages.length) return null;
    return _pages[pageNumber - 1];
  }

  /// Get page at grid position
  DiagramPage? getPageAt(int column, int row) {
    if (column < 0 || column >= _columnCount || row < 0 || row >= _rowCount) {
      return null;
    }
    final index = row * _columnCount + column;
    return _pages[index];
  }

  /// Get page containing a specific diagram point
  DiagramPage? getPageContaining(Position2D point) {
    for (final page in _pages) {
      if (page.viewport.contains(Offset(point.x, point.y))) {
        return page;
      }
    }
    return null;
  }
}

/// Information about project to display in page headers.
class PageHeaderInfo {
  /// Project name
  final String projectName;

  /// Project location/site
  final String? location;

  /// Document title (e.g., "Wiring Diagram")
  final String documentTitle;

  /// Document date
  final DateTime? documentDate;

  /// Revision/version
  final String? revision;

  /// Company/organization name
  final String? organization;

  const PageHeaderInfo({
    required this.projectName,
    this.location,
    this.documentTitle = 'Wiring Diagram',
    this.documentDate,
    this.revision,
    this.organization,
  });

  /// Format date for display
  String get formattedDate {
    if (documentDate == null) return '';
    return '${documentDate!.year}-${documentDate!.month.toString().padLeft(2, '0')}-${documentDate!.day.toString().padLeft(2, '0')}';
  }
}
