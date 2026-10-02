import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/strategies/playlist_strategies.dart';
import 'package:libre_photo_frame/infrastructure/strategies/random_playlist_strategy.dart';
import 'package:libre_photo_frame/infrastructure/strategies/weighted_freshness_strategy.dart';

void main() {
  group('PlaylistStrategies', () {
    test('creates the strategy named by the configured order', () {
      expect(
        PlaylistStrategies.create('random'),
        isA<RandomPlaylistStrategy>(),
      );
      expect(
        PlaylistStrategies.create('weighted_freshness'),
        isA<WeightedFreshnessStrategy>(),
      );
    });

    test('falls back to the freshness shuffle for an unknown order', () {
      expect(
        PlaylistStrategies.create('something_else'),
        isA<WeightedFreshnessStrategy>(),
      );
    });

    test('matches the id of the created strategy, so it is not swapped twice', () {
      for (final order in ['random', 'weighted_freshness', 'unknown']) {
        expect(PlaylistStrategies.create(order).id, order == 'random' ? 'random' : 'weighted_freshness');
      }
    });
  });
}