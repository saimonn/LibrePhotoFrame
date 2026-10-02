import 'dart:math';

import '../../domain/interfaces/playlist_strategy.dart';
import '../../domain/models/photo_entry.dart';

/// Picks the next photo at random, favouring the photos the frame has not
/// shown recently.
///
/// Every photo that is not in the recent history gets the weight 1. A photo
/// that was shown recently is weighted by its rank: 0.01 for the photo shown
/// last, 0.02 for the one before, and so on up to [rememberedPhotos], so a
/// collection of any size keeps turning through all of its photos while a
/// photo that just passed by is unlikely to come back right away.
class RandomPlaylistStrategy implements PlaylistStrategy {
  /// How many slides stay in the history. The photo shown last gets 0.01, so
  /// the oldest remembered photo gets the weight of an unseen one.
  static const int rememberedPhotos = 100;

  final Random _random;

  /// Shown photos, most recent first. Each entry holds the photos shown
  /// together in split mode, which share a single rank. Compared by path
  /// because a rescan replaces the PhotoEntry objects.
  final List<List<String>> _history = [];

  RandomPlaylistStrategy({Random? random}) : _random = random ?? Random();

  @override
  String get id => 'random';

  @override
  String get name => 'Random order';

  @override
  void recordShown(List<PhotoEntry> photos) {
    if (photos.isEmpty) return;

    final paths = photos.map((photo) => photo.file.path).toSet();
    _history.removeWhere((group) => group.any(paths.contains));
    _history.insert(0, paths.toList());
    if (_history.length > rememberedPhotos) {
      _history.removeLast();
    }
  }

  @override
  PhotoEntry? nextPhoto(List<PhotoEntry> availablePhotos) {
    if (availablePhotos.isEmpty) return null;

    var totalWeight = 0.0;
    final weights = <PhotoEntry, double>{};
    for (final photo in availablePhotos) {
      final weight = _weightFor(photo.file.path);
      weights[photo] = weight;
      totalWeight += weight;
    }

    var point = _random.nextDouble() * totalWeight;
    for (final photo in availablePhotos) {
      point -= weights[photo]!;
      if (point <= 0) return photo;
    }
    return availablePhotos.last;
  }

  /// Weight of a photo: its rank in the history divided by
  /// [rememberedPhotos], or 1 when the frame never showed it.
  double _weightFor(String path) {
    for (var rank = 0; rank < _history.length; rank++) {
      if (_history[rank].contains(path)) {
        return (rank + 1) / rememberedPhotos;
      }
    }
    return 1;
  }
}
