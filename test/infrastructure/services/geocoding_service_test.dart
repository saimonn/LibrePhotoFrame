import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:libre_photo_frame/infrastructure/services/geocoding_service.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

/// Mimics the Nominatim /reverse response, counting every request.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient({
    Map<String, dynamic>? address,
    this.statusCode = 200,
    this.delay = Duration.zero,
  }) : address = address;

  final Map<String, dynamic>? address;
  final int statusCode;
  final Duration delay;
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final body = jsonEncode({'address': address});
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode(body)]),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

const _lat = 48.137108;
const _lon = 11.575383;

void main() {
  group('GeocodingService', () {
    late PhotoMetadataDatabase database;
    late FakeHttpClient client;
    late GeocodingService service;

    setUp(() {
      database = PhotoMetadataDatabase.openInMemory();
      client = FakeHttpClient(address: const {
        'city': 'Munich',
        'state': 'Bayern',
        'country': 'Germany',
      });
      service = GeocodingService(database: database, client: client);
    });

    test('builds "City, State, Country" and caches the result', () async {
      final first = await service.getLocationName(_lat, _lon);
      final second = await service.getLocationName(_lat, _lon);

      expect(first, 'Munich, Bayern, Germany');
      expect(second, first);
      // The second call was served from the cache.
      expect(client.calls, 1);
    });

    test('concurrent identical requests share one HTTP call', () async {
      client = FakeHttpClient(
        address: const {'city': 'Munich'},
        delay: const Duration(milliseconds: 50),
      );
      service = GeocodingService(database: database, client: client);

      final results = await Future.wait([
        service.getLocationName(_lat, _lon),
        service.getLocationName(_lat, _lon),
      ]);

      expect(results, ['Munich', 'Munich']);
      expect(client.calls, 1);
    });

    test('a cached negative result is not requested again', () async {
      client = FakeHttpClient(address: null);
      service = GeocodingService(database: database, client: client);

      final first = await service.getLocationName(_lat, _lon);
      final second = await service.getLocationName(_lat, _lon);

      expect(first, isNull);
      expect(second, isNull);
      expect(client.calls, 1);
    });

    test('an HTTP error is not cached', () async {
      client = FakeHttpClient(statusCode: 500);
      service = GeocodingService(database: database, client: client);

      expect(await service.getLocationName(_lat, _lon), isNull);
      expect(await service.getLocationName(_lat, _lon), isNull);
      expect(client.calls, 2);
    });

    test('a result survives a service restart through the database', () async {
      final firstService = GeocodingService(database: database, client: client);
      await firstService.getLocationName(_lat, _lon);

      final restarted = GeocodingService(database: database, client: client);
      final result = await restarted.getLocationName(_lat, _lon);

      expect(result, 'Munich, Bayern, Germany');
      expect(client.calls, 1);
    });

    test('clearCache forces a new request', () async {
      await service.getLocationName(_lat, _lon);
      await service.clearCache();

      await service.getLocationName(_lat, _lon);

      expect(client.calls, 2);
    });
  });

  group('GeocodingService without a database', () {
    test('still resolves a place name', () async {
      final client = FakeHttpClient(address: const {'city': 'Berlin'});
      final service = GeocodingService(client: client);

      expect(await service.getLocationName(52.52, 13.404954), 'Berlin');
      expect(client.calls, 1);
    });
  });
}