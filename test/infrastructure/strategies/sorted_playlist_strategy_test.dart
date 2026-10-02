import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/strategies/sorted_playlist_strategy.dart';

void main() {
  group('SortedPlaylistStrategy', () {
    final day = DateTime(2026, 6, 1);

    PhotoEntry photo(
      String name, {
      DateTime? modified,
      DateTime? created,
      DateTime? captured,
    }) {
      return PhotoEntry(
        file: File('/fake/$name.jpg'),
        date: modified ?? day,
        createdAt: created,
        sizeBytes: 1024,
      )..setExifMetadata(captureDate: captured);
    }

    test('returns null when no photo is available', () {
      expect(SortedPlaylistStrategy(PhotoOrderField.exif).nextPhoto([]), isNull);
    });

    test('keeps showing the single photo of a one photo collection', () {
      final photos = [photo('only', modified: day)];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);

      expect(strategy.nextPhoto(photos), same(photos.first));
      expect(strategy.nextPhoto(photos), same(photos.first));
    });

    test('walks the file modification dates from oldest to newest', () {
      final photos = [
        photo('new', modified: day.add(const Duration(days: 2))),
        photo('old', modified: day),
        photo('middle', modified: day.add(const Duration(days: 1))),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);

      final order = [
        for (var i = 0; i < 3; i++) strategy.nextPhoto(photos)!.file.path,
      ];

      expect(order, ['/fake/old.jpg', '/fake/middle.jpg', '/fake/new.jpg']);
    });

    test('starts over at the oldest photo when the collection ends', () {
      final photos = [
        photo('a', modified: day),
        photo('b', modified: day.add(const Duration(days: 1))),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);

      expect(
        [for (var i = 0; i < 4; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/a.jpg', '/fake/b.jpg', '/fake/a.jpg', '/fake/b.jpg'],
      );
    });

    test('walks the file creation dates when the platform reports them', () {
      final photos = [
        photo('new', modified: day, created: day.add(const Duration(days: 9))),
        photo('old', modified: day, created: day),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.creation);

      expect(
        [for (var i = 0; i < 2; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/old.jpg', '/fake/new.jpg'],
      );
    });

    test('falls back to the file date when there is no creation date', () {
      final photos = [
        photo('new', modified: day.add(const Duration(days: 2))),
        photo('old', modified: day),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.creation);

      expect(
        [for (var i = 0; i < 2; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/old.jpg', '/fake/new.jpg'],
      );
    });

    test('prefers the EXIF capture date over the file dates', () {
      final photos = [
        photo(
          'shot_first',
          modified: day.add(const Duration(days: 5)),
          captured: day,
        ),
        photo(
          'shot_last',
          modified: day,
          captured: day.add(const Duration(days: 6)),
        ),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.exif);

      expect(
        [for (var i = 0; i < 2; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/shot_first.jpg', '/fake/shot_last.jpg'],
      );
    });

    test('sorts a photo without EXIF by its file date', () {
      // The capture date is only read when a photo is displayed, so a photo the
      // frame has not shown yet is ordered by its file date.
      final photos = [
        photo('with_exif', modified: day, captured: day),
        photo('without_exif', modified: day.subtract(const Duration(days: 3))),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.exif);

      expect(
        [for (var i = 0; i < 2; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/without_exif.jpg', '/fake/with_exif.jpg'],
      );
    });

    test('walks on from the photo on screen when the order is rebuilt', () {
      final photos = [
        photo('a', modified: day),
        photo('b', modified: day.add(const Duration(days: 1))),
        photo('c', modified: day.add(const Duration(days: 2))),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);

      expect(strategy.nextPhoto(photos)!.file.path, '/fake/a.jpg');
      expect(strategy.nextPhoto(photos)!.file.path, '/fake/b.jpg');

      // The frame read the capture date of c while it was showing b. That only
      // moves c in the exif order, and the rescan hands out a new list.
      photos[2].setExifMetadata(captureDate: day);
      final rescan = [photos[2], photos[1], photos[0]];

      expect(strategy.nextPhoto(rescan)!.file.path, '/fake/c.jpg');
    });

    test('walks from the start when the photo on screen disappeared', () {
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);
      final photos = [
        photo('a', modified: day),
        photo('b', modified: day.add(const Duration(days: 1))),
        photo('c', modified: day.add(const Duration(days: 2))),
      ];

      expect(strategy.nextPhoto(photos)!.file.path, '/fake/a.jpg');
      expect(strategy.nextPhoto(photos)!.file.path, '/fake/b.jpg');

      // b disappeared from the folder, so the walk starts over at a.
      final remaining = [photos[0], photos[2]];
      expect(
        [for (var i = 0; i < 3; i++) strategy.nextPhoto(remaining)!.file.path],
        ['/fake/a.jpg', '/fake/c.jpg', '/fake/a.jpg'],
      );
    });

    test('keeps a stable order for photos sharing a date', () {
      final photos = [
        photo('b', modified: day),
        photo('a', modified: day),
        photo('c', modified: day),
      ];
      final strategy = SortedPlaylistStrategy(PhotoOrderField.modification);

      expect(
        [for (var i = 0; i < 3; i++) strategy.nextPhoto(photos)!.file.path],
        ['/fake/a.jpg', '/fake/b.jpg', '/fake/c.jpg'],
      );
    });
  });
}
