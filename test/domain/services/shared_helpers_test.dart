import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/domain/services/photo_files.dart';
import 'package:libre_photo_frame/domain/services/photo_lists.dart';
import 'package:libre_photo_frame/ui/widgets/overlay_position.dart';

void main() {
  group('isImageFile', () {
    test('accepts the supported formats, case-insensitively', () {
      for (final name in ['a.jpg', 'A.JPEG', 'x.png', 'y.WEBP']) {
        expect(isImageFile(name), isTrue, reason: name);
      }
    });

    test('rejects other files and no-extension names', () {
      for (final name in ['a.gif', 'a.tiff', 'photo', '.part']) {
        expect(isImageFile(name), isFalse, reason: name);
      }
    });
  });

  group('isSamePhotoList', () {
    PhotoEntry entry(String path) => PhotoEntry(
          file: File(path),
          date: DateTime(2026),
          sizeBytes: 1,
        );

    test('is true for the same instances in the same order', () {
      final entries = [entry('a'), entry('b')];
      expect(isSamePhotoList(entries, List.of(entries)), isTrue);
    });

    test('is false for a replaced instance (same path, new object)', () {
      expect(isSamePhotoList([entry('a')], [entry('a')]), isFalse);
    });

    test('is false for a different length or order', () {
      final a = entry('a');
      final b = entry('b');
      expect(isSamePhotoList([a], [a, b]), isFalse);
      expect(isSamePhotoList([a, b], [b, a]), isFalse);
    });
  });

  group('OverlayPosition', () {
    test('maps all four positions consistently', () {
      expect(OverlayPosition.of('bottomRight').alignment, Alignment.bottomRight);
      expect(OverlayPosition.of('bottomRight').padding,
          const EdgeInsets.only(right: 24, bottom: 24));
      expect(OverlayPosition.of('bottomRight').crossAxisAlignment,
          CrossAxisAlignment.end);

      expect(OverlayPosition.of('bottomLeft').alignment, Alignment.bottomLeft);
      expect(OverlayPosition.of('bottomLeft').padding,
          const EdgeInsets.only(left: 24, bottom: 24));
      expect(OverlayPosition.of('bottomLeft').crossAxisAlignment,
          CrossAxisAlignment.start);

      expect(OverlayPosition.of('topRight').alignment, Alignment.topRight);
      expect(OverlayPosition.of('topRight').padding,
          const EdgeInsets.only(right: 24, top: 24));
      expect(OverlayPosition.of('topRight').crossAxisAlignment,
          CrossAxisAlignment.end);

      expect(OverlayPosition.of('topLeft').alignment, Alignment.topLeft);
      expect(OverlayPosition.of('topLeft').padding,
          const EdgeInsets.only(left: 24, top: 24));
      expect(OverlayPosition.of('topLeft').crossAxisAlignment,
          CrossAxisAlignment.start);
    });

    test('defaults to bottomRight for unknown positions', () {
      expect(OverlayPosition.of('center').alignment, Alignment.bottomRight);
    });
  });
}