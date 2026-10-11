import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/sync_provider.dart';

void main() {
  group('SyncProgress.fraction', () {
    test('is null without files to download', () {
      const progress = SyncProgress(completedFiles: 0, totalFiles: 0);
      expect(progress.fraction, isNull);
    });

    test('is completed over total', () {
      const progress = SyncProgress(completedFiles: 3, totalFiles: 4);
      expect(progress.fraction, 0.75);
    });

    test('clamps to the valid range', () {
      expect(
        const SyncProgress(completedFiles: 9, totalFiles: 4).fraction,
        1.0,
      );
      expect(
        const SyncProgress(completedFiles: -2, totalFiles: 4).fraction,
        0.0,
      );
    });
  });

  group('SyncProgress.counterLabel', () {
    test('is 0 / 0 without files', () {
      expect(
        const SyncProgress(completedFiles: 0, totalFiles: 0).counterLabel,
        '0 / 0',
      );
    });

    test('shows the file currently downloading', () {
      expect(
        const SyncProgress(completedFiles: 0, totalFiles: 3).counterLabel,
        '1 / 3',
      );
      expect(
        const SyncProgress(completedFiles: 2, totalFiles: 3).counterLabel,
        '3 / 3',
      );
    });

    test('caps the index at the total when complete', () {
      expect(
        const SyncProgress(completedFiles: 3, totalFiles: 3).counterLabel,
        '3 / 3',
      );
      expect(
        const SyncProgress(completedFiles: 5, totalFiles: 3).counterLabel,
        '3 / 3',
      );
    });
  });

  group('SyncFolderProgress', () {
    test('fraction is null without files and clamped otherwise', () {
      const empty = SyncFolderProgress(
        folderPath: '',
        completedFiles: 0,
        totalFiles: 0,
      );
      expect(empty.fraction, isNull);
      expect(empty.counterLabel, '0 / 0');

      const half = SyncFolderProgress(
        folderPath: 'albums/summer',
        completedFiles: 1,
        totalFiles: 2,
      );
      expect(half.fraction, 0.5);
      expect(half.counterLabel, '1 / 2');

      const over = SyncFolderProgress(
        folderPath: 'albums',
        completedFiles: 4,
        totalFiles: 2,
      );
      expect(over.fraction, 1.0);
    });
  });
}
