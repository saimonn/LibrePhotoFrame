import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/exif_metadata_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

/// 8x8 JPEG holding one EXIF DateTimeOriginal tag, capture date 2026-06-01.
const String _photoWithExifBase64 =
    '/9j/4QBIRXhpZgAASUkqAAgAAAABAGmHBAABAAAAGgAAAAAAAAABAAOQAgAUAAAALAAAAAAAAAAy'
    'MDI2OjA2OjAxIDEyOjAwOjAwAP/gABBKRklGAAEBAAABAAEAAP/bAEMABgQFBgUEBgYFBgcHBggK'
    'EAoKCQkKFA4PDBAXFBgYFxQWFhodJR8aGyMcFhYgLCAjJicpKikZHy0wLSgwJSgpKP/bAEMBBwcH'
    'CggKEwoKEygaFhooKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgo'
    'KCgoKP/AABEIAAgACAMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/'
    'xAC1EAACAQMDAgQDBQUEBAAAAX0BAgMABBEFEiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKC'
    'CQoWFxgZGiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoOEhYaH'
    'iImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp'
    '6vHy8/T19vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAME'
    'BwUEBAABAncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYn'
    'KCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeY'
    'mZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/'
    '2gAMAwEAAhEDEQA/AOAooor54/YT/9k=';

void main() {
  group('ExifMetadataProvider cache', () {
    late Directory cacheDir;
    late File photo;
    late File dbFile;

    /// A file system only keeps whole seconds here, and the tests need a
    /// modification date they can restore exactly.
    final modified = DateTime(2026, 6, 2, 8, 30);

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('exif_cache_test_');
      dbFile = File('${cacheDir.path}/frame_metadata.db');
      photo = File('${cacheDir.path}/photo.jpg');
      await photo.writeAsBytes(base64Decode(_photoWithExifBase64));
      await photo.setLastModified(modified);
    });

    tearDown(() async {
      await cacheDir.delete(recursive: true);
    });

    final captureDate = DateTime(2026, 6, 1, 12);

    ExifMetadataProvider createProvider() =>
        ExifMetadataProvider(PhotoMetadataDatabase.open(dbFile.path));

    /// Returns the row the provider persisted for [photo].
    PhotoMetadata? storedRow() =>
        PhotoMetadataDatabase.open(dbFile.path).photoByPath(photo.path);

    /// Replaces the content of the photo, keeping its modification date, so
    /// only a provider that reads the file again can see the difference.
    Future<void> replaceContent() async {
      await photo.writeAsBytes(List.filled(2048, 0));
      await photo.setLastModified(modified);
    }

    test('reads the capture date and persists it', () async {
      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
      final row = storedRow();
      expect(row?.captureDate, captureDate);
      expect(row?.exifLoaded, isTrue);
    });

    test('serves a cached capture date without reading the file', () async {
      await createProvider().getExifMetadata(photo);
      await replaceContent();

      // A provider that starts now only has what the database holds.
      final restarted = createProvider();
      final metadata = await restarted.getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
    });

    test('reads the file again after it changed', () async {
      await createProvider().getExifMetadata(photo);
      await replaceContent();

      await photo.setLastModified(modified.add(const Duration(days: 1)));
      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, isNull);
      final row = storedRow();
      expect(row?.captureDate, isNull);
    });

    test('recovers from a corrupted database file', () async {
      await dbFile.writeAsString('{ not sqlite');

      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
    });
  });
}