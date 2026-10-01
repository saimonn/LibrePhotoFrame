import 'dart:async';

import '../../domain/interfaces/photo_repository.dart';
import '../../domain/interfaces/metadata_provider.dart';
import '../../domain/interfaces/storage_provider.dart';
import '../../domain/models/photo_entry.dart';
import 'file_system_photo_scanner.dart';

/// PhotoRepository backed purely by the file system (app folder / local folder).
///
/// All scanning, watching and periodic refreshing lives in
/// [FileSystemPhotoScanner].
class FileSystemPhotoRepository implements PhotoRepository {
  final FileSystemPhotoScanner _scanner;
  // ignore: unused_field
  final MetadataProvider _metadataProvider;

  FileSystemPhotoRepository({
    required StorageProvider storageProvider,
    required MetadataProvider metadataProvider,
  })  : _scanner = FileSystemPhotoScanner(storageProvider: storageProvider),
        _metadataProvider = metadataProvider;

  @override
  List<PhotoEntry> get photos => _scanner.photos;

  @override
  Stream<void> get onPhotosChanged => _scanner.onPhotosChanged;

  @override
  Future<void> initialize() => _scanner.start();

  @override
  Future<void> reinitialize() async {
    // Stop the old watcher, then scan the new directory and watch it again.
    await _scanner.stop();
    await _scanner.start();
  }

  @override
  Future<void> refresh() => _scanner.scan();

  @override
  void dispose() {
    _scanner.dispose();
  }
}
