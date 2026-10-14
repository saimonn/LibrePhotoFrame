import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/domain/interfaces/metadata_provider.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/services/geocoding_service.dart';
import 'package:libre_photo_frame/ui/controllers/photo_enrichment_controller.dart';

/// Config double: the controller only reads [geocodingEnabled].
class _FakeConfig extends ChangeNotifier implements ConfigProvider {
  _FakeConfig({this.geocodingEnabled = true});

  @override
  bool geocodingEnabled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns a fixed GPS position so the controller has something to geocode.
class _FakeMetadataProvider implements MetadataProvider {
  _FakeMetadataProvider(this.location);

  final GpsCoordinates? location;
  int calls = 0;

  @override
  Future<ExifMetadata> getExifMetadata(File file) async {
    calls++;
    return ExifMetadata(location: location);
  }
}

/// Mimics the Nominatim response at the dio transport level.
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this.address);

  final Map<String, dynamic>? address;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode({'address': address}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PhotoEntry _photo(String name) => PhotoEntry(
      file: File('/photos/$name.jpg'),
      date: DateTime(2026),
      sizeBytes: 1024,
    );

void main() {
  group('PhotoEnrichmentController', () {
    test('repaints once the place name arrives', () async {
      final adapter = _FakeDioAdapter({'city': 'Paris', 'country': 'France'});
      final controller = PhotoEnrichmentController(
        geocodingService: GeocodingService(
          dio: Dio()..httpClientAdapter = adapter,
        ),
        metadataProvider: _FakeMetadataProvider(
          const GpsCoordinates(48.8566, 2.3522),
        ),
      );
      final config = _FakeConfig();
      final photo = _photo('a');

      var repaints = 0;
      await controller.enrichDisplayedPhotos(
        photo,
        null,
        config,
        mounted: true,
        onPhotoUpdated: () => repaints++,
      );

      // The name is available for the overlay...
      expect(controller.locationNames[photo.file.path], 'Paris, France');
      // ...and the frame was asked to repaint after the lookup, so the overlay
      // actually shows it (regression: a name set without a repaint is unseen
      // until the next slide).
      expect(repaints, greaterThanOrEqualTo(2));
      expect(adapter.calls, 1);

      controller.dispose();
    });

    test('does not geocode when disabled', () async {
      final adapter = _FakeDioAdapter({'city': 'Paris'});
      final controller = PhotoEnrichmentController(
        geocodingService: GeocodingService(
          dio: Dio()..httpClientAdapter = adapter,
        ),
        metadataProvider: _FakeMetadataProvider(
          const GpsCoordinates(48.8566, 2.3522),
        ),
      );

      await controller.enrichDisplayedPhotos(
        _photo('a'),
        null,
        _FakeConfig(geocodingEnabled: false),
        mounted: true,
        onPhotoUpdated: () {},
      );

      expect(adapter.calls, 0);
      expect(controller.locationNames, isEmpty);

      controller.dispose();
    });

    test('clears the names of the photos that leave the frame', () async {
      final adapter = _FakeDioAdapter({'city': 'Paris'});
      final controller = PhotoEnrichmentController(
        geocodingService: GeocodingService(
          dio: Dio()..httpClientAdapter = adapter,
        ),
        metadataProvider: _FakeMetadataProvider(
          const GpsCoordinates(48.8566, 2.3522),
        ),
      );
      final config = _FakeConfig();
      final first = _photo('a');
      final second = _photo('b');

      await controller.enrichDisplayedPhotos(
        first,
        null,
        config,
        mounted: true,
        onPhotoUpdated: () {},
      );
      expect(controller.locationNames.containsKey(first.file.path), isTrue);

      await controller.enrichDisplayedPhotos(
        second,
        null,
        config,
        mounted: true,
        onPhotoUpdated: () {},
      );
      expect(controller.locationNames.containsKey(first.file.path), isFalse);
      expect(controller.locationNames.containsKey(second.file.path), isTrue);

      controller.dispose();
    });
  });
}
