import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/services/version_comparison.dart';
import 'package:libre_photo_frame/infrastructure/services/update_service.dart';

void main() {
  group('compareVersions', () {
    test('orders the numeric core', () {
      expect(compareVersions('1.13.16', '1.14.0'), lessThan(0));
      expect(compareVersions('1.14.0', '1.13.16'), greaterThan(0));
      expect(compareVersions('1.14.0', '1.14.0'), 0);
      expect(compareVersions('1.14', '1.14.0'), 0);
    });

    test('ignores the build number', () {
      expect(compareVersions('1.14.0+27', '1.14.0+28'), 0);
    });

    test('ranks a prerelease below its release', () {
      expect(compareVersions('1.14.0-beta.1', '1.14.0'), lessThan(0));
      expect(compareVersions('1.14.0', '1.14.0-beta.1'), greaterThan(0));
    });

    test('orders prereleases between themselves', () {
      expect(compareVersions('1.14.0-beta.1', '1.14.0-beta.2'), lessThan(0));
      expect(compareVersions('1.14.0-beta.2', '1.14.0-beta.10'), lessThan(0));
      expect(compareVersions('1.14.0-alpha', '1.14.0-beta'), lessThan(0));
    });

    test('a new beta is newer than the previous stable', () {
      expect(compareVersions('1.14.0-beta.1', '1.13.16'), greaterThan(0));
    });
  });

  group('isVersionTag', () {
    test('accepts version tags, with or without the v prefix', () {
      expect(isVersionTag('v1.14.0'), isTrue);
      expect(isVersionTag('1.14.0'), isTrue);
      expect(isVersionTag('v1.14.0-beta.1'), isTrue);
    });

    test('rejects moving tags', () {
      expect(isVersionTag('dev-latest'), isFalse);
      expect(isVersionTag(''), isFalse);
    });
  });

  group('newestVersionedRelease', () {
    test('returns the first versioned release, prereleases included', () {
      final releases = [
        {'tag_name': 'dev-latest', 'draft': false},
        {'tag_name': 'v1.14.0-beta.2', 'draft': false},
        {'tag_name': 'v1.13.16', 'draft': false},
      ];
      expect(newestVersionedRelease(releases)?['tag_name'], 'v1.14.0-beta.2');
    });

    test('skips drafts and returns null when nothing qualifies', () {
      expect(
        newestVersionedRelease([
          {'tag_name': 'v1.14.0-beta.1', 'draft': true},
          {'tag_name': 'dev-latest', 'draft': false},
        ]),
        isNull,
      );
    });
  });
}
