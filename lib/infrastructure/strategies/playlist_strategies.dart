import '../../domain/interfaces/playlist_strategy.dart';
import 'random_playlist_strategy.dart';
import 'weighted_freshness_strategy.dart';

/// Creates the playlist strategy a configured photo order refers to.
abstract final class PlaylistStrategies {
  /// Returns the strategy whose id is [order], falling back to the freshness
  /// weighted shuffle for anything unknown.
  static PlaylistStrategy create(String order) {
    switch (order) {
      case 'random':
        return RandomPlaylistStrategy();
      default:
        return WeightedFreshnessStrategy();
    }
  }
}