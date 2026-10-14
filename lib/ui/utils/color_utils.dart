import 'package:flutter/material.dart';

Color parseHexColor(String? colorStr, {Color fallback = Colors.white}) {
  if (colorStr == null) return fallback;
  try {
    var str = colorStr.trim().toLowerCase();
    if (str.startsWith('#')) {
      str = str.substring(1);
      if (str.length == 3) {
        str = 'ff${str[0]}${str[0]}${str[1]}${str[1]}${str[2]}${str[2]}';
      } else if (str.length == 6) {
        str = 'ff$str';
      } else if (str.length == 8) {
        // Keep as is
      } else {
        return fallback;
      }
      return Color(int.parse(str, radix: 16));
    }
    switch (str) {
      case 'black':
        return Colors.black;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'white':
        return Colors.white;
      case 'transparent':
        return Colors.transparent;
      default:
        return fallback;
    }
  } catch (_) {
    return fallback;
  }
}

String colorToHex(Color color, {bool includeAlpha = true}) {
  final value = color.value;
  final a = (value >> 24) & 0xFF;
  final r = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final b = value & 0xFF;
  if (includeAlpha) {
    return '#${a.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
