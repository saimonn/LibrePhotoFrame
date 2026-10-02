import 'dart:ui' as ui;

import 'package:logging/logging.dart';

import '../../domain/models/photo_entry.dart';

/// Reads the pixel dimensions of a photo without decoding the whole image.
///
/// Decoding every photo up front would be far too slow on a Raspberry Pi-class
/// frame, so dimensions are resolved lazily and then cached on the
/// [PhotoEntry] for the lifetime of the scan.
class PhotoDimensionsService {
  PhotoDimensionsService();

  final _log = Logger('PhotoDimensionsService');

  final Map<String, Future<PhotoShape?>> _inFlight = {};

  /// Resolves the dimensions of [photo], caching the result on the entry.
  ///
  /// Returns the photo's shape, or null when the file cannot be read or holds
  /// no image. Concurrent calls for the same entry share one decode.
  Future<PhotoShape?> shapeOf(PhotoEntry photo) async {
    if (photo.dimensionsResolved) return photo.shape;

    final inFlight = _inFlight[photo.file.path];
    if (inFlight != null) return inFlight;

    final future = _read(photo).whenComplete(() {
      _inFlight.remove(photo.file.path);
    });
    _inFlight[photo.file.path] = future;
    return future;
  }

  Future<PhotoShape?> _read(PhotoEntry photo) async {
    // ImageDescriptor.encoded only parses the container header, so this reads
    // the width/height without decoding pixels. instantiateImageCodec would
    // decode every candidate in full, which is far too slow when the
    // slideshow resolves dimensions for a pool of photos on every slide.
    final buffer = await ui.ImmutableBuffer.fromFilePath(photo.file.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final width = descriptor.width;
        final height = descriptor.height;
        if (width <= 0 || height <= 0) {
          photo.setDimensions(null, null);
          return null;
        }
        photo.setDimensions(width, height);
        return photo.shape;
      } finally {
        descriptor.dispose();
      }
    } catch (e) {
      // Not a decodable image (or unreadable): leave it unpaired rather than
      // breaking the slideshow.
      _log.fine('Could not read dimensions of ${photo.file.path}: $e');
      photo.setDimensions(null, null);
      return null;
    } finally {
      buffer.dispose();
    }
  }

  void dispose() {
    _inFlight.clear();
  }
}
