import 'package:flutter/material.dart';

import '../../domain/services/photo_pair_layout.dart';
import '../../ui/widgets/photo_slide.dart';
import 'photo_service.dart';

/// Warms the image cache for the photos of the upcoming slide so transitions
/// stay smooth on slower devices.
///
/// The next lot is previewed without moving the play position, and every photo
/// of it (one, or two in split mode) is decoded at the size the slide will ask
/// for.
class ImagePrefetcher {
  ImagePrefetcher({
    required PhotoService photoService,
    required BuildContext context,
    required Size? Function() screenSizeGetter,
  })  : _photoService = photoService,
        _context = context,
        _screenSizeGetter = screenSizeGetter;

  final PhotoService _photoService;
  final BuildContext _context;
  final Size? Function() _screenSizeGetter;

  /// How many upcoming photos to warm. Two covers a split slide (a pair).
  static const int _prefetchCount = 2;

  Future<void> prefetchNext() async {
    final size = _screenSizeGetter();
    if (size == null) return;

    final pairing = PhotoPairLayout.forScreen(size.width, size.height);
    for (final photo in _photoService.peekUpcoming(_prefetchCount)) {
      final cell = PhotoSlide.cellSize(
        size,
        PhotoPairLayout.isPaired(pairing) &&
                PhotoPairLayout.accepts(pairing, photo)
            ? pairing
            : PhotoPairing.single,
      );
      try {
        await precacheImage(
          PhotoSlide.createOptimizedProvider(photo.file, cell),
          _context,
        );
      } catch (_) {
        // A photo that cannot be decoded is skipped; the slide still shows it.
      }
    }
  }
}
