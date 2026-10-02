import 'dart:math';

import '../../domain/interfaces/playlist_strategy.dart';
import '../../domain/models/photo_entry.dart';

/// Picks the next photo at random, without favouring recent photos the way
/// WeightedFreshnessStrategy does.
class RandomPlaylistStrategy implements PlaylistStrategy {
  final Random _random;

  /// Photo shown last, kept out of the next draw so the same photo is never
  /// shown twice in a row. Compared by path because a rescan replaces the
  /// PhotoEntry objects.
  PhotoEntry? _previous;

  RandomPlaylistStrategy({Random? random}) : _random = random ?? Random();

  @override
  String get id => 'random';

  @override
  String get name => 'Random order';

  @override
  PhotoEntry? nextPhoto(List<PhotoEntry> availablePhotos) {
    if (availablePhotos.isEmpty) return null;

    final candidates = _previous == null
        ? availablePhotos
        : availablePhotos
              .where((photo) => photo.file.path != _previous!.file.path)
              .toList();

    // A collection holding a single photo always shows that photo.
    final photo = candidates.isEmpty
        ? availablePhotos.first
        : candidates[_random.nextInt(candidates.length)];

    _previous = photo;
    return photo;
  }
}