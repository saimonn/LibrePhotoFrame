import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart';

/// One row of the `photos` table: everything that is known about a photo
/// without opening its file.
///
/// All fields are optional: a filesystem scan only knows path/mtime/size, and
/// EXIF and pixel dimensions are filled in later, when the photo is displayed.
class PhotoMetadata {
  const PhotoMetadata({
    required this.path,
    this.assetId,
    this.modified,
    this.size,
    this.width,
    this.height,
    this.captureDate,
    this.latitude,
    this.longitude,
    this.exifLoaded = false,
  });

  /// Absolute path of the photo file.
  final String path;

  /// MediaStore asset id. Filesystem photos have none.
  final String? assetId;

  /// File modification date, the key that tells a scan whether a name is
  /// still the same file.
  final DateTime? modified;

  /// File size in bytes (filesystem) or width*height (MediaStore).
  final int? size;

  final int? width;
  final int? height;
  final DateTime? captureDate;
  final double? latitude;
  final double? longitude;

  /// Whether the EXIF was already read (possibly with no data).
  final bool exifLoaded;
}

/// Cached reverse-geocoding result for one rounded coordinate.
class PlaceRecord {
  const PlaceRecord({required this.name, required this.resolvedAt});

  /// Place name, or null when the coordinate has no readable address.
  final String? name;
  final DateTime resolvedAt;
}

/// Persistent cache of photo metadata, backed by single SQLite database.
///
/// The three caches that used to live in separate places (JSON file, shared
/// preferences, in-memory only) are merged into one small file:
///
///  * `photos` - per-photo scan state (mtime, size) plus the metadata decoded
///    from the file (EXIF capture date, GPS, pixel dimensions). MediaStore
///    rows also carry the asset id, so a poll can reuse the resolved file path
///    instead of asking the platform for every photo.
///  * `places`  - reverse-geocoded place names by rounded coordinate.
///  * `meta`    - bookkeeping, currently the last full scan time.
///
/// All methods are synchronous: the dataset stays around a few hundred rows,
/// so a query costs microseconds and SQLite's WAL mode makes the reads cheap
/// even while the periodic scans write.
class PhotoMetadataDatabase {
  PhotoMetadataDatabase._(this._db) {
    _db.execute('PRAGMA journal_mode = WAL;');
    _createTables();
  }

  factory PhotoMetadataDatabase.open(String path) {
    Database db;
    try {
      db = sqlite3.open(path);
      // Fail fast on a file that was never a valid database.
      db.select('SELECT 1');
    } catch (_) {
      _log.warning(
        'Discarding unreadable metadata database at $path',
      );
      _deleteFile(path);
      db = sqlite3.open(path);
    }
    return PhotoMetadataDatabase._(db);
  }

  /// In-memory database, used by tests (and as a graceful fallback when no
  /// writable directory is available).
  factory PhotoMetadataDatabase.openInMemory() =>
      PhotoMetadataDatabase._(sqlite3.openInMemory());

  static final _log = Logger('PhotoMetadataDatabase');

  final Database _db;

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS photos (
        path TEXT PRIMARY KEY,
        asset_id TEXT,
        modified INTEGER,
        size INTEGER,
        width INTEGER,
        height INTEGER,
        capture_date INTEGER,
        latitude REAL,
        longitude REAL,
        exif_loaded INTEGER NOT NULL DEFAULT 0
      );
    ''');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_photos_asset ON photos(asset_id);');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS places (
        key TEXT PRIMARY KEY,
        name TEXT,
        resolved_at INTEGER NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  // ============================================================
  // Photos
  // ============================================================

  /// All rows that belong to filesystem photos, keyed by path.
  Map<String, PhotoMetadata> filePhotos() {
    final result = <String, PhotoMetadata>{};
    for (final row in _db.select('SELECT * FROM photos WHERE asset_id IS NULL')) {
      final photo = _photoFromRow(row);
      result[photo.path] = photo;
    }
    return result;
  }

  /// All rows that belong to MediaStore photos, keyed by asset id.
  Map<String, PhotoMetadata> mediaStorePhotos() {
    final result = <String, PhotoMetadata>{};
    for (final row in _db.select('SELECT * FROM photos WHERE asset_id IS NOT NULL')) {
      final photo = _photoFromRow(row);
      final assetId = photo.assetId;
      if (assetId != null) result[assetId] = photo;
    }
    return result;
  }

  /// The row of [path], or null when the photo is not in the cache yet.
  PhotoMetadata? photoByPath(String path) {
    final rows = _db.select('SELECT * FROM photos WHERE path = ?', [path]);
    return rows.isEmpty ? null : _photoFromRow(rows.first);
  }

  PhotoMetadata _photoFromRow(Row row) {
    return PhotoMetadata(
      path: row['path'] as String,
      assetId: row['asset_id'] as String?,
      modified: _millis(row['modified']),
      size: row['size'] as int?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      captureDate: _millis(row['capture_date']),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      exifLoaded: row['exif_loaded'] == 1,
    );
  }

  /// Records what a filesystem scan saw for each photo, in one transaction:
  /// path, modification date and size. The other columns (EXIF, asset id) are
  /// left untouched.
  void saveScannedFiles(
    Iterable<({String path, DateTime modified, int size})> photos,
  ) {
    _transaction(() {
      final statement = _db.prepare('''
        INSERT INTO photos (path, modified, size) VALUES (?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET
          modified = excluded.modified,
          size = excluded.size
      ''');
      try {
        for (final photo in photos) {
          statement.execute([
            photo.path,
            photo.modified.millisecondsSinceEpoch,
            photo.size,
          ]);
        }
      } finally {
        statement.close();
      }
    });
  }

  /// Records a MediaStore photo: the resolved file path plus everything the
  /// platform already knows (asset id, dates, dimensions). A later poll can
  /// reuse [path] for this asset id without asking the platform again.
  void saveMediaStorePhoto({
    required String path,
    required String assetId,
    required DateTime modified,
    required int size,
    int? width,
    int? height,
    DateTime? captureDate,
  }) {
    _db.execute('''
      INSERT INTO photos
        (path, asset_id, modified, size, width, height, capture_date)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(path) DO UPDATE SET
        asset_id = excluded.asset_id,
        modified = excluded.modified,
        size = excluded.size,
        width = excluded.width,
        height = excluded.height,
        capture_date = excluded.capture_date
    ''', [
      path,
      assetId,
      modified.millisecondsSinceEpoch,
      size,
      width,
      height,
      captureDate?.millisecondsSinceEpoch,
    ]);
  }

  /// Records EXIF metadata (capture date, GPS) read from [path]'s file,
  /// marking it as read so it is never decoded again while the file keeps its
  /// modification date.
  void saveExif({
    required String path,
    required DateTime? modified,
    DateTime? captureDate,
    double? latitude,
    double? longitude,
  }) {
    _db.execute('''
      INSERT INTO photos
        (path, modified, exif_loaded, capture_date, latitude, longitude)
      VALUES (?, ?, 1, ?, ?, ?)
      ON CONFLICT(path) DO UPDATE SET
        modified = excluded.modified,
        exif_loaded = 1,
        capture_date = excluded.capture_date,
        latitude = excluded.latitude,
        longitude = excluded.longitude
    ''', [
      path,
      modified?.millisecondsSinceEpoch,
      captureDate?.millisecondsSinceEpoch,
      latitude,
      longitude,
    ]);
  }

  /// Records the pixel dimensions of [path] once they were read from the file
  /// header, so a restart can pair photos without decoding the header again.
  void saveDimensions({required String path, int? width, int? height}) {
    _db.execute('''
      INSERT INTO photos (path, width, height) VALUES (?, ?, ?)
      ON CONFLICT(path) DO UPDATE SET
        width = excluded.width,
        height = excluded.height
    ''', [path, width, height]);
  }

  /// Drops the filesystem rows whose path is no longer part of [paths].
  void deleteScannedFilesNotIn(Iterable<String> paths) {
    _deleteWhereNotIn(
      'DELETE FROM photos WHERE asset_id IS NULL AND path NOT IN (%s)',
      'DELETE FROM photos WHERE asset_id IS NULL',
      'path',
      paths,
    );
  }

  /// Drops the MediaStore rows whose asset id is no longer part of [assetIds].
  void deleteMediaStorePhotosNotIn(Iterable<String> assetIds) {
    _deleteWhereNotIn(
      'DELETE FROM photos WHERE asset_id IS NOT NULL AND asset_id NOT IN (%s)',
      'DELETE FROM photos WHERE asset_id IS NOT NULL',
      'asset_id',
      assetIds,
    );
  }

  /// Deletes all rows matching [column], optionally restricted to the values of
  /// [values] via a `NOT IN` clause. An empty [values] deletes everything.
  void _deleteWhereNotIn(
    String notInSql,
    String allSql,
    String column,
    Iterable<String> values,
  ) {
    final list = values.toList();
    if (list.isEmpty) {
      _db.execute(allSql);
      return;
    }
    final placeholders = List.filled(list.length, '?').join(',');
    _db.execute(notInSql.replaceFirst('%s', placeholders), list);
  }

  // ============================================================
  // Geocoding cache
  // ============================================================

  /// The cached result for [key] (rounded coordinates), or null when nothing
  /// is cached yet. A null [PlaceRecord.name] is a cached negative result.
  PlaceRecord? place(String key) {
    final rows = _db.select('SELECT * FROM places WHERE key = ?', [key]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return PlaceRecord(
      name: row['name'] as String?,
      resolvedAt: _millis(row['resolved_at'])!,
    );
  }

  void savePlace(String key, String? name) {
    _db.execute('''
      INSERT INTO places (key, name, resolved_at) VALUES (?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET
        name = excluded.name,
        resolved_at = excluded.resolved_at
    ''', [key, name, DateTime.now().millisecondsSinceEpoch]);
  }

  /// Drops cached places that have not been used for [maxAge], so the table
  /// cannot grow without bound.
  void prunePlacesOlderThan(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    _db.execute('DELETE FROM places WHERE resolved_at < ?', [cutoff]);
  }

  void clearPlaces() => _db.execute('DELETE FROM places');

  // ============================================================
  // Bookkeeping
  // ============================================================

  /// When the last full scan ran, null when there never was one.
  DateTime? get lastFullScan {
    final rows = _db.select("SELECT value FROM meta WHERE key = 'last_full_scan'");
    if (rows.isEmpty) return null;
    return _millis(int.parse(rows.first['value'] as String));
  }

  set lastFullScan(DateTime value) {
    _db.execute('''
      INSERT INTO meta (key, value) VALUES ('last_full_scan', ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
    ''', [value.millisecondsSinceEpoch.toString()]);
  }

  // ============================================================
  // Plumbing
  // ============================================================

  void close() => _db.close();

  void _transaction(void Function() action) {
    _db.execute('BEGIN');
    try {
      action();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  static DateTime? _millis(dynamic value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);

  static void _deleteFile(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {
      // Best effort: the corrupted file only costs a few bytes of cache.
    }
  }
}