import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

void main() {
  group('PhotoMetadataDatabase', () {
    late Directory dir;
    late String dbPath;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('meta_db_test_');
      dbPath = '${dir.path}/frame_metadata.db';
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('keeps scanned files across a reopen', () async {
      final db = PhotoMetadataDatabase.open(dbPath);
      db.saveScannedFiles([
        (path: '/a.jpg', modified: DateTime(2026, 1, 1), size: 10),
        (path: '/b.jpg', modified: DateTime(2026, 1, 2), size: 20),
      ]);
      db.close();

      final reopened = PhotoMetadataDatabase.open(dbPath);
      final photos = reopened.filePhotos();
      expect(photos.keys, containsAll(['/a.jpg', '/b.jpg']));
      expect(photos['/a.jpg']!.size, 10);
      expect(photos['/a.jpg']!.modified, DateTime(2026, 1, 1));
      reopened.close();
    });

    test('exif and dimensions keep the scan fields of the row', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.saveScannedFiles([
        (path: '/a.jpg', modified: DateTime(2026, 1, 1), size: 10),
      ]);

      db.saveExif(
        path: '/a.jpg',
        modified: DateTime(2026, 1, 1),
        captureDate: DateTime(2025, 12, 25),
        latitude: 48.5,
        longitude: 11.5,
      );
      db.saveDimensions(path: '/a.jpg', width: 100, height: 200);

      final row = db.photoByPath('/a.jpg')!;
      expect(row.size, 10);
      expect(row.captureDate, DateTime(2025, 12, 25));
      expect(row.latitude, closeTo(48.5, 1e-9));
      expect(row.height, 200);
      expect(row.exifLoaded, isTrue);
      db.close();
    });

    test('saves a MediaStore photo by asset id and reuses its path', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.saveMediaStorePhoto(
        path: '/dcim/a.jpg',
        assetId: '42',
        modified: DateTime(2026, 2, 1),
        size: 300,
        width: 10,
        height: 30,
        captureDate: DateTime(2026, 1, 31),
      );

      final byAsset = db.mediaStorePhotos();
      expect(byAsset['42']!.path, '/dcim/a.jpg');
      expect(byAsset['42']!.width, 10);
      // A MediaStore row is not part of the filesystem scan state.
      expect(db.filePhotos(), isEmpty);
      db.close();
    });

    test('deleteScannedFilesNotIn only drops filesystem rows', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.saveScannedFiles([
        (path: '/folder/keep.jpg', modified: DateTime(2026, 1, 1), size: 1),
        (path: '/folder/gone.jpg', modified: DateTime(2026, 1, 1), size: 1),
      ]);
      db.saveMediaStorePhoto(
        path: '/dcim/device.jpg',
        assetId: '7',
        modified: DateTime(2026, 1, 1),
        size: 1,
      );

      db.deleteScannedFilesNotIn(['/folder/keep.jpg']);

      final files = db.filePhotos();
      expect(files.keys, ['/folder/keep.jpg']);
      expect(db.mediaStorePhotos().keys, ['7']);
      db.close();
    });

    test('deleteMediaStorePhotosNotIn drops rows of removed assets', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.saveMediaStorePhoto(
        path: '/dcim/a.jpg',
        assetId: 'a',
        modified: DateTime(2026, 1, 1),
        size: 1,
      );
      db.saveMediaStorePhoto(
        path: '/dcim/b.jpg',
        assetId: 'b',
        modified: DateTime(2026, 1, 1),
        size: 1,
      );

      db.deleteMediaStorePhotosNotIn(['a']);

      expect(db.mediaStorePhotos().keys, ['a']);
      db.close();
    });

    test('lastFullScan survives a reopen', () async {
      final db = PhotoMetadataDatabase.open(dbPath);
      expect(db.lastFullScan, isNull);
      db.lastFullScan = DateTime(2026, 3, 1, 12);
      db.close();

      final reopened = PhotoMetadataDatabase.open(dbPath);
      expect(reopened.lastFullScan, DateTime(2026, 3, 1, 12));
      reopened.close();
    });

    test('places cache stores names and negative results', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      expect(db.place('48.500,11.500'), isNull);

      db.savePlace('48.500,11.500', 'Munich, Bayern, Germany');
      db.savePlace('0.000,0.000', null);

      expect(db.place('48.500,11.500')!.name, 'Munich, Bayern, Germany');
      expect(db.place('0.000,0.000')!.name, isNull);
      db.close();
    });

    test('prunes places older than the given age', () async {
      final db = PhotoMetadataDatabase.openInMemory();
      db.savePlace('48.500,11.500', 'Munich');

      db.prunePlacesOlderThan(const Duration(seconds: -1));

      expect(db.place('48.500,11.500'), isNull);
      db.close();
    });

    test('recovers from a corrupted file', () async {
      await File(dbPath).writeAsString('this is not a database');

      final db = PhotoMetadataDatabase.open(dbPath);
      db.saveScannedFiles([
        (path: '/a.jpg', modified: DateTime(2026, 1, 1), size: 1),
      ]);
      expect(db.photoByPath('/a.jpg'), isNotNull);
      db.close();
    });
  });
}