import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/geocoding_service.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_metadata_database.dart';

/// Mimics the Nominatim /reverse response at the dio transport level,
/// counting every request.
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter({
    this.address = const {},
    this.statusCode = 200,
    this.delay = Duration.zero,
  });

  final Map<String, dynamic>? address;
  final int statusCode;
  final Duration delay;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final body = jsonEncode({'address': address});
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _lat = 48.137108;
const _lon = 11.575383;

void main() {
  group('GeocodingService', () {
    late PhotoMetadataDatabase database;
    late FakeDioAdapter adapter;
    late GeocodingService service;

    GeocodingService buildService() {
      final dio = Dio()..httpClientAdapter = adapter;
      return GeocodingService(database: database, dio: dio);
    }

    setUp(() {
      database = PhotoMetadataDatabase.openInMemory();
      adapter = FakeDioAdapter(address: const {
        'city': 'Munich',
        'state': 'Bayern',
        'country': 'Germany',
      });
      service = buildService();
    });

    test('builds "City, State, Country" and caches the result', () async {
      final first = await service.getLocationName(_lat, _lon);
      final second = await service.getLocationName(_lat, _lon);

      expect(first, 'Munich, Bayern, Germany');
      expect(second, first);
      // The second call was served from the cache.
      expect(adapter.calls, 1);
    });

    test('concurrent identical requests share one HTTP call', () async {
      adapter = FakeDioAdapter(
        address: const {'city': 'Munich'},
        delay: const Duration(milliseconds: 50),
      );
      service = buildService();

      final results = await Future.wait([
        service.getLocationName(_lat, _lon),
        service.getLocationName(_lat, _lon),
      ]);

      expect(results, ['Munich', 'Munich']);
      expect(adapter.calls, 1);
    });

    test('a cached negative result is not requested again', () async {
      adapter = FakeDioAdapter(address: null);
      service = buildService();

      final first = await service.getLocationName(_lat, _lon);
      final second = await service.getLocationName(_lat, _lon);

      expect(first, isNull);
      expect(second, isNull);
      expect(adapter.calls, 1);
    });

    test('an HTTP error is not cached', () async {
      adapter = FakeDioAdapter(statusCode: 500);
      service = buildService();

      expect(await service.getLocationName(_lat, _lon), isNull);
      expect(await service.getLocationName(_lat, _lon), isNull);
      expect(adapter.calls, 2);
    });

    test('a result survives a service restart through the database', () async {
      final firstService = buildService();
      await firstService.getLocationName(_lat, _lon);

      final restarted = buildService();
      final result = await restarted.getLocationName(_lat, _lon);

      expect(result, 'Munich, Bayern, Germany');
      expect(adapter.calls, 1);
    });

    test('clearCache forces a new request', () async {
      await service.getLocationName(_lat, _lon);
      await service.clearCache();

      await service.getLocationName(_lat, _lon);

      expect(adapter.calls, 2);
    });
  });

  group('GeocodingService without a database', () {
    test('still resolves a place name', () async {
      final adapter = FakeDioAdapter(address: const {'city': 'Berlin'});
      final dio = Dio()..httpClientAdapter = adapter;
      final service = GeocodingService(dio: dio);

      expect(await service.getLocationName(52.52, 13.404954), 'Berlin');
      expect(adapter.calls, 1);
    });
  });
}