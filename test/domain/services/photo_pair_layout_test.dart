import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/domain/services/photo_pair_layout.dart';

PhotoEntry entry(String name, {int? width, int? height}) {
  return PhotoEntry(
    file: File('/photos/$name.jpg'),
    date: DateTime(2026),
    sizeBytes: 1024,
    width: width,
    height: height,
  );
}

PhotoEntry portrait(String name) => entry(name, width: 1000, height: 2000);
PhotoEntry landscape(String name) => entry(name, width: 2000, height: 1000);
PhotoEntry square(String name) => entry(name, width: 1500, height: 1500);
PhotoEntry unknown(String name) => entry(name);

void main() {
  group('PhotoEntry dimensions', () {
    test('shape is derived from width and height', () {
      expect(portrait('a').shape, PhotoShape.portrait);
      expect(landscape('b').shape, PhotoShape.landscape);
      expect(square('c').shape, PhotoShape.square);
    });

    test('shape is null until dimensions are known', () {
      final photo = unknown('a');
      expect(photo.dimensionsResolved, isFalse);
      expect(photo.shape, isNull);
      expect(photo.isPortrait, isFalse);
      expect(photo.isLandscape, isFalse);
    });

    test('setDimensions resolves the shape lazily', () {
      final photo = unknown('a');
      expect(photo.shape, isNull);

      photo.setDimensions(800, 1600);
      expect(photo.dimensionsResolved, isTrue);
      expect(photo.shape, PhotoShape.portrait);
      expect(photo.isPortrait, isTrue);
    });

    test('unreadable files resolve to a null shape', () {
      final photo = unknown('a');
      photo.setDimensions(null, null);
      expect(photo.dimensionsResolved, isTrue);
      expect(photo.shape, isNull);
    });

    test('zero or negative dimensions do not produce a shape', () {
      final photo = unknown('a')..setDimensions(0, 100);
      expect(photo.shape, isNull);
    });
  });

  group('PhotoPairLayout.forScreen', () {
    test('a landscape frame pairs portrait photos side by side', () {
      expect(
        PhotoPairLayout.forScreen(1920, 1080),
        PhotoPairing.portraitSideBySide,
      );
    });

    test('a portrait frame pairs landscape photos stacked', () {
      expect(
        PhotoPairLayout.forScreen(1080, 1920),
        PhotoPairing.landscapeStacked,
      );
    });

    test('a square frame is treated as portrait', () {
      expect(
        PhotoPairLayout.forScreen(1080, 1080),
        PhotoPairing.landscapeStacked,
      );
    });
  });

  group('PhotoPairLayout.partnerFor', () {
    test('landscape frame pairs two portrait photos', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [primary, portrait('b'), landscape('c')],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner, isNotNull);
      expect(partner!.file.path, endsWith('/b.jpg'));
    });

    test('portrait frame pairs two landscape photos', () {
      final primary = landscape('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [primary, landscape('b'), portrait('c')],
        pairing: PhotoPairing.landscapeStacked,
      );

      expect(partner, isNotNull);
      expect(partner!.file.path, endsWith('/b.jpg'));
    });

    test('never pairs a photo with itself', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [primary],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner, isNull);
    });

    test('skips photos whose dimensions are unknown', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [unknown('x'), unknown('y')],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner, isNull);
    });

    test('square photos are not used as partners', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [square('s'), portrait('b')],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner!.file.path, endsWith('/b.jpg'));
    });

    test('respects excluded paths', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [portrait('b'), portrait('c')],
        pairing: PhotoPairing.portraitSideBySide,
        excludePaths: {'/photos/b.jpg'},
      );

      expect(partner!.file.path, endsWith('/c.jpg'));
    });

    test('returns null when no candidate has the required shape', () {
      final partner = PhotoPairLayout.partnerFor(
        primary: portrait('a'),
        candidates: [landscape('b')],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner, isNull);
    });

    test('single pairing never produces a partner', () {
      final partner = PhotoPairLayout.partnerFor(
        primary: portrait('a'),
        candidates: [portrait('b')],
        pairing: PhotoPairing.single,
      );

      expect(partner, isNull);
    });

    test('a primary of the wrong shape is shown alone', () {
      // A landscape photo cannot share a portrait frame with a portrait photo,
      // so it fills the frame on its own instead of leaving half of it empty.
      final partner = PhotoPairLayout.partnerFor(
        primary: portrait('a'),
        candidates: [landscape('b')],
        pairing: PhotoPairing.landscapeStacked,
      );

      expect(partner, isNull);
    });

    test('two photos of the frame shape never share the frame', () {
      // Landscape frame: one landscape photo or two portrait photos.
      expect(
        PhotoPairLayout.partnerFor(
          primary: landscape('a'),
          candidates: [landscape('b')],
          pairing: PhotoPairing.portraitSideBySide,
        ),
        isNull,
      );
      // Portrait frame: one portrait photo or two landscape photos.
      expect(
        PhotoPairLayout.partnerFor(
          primary: portrait('a'),
          candidates: [portrait('b')],
          pairing: PhotoPairing.landscapeStacked,
        ),
        isNull,
      );
    });

    test('a mixed collection finds a partner of the right shape', () {
      final primary = portrait('a');
      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: [
          landscape('l1'),
          square('s1'),
          landscape('l2'),
          portrait('p2'),
          portrait('p3'),
        ],
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner!.file.path, endsWith('/p2.jpg'));
    });
  });

  group('PhotoPairLayout.accepts', () {
    test('landscape frame accepts portrait photos only', () {
      expect(
        PhotoPairLayout.accepts(
          PhotoPairing.portraitSideBySide,
          portrait('a'),
        ),
        isTrue,
      );
      expect(
        PhotoPairLayout.accepts(
          PhotoPairing.portraitSideBySide,
          landscape('b'),
        ),
        isFalse,
      );
      expect(
        PhotoPairLayout.accepts(
          PhotoPairing.portraitSideBySide,
          square('c'),
        ),
        isFalse,
      );
    });

    test('portrait frame accepts landscape photos only', () {
      expect(
        PhotoPairLayout.accepts(
          PhotoPairing.landscapeStacked,
          landscape('b'),
        ),
        isTrue,
      );
      expect(
        PhotoPairLayout.accepts(
          PhotoPairing.landscapeStacked,
          portrait('a'),
        ),
        isFalse,
      );
    });
  });

  group('PhotoPairLayout.windowAfter', () {
    test('starts with the photo after the primary', () {
      final photos = [portrait('a'), portrait('b'), portrait('c')];
      final window = PhotoPairLayout.windowAfter(photos[0], photos, 2);

      expect(window.map((p) => p.file.path).toList(), [
        '/photos/b.jpg',
        '/photos/c.jpg',
      ]);
    });

    test('wraps around the end of the list', () {
      final photos = [portrait('a'), portrait('b'), portrait('c')];
      final window = PhotoPairLayout.windowAfter(photos[2], photos, 3);

      expect(window.map((p) => p.file.path).toList(), [
        '/photos/a.jpg',
        '/photos/b.jpg',
        '/photos/c.jpg',
      ]);
    });

    test('caps the window at the requested limit', () {
      final photos = List.generate(10, (i) => portrait('p$i'));
      final window = PhotoPairLayout.windowAfter(photos[0], photos, 4);

      expect(window, hasLength(4));
      expect(window.first.file.path, endsWith('/p1.jpg'));
    });

    test('starts at the head when the primary is not in the list', () {
      final photos = [portrait('a'), portrait('b')];
      final window = PhotoPairLayout.windowAfter(portrait('ghost'), photos, 2);

      expect(window.map((p) => p.file.path).toList(), [
        '/photos/a.jpg',
        '/photos/b.jpg',
      ]);
    });

    test('returns an empty list for an empty collection or a null limit', () {
      expect(PhotoPairLayout.windowAfter(portrait('a'), const [], 4), isEmpty);
      expect(
        PhotoPairLayout.windowAfter(portrait('a'), [portrait('a')], 0),
        isEmpty,
      );
    });
  });

  group('issue 19 - the partner follows the photo on screen', () {
    // A landscape frame pairs portrait photos. The primary is picked at random
    // across the whole collection, so partners must not all come from the same
    // fixed head of the list.
    List<PhotoEntry> collection(int portraits, int landscapes) {
      return [
        for (var i = 0; i < portraits; i++) portrait('p$i'),
        for (var i = 0; i < landscapes; i++) landscape('l$i'),
      ];
    }

    test('two different primaries get two different partners', () {
      final photos = collection(6, 0);
      final first = PhotoPairLayout.windowAfter(photos[0], photos, 3);
      final second = PhotoPairLayout.windowAfter(photos[3], photos, 3);

      final partnerOfFirst = PhotoPairLayout.partnerFor(
        primary: photos[0],
        candidates: first,
        pairing: PhotoPairing.portraitSideBySide,
      );
      final partnerOfSecond = PhotoPairLayout.partnerFor(
        primary: photos[3],
        candidates: second,
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partnerOfFirst, isNotNull);
      expect(partnerOfSecond, isNotNull);
      expect(partnerOfFirst!.file.path, isNot(partnerOfSecond!.file.path));
    });

    test('the head of the list no longer freezes the partner', () {
      // With the old fixed head window, the primary at the end of a long
      // collection could only ever pair with the first portrait of the list.
      final photos = collection(40, 0);
      final primary = photos[35];
      final window = PhotoPairLayout.windowAfter(primary, photos, 3);

      final partner = PhotoPairLayout.partnerFor(
        primary: primary,
        candidates: window,
        pairing: PhotoPairing.portraitSideBySide,
      );

      expect(partner, isNotNull);
      expect(partner!.file.path, isNot(endsWith('/p0.jpg')));
    });
  });
}
