import 'dart:io';

/// Shape of a photo, derived from its pixel dimensions.
///
/// Square photos are reported as [PhotoShape.square] so callers can decide
/// whether they are worth pairing (see [PhotoPairLayout]).
enum PhotoShape { portrait, landscape, square }

class PhotoEntry {
  final File file;
  /// File modification date - used for shuffle algorithm
  final DateTime date;
  final int sizeBytes;
  
  // EXIF metadata - loaded lazily when photo is displayed
  // null = not yet loaded, use _exifLoaded to check if loading was attempted
  bool _exifLoaded = false;
  DateTime? _captureDate;
  double? _latitude;
  double? _longitude;
  
  // Runtime properties (not persisted)
  double weight = 0;
  DateTime? lastShown;

  // Pixel dimensions - loaded lazily, see [PhotoDimensionsService].
  int? _width;
  int? _height;
  bool _dimensionsResolved = false;

  PhotoEntry({
    required this.file,
    required this.date,
    required this.sizeBytes,
    int? width,
    int? height,
  })  : _width = width,
        _height = height,
        _dimensionsResolved = width != null && height != null;

  /// Returns true if EXIF data has been loaded (or attempted to load)
  bool get exifLoaded => _exifLoaded;
  
  /// Original capture date from EXIF (DateTimeOriginal)
  DateTime? get captureDate => _captureDate;
  
  /// GPS latitude
  double? get latitude => _latitude;
  
  /// GPS longitude  
  double? get longitude => _longitude;

  /// Returns true if GPS coordinates are available
  bool get hasLocation => _latitude != null && _longitude != null;
  
  /// Returns true if EXIF capture date is available
  bool get hasCaptureDate => _captureDate != null;
  
  /// Set EXIF metadata after lazy loading
  void setExifMetadata({DateTime? captureDate, double? latitude, double? longitude}) {
    _exifLoaded = true;
    _captureDate = captureDate;
    _latitude = latitude;
    _longitude = longitude;
  }

  // ===== Pixel dimensions =====

  /// Whether the dimensions were already loaded (or loading was attempted).
  bool get dimensionsResolved => _dimensionsResolved;

  /// Pixel width, or null when not known yet.
  int? get width => _width;

  /// Pixel height, or null when not known yet.
  int? get height => _height;

  /// Shape of the photo, or null while the dimensions are unknown.
  ///
  /// EXIF orientation is deliberately ignored: the pairing only needs to know
  /// whether a photo is taller or wider than the frame.
  PhotoShape? get shape {
    final w = _width;
    final h = _height;
    if (!_dimensionsResolved || w == null || h == null || w <= 0 || h <= 0) {
      return null;
    }
    if (w == h) return PhotoShape.square;
    return h > w ? PhotoShape.portrait : PhotoShape.landscape;
  }

  /// True when this photo is taller than wide and its dimensions are known.
  bool get isPortrait => shape == PhotoShape.portrait;

  /// True when this photo is wider than tall and its dimensions are known.
  bool get isLandscape => shape == PhotoShape.landscape;

  /// Stores the pixel dimensions once they have been read from the file.
  ///
  /// Unreadable or non-image files get nulls, which makes [shape] null and
  /// keeps such photos out of pairing.
  void setDimensions(int? width, int? height) {
    _dimensionsResolved = true;
    _width = width;
    _height = height;
  }

  @override
  String toString() => 'PhotoEntry(path: ${file.path}, date: $date, captureDate: $_captureDate, location: ${hasLocation ? "($_latitude, $_longitude)" : "none"})';
}
