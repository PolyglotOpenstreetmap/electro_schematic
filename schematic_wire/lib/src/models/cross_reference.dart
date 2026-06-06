// packages/electro_schematic/schematic_wire/lib/src/models/cross_reference.dart

/// Whether this cross-reference marker denotes a wire leaving this page
/// or arriving on this page.
enum CrossReferenceDirection {
  /// Wire exits this page and continues elsewhere (→ annotation).
  outgoing,

  /// Wire arrives on this page from elsewhere (← annotation).
  incoming,
}

/// An IEC 60617-style cross-reference annotation placed at the endpoint of
/// a wire that continues on another page of a multi-page schematic.
///
/// The diagram painter renders this as a small labelled arrow box (→ or ←)
/// positioned at the terminal exit point of the wire.
///
/// ### Placement
/// [pageIndex] / [blockId] / [terminalId] identify where this marker is drawn
/// on the diagram (the "here" side).
///
/// ### Target
/// [targetPageIndex] / [targetBlockId] / [targetTerminalId] identify where the
/// wire continues (the "there" side), and are shown in the annotation text.
///
/// ### Deriving cross-references
/// The host app computes cross-references from [Connection] data — any
/// connection whose source and destination blocks fall on different pages
/// generates an outgoing marker at the source page and an incoming marker
/// at the destination page.
class CrossReference {
  /// Unique identifier.
  final String id;

  /// 0-based index of the page on which this marker is drawn.
  final int pageIndex;

  /// [TerminalBlock.id] of the block at which the marker is anchored.
  final String blockId;

  /// [Terminal.id] at which the marker is anchored, or null to anchor at
  /// the block's default exit position.
  final String? terminalId;

  /// Page index where the wire continues.
  final int targetPageIndex;

  /// [TerminalBlock.id] where the wire continues.
  final String targetBlockId;

  /// [Terminal.id] where the wire continues, or null if unknown.
  final String? targetTerminalId;

  /// Arrow direction for the annotation symbol.
  final CrossReferenceDirection direction;

  /// Override for the annotation text. When null the painter derives it from
  /// [targetPageIndex] and [targetBlockId] (e.g. "P.3 / TB5").
  final String? label;

  const CrossReference({
    required this.id,
    required this.pageIndex,
    required this.blockId,
    this.terminalId,
    required this.targetPageIndex,
    required this.targetBlockId,
    this.targetTerminalId,
    required this.direction,
    this.label,
  });

  /// Derived annotation text shown inside the arrow box.
  ///
  /// Uses [label] when set; otherwise builds "P.<N> / <block>" where N is the
  /// 1-based page number.
  String get annotationText {
    if (label != null) return label!;
    final page = 'P.${targetPageIndex + 1}';
    return targetTerminalId != null
        ? '$page / $targetBlockId / $targetTerminalId'
        : '$page / $targetBlockId';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageIndex': pageIndex,
        'blockId': blockId,
        if (terminalId != null) 'terminalId': terminalId,
        'targetPageIndex': targetPageIndex,
        'targetBlockId': targetBlockId,
        if (targetTerminalId != null) 'targetTerminalId': targetTerminalId,
        'direction': direction.name,
        if (label != null) 'label': label,
      };

  factory CrossReference.fromJson(Map<String, dynamic> json) => CrossReference(
        id: json['id'] as String,
        pageIndex: json['pageIndex'] as int,
        blockId: json['blockId'] as String,
        terminalId: json['terminalId'] as String?,
        targetPageIndex: json['targetPageIndex'] as int,
        targetBlockId: json['targetBlockId'] as String,
        targetTerminalId: json['targetTerminalId'] as String?,
        direction: CrossReferenceDirection.values
            .byName(json['direction'] as String),
        label: json['label'] as String?,
      );

  @override
  String toString() =>
      'CrossReference($id, ${direction.name}, page $pageIndex → $targetPageIndex)';
}
