import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/exif_metadata_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExifMetadataProvider cache', () {
    late Directory cacheDir;
    late File photo;

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('exif_cache_test_');
      photo = File('${cacheDir.path}/photo.jpg');
      await photo.writeAsBytes(List.filled(2048, 0));
    });

    tearDown(() async {
      await cacheDir.delete(recursive: true);
    });

    ExifMetadataProvider createProvider() {
      return ExifMetadataProvider(cacheDirectoryProvider: () async => cacheDir);
    }

    File cacheFile() => File('${cacheDir.path}/exif_metadata_cache.json');

    /// Reads the cache file the provider writes after its save delay.
    Future<Map<String, dynamic>> readCache() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!await cacheFile().exists() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(await cacheFile().exists(), isTrue,
          reason: 'the provider did not write its cache');
      return jsonDecode(await cacheFile().readAsString()) as Map<String, dynamic>;
    }

    test('reads a photo without EXIF and remembers the file', () async {
      final provider = createProvider();

      final metadata = await provider.getExifMetadata(photo);

      expect(metadata.captureDate, isNull);
      final cache = await readCache();
      expect(cache.keys, contains(photo.path));
    });

    test('reuses the cached result of an unchanged file', () async {
      await createProvider().getExifMetadata(photo);

      // A second provider only has what the cache file holds.
      final restarted = createProvider();
      await restarted.getExifMetadata(photo);

      final cache = await readCache();
      expect(cache[photo.path], isNotNull);
      expect(cache[photo.path]!['m'], isA<int>());
    });

    test('reads the file again after it changed', () async {
      await createProvider().getExifMetadata(photo);
      final before = (await readCache())[photo.path]!['m'];

      await photo.setLastModified(
        DateTime.now().add(const Duration(days: 1)),
      );
      await createProvider().getExifMetadata(photo);

      final cache = await readCache();
      expect(cache[photo.path]!['m'], isNot(before));
    });

    test('survives a corrupted cache file', () async {
      await cacheFile.writeAsString('{ not json');

      final metadata = await createProvider().getExifMetadata(photo);

      expect(metadata.captureDate, isNull);
      final cache = await readCache();
      expect(cache.keys, contains(photo.path));
    });
  });
}
