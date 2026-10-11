import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/local_storage_provider.dart';

/// Only the fields [LocalStorageProvider] reads are backed by real state; the
/// rest of the interface is never called and falls through to [noSuchMethod].
class FakeConfig extends ChangeNotifier implements ConfigProvider {
  FakeConfig({this.customPhotoPath, this.activeSourceTypeValue = ''});

  @override
  String? customPhotoPath;

  String activeSourceTypeValue;

  @override
  String get activeSourceType => activeSourceTypeValue;

  @override
  set activeSourceType(String value) => activeSourceTypeValue = value;

  @override
  int pollIntervalSeconds = defaultPollIntervalSeconds;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LocalStorageProvider', () {
    late FakeConfig config;
    late LocalStorageProvider provider;

    setUp(() {
      config = FakeConfig();
      provider = LocalStorageProvider(configProvider: config);
    });

    tearDown(() => provider.dispose());

    test('is read-only for a custom folder and for device photos', () {
      config.customPhotoPath = '/sdcard/pictures';
      expect(provider.isReadOnly, isTrue);

      config.customPhotoPath = null;
      config.activeSourceTypeValue = 'device_photos';
      expect(provider.isReadOnly, isTrue);
    });

    test('is read-write for the internal app folder', () {
      expect(provider.isReadOnly, isFalse);
    });

    test('getPhotoDirectory returns the custom folder', () async {
      config.customPhotoPath = '/sdcard/pictures';

      final directory = await provider.getPhotoDirectory();

      expect(directory.path, '/sdcard/pictures');
    });

    test('emits a change when the custom path changes', () async {
      final events = <void>[];
      final subscription = provider.onDirectoryChanged.listen(events.add);
      addTearDown(subscription.cancel);

      config.customPhotoPath = '/new/path';
      config.notifyListeners();
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('emits a change when the active source type changes', () async {
      final events = <void>[];
      final subscription = provider.onDirectoryChanged.listen(events.add);
      addTearDown(subscription.cancel);

      config.activeSourceType = 'device_photos';
      config.notifyListeners();
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('stays quiet when nothing relevant changed', () async {
      final events = <void>[];
      final subscription = provider.onDirectoryChanged.listen(events.add);
      addTearDown(subscription.cancel);

      config.notifyListeners();
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });
}
