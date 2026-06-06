// lib/src/models/parameter_def.dart
//
// Typed parameter definitions for DeviceDefinition.

/// Base for typed parameter definitions.
///
/// A parameter is a named, typed, configurable value that a DeviceDefinition
/// exposes. DeviceInstance supplies concrete values; the drawable DSL reads
/// them at render time.
sealed class ParameterDef {
  final String id;
  final String label;
  final dynamic defaultValue;

  const ParameterDef({
    required this.id,
    required this.label,
    required this.defaultValue,
  });

  Map<String, dynamic> toJson();

  factory ParameterDef.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'string' => StringParamDef.fromJson(json),
      'num' => NumParamDef.fromJson(json),
      'bool' => BoolParamDef.fromJson(json),
      'enum' => EnumParamDef.fromJson(json),
      _ => throw ArgumentError('Unknown ParameterDef type: $type'),
    };
  }
}

/// A free-form string parameter.
class StringParamDef extends ParameterDef {
  const StringParamDef({
    required super.id,
    required super.label,
    String super.defaultValue = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'string',
        'id': id,
        'label': label,
        'defaultValue': defaultValue as String,
      };

  factory StringParamDef.fromJson(Map<String, dynamic> json) {
    return StringParamDef(
      id: json['id'] as String,
      label: json['label'] as String,
      defaultValue: json['defaultValue'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringParamDef &&
          id == other.id &&
          label == other.label &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode => Object.hash(id, label, defaultValue);
}

/// A numeric parameter (int or double).
class NumParamDef extends ParameterDef {
  final num? min;
  final num? max;

  const NumParamDef({
    required super.id,
    required super.label,
    num super.defaultValue = 0,
    this.min,
    this.max,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'num',
        'id': id,
        'label': label,
        'defaultValue': defaultValue as num,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };

  factory NumParamDef.fromJson(Map<String, dynamic> json) {
    return NumParamDef(
      id: json['id'] as String,
      label: json['label'] as String,
      defaultValue: json['defaultValue'] as num? ?? 0,
      min: json['min'] as num?,
      max: json['max'] as num?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumParamDef &&
          id == other.id &&
          label == other.label &&
          defaultValue == other.defaultValue &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => Object.hash(id, label, defaultValue, min, max);
}

/// A boolean parameter.
class BoolParamDef extends ParameterDef {
  const BoolParamDef({
    required super.id,
    required super.label,
    bool super.defaultValue = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'bool',
        'id': id,
        'label': label,
        'defaultValue': defaultValue as bool,
      };

  factory BoolParamDef.fromJson(Map<String, dynamic> json) {
    return BoolParamDef(
      id: json['id'] as String,
      label: json['label'] as String,
      defaultValue: json['defaultValue'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolParamDef &&
          id == other.id &&
          label == other.label &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode => Object.hash(id, label, defaultValue);
}

/// A parameter whose value must be one of a fixed set of strings.
class EnumParamDef extends ParameterDef {
  final List<String> values;

  const EnumParamDef({
    required super.id,
    required super.label,
    required this.values,
    String super.defaultValue = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'enum',
        'id': id,
        'label': label,
        'values': values,
        'defaultValue': defaultValue as String,
      };

  factory EnumParamDef.fromJson(Map<String, dynamic> json) {
    return EnumParamDef(
      id: json['id'] as String,
      label: json['label'] as String,
      values: List<String>.from(json['values'] as List),
      defaultValue: json['defaultValue'] as String? ?? '',
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnumParamDef &&
          id == other.id &&
          label == other.label &&
          defaultValue == other.defaultValue &&
          _listEquals(values, other.values);

  @override
  int get hashCode =>
      Object.hash(id, label, defaultValue, Object.hashAll(values));
}
