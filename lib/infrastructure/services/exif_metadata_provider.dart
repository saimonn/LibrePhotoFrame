import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:exif_reader/exif_reader.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/interfaces/metadata_provider.dart';

/// MetadataProvider that extracts EXIF data (capture date, GPS) from photos.
/// Only reads the first 512KB of the file for performance (EXIF is typically at the start).
///
/// Results are kept in a small cache in the application cache directory, keyed
/// by file path and modification date: reading and parsing EXIF costs a file
/// read per photo, and the frames that show a photo again after a restart
/// would otherwise pay it every time.
class ExifMetadataProvider implements MetadataProvider {
  static const String _cacheFileName = 'exif_metadata_cache.json';

  /// How long new results are collected before the cache is written.
  static const Duration _saveDelay = Duration(seconds: 2);

  final _log = Logger('ExifMetadataProvider');

  /// Maximum bytes to read for EXIF data (512KB ensures we catch all GPS data)
  static const int _maxExifBytes = 512 * 1024;

  final Future<Directory> Function() _cacheDirectoryProvider;

  /// EXIF results of the photos read so far, by path.
  final Map<String, _CachedMetadata> _cache = {};

  File? _cacheFile;
  Future<void>? _loadingCache;
  Timer? _saveTimer;

  ExifMetadataProvider({Future<Directory> Function()? cacheDirectoryProvider})
      : _cacheDirectoryProvider =
            cacheDirectoryProvider ?? getApplicationCacheDirectory;

  @override
  Future<ExifMetadata> getExifMetadata(File file) async {
    await _loadCache();

    final cached = await _lookup(file);
    if (cached != null) {
      return cached;
    }

    final metadata = await _readExif(file);
    final modified = await _modified(file);
    if (modified != null) {
      _cache[file.path] = _CachedMetadata(modified, metadata);
      _scheduleSave();
    }
    return metadata;
  }

  Future<ExifMetadata> _readExif(File file) async {
    try {
      // Only read first 512KB - EXIF is typically at the start of the file
      final bytes = await _readFirstBytes(file, _maxExifBytes);
      final exifResult = await readExifFromBytes(bytes);

      if (exifResult.tags.isEmpty) {
        _log.fine('No EXIF data in ${file.path}');
        return const ExifMetadata();
      }

      // Extract capture date (optional)
      final captureDate = _extractCaptureDate(exifResult.tags);

      // Extract GPS coordinates (optional)
      final location = _extractGpsCoordinates(exifResult.tags);

      return ExifMetadata(captureDate: captureDate, location: location);
    } catch (e) {
      _log.warning('Error reading EXIF from ${file.path}: $e');
      return const ExifMetadata();
    }
  }

  /// Returns the cached metadata of [file] when the file did not change since
  /// it was cached.
  Future<ExifMetadata?> _lookup(File file) async {
    final modified = await _modified(file);
    final cached = _cache[file.path];
    if (modified == null || cached == null || cached.modified != modified) {
      return null;
    }
    return cached.metadata;
  }

  Future<DateTime?> _modified(File file) async {
    try {
      return (await file.stat()).modified;
    } catch (e) {
      _log.fine('Could not stat ${file.path}: $e');
      return null;
    }
  }

  Future<void> _loadCache() => _loadingCache ??= _readCache();

  Future<void> _readCache() async {
    try {
      final directory = await getApplicationCacheDirectory();
      _cacheFile = File('${directory.path}/$_cacheFileName');
      if (!await _cacheFile!.exists()) return;

      final decoded = jsonDecode(await _cacheFile!.readAsString());
      if (decoded is! Map<String, dynamic>) return;

      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final cached = _CachedMetadata.tryParse(value);
          if (cached != null) _cache[entry.key] = cached;
        }
      }
      _log.fine('EXIF cache holds ${_cache.length} photo(s)');
    } catch (e) {
      _log.warning('Could not read the EXIF cache: $e');
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _writeCache);
  }

  Future<void> _writeCache() async {
    final file = _cacheFile;
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode({
        for (final entry in _cache.entries) entry.key: entry.value.toJson(),
      }));
    } catch (e) {
      _log.warning('Could not write the EXIF cache: $e');
    }
  }

  /// Reads only the first [maxBytes] from a file
  Future<Uint8List> _readFirstBytes(File file, int maxBytes) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final length = await raf.length();
      final bytesToRead = length < maxBytes ? length : maxBytes;
      return Uint8List.fromList(await raf.read(bytesToRead));
    } finally {
      await raf.close();
    }
  }

  /// Extracts the original capture date from EXIF data.
  DateTime? _extractCaptureDate(Map<String, IfdTag> exifData) {
    // Try DateTimeOriginal first (when photo was taken)
    // Then DateTimeDigitized (when photo was digitized)
    // Then DateTime (file modification time in EXIF)
    final dateTag = exifData['EXIF DateTimeOriginal'] ??
        exifData['EXIF DateTimeDigitized'] ??
        exifData['Image DateTime'];

    if (dateTag == null) return null;

    try {
      // EXIF date format: "2024:12:25 14:30:00"
      final dateString = dateTag.printable;
      return _parseExifDate(dateString);
    } catch (e) {
      _log.fine('Could not parse EXIF date: ${dateTag.printable}');
      return null;
    }
  }

  /// Parses EXIF date format "YYYY:MM:DD HH:MM:SS"
  DateTime? _parseExifDate(String dateString) {
    // Format: "2024:12:25 14:30:00"
    final regex = RegExp(r'(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})');
    final match = regex.firstMatch(dateString);

    if (match == null) return null;

    return DateTime(
      int.parse(match.group(1)!), // year
      int.parse(match.group(2)!), // month
      int.parse(match.group(3)!), // day
      int.parse(match.group(4)!), // hour
      int.parse(match.group(5)!), // minute
      int.parse(match.group(6)!), // second
    );
  }

  /// Extracts GPS coordinates from EXIF data.
  GpsCoordinates? _extractGpsCoordinates(Map<String, IfdTag> exifData) {
    final latTag = exifData['GPS GPSLatitude'];
    final latRefTag = exifData['GPS GPSLatitudeRef'];
    final lonTag = exifData['GPS GPSLongitude'];
    final lonRefTag = exifData['GPS GPSLongitudeRef'];

    if (latTag == null || lonTag == null) return null;

    try {
      final latitude = _convertGpsToDecimal(latTag.values, latRefTag?.printable);
      final longitude = _convertGpsToDecimal(lonTag.values, lonRefTag?.printable);

      if (latitude == null || longitude == null) return null;

      return GpsCoordinates(latitude, longitude);
    } catch (e) {
      _log.fine('Could not parse GPS coordinates: $e');
      return null;
    }
  }

  /// Converts GPS coordinates from EXIF format (degrees, minutes, seconds) to decimal.
  double? _convertGpsToDecimal(IfdValues? values, String? ref) {
    if (values == null) return null;

    // GPS values are stored as [degrees, minutes, seconds] as Ratios
    final ratios = values.toList();
    if (ratios.length < 3) return null;

    final degrees = _ratioToDouble(ratios[0]);
    final minutes = _ratioToDouble(ratios[1]);
    final seconds = _ratioToDouble(ratios[2]);

    if (degrees == null || minutes == null || seconds == null) return null;

    double decimal = degrees + (minutes / 60) + (seconds / 3600);

    // South and West are negative
    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }

    return decimal;
  }

  /// Converts a Ratio to double.
  double? _ratioToDouble(dynamic value) {
    if (value is Ratio) {
      if (value.denominator == 0) return null;
      return value.numerator / value.denominator;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    return null;
  }
}

/// EXIF result of one photo, together with the modification date of the file it
/// was read from: a changed file has to be read again.
class _CachedMetadata {
  _CachedMetadata(this.modified, this.metadata);

  final DateTime modified;
  final ExifMetadata metadata;

  Map<String, dynamic> toJson() => {
        'm': modified.millisecondsSinceEpoch,
        'c': metadata.captureDate?.millisecondsSinceEpoch,
        'lat': metadata.location?.latitude,
        'lon': metadata.location?.longitude,
      };

  static _CachedMetadata? tryParse(Map<String, dynamic> json) {
    final modified = json['m'];
    if (modified is! int) return null;

    final capture = json['c'];
    final latitude = json['lat'];
    final longitude = json['lon'];
    return _CachedMetadata(
      DateTime.fromMillisecondsSinceEpoch(modified),
      ExifMetadata(
        captureDate: capture is int
            ? DateTime.fromMillisecondsSinceEpoch(capture)
            : null,
        location: latitude is num && longitude is num
            ? GpsCoordinates(latitude.toDouble(), longitude.toDouble())
            : null,
      ),
    );
  }
}
