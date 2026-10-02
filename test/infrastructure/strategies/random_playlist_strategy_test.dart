import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/strategies/random_playlist_strategy.dart';

void main() {
  group('RandomPlaylistStrategy', () {
    // Enough draws to compare the weights of the first ranks: the photo shown
    // last is drawn about 170 times out of 100000.
    const draws = 100000;

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

    Map<String, int> countDraws(
      RandomPlaylistStrategy strategy,
      List<PhotoEntry> photos, {
      int count = draws,
    }) {
      final counts = <String, int>{};
      for (var i = 0; i < count; i++) {
        final path = strategy.nextPhoto(photos)!.file.path;
        counts[path] = (counts[path] ?? 0) + 1;
      }
      return counts;
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

    test('reaches every photo of the collection', () {
      final photos = createPhotos(5);
      final strategy = RandomPlaylistStrategy(random: Random(3));

      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        final photo = strategy.nextPhoto(photos)!;
        seen.add(photo.file.path);
        strategy.recordShown([photo]);
      }

      expect(seen, photos.map((photo) => photo.file.path).toSet());
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
        final photo = strategy.nextPhoto(photos)!;
        seen.add(photo.file.path);
        strategy.recordShown([photo]);
      }

      expect(seen, photos.map((photo) => photo.file.path).toSet());
    });

    test('spreads the picks evenly over the photos never shown', () {
      final photos = createPhotos(4);
      final strategy = RandomPlaylistStrategy(random: Random(11));

      final counts = countDraws(strategy, photos);

      counts.forEach((path, count) {
        expect(count, greaterThan(draws ~/ 4 ~/ 2));
      });
    });

    test('weights the photo shown last far below an unseen one', () {
      final photos = createPhotos(5);
      final strategy = RandomPlaylistStrategy(random: Random(7));

      final last = strategy.nextPhoto(photos)!;
      strategy.recordShown([last]);

      final counts = countDraws(strategy, photos);

      // Weight 0.01 against four unseen photos at weight 1.
      expect(counts[last.file.path], lessThan(draws ~/ 50));
      counts.forEach((path, count) {
        if (path != last.file.path) {
          expect(count, greaterThan(draws ~/ 5 ~/ 2));
        }
      });
    });

    test('the more recently a photo was shown, the lower its weight', () {
      final photos = createPhotos(6);
      final strategy = RandomPlaylistStrategy(random: Random(3));

      strategy.recordShown([photos[0]]); // rank 3
      strategy.recordShown([photos[1]]); // rank 2
      strategy.recordShown([photos[2]]); // rank 1

      final counts = countDraws(strategy, photos);

      expect(counts[photos[2].file.path], lessThan(counts[photos[1].file.path]!));
      expect(counts[photos[1].file.path], lessThan(counts[photos[0].file.path]!));
      expect(
        counts[photos[0].file.path],
        lessThan(counts[photos[3].file.path]!),
      );
    });

    test('gives both photos of a split frame the same rank', () {
      final photos = createPhotos(5);
      final strategy = RandomPlaylistStrategy(random: Random(17));

      strategy.recordShown([photos[0], photos[1]]);

      final counts = countDraws(strategy, photos);

      final first = counts[photos[0].file.path]!;
      final second = counts[photos[1].file.path]!;
      expect(first, greaterThan(second * 0.6));
      expect(first, lessThan(second * 1.4));
    });

    test('keeps the history across a rescan', () {
      // A rescan rebuilds the list with new PhotoEntry objects, so the history
      // has to be compared by path.
      final strategy = RandomPlaylistStrategy(random: Random(23));
      strategy.recordShown([createPhotos(1).first]);

      final counts = countDraws(strategy, createPhotos(3));

      expect(counts['/fake/photo_0.jpg'], lessThan(draws ~/ 50));
    });

    test('drops the oldest photos once the history is full', () {
      final photos = createPhotos(105);
      final strategy = RandomPlaylistStrategy(random: Random(29));

      for (final photo in photos) {
        strategy.recordShown([photo]);
      }

      final counts = countDraws(strategy, photos);

      // Only the last 100 shown keep a weight, photo_0 is unseen again.
      expect(counts['/fake/photo_0.jpg'], greaterThan(draws ~/ 2 ~/ 2));
      expect(
        counts['/fake/photo_104.jpg'],
        lessThan(counts['/fake/photo_0.jpg']! ~/ 20),
      );
    });
  });
}
