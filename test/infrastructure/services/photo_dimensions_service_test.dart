import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_dimensions_service.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

PhotoEntry entry(String path) => PhotoEntry(
      file: File(path),
      date: DateTime(2026),
      sizeBytes: 1,
    );

/// `gps_ne.jpg` is a 64x48 fixture, so its shape is landscape.
const fixture = 'test/fixtures/exif/gps_ne.jpg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoDimensionsService', () {
    test('reads the dimensions from a real image header', () async {
      final service = PhotoDimensionsService();
      final photo = entry(fixture);

      final shape = await service.shapeOf(photo);

      expect(photo.dimensionsResolved, isTrue);
      expect(photo.width, 64);
      expect(photo.height, 48);
      expect(shape, PhotoShape.landscape);
    });

    test('returns the shape of an already resolved entry without reading',
        () async {
      final service = PhotoDimensionsService();
      final photo = entry('/does/not/exist.jpg')..setDimensions(1000, 2000);

      expect(await service.shapeOf(photo), PhotoShape.portrait);
    });

    test('reuses the dimensions stored in the database', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.saveDimensions(path: '/cached.jpg', width: 2000, height: 1000);
      final service = PhotoDimensionsService(database: db);

      final photo = entry('/cached.jpg');
      expect(await service.shapeOf(photo), PhotoShape.landscape);
      expect(photo.width, 2000);
      expect(photo.height, 1000);
      db.close();
    });

    test('stores the measured dimensions in the database', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      final service = PhotoDimensionsService(database: db);
      final photo = entry(fixture);

      await service.shapeOf(photo);

      final row = db.photoByPath(photo.file.path)!;
      expect(row.width, photo.width);
      expect(row.height, photo.height);
      db.close();
    });

    test('leaves a non-image unpaired', () async {
      final dir = await Directory.systemTemp.createTemp('dimensions_test_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/not-an-image.jpg');
      await file.writeAsString('definitely not a jpeg');

      final photo = entry(file.path);

      expect(await PhotoDimensionsService().shapeOf(photo), isNull);
      expect(photo.dimensionsResolved, isTrue);
      expect(photo.shape, isNull);
    });

    test('resolves concurrent calls for the same entry consistently', () async {
      final service = PhotoDimensionsService();
      final photo = entry(fixture);

      final results = await Future.wait([
        service.shapeOf(photo),
        service.shapeOf(photo),
      ]);

      expect(results[0], PhotoShape.landscape);
      expect(results[1], PhotoShape.landscape);
    });

    test('dispose clears the in-flight map', () {
      final service = PhotoDimensionsService();
      expect(service.dispose, returnsNormally);
    });
  });
}
