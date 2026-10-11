import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/webdav_remote_client.dart';

void main() {
  group('NextcloudPublicShare.fromPublicLink', () {
    test('derives the webdav endpoint and token from a share link', () {
      final share = NextcloudPublicShare.fromPublicLink(
        'https://cloud.example.com/s/abc123',
      );

      expect(share.webDavUrl, 'https://cloud.example.com/public.php/webdav');
      expect(share.user, 'abc123');
      expect(share.password, '');
    });

    test('rejects an empty link', () {
      expect(
        () => NextcloudPublicShare.fromPublicLink(''),
        throwsArgumentError,
      );
    });

    test('rejects a link without a token segment', () {
      expect(
        () => NextcloudPublicShare.fromPublicLink('https://cloud.example.com'),
        throwsArgumentError,
      );
    });
  });

  group('createWebDavRemoteClientImpl', () {
    test('builds a client for a WebDAV endpoint', () {
      final client = createWebDavRemoteClientImpl(
        webDavUrl: 'https://cloud.example.com/public.php/webdav',
        user: 'token',
        password: '',
      );

      expect(client, isA<WebDavRemoteClientImpl>());
    });

    test('accepts the invalid-certificate opt-in', () {
      final client = createWebDavRemoteClientImpl(
        webDavUrl: 'https://cloud.example.com/public.php/webdav',
        user: 'token',
        password: '',
        allowInvalidCertificate: true,
      );

      expect(client, isA<WebDavRemoteClientImpl>());
    });
  });
}
