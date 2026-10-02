import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/strategies/playlist_strategies.dart';
import 'package:libre_photo_frame/infrastructure/strategies/random_playlist_strategy.dart';
import 'package:libre_photo_frame/infrastructure/strategies/sorted_playlist_strategy.dart';

void main() {
  group('PlaylistStrategies', () {
    test('creates the strategy named by the configured order', () {
      expect(PlaylistStrategies.create('random'), isA<RandomPlaylistStrategy>());
      expect(
        PlaylistStrategies.create('creation'),
        isA<SortedPlaylistStrategy>()
            .having((s) => s.field, 'field', PhotoOrderField.creation),
      );
    });

    test('falls back to the random order for an unknown order', () {
      expect(
        PlaylistStrategies.create('something_else'),
        isA<RandomPlaylistStrategy>(),
      );
    });

    test('offers an order id for every strategy it creates', () {
      for (final order in PlaylistStrategies.orders) {
        expect(PlaylistStrategies.create(order).id, order);
      }
    });
  });
}
