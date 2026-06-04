// lib/models/title_block_config.dart

/// Alignment for text within a title block cell.
enum CellAlignment { left, center, right, spaceBetween }

/// A single cell in the title block grid.
///
/// Contains one or more field keys that are resolved at render time
/// to actual display values (e.g. 'projectName' → "St. Mary's Church").
class TitleBlockCell {
  final List<String> fields;
  final CellAlignment alignment;

  const TitleBlockCell({
    required this.fields,
    this.alignment = CellAlignment.left,
  });

  Map<String, dynamic> toJson() => {
        'fields': fields,
        'alignment': alignment.name,
      };

  factory TitleBlockCell.fromJson(Map<String, dynamic> json) {
    return TitleBlockCell(
      fields: List<String>.from(json['fields'] as List<dynamic>),
      alignment: CellAlignment.values.firstWhere(
        (a) => a.name == json['alignment'],
        orElse: () => CellAlignment.left,
      ),
    );
  }

  TitleBlockCell copyWith({
    List<String>? fields,
    CellAlignment? alignment,
  }) {
    return TitleBlockCell(
      fields: fields ?? this.fields,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleBlockCell &&
          _listEquals(fields, other.fields) &&
          alignment == other.alignment;

  @override
  int get hashCode => Object.hash(Object.hashAll(fields), alignment);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Title block layout configuration: 3 rows, bottom row split into 2 columns.
///
/// ```
/// ┌─────────────────────────┐
/// │ topRow (full width)     │
/// ├─────────────────────────┤
/// │ middleRow (full width)  │
/// ├────────────┬────────────┤
/// │ bottomLeft │ bottomRight│
/// └────────────┴────────────┘
/// ```
class TitleBlockConfig {
  final double borderWidth;
  final TitleBlockCell topRow;
  final TitleBlockCell middleRow;
  final TitleBlockCell bottomLeft;
  final TitleBlockCell bottomRight;
  final double titleBlockWidth;
  final double titleBlockHeight;

  const TitleBlockConfig({
    this.borderWidth = 3.0,
    required this.topRow,
    required this.middleRow,
    required this.bottomLeft,
    required this.bottomRight,
    this.titleBlockWidth = 250.0,
    this.titleBlockHeight = 90.0,
  });

  /// Standard default layout for engineering drawings.
  factory TitleBlockConfig.standard() {
    return const TitleBlockConfig(
      topRow: TitleBlockCell(
        fields: ['projectName'],
        alignment: CellAlignment.left,
      ),
      middleRow: TitleBlockCell(
        fields: ['companyName', 'date'],
        alignment: CellAlignment.spaceBetween,
      ),
      bottomLeft: TitleBlockCell(
        fields: ['powerGrid'],
        alignment: CellAlignment.center,
      ),
      bottomRight: TitleBlockCell(
        fields: ['pageNumber'],
        alignment: CellAlignment.center,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'borderWidth': borderWidth,
        'topRow': topRow.toJson(),
        'middleRow': middleRow.toJson(),
        'bottomLeft': bottomLeft.toJson(),
        'bottomRight': bottomRight.toJson(),
        'titleBlockWidth': titleBlockWidth,
        'titleBlockHeight': titleBlockHeight,
      };

  factory TitleBlockConfig.fromJson(Map<String, dynamic> json) {
    return TitleBlockConfig(
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 3.0,
      topRow: TitleBlockCell.fromJson(json['topRow'] as Map<String, dynamic>),
      middleRow:
          TitleBlockCell.fromJson(json['middleRow'] as Map<String, dynamic>),
      bottomLeft:
          TitleBlockCell.fromJson(json['bottomLeft'] as Map<String, dynamic>),
      bottomRight:
          TitleBlockCell.fromJson(json['bottomRight'] as Map<String, dynamic>),
      titleBlockWidth:
          (json['titleBlockWidth'] as num?)?.toDouble() ?? 250.0,
      titleBlockHeight:
          (json['titleBlockHeight'] as num?)?.toDouble() ?? 90.0,
    );
  }

  TitleBlockConfig copyWith({
    double? borderWidth,
    TitleBlockCell? topRow,
    TitleBlockCell? middleRow,
    TitleBlockCell? bottomLeft,
    TitleBlockCell? bottomRight,
    double? titleBlockWidth,
    double? titleBlockHeight,
  }) {
    return TitleBlockConfig(
      borderWidth: borderWidth ?? this.borderWidth,
      topRow: topRow ?? this.topRow,
      middleRow: middleRow ?? this.middleRow,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      titleBlockWidth: titleBlockWidth ?? this.titleBlockWidth,
      titleBlockHeight: titleBlockHeight ?? this.titleBlockHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleBlockConfig &&
          borderWidth == other.borderWidth &&
          topRow == other.topRow &&
          middleRow == other.middleRow &&
          bottomLeft == other.bottomLeft &&
          bottomRight == other.bottomRight &&
          titleBlockWidth == other.titleBlockWidth &&
          titleBlockHeight == other.titleBlockHeight;

  @override
  int get hashCode => Object.hash(
        borderWidth,
        topRow,
        middleRow,
        bottomLeft,
        bottomRight,
        titleBlockWidth,
        titleBlockHeight,
      );

  /// All available field keys that can be used in cells.
  static const List<String> availableFields = [
    'projectName',
    'companyName',
    'date',
    'version',
    'powerGrid',
    'serialBus',
    'topology',
    'pageNumber',
  ];

  /// Human-readable label for a field key.
  static String fieldLabel(String key) {
    switch (key) {
      case 'projectName':
        return 'Project Name';
      case 'companyName':
        return 'Company Name';
      case 'date':
        return 'Date';
      case 'version':
        return 'Version';
      case 'powerGrid':
        return 'Power Grid';
      case 'serialBus':
        return 'Serial Bus';
      case 'topology':
        return 'Topology';
      case 'pageNumber':
        return 'Page Number';
      default:
        return key;
    }
  }
}
