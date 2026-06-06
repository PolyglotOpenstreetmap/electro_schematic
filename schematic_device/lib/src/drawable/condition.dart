// lib/src/drawable/condition.dart
//
// Condition expression AST used by DrawableNode.showIf.

import '../rendering/render_context.dart';

/// Sealed condition expression tree.
///
/// Every condition can be evaluated against a parameter map and a
/// [RenderContext], and serialized to/from JSON.
sealed class ConditionExpr {
  const ConditionExpr();

  bool evaluate(Map<String, dynamic> params, RenderContext ctx);
  Map<String, dynamic> toJson();

  factory ConditionExpr.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'eq' => ParamEqualsCondition.fromJson(json),
      'lt' => ParamLessThanCondition.fromJson(json),
      'gt' => ParamGreaterThanCondition.fromJson(json),
      'startsWith' => ParamStartsWithCondition.fromJson(json),
      'boolParam' => BoolParamCondition.fromJson(json),
      'not' => NotCondition.fromJson(json),
      'and' => AndCondition.fromJson(json),
      'or' => OrCondition.fromJson(json),
      _ => throw ArgumentError('Unknown ConditionExpr type: $type'),
    };
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  static dynamic _resolve(Map<String, dynamic> params, String paramId) =>
      params[paramId];
}

// ─── Leaf conditions ─────────────────────────────────────────────────────────

/// Passes when `params[param] == value`.
class ParamEqualsCondition extends ConditionExpr {
  final String param;
  final dynamic value;

  const ParamEqualsCondition(this.param, this.value);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) =>
      ConditionExpr._resolve(params, param) == value;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'eq',
        'param': param,
        'value': value,
      };

  factory ParamEqualsCondition.fromJson(Map<String, dynamic> json) =>
      ParamEqualsCondition(json['param'] as String, json['value']);
}

/// Passes when `params[param] < value`.
class ParamLessThanCondition extends ConditionExpr {
  final String param;
  final num value;

  const ParamLessThanCondition(this.param, this.value);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) {
    final v = ConditionExpr._resolve(params, param);
    if (v == null) return false;
    return (v as num) < value;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'lt',
        'param': param,
        'value': value,
      };

  factory ParamLessThanCondition.fromJson(Map<String, dynamic> json) =>
      ParamLessThanCondition(
        json['param'] as String,
        json['value'] as num,
      );
}

/// Passes when `params[param] > value`.
class ParamGreaterThanCondition extends ConditionExpr {
  final String param;
  final num value;

  const ParamGreaterThanCondition(this.param, this.value);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) {
    final v = ConditionExpr._resolve(params, param);
    if (v == null) return false;
    return (v as num) > value;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gt',
        'param': param,
        'value': value,
      };

  factory ParamGreaterThanCondition.fromJson(Map<String, dynamic> json) =>
      ParamGreaterThanCondition(
        json['param'] as String,
        json['value'] as num,
      );
}

/// Passes when `params[param].toString().startsWith(prefix)`.
class ParamStartsWithCondition extends ConditionExpr {
  final String param;
  final String prefix;

  const ParamStartsWithCondition(this.param, this.prefix);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) {
    final v = ConditionExpr._resolve(params, param);
    if (v == null) return false;
    return v.toString().startsWith(prefix);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'startsWith',
        'param': param,
        'value': prefix,
      };

  factory ParamStartsWithCondition.fromJson(Map<String, dynamic> json) =>
      ParamStartsWithCondition(
        json['param'] as String,
        json['value'] as String,
      );
}

/// Passes when `params[param]` is truthy.
class BoolParamCondition extends ConditionExpr {
  final String param;

  const BoolParamCondition(this.param);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) {
    final v = ConditionExpr._resolve(params, param);
    if (v == null) return false;
    if (v is bool) return v;
    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'boolParam',
        'param': param,
      };

  factory BoolParamCondition.fromJson(Map<String, dynamic> json) =>
      BoolParamCondition(json['param'] as String);
}

// ─── Combinator conditions ────────────────────────────────────────────────────

/// Inverts an inner condition.
class NotCondition extends ConditionExpr {
  final ConditionExpr inner;

  const NotCondition(this.inner);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) =>
      !inner.evaluate(params, ctx);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'not',
        'inner': inner.toJson(),
      };

  factory NotCondition.fromJson(Map<String, dynamic> json) =>
      NotCondition(ConditionExpr.fromJson(json['inner'] as Map<String, dynamic>));
}

/// Passes when ALL sub-conditions pass.
class AndCondition extends ConditionExpr {
  final List<ConditionExpr> conditions;

  const AndCondition(this.conditions);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) =>
      conditions.every((c) => c.evaluate(params, ctx));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'and',
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory AndCondition.fromJson(Map<String, dynamic> json) =>
      AndCondition(
        (json['conditions'] as List)
            .map((c) => ConditionExpr.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// Passes when ANY sub-condition passes.
class OrCondition extends ConditionExpr {
  final List<ConditionExpr> conditions;

  const OrCondition(this.conditions);

  @override
  bool evaluate(Map<String, dynamic> params, RenderContext ctx) =>
      conditions.any((c) => c.evaluate(params, ctx));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'or',
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory OrCondition.fromJson(Map<String, dynamic> json) =>
      OrCondition(
        (json['conditions'] as List)
            .map((c) => ConditionExpr.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
