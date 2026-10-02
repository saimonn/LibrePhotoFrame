import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/strategies/random_playlist_strategy.dart';

void main() {
  group('RandomPlaylistStrategy', () {
    List<PhotoEntry> createPhotos(int count) {
      return List.generate(
        count,
        (i) => PhotoEntry(
          file: File('/fake/photo_$i.jpg'),
          date: DateTime.now(),
          sizeBytes: 1024,
        ),
      );
    }

    test('returns null when no photo is available', () {
      expect(RandomPlaylistStrategy().nextPhoto([]), isNull);
    });

    test('keeps showing the single photo of a one photo collection', () {
      final photos = createPhotos(1);
      final strategy = RandomPlaylistStrategy();

      expect(strategy.nextPhoto(photos), same(photos.first));
      expect(strategy.nextPhoto(photos), same(photos.first));
    });

    test('never shows the same photo twice in a row', () {
      final photos = createPhotos(4);
      final strategy = RandomPlaylistStrategy(random: Random(7));

      PhotoEntry? previous;
      for (var i = 0; i < 200; i++) {
        final photo = strategy.nextPhoto(photos)!;
        if (previous != null) {
          expect(photo.file.path, isNot(previous.file.path));
        }
        previous = photo;
      }
    });

    test('reaches every photo of the collection', () {
      final photos = createPhotos(5);
      final strategy = RandomPlaylistStrategy(random: Random(3));

      final seen = {
        for (var i = 0; i < 200; i++) strategy.nextPhoto(photos)!.file.path,
      };

      expect(seen, photos.map((photo) => photo.file.path).toSet());
    });

    test('avoids the photo shown last across a rescan', () {
      // A rescan rebuilds the list with new PhotoEntry objects, so the photo
      // shown last is recognized by its path, not by identity.
      final strategy = RandomPlaylistStrategy(random: Random(1));
      final shown = strategy.nextPhoto(createPhotos(2))!;

      for (var i = 0; i < 20; i++) {
        expect(
          strategy.nextPhoto(createPhotos(2))!.file.path,
          isNot(shown.file.path),
        );
      }
    });

    test('reaches a photo synced with an old file date as well', () {
      // Two batches like a sync client leaves them: one carries the date it was
      // synced, the other keeps the file date of months ago. Every photo has to
      // show up whatever its file date.
      final now = DateTime.now();
      final fresh = List.generate(
        5,
        (i) => PhotoEntry(
          file: File('/fake/fresh_$i.jpg'),
          date: now.subtract(Duration(hours: i)),
          sizeBytes: 1024,
        ),
      );
      final old = List.generate(
        7,
        (i) => PhotoEntry(
          file: File('/fake/old_$i.jpg'),
          date: now.subtract(Duration(days: 120 + i)),
          sizeBytes: 1024,
        ),
      );
      final photos = [...fresh, ...old];
      final strategy = RandomPlaylistStrategy(random: Random(5));

      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        seen.add(strategy.nextPhoto(photos)!.file.path);
      }

      expect(seen, photos.map((photo) => photo.file.path).toSet());
    });

    test('spreads the picks evenly over the collection', () {
      final photos = createPhotos(4);
      final strategy = RandomPlaylistStrategy(random: Random(11));

      final counts = <String, int>{};
      for (var i = 0; i < 4000; i++) {
        final path = strategy.nextPhoto(photos)!.file.path;
        counts[path] = (counts[path] ?? 0) + 1;
      }

      // Each photo is drawn without its predecessor, so roughly a quarter of
      // the draws go to each of them.
      counts.forEach((path, count) {
        expect(count, greaterThan(4000 ~/ 4 ~/ 2));
      });
    });
  });
}