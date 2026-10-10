import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/metadata_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/exif_metadata_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

/// GPS reading (issue 10): a photo carrying coordinates must report them, a
/// photo without a GPS block must report none.
///
/// The fixtures in `test/fixtures/exif` are 64x48 JPEGs whose EXIF block was
/// written with Pillow (tags DateTime, DateTimeOriginal, DateTimeDigitized and,
/// for the first two, the GPS IFD):
///
/// | file         | capture date        | position                     |
/// | ------------ | ------------------- | ---------------------------- |
/// | `gps_ne.jpg` | 2026-06-01 12:00:00 | 48deg30'0"N 11deg30'0"E       |
/// | `gps_sw.jpg` | 2025-12-25 08:15:30 | 33deg51'6"S 151deg12'0"W      |
/// | `no_gps.jpg` | 2024-01-02 03:04:05 | no GPS block                  |
void main() {
  group('ExifMetadataProvider GPS', () {
    late Directory cacheDir;
    late File dbFile;

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('exif_gps_test_');
      dbFile = File('${cacheDir.path}/frame_metadata.db');
    });

    tearDown(() async {
      await cacheDir.delete(recursive: true);
    });

    Future<ExifMetadata> read(String name) {
      final provider = ExifMetadataProvider(
        PhotoMetadataDatabase.open(dbFile.path),
      );
      return provider.getExifMetadata(File('test/fixtures/exif/$name'));
    }

    test('reads the date and the coordinates of gps_ne.jpg', () async {
      final metadata = await read('gps_ne.jpg');

      expect(metadata.captureDate, DateTime(2026, 6, 1, 12));
      expect(metadata.location, isNotNull);
      expect(metadata.location!.latitude, closeTo(48.5, 1e-9));
      expect(metadata.location!.longitude, closeTo(11.5, 1e-9));
    });

    test('reads southern and western coordinates as negative', () async {
      final metadata = await read('gps_sw.jpg');

      expect(metadata.captureDate, DateTime(2025, 12, 25, 8, 15, 30));
      expect(metadata.location, isNotNull);
      expect(metadata.location!.latitude, closeTo(-33.851666, 1e-6));
      expect(metadata.location!.longitude, closeTo(-151.2, 1e-9));
    });

    test('reports no location for a photo without GPS', () async {
      final metadata = await read('no_gps.jpg');

      expect(metadata.captureDate, DateTime(2024, 1, 2, 3, 4, 5));
      expect(metadata.location, isNull);
    });
  });
}
