import '../../domain/interfaces/playlist_strategy.dart';
import 'random_playlist_strategy.dart';
import 'sorted_playlist_strategy.dart';

/// Creates the playlist strategy a configured photo order refers to.
abstract final class PlaylistStrategies {
  /// Orders the settings offer, and the only values a config file may hold.
  static const orders = ['random', 'exif', 'creation', 'modification'];

  /// Order used when nothing is configured or a stored value is not offered
  /// any more, e.g. the removed freshness weighted shuffle.
  static const fallback = 'random';

  /// Returns the strategy for [order], falling back to [fallback] for anything
  /// unknown.
  static PlaylistStrategy create(String order) => switch (order) {
        'random' => RandomPlaylistStrategy(),
        'exif' => SortedPlaylistStrategy(PhotoOrderField.exif),
        'creation' => SortedPlaylistStrategy(PhotoOrderField.creation),
        'modification' => SortedPlaylistStrategy(PhotoOrderField.modification),
        _ => RandomPlaylistStrategy(),
      };
}
