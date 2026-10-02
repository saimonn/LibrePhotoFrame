import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/exif_metadata_provider.dart';

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

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('exif_cache_test_');
      photo = File('${cacheDir.path}/photo.jpg');
      await photo.writeAsBytes(base64Decode(_photoWithExifBase64));
    });

    tearDown(() async {
      await cacheDir.delete(recursive: true);
    });

    final captureDate = DateTime(2026, 6, 1, 12);

    ExifMetadataProvider createProvider() {
      return ExifMetadataProvider(
        cacheDirectoryProvider: () async => cacheDir,
        saveDelay: const Duration(milliseconds: 10),
      );
    }

    File cacheFile() => File('${cacheDir.path}/exif_metadata_cache.json');

    /// Returns the cache file as soon as [check] holds, the provider writes it
    /// after its save delay.
    Future<Map<String, dynamic>> waitForCache(
      bool Function(Map<String, dynamic>) check,
    ) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        try {
          final decoded = jsonDecode(await cacheFile().readAsString());
          if (decoded is Map<String, dynamic> && check(decoded)) {
            return decoded;
          }
        } catch (_) {
          // Not written yet, or not readable.
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      fail('the provider did not write the expected cache');
      return {};
    }

    bool holdsPhoto(Map<String, dynamic> cache) =>
        cache.containsKey(photo.path);

    /// Replaces the content of the photo, keeping its modification date, so
    /// only a provider that reads the file again can see the difference.
    Future<void> replaceContent() async {
      final modified = (await photo.stat()).modified;
      await photo.writeAsBytes(List.filled(2048, 0));
      await photo.setLastModified(modified);
    }

    test('reads the capture date and writes it to the cache', () async {
      final provider = createProvider();

      final metadata = await provider.getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
      final cache = await waitForCache(holdsPhoto);
      expect(cache[photo.path]!['m'], isA<int>());
      expect(cache[photo.path]!['c'], captureDate.millisecondsSinceEpoch);
    });

    test('serves a cached capture date without reading the file', () async {
      await createProvider().getExifMetadata(photo);
      await waitForCache(holdsPhoto);
      await replaceContent();

      // A provider that starts now only has what the cache file holds.
      final restarted = createProvider();
      final metadata = await restarted.getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
    });

    test('reads the file again after it changed', () async {
      await createProvider().getExifMetadata(photo);
      final before = (await waitForCache(holdsPhoto))[photo.path]!['m'];
      await replaceContent();

      await photo.setLastModified(
        (await photo.stat()).modified.add(const Duration(days: 1)),
      );
      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, isNull);
      final cache = await waitForCache(
        (cache) => cache[photo.path]?['m'] != before,
      );
      expect(cache[photo.path]!['c'], isNull);
    });

    test('ignores a corrupted cache file', () async {
      await cacheFile().writeAsString('{ not json');

      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, captureDate);
      await waitForCache(holdsPhoto);
    });
  });
}
