import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../domain/interfaces/config_provider.dart';
import '../../domain/interfaces/metadata_provider.dart';
import '../../domain/models/photo_entry.dart';
import '../../infrastructure/services/geocoding_service.dart';

final _log = Logger('PhotoEnrichmentController');

/// Groups EXIF loading and reverse geocoding for photos shown on screen.
/// Maintains a cache of location names keyed by photo file path that is
/// cleared whenever the set of displayed photos changes.
class PhotoEnrichmentController extends ChangeNotifier {
  PhotoEnrichmentController({
    required GeocodingService geocodingService,
    required MetadataProvider metadataProvider,
  })  : _geocodingService = geocodingService,
        _metadataProvider = metadataProvider;

  final GeocodingService _geocodingService;
  final MetadataProvider _metadataProvider;

  /// Location names (from geocoding) of the photos on screen, by file path.
  /// Cleared whenever a photo takes the frame, so a name never outlives the
  /// photo it belongs to.
  final Map<String, String> _locationNames = {};

  Map<String, String> get locationNames => _locationNames;

  /// Whether [photo] is currently tracked as on screen.
  bool isOnScreen(PhotoEntry photo) {
    final path = photo.file.path;
    return _locationNames.containsKey(path) ||
        _currentPhotoPaths.contains(path);
  }

  final Set<String> _currentPhotoPaths = <String>{};

  /// Clears cached location names and tracked on-screen photos.
  void clear() {
    if (_locationNames.isNotEmpty || _currentPhotoPaths.isNotEmpty) {
      _locationNames.clear();
      _currentPhotoPaths.clear();
      notifyListeners();
    }
  }

  /// Loads EXIF metadata and reverse-geocodes location names for the photos
  /// that take the frame. Clears previous cached names first.
  Future<void> enrichDisplayedPhotos(
    PhotoEntry photo,
    PhotoEntry? partner,
    ConfigProvider config, {
    required bool mounted,
    required void Function() onPhotoUpdated,
    bool Function(PhotoEntry photo)? isOnScreenOverride,
  }) async {
    _currentPhotoPaths
      ..clear()
      ..add(photo.file.path)
      ..addAll(partner == null ? const [] : [partner.file.path]);

    if (_locationNames.isNotEmpty) {
      _locationNames.clear();
      notifyListeners();
    }

    await _enrichPhoto(photo, config, mounted, onPhotoUpdated,
        isOnScreenOverride);
    if (partner != null) {
      await _enrichPhoto(partner, config, mounted, onPhotoUpdated,
          isOnScreenOverride);
    }
  }

  Future<void> _enrichPhoto(
    PhotoEntry photo,
    ConfigProvider config,
    bool mounted,
    void Function() onPhotoUpdated,
    bool Function(PhotoEntry photo)? isOnScreenOverride,
  ) async {
    final isOnScreenCheck = isOnScreenOverride ?? isOnScreen;

    // Load EXIF data lazily if not already loaded
    if (!photo.exifLoaded) {
      try {
        final exif = await _metadataProvider.getExifMetadata(photo.file);
        photo.setExifMetadata(
          // Keep the media store date when the file carries no EXIF date.
          captureDate: exif.captureDate ?? photo.captureDate,
          latitude: exif.location?.latitude,
          longitude: exif.location?.longitude,
        );
        if (mounted) {
          onPhotoUpdated();
        }
      } catch (e) {
        _log.warning('Failed to load EXIF for ${photo.file.path}: $e');
        photo.setExifMetadata(); // Mark as loaded (with no data)
      }
    }

    final fileName = photo.file.path.split('/').last;
    final buffer = StringBuffer('Displaying: $fileName');
    buffer.write(' | File date: ${photo.date}');
    if (photo.hasCaptureDate) {
      buffer.write(' | Capture date: ${photo.captureDate}');
    }
    if (photo.hasLocation) {
      buffer.write(
          ' | GPS: (${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)})');
      if (config.geocodingEnabled) {
        try {
          final location = await _geocodingService.getLocationName(
              photo.latitude!, photo.longitude!);
          if (location != null && location.isNotEmpty) {
            _log.info('Location: $location');
            if (mounted && isOnScreenCheck(photo)) {
              _locationNames[photo.file.path] = location;
              notifyListeners();
              // The overlay shows the name, so the frame has to repaint once
              // the lookup returns.
              onPhotoUpdated();
            }
          }
        } catch (e) {
          _log.warning('Failed to geocode for ${photo.file.path}: $e');
        }
      }
    }
    _log.info(buffer.toString());
  }

  @override
  void dispose() {
    _locationNames.clear();
    _currentPhotoPaths.clear();
    super.dispose();
  }
}