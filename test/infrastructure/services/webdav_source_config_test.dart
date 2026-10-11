import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/webdav_source_config.dart';

void main() {
  group('WebDavSourceConfig.normalizeFolderPath', () {
    test('trims, normalizes separators and slashes', () {
      expect(
        WebDavSourceConfig.normalizeFolderPath('  /albums//summer/ '),
        'albums/summer',
      );
      expect(
        WebDavSourceConfig.normalizeFolderPath('\\albums\\winter\\'),
        'albums/winter',
      );
    });

    test('maps empty, blank and root paths to the empty string', () {
      expect(WebDavSourceConfig.normalizeFolderPath(''), '');
      expect(WebDavSourceConfig.normalizeFolderPath('   '), '');
      expect(WebDavSourceConfig.normalizeFolderPath('/'), '');
    });
  });

  group('WebDavSourceConfig.parentDirectoryOf', () {
    test('returns the parent of a nested file', () {
      expect(
        WebDavSourceConfig.parentDirectoryOf('albums/summer/photo.jpg'),
        'albums/summer',
      );
    });

    test('returns root for a top-level or empty path', () {
      expect(WebDavSourceConfig.parentDirectoryOf('photo.jpg'), '');
      expect(WebDavSourceConfig.parentDirectoryOf(''), '');
    });
  });

  group('CachedWebDavFolder', () {
    test('parses a map entry', () {
      final folder = CachedWebDavFolder.fromEntry({'path': '/albums/', 'count': 3});
      expect(folder.path, '/albums/');
      expect(folder.fileCount, 3);
    });

    test('defaults the count to zero and tolerates missing keys', () {
      expect(CachedWebDavFolder.fromEntry({'path': 'x'}).fileCount, 0);
      expect(CachedWebDavFolder.fromEntry(const <String, dynamic>{}).path, '');
    });

    test('reads the legacy bare string format', () {
      final folder = CachedWebDavFolder.fromEntry('albums/summer');
      expect(folder.path, 'albums/summer');
      expect(folder.fileCount, 0);
    });

    test('toMap normalizes the path', () {
      expect(
        const CachedWebDavFolder(path: '/albums//summer/', fileCount: 5).toMap(),
        {'path': 'albums/summer', 'count': 5},
      );
    });
  });

  group('WebDavSourceConfig.fromMap', () {
    test('reads every stored field', () {
      final config = WebDavSourceConfig.fromMap({
        'url': '  https://cloud.example.com/s/abc  ',
        'auth_mode': 'user_password',
        'username': '  bob  ',
        'password': 'secret',
        'allow_invalid_certificate': true,
        'folder_sync_mode': 'selected',
        'selected_folders': ['/', 'albums'],
        'cached_folders': [
          {'path': 'albums', 'count': 2},
        ],
      });

      expect(config.url, 'https://cloud.example.com/s/abc');
      expect(config.authMode, WebDavAuthMode.userPassword);
      expect(config.username, 'bob');
      expect(config.password, 'secret');
      expect(config.allowInvalidCertificate, isTrue);
      expect(config.folderSyncMode, WebDavFolderSyncMode.selectedFolders);
      expect(config.selectedFolders, ['/', 'albums']);
      expect(config.cachedFolders.single.path, 'albums');
      expect(config.cachedFolders.single.fileCount, 2);
    });

    test('defaults to a public share syncing every folder', () {
      final config = WebDavSourceConfig.fromMap(const {});
      expect(config.url, '');
      expect(config.authMode, WebDavAuthMode.publicShare);
      expect(config.syncAllFolders, isTrue);
      expect(config.selectedFolders, isEmpty);
      expect(config.cachedFolders, isEmpty);
      expect(config.copyWith().url, '');
    });

    test('tolerates malformed list values', () {
      final config = WebDavSourceConfig.fromMap(const {
        'selected_folders': 'albums',
        'cached_folders': 42,
      });
      expect(config.selectedFolders, isEmpty);
      expect(config.cachedFolders, isEmpty);
    });
  });

  group('WebDavSourceConfig selection', () {
    test('all-folders mode includes everything', () {
      const config = WebDavSourceConfig();
      expect(config.includesDirectory('any/where'), isTrue);
      expect(config.includesRelativeFile('a/b/photo.jpg'), isTrue);
    });

    test('selected mode includes the root only when it was selected', () {
      final withRoot = WebDavSourceConfig.fromMap(const {
        'folder_sync_mode': 'selected',
        'selected_folders': ['/', 'albums//summer/'],
      });
      expect(withRoot.normalizedSelectedFolders, {'', 'albums/summer'});
      expect(withRoot.includesDirectory(''), isTrue);

      final withoutRoot = WebDavSourceConfig.fromMap(const {
        'folder_sync_mode': 'selected',
        'selected_folders': ['albums//summer/'],
      });
      expect(withoutRoot.normalizedSelectedFolders, {'albums/summer'});
      expect(withoutRoot.includesDirectory(''), isFalse);
    });
  });

  group('WebDavSourceConfig.toMap', () {
    test('round-trips through fromMap', () {
      const config = WebDavSourceConfig(
        url: 'https://cloud.example.com/dav/',
        authMode: WebDavAuthMode.userPassword,
        username: 'bob',
        password: 'pw',
        allowInvalidCertificate: true,
        folderSyncMode: WebDavFolderSyncMode.selectedFolders,
        selectedFolders: ['/albums/', 'music'],
        cachedFolders: [CachedWebDavFolder(path: '/albums/', fileCount: 7)],
      );

      final restored = WebDavSourceConfig.fromMap(config.toMap());
      expect(restored.url, config.url);
      expect(restored.authMode, config.authMode);
      expect(restored.username, config.username);
      expect(restored.password, config.password);
      expect(restored.allowInvalidCertificate, isTrue);
      expect(restored.folderSyncMode, config.folderSyncMode);
      expect(restored.normalizedSelectedFolders, {'albums', 'music'});
      expect(restored.cachedFolders.single.fileCount, 7);
    });

    test('copyWith replaces only the given fields', () {
      const config = WebDavSourceConfig(url: 'https://a', username: 'a');
      final changed = config.copyWith(
        url: 'https://b',
        allowInvalidCertificate: true,
      );
      expect(changed.url, 'https://b');
      expect(changed.username, 'a');
      expect(changed.allowInvalidCertificate, isTrue);
    });
  });

  group('WebDavSourceConfig.splitInlineCredentials', () {
    test('leaves URLs without credentials untouched', () {
      final split = WebDavSourceConfig.splitInlineCredentials(
        '  https://cloud.example.com/dav/  ',
      );
      expect(split.url, 'https://cloud.example.com/dav/');
      expect(split.username, isNull);
      expect(split.password, isNull);
    });

    test('splits a user name without a password', () {
      final split = WebDavSourceConfig.splitInlineCredentials(
        'https://alice@cloud.example.com/dav/',
      );
      expect(split.url, 'https://cloud.example.com/dav/');
      expect(split.username, 'alice');
      expect(split.password, '');
    });
  });
}
