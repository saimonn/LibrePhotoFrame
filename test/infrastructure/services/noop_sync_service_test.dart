import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/infrastructure/services/noop_sync_service.dart';

void main() {
  group('NoOpSyncService', () {
    test('uses the noop id', () {
      expect(NoOpSyncService().id, 'noop');
    });

    test('a sync run completes without touching anything', () async {
      var progressCalls = 0;

      await NoOpSyncService().sync(
        deleteOrphanedFiles: true,
        onProgress: (_) => progressCalls++,
      );

      expect(progressCalls, 0);
    });
  });
}
