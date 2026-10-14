import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/ui/utils/color_utils.dart';

void main() {
  group('parseHexColor', () {
    test('handles null -> fallback', () {
      final c = parseHexColor(null, fallback: Colors.red);
      expect(c, Colors.red);
    });

    test('#RGB format', () {
      final c = parseHexColor('#F00');
      expect(c, const Color(0xFFFF0000));
    });

    test('#RRGGBB format', () {
      final c = parseHexColor('#00FF00');
      expect(c, const Color(0xFF00FF00));
    });

    test('#AARRGGBB format', () {
      final c = parseHexColor('#800000FF');
      expect(c, const Color(0x800000FF));
    });

    test('named colors', () {
      expect(parseHexColor('black'), Colors.black);
      expect(parseHexColor('red'), Colors.red);
      expect(parseHexColor('green'), Colors.green);
      expect(parseHexColor('blue'), Colors.blue);
      expect(parseHexColor('yellow'), Colors.yellow);
      expect(parseHexColor('white'), Colors.white);
      expect(parseHexColor('transparent'), Colors.transparent);
    });

    test('invalid -> safe fallback', () {
      expect(parseHexColor('notacolor'), Colors.white);
      expect(parseHexColor('#GGG'), Colors.white);
      expect(parseHexColor(''), Colors.white);
    });

    test('case insensitive', () {
      expect(parseHexColor('#ff00ff'), const Color(0xFFFF00FF));
    });
  });

  group('colorToHex', () {
    test('converts color to hex with alpha', () {
      expect(colorToHex(const Color(0xFFFF0000)), '#FFFF0000');
      expect(colorToHex(Colors.transparent), '#00000000');
    });

    test('converts color to hex without alpha', () {
      expect(colorToHex(const Color(0xFFFF0000), includeAlpha: false), '#FF0000');
    });
  });
}
