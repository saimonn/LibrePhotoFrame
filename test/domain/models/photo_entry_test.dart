import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';

void main() {
  group('PhotoEntry EXIF', () {
    PhotoEntry photo() => PhotoEntry(
          file: File('/fake/frame.jpg'),
          date: DateTime(2026, 6, 1),
          sizeBytes: 1024,
        );

    test('setCaptureDate keeps the file EXIF to load', () {
      final entry = photo();
      final captureDate = DateTime(2024, 12, 25, 14, 30);

      entry.setCaptureDate(captureDate);

      expect(entry.captureDate, captureDate);
      expect(entry.exifLoaded, isFalse);
    });

    test('setExifMetadata marks the EXIF as loaded', () {
      final entry = photo()..setCaptureDate(DateTime(2024, 12, 25));

      entry.setExifMetadata(latitude: 48.85, longitude: 2.35);

      expect(entry.exifLoaded, isTrue);
      expect(entry.hasLocation, isTrue);
    });
  });
}
