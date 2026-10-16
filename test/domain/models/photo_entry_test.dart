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

  group('PhotoEntry file name date', () {
    test('exposes the date encoded in the name', () {
      final entry = PhotoEntry(
        file: File('/kiosk/IMG-20261224-WA0001.jpg'),
        date: DateTime(2026, 6, 1),
        sizeBytes: 1024,
      );

      expect(entry.filenameDate, DateTime(2026, 12, 24));
      expect(entry.bestCaptureDate, DateTime(2026, 12, 24));
    });

    test('prefers a known capture date over the name', () {
      final entry = PhotoEntry(
        file: File('/kiosk/IMG-20261224-WA0001.jpg'),
        date: DateTime(2026, 6, 1),
        sizeBytes: 1024,
      )..setExifMetadata(captureDate: DateTime(2025, 1, 2, 3, 4, 5));

      expect(entry.bestCaptureDate, DateTime(2025, 1, 2, 3, 4, 5));
    });

    test('has no name date when the name carries none', () {
      final entry = PhotoEntry(
        file: File('/kiosk/frame.jpg'),
        date: DateTime(2026, 6, 1),
        sizeBytes: 1024,
      );

      expect(entry.filenameDate, isNull);
      expect(entry.bestCaptureDate, isNull);
    });
  });
}
