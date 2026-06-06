// lib/src/drawable/color_utils.dart
//
// Hex-string ↔ Color helpers.

import 'package:flutter/material.dart';

/// Parses a CSS-style hex color string to a Flutter [Color].
///
/// Accepts:
///   "#RGB"        → expands to #RRGGBB
///   "#RRGGBB"     → full opaque color
///   "#AARRGGBB"   → full color with alpha
Color colorFromHex(String hex) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  final value = switch (s.length) {
    3 => int.parse(
        'FF'
        '${s[0]}${s[0]}'
        '${s[1]}${s[1]}'
        '${s[2]}${s[2]}',
        radix: 16),
    6 => int.parse('FF$s', radix: 16),
    8 => int.parse(s, radix: 16),
    _ => throw ArgumentError('Invalid hex color: $hex'),
  };
  return Color(value);
}

/// Serialises a [Color] to an "#AARRGGBB" hex string.
String colorToHex(Color c) {
  final a = (c.a * 255).round();
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return '#'
      '${a.toRadixString(16).padLeft(2, '0')}'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

/// Serialises a [Color] to "#RRGGBB" when fully opaque, "#AARRGGBB" otherwise.
String colorToHexCompact(Color c) {
  final a = (c.a * 255).round();
  if (a == 255) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
  return colorToHex(c);
}
