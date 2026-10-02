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
}
