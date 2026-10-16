import '../../domain/interfaces/playlist_strategy.dart';
import '../../domain/models/photo_entry.dart';

/// Date a chronological order is based on.
enum PhotoOrderField {
  /// Capture date, falling back to the file creation date.
  ///
  /// Uses [PhotoEntry.bestCaptureDate], so photos without EXIF sort on the date
  /// encoded in their file name before falling back to the file dates.
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
  /// that was never shown sorts on the date in its file name, then on its file
  /// date, until EXIF arrives.
  DateTime dateOf(PhotoEntry photo) => switch (this) {
        PhotoOrderField.exif =>
          photo.bestCaptureDate ?? photo.createdAt ?? photo.date,
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

    final sorted = _sortedOrder(availablePhotos);

    _index = sorted.indexWhere(
      (photo) => photo.file.path == _currentPath,
    );
    _index = (_index + 1) % sorted.length;

    final photo = sorted[_index];
    _currentPath = photo.file.path;
    return photo;
  }

  @override
  List<PhotoEntry> peekNextPhotos(List<PhotoEntry> availablePhotos, int count) {
    if (availablePhotos.isEmpty || count <= 0) return const [];

    final sorted = _sortedOrder(availablePhotos);
    var index = sorted.indexWhere(
      (photo) => photo.file.path == _currentPath,
    );

    final result = <PhotoEntry>[];
    while (result.length < count && result.length < sorted.length) {
      index = (index + 1) % sorted.length;
      result.add(sorted[index]);
    }
    return result;
  }

  /// The collection in walking order. Rebuilt on every call because EXIF dates
  /// arrive while the frame runs.
  List<PhotoEntry> _sortedOrder(List<PhotoEntry> availablePhotos) {
    return availablePhotos.toList()
      ..sort((a, b) {
        final byDate = field.dateOf(a).compareTo(field.dateOf(b));
        // Photos sharing a date, e.g. a whole burst, keep a stable order.
        return byDate != 0 ? byDate : a.file.path.compareTo(b.file.path);
      });
  }
}
