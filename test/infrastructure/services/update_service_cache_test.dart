import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/update_service.dart';

void main() {
  group('apkVersion', () {
    test('reads the version of a release APK', () {
      expect(apkVersion('LibrePhotoFrame-1.13.17-arm64-v8a.apk'), '1.13.17');
      expect(apkVersion('LibrePhotoFrame-1.13.17-debug.apk'), '1.13.17');
      expect(apkVersion('LibrePhotoFrame-1.13.17.apk'), '1.13.17');
    });

    test('keeps a prerelease and a dev suffix', () {
      expect(
        apkVersion('LibrePhotoFrame-1.14.0-beta.2-armeabi-v7a.apk'),
        '1.14.0-beta.2',
      );
      expect(
        apkVersion('LibrePhotoFrame-1.13.18-dev.0042-x86_64.apk'),
        '1.13.18-dev.0042',
      );
    });

    test('rejects names that are not versioned APKs', () {
      expect(apkVersion('LibrePhotoFrame-dev-latest-arm64-v8a.apk'), isNull);
      expect(apkVersion('LibrePhotoFrame-1.13.17-arm64-v8a.apk.tmp'), isNull);
      expect(apkVersion('LibrePhotoFrame-1.13.17-arm64-v8a'), isNull);
      expect(apkVersion('some-other.apk'), isNull);
      expect(apkVersion('photo.jpg'), isNull);
    });
  });

  group('apkToKeep', () {
    test('keeps nothing when there is no cached APK', () {
      expect(apkToKeep(const [], '1.13.17'), isNull);
    });

    test('keeps nothing when the newest is not newer than the running build',
        () {
      expect(apkToKeep(['LibrePhotoFrame-1.13.17-arm64-v8a.apk'], '1.13.17'), isNull);
      expect(apkToKeep(['LibrePhotoFrame-1.13.16-arm64-v8a.apk'], '1.13.17'), isNull);
    });

    test('keeps the newest when it is newer than the running build', () {
      expect(
        apkToKeep([
          'LibrePhotoFrame-1.13.16-arm64-v8a.apk',
          'LibrePhotoFrame-1.13.18-arm64-v8a.apk',
          'LibrePhotoFrame-1.13.17-arm64-v8a.apk',
        ], '1.13.17'),
        'LibrePhotoFrame-1.13.18-arm64-v8a.apk',
      );
    });

    test('ignores the files that are not update APKs', () {
      expect(
        apkToKeep(['notes.txt', 'LibrePhotoFrame-1.13.18-arm64-v8a.apk'], '1.13.17'),
        'LibrePhotoFrame-1.13.18-arm64-v8a.apk',
      );
      expect(apkToKeep(['notes.txt'], '1.13.17'), isNull);
    });

    test('orders a dev build by semantic versioning', () {
      expect(
        apkToKeep(['LibrePhotoFrame-1.14.0-dev.0042-arm64-v8a.apk'], '1.14.0-beta.2'),
        'LibrePhotoFrame-1.14.0-dev.0042-arm64-v8a.apk',
      );
    });
  });
}
