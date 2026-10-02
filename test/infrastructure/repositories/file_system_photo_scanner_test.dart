import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/storage_provider.dart';
import 'package:libre_photo_frame/infrastructure/repositories/file_system_photo_scanner.dart';

class MockStorageProvider implements StorageProvider {
  Directory _dir;

  MockStorageProvider(this._dir);

  void setDirectory(Directory dir) => _dir = dir;

  @override
  Future<Directory> getPhotoDirectory() async => _dir;

  @override
  bool get isReadOnly => false;

  @override
  Stream<void> get onDirectoryChanged => const Stream.empty();
}

/// Writes a file and back-dates its mtime so the scanner treats it as
/// "not being written right now".
Future<File> writePhoto(
  Directory dir,
  String name, {
  String content = 'fake image',
  bool oldTimestamp = true,
}) async {
  final file = File('${dir.path}/$name');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
  if (oldTimestamp) {
    await file.setLastModified(
      DateTime.now().subtract(const Duration(hours: 1)),
    );
  }
  return file;
}

void main() {
  group('FileSystemPhotoScanner', () {
    late Directory tempDir;
    late MockStorageProvider storageProvider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('photo_scanner_test_');
      storageProvider = MockStorageProvider(tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('start() publishes the photos already in the folder', () async {
      await writePhoto(tempDir, 'one.jpg');
      await writePhoto(tempDir, 'nested/two.png');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();

      expect(scanner.photos.length, 2);
      expect(
        scanner.photos.map((p) => p.file.path),
        containsAll([
          '${tempDir.path}/one.jpg',
          '${tempDir.path}/nested/two.png',
        ]),
      );
    });

    test('refresh() picks up a file that appeared without any event',
        () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos, isEmpty);

      final added = await writePhoto(tempDir, 'arrived.jpg');

      // No watcher event, no timer - only the explicit rescan.
      await scanner.scan();

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, added.path);
    });

    test('refresh() drops files that were removed from the folder', () async {
      final keep = await writePhoto(tempDir, 'keep.jpg');
      final remove = await writePhoto(tempDir, 'remove.jpg');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos.length, 2);

      var changes = 0;
      final subscription = scanner.onPhotosChanged.listen((_) => changes++);

      await remove.delete();
      await scanner.scan();

      expect(changes, 1);
      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, keep.path);

      await subscription.cancel();
    });

    test('onPhotosChanged stays silent when the folder did not change',
        () async {
      await writePhoto(tempDir, 'one.jpg');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();

      var changes = 0;
      final subscription = scanner.onPhotosChanged.listen((_) => changes++);

      await scanner.scan();
      await scanner.scan();

      expect(changes, 0);
      expect(scanner.photos.length, 1);

      await subscription.cancel();
    });

    test('untouched files keep their PhotoEntry instance across rescans',
        () async {
      await writePhoto(tempDir, 'one.jpg');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      final before = scanner.photos.single;
      before.lastShown = DateTime.now();
      before.weight = 42;

      await scanner.scan();

      final after = scanner.photos.single;
      expect(identical(before, after), isTrue);
      expect(after.weight, 42);
      expect(after.lastShown, isNotNull);
    });

    test('a file whose content changed is replaced by a fresh entry', () async {
      final file = await writePhoto(tempDir, 'one.jpg');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      final before = scanner.photos.single;

      await file.writeAsString('a completely different, longer image');
      // First scan sees a changed size and keeps the old entry; the second one
      // confirms the size is stable and publishes the new version.
      await scanner.scan();
      expect(identical(scanner.photos.single, before), isTrue);

      await scanner.scan();
      final after = scanner.photos.single;
      expect(identical(before, after), isFalse);
      expect(after.sizeBytes, greaterThan(before.sizeBytes));
    });

    test('files that are still growing are not published yet', () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        // Keep the automatic re-check out of the way, this test drives the
        // scans itself.
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();

      // Freshly created file: it may still be copied in.
      final file = await writePhoto(tempDir, 'incoming.jpg', oldTimestamp: false);
      await scanner.scan();
      expect(scanner.photos, isEmpty);

      // Second observation with an unchanged size: the copy is done.
      await scanner.scan();
      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, file.path);
    });

    test('a growing file is published once it settled and re-checked',
        () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(milliseconds: 200),
      );
      addTearDown(scanner.dispose);

      await scanner.start();

      final file = await writePhoto(tempDir, 'incoming.jpg', oldTimestamp: false);
      await file.writeAsString('a much longer payload');

      // The automatic settle re-check has to publish it without help.
      await Future.delayed(const Duration(milliseconds: 800));

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, file.path);
    });

    test('periodic rescan finds new and removed files without a watcher',
        () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        // No watcher at all: this is the Android/FUSE fallback path.
        watchForChanges: false,
        pollInterval: const Duration(milliseconds: 100),
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos, isEmpty);

      final added = await writePhoto(tempDir, 'incoming.jpg');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, added.path);

      await added.delete();
      await Future.delayed(const Duration(milliseconds: 600));

      expect(scanner.photos, isEmpty);
    });

    test('stop() ends the periodic rescan', () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        watchForChanges: false,
        pollInterval: const Duration(milliseconds: 100),
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      await scanner.stop();

      var changes = 0;
      final subscription = scanner.onPhotosChanged.listen((_) => changes++);
      await writePhoto(tempDir, 'late.jpg');
      await Future.delayed(const Duration(milliseconds: 500));

      expect(changes, 0);
      expect(scanner.photos, isEmpty);

      await subscription.cancel();
    });

    test('a folder that appears later is picked up', () async {
      final notYetCreated = Directory('${tempDir.path}/not-created-yet');
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        watchForChanges: false,
        pollInterval: const Duration(milliseconds: 100),
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos, isEmpty);

      await notYetCreated.create();
      await writePhoto(notYetCreated, 'later.jpg');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path,
          '${notYetCreated.path}/later.jpg');
    });

    test('watcher still reacts to changes', () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        debounceInterval: const Duration(milliseconds: 50),
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos, isEmpty);

      final added = await writePhoto(tempDir, 'watched.jpg');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, added.path);
    });

    test('incomplete .part downloads stay invisible until renamed', () async {
      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        debounceInterval: const Duration(milliseconds: 50),
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();

      await writePhoto(tempDir, 'download.part');
      await Future.delayed(const Duration(milliseconds: 400));
      expect(scanner.photos, isEmpty);

      await File('${tempDir.path}/download.part')
          .rename('${tempDir.path}/download.jpg');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, '${tempDir.path}/download.jpg');
    });

    test('switching the folder re-scans the new location', () async {
      final otherDir = await Directory.systemTemp.createTemp('photo_scanner_other_');
      addTearDown(() async {
        if (await otherDir.exists()) {
          await otherDir.delete(recursive: true);
        }
      });

      await writePhoto(tempDir, 'first.jpg');
      await writePhoto(otherDir, 'second.jpg');

      final scanner = FileSystemPhotoScanner(
        storageProvider: storageProvider,
        settleRecheckInterval: const Duration(seconds: 30),
      );
      addTearDown(scanner.dispose);

      await scanner.start();
      expect(scanner.photos.length, 1);

      storageProvider.setDirectory(otherDir);
      await scanner.stop();
      await scanner.start();

      expect(scanner.photos.length, 1);
      expect(scanner.photos.single.file.path, '${otherDir.path}/second.jpg');
    });
  });
}
