import '../../domain/interfaces/playlist_strategy.dart';
import '../../domain/models/photo_entry.dart';

/// Date a chronological order is based on.
enum PhotoOrderField {
  /// EXIF capture date, falling back to the file creation date.
  exif('exif', 'By capture time'),

  /// File creation date, falling back to the file modification date when the
  /// platform does not report one.
  creation('creation', 'By file creation time'),

  /// File modification date.
  modification('modification', 'By file modification time');

  const PhotoOrderField(this.id, this.name);

  final String id;
  final String name;

  /// Date this order sorts by, falling back to the next date that is known.
  ///
  /// The EXIF capture date is only read when a photo is displayed, so a photo
  /// that was never shown sorts on its file date until then.
  DateTime dateOf(PhotoEntry photo) => switch (this) {
        PhotoOrderField.exif =>
          photo.captureDate ?? photo.createdAt ?? photo.date,
        PhotoOrderField.creation => photo.createdAt ?? photo.date,
        PhotoOrderField.modification => photo.date,
      };
}

/// Shows the whole collection in a fixed order, oldest photo first, and starts
/// over at the end.
///
/// EXIF dates arrive while the frame runs, so the order is rebuilt on every
/// draw and the walk continues from the photo on screen instead of jumping.
class SortedPlaylistStrategy implements PlaylistStrategy {
  final PhotoOrderField field;

  /// Path of the photo on screen, so a rebuild continues from it.
  String? _currentPath;

  /// Position of [_currentPath] in the last built order, -1 before the first.
  int _index = -1;

  SortedPlaylistStrategy(this.field);

  @override
  String get id => field.id;

  @override
  String get name => field.name;

  /// The walk order does not depend on what was shown before.
  @override
  void recordShown(List<PhotoEntry> photos) {}

  @override
  PhotoEntry? nextPhoto(List<PhotoEntry> availablePhotos) {
    if (availablePhotos.isEmpty) return null;

    final sorted = availablePhotos.toList()
      ..sort((a, b) {
        final byDate = field.dateOf(a).compareTo(field.dateOf(b));
        // Photos sharing a date, e.g. a whole burst, keep a stable order.
        return byDate != 0 ? byDate : a.file.path.compareTo(b.file.path);
      });

    _index = sorted.indexWhere(
      (photo) => photo.file.path == _currentPath,
    );
    _index = (_index + 1) % sorted.length;

    final photo = sorted[_index];
    _currentPath = photo.file.path;
    return photo;
  }
}
