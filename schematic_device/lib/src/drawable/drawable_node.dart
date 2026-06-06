// lib/src/drawable/drawable_node.dart
//
// Sealed DrawableNode hierarchy with all concrete types defined in the same
// library via `part` directives (required for `sealed` subclassing).

import 'package:flutter/material.dart';

import '../models/drawing_level.dart';
import 'color_utils.dart';
import 'condition.dart';
import 'terminal_color_binding.dart';

export '../models/drawing_level.dart';
export 'color_utils.dart';
export 'condition.dart';
export 'terminal_color_binding.dart';

part 'primitives.dart';
part 'composite_symbols.dart';

// ─── Sealed base ─────────────────────────────────────────────────────────────

/// Sealed base for every node in the drawable scene-graph.
///
/// All concrete subtypes are declared in [primitives.dart] and
/// [composite_symbols.dart] which are `part` files of this library.
sealed class DrawableNode {
  final String? id;
  final ConditionExpr? showIf;

  const DrawableNode({this.id, this.showIf});

  Map<String, dynamic> toJson();
}

// ─── Serialization registry ───────────────────────────────────────────────────

/// Static factory that deserializes any [DrawableNode] from JSON.
///
/// Call [registerBuiltinDrawableNodes] (or [SchematicDevicePackage.initialize])
/// before using [fromJson].
class DrawableNodeFactory {
  DrawableNodeFactory._();

  static final Map<String, DrawableNode Function(Map<String, dynamic>)>
      _registry = {};

  static void register(
      String type, DrawableNode Function(Map<String, dynamic>) factory) {
    _registry[type] = factory;
  }

  static DrawableNode fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final factory = _registry[type];
    if (factory == null) {
      throw ArgumentError(
          'Unknown DrawableNode type: "$type". '
          'Call SchematicDevicePackage.initialize() or '
          'registerBuiltinDrawableNodes() once before deserializing.');
    }
    return factory(json);
  }
}

// ─── Shared helpers (available to all parts) ─────────────────────────────────

ConditionExpr? _conditionFromJson(dynamic json) {
  if (json == null) return null;
  return ConditionExpr.fromJson(json as Map<String, dynamic>);
}

Offset _offsetFromJson(Map<String, dynamic> j) =>
    Offset((j['dx'] as num).toDouble(), (j['dy'] as num).toDouble());

Map<String, dynamic> _offsetToJson(Offset o) => {'dx': o.dx, 'dy': o.dy};
