import 'dart:async';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../domain/interfaces/photo_repository.dart';
import '../../domain/interfaces/metadata_provider.dart';
import '../../domain/interfaces/storage_provider.dart';
import '../../domain/interfaces/config_provider.dart';
import '../../domain/models/photo_entry.dart';
import 'file_system_photo_scanner.dart';

const PermissionRequestOption _devicePhotoPermissionRequest =
    PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.image,
        mediaLocation: false,
      ),
    );

/// A PhotoRepository that can switch between FileSystem and MediaStore sources.
/// 
/// - For 'app_folder' and 'local_folder': Uses FileSystem scanning
/// - For 'device_photos': Uses Android MediaStore API
class HybridPhotoRepository implements PhotoRepository {
  // ignore: unused_field
  final StorageProvider _storageProvider;
  // ignore: unused_field
  final MetadataProvider _metadataProvider;
  final ConfigProvider _config;
  final _log = Logger('HybridPhotoRepository');

  /// Scans the photo folder, watches it for changes and re-checks it
  /// periodically so new/removed files are picked up even when the platform
  /// delivers no file system event.
  final FileSystemPhotoScanner _scanner;

  /// Photo list of the MediaStore source. In filesystem mode the list is owned
  /// by [_scanner].
  List<PhotoEntry> _mediaStorePhotos = [];
  final _photosController = StreamController<void>.broadcast();
  StreamSubscription<void>? _scannerSubscription;

  /// Last folder watching setting applied to [_scanner], so a change can be
  /// detected.
  bool _watchPhotoFolder = true;

  // MediaStore mode resources
  String? _selectedAlbumId;
  bool _mediaStoreListenerRegistered = false;

  HybridPhotoRepository({
    required StorageProvider storageProvider,
    required MetadataProvider metadataProvider,
    required ConfigProvider configProvider,
  })  : _storageProvider = storageProvider,
        _metadataProvider = metadataProvider,
        _config = configProvider,
        _scanner = FileSystemPhotoScanner(storageProvider: storageProvider) {
    _watchPhotoFolder = configProvider.watchPhotoFolder;
    _scanner.watchForChanges = _watchPhotoFolder;

    // Expose a single, stable stream. The scanner is only active in filesystem
    // mode while the source can change at runtime (settings), and consumers
    // subscribe once - so forward the scanner events instead of exposing its
    // stream directly.
    _scannerSubscription = _scanner.onPhotosChanged.listen((_) {
      _notifyChanged();
    });

    // The watcher follows the setting instead of requiring a restart.
    configProvider.addListener(_onConfigChanged);
  }

  /// Applies the folder watching setting as soon as it is toggled, so no
  /// restart is needed.
  void _onConfigChanged() {
    if (_useMediaStore) return;
    if (_watchPhotoFolder == _config.watchPhotoFolder) return;

    _watchPhotoFolder = _config.watchPhotoFolder;
    _scanner.watchForChanges = _watchPhotoFolder;
    // Re-scan right away: enabling the watcher has to pick up the changes that
    // happened while it was off.
    unawaited(_scanner.scan());
  }

  @override
  List<PhotoEntry> get photos {
    if (!_useMediaStore) return _scanner.photos;
    return List.unmodifiable(_mediaStorePhotos);
  }

  @override
  Stream<void> get onPhotosChanged => _photosController.stream;
  
  bool get _useMediaStore => _config.activeSourceType == 'device_photos';

  @override
  Future<void> initialize() async {
    _log.info("Initializing HybridPhotoRepository...");
    await _scan();
  }
  
  @override
  Future<void> reinitialize() async {
    _log.info("Reinitializing HybridPhotoRepository...");
    
    // 1. Clean up ALL old resources
    await _cleanup();
    
    // 2. Clear photo list
    _mediaStorePhotos = [];
    
    // 3. Scan with new configuration
    await _scan();
  }

  @override
  Future<void> refresh() async {
    if (_useMediaStore) {
      await _scanMediaStore();
    } else {
      // Re-check the folder right now, e.g. after the app was in the
      // background and file system events were missed.
      await _scanner.scan();
    }
  }
  
  /// Clean up all resources (watchers, timers, listeners)
  Future<void> _cleanup() async {
    // Stop FileSystem watcher, poll timer and settle re-checks
    await _scanner.stop();
    
    // Remove MediaStore listener
    if (_mediaStoreListenerRegistered) {
      PhotoManager.removeChangeCallback(_onMediaStoreChanged);
      _mediaStoreListenerRegistered = false;
    }
  }
  
  /// Scan photos based on current configuration
  Future<void> _scan() async {
    if (_useMediaStore) {
      await _scanMediaStore();
      _setupMediaStoreListener();
    } else {
      // Scans the folder, watches it and arms the periodic rescan.
      await _scanner.start();
    }
  }

  // ============================================================
  // MediaStore Mode (Device Photos)
  // ============================================================
  
  void _setupMediaStoreListener() {
    if (!_mediaStoreListenerRegistered) {
      PhotoManager.addChangeCallback(_onMediaStoreChanged);
      _mediaStoreListenerRegistered = true;
    }
  }
  
  void _onMediaStoreChanged(dynamic call) {
    _log.info("MediaStore change detected");
    _scanMediaStore();
  }
  
  Future<void> _scanMediaStore() async {
    try {
      // Request permission
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: _devicePhotoPermissionRequest,
      );
      if (!permission.hasAccess) {
        _log.warning("Photo permission not granted");
        _publishMediaStorePhotos(const []);
        return;
      }
      
      // Load selected album from config (persistence across restarts)
      final sourceConfig = _config.getSourceConfig('device_photos');
      _selectedAlbumId = sourceConfig['albumId'] as String?;
      _log.fine("Loaded album selection from config: $_selectedAlbumId");
      
      // Get the selected album or use all photos
      List<AssetEntity> assets;
      
      // Common filter options for all album queries
      final filterOption = FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      );
      
      if (_selectedAlbumId != null) {
        // Get specific album - must use same filterOption for proper SQL generation
        final albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          filterOption: filterOption,
        );
        _log.fine("Available albums: ${albums.map((a) => '${a.name}(${a.id})').join(', ')}");
        
        // Find the selected album, or null if not found
        AssetPathEntity? album;
        try {
          album = albums.firstWhere((a) => a.id == _selectedAlbumId);
          _log.fine("Found matching album: ${album.name}");
        } catch (e) {
          _log.warning("Selected album not found: $_selectedAlbumId, falling back to all photos");
          album = null;
        }
        
        if (album != null) {
          final count = await album.assetCountAsync;
          _log.fine("Album '${album.name}' has $count photos");
          if (count > 0) {
            assets = await album.getAssetListRange(start: 0, end: count);
          } else {
            // Album is empty
            _log.info("Selected album is empty");
            _publishMediaStorePhotos(const []);
            return;
          }
        } else {
          // Album not found - fall through to get all photos
          _selectedAlbumId = null;
          assets = await _getAllPhotos();
        }
      } else {
        assets = await _getAllPhotos();
      }
      
      _log.fine("Found ${assets.length} assets in MediaStore");
      
      // Convert AssetEntity to PhotoEntry
      final newPhotos = <PhotoEntry>[];
      
      for (final asset in assets) {
        // Get the actual file
        final file = await asset.file;
        if (file == null) continue;
        
        // Preserve existing PhotoEntry instances
        final existingIndex = _mediaStorePhotos.indexWhere((p) => p.file.path == file.path);
        
        if (existingIndex != -1) {
          newPhotos.add(_mediaStorePhotos[existingIndex]);
        } else {
          // Get GPS coordinates from AssetEntity if available (fast - no file I/O)
          final latLng = await asset.latlngAsync();
          final hasLocation = latLng != null && (latLng.latitude != 0 || latLng.longitude != 0);
          
          // For MediaStore: modifiedDateTime for shuffle, createDateTime as captureDate
          final entry = PhotoEntry(
            file: file,
            date: asset.modifiedDateTime,  // File date for shuffle algorithm
            sizeBytes: asset.width * asset.height,  // Approximate size from dimensions
          );
          // Set EXIF data from MediaStore (already available, no need for lazy loading)
          entry.setExifMetadata(
            captureDate: asset.createDateTime,
            latitude: hasLocation ? latLng.latitude : null,
            longitude: hasLocation ? latLng.longitude : null,
          );
          newPhotos.add(entry);
        }
      }
      
      _publishMediaStorePhotos(newPhotos);
      
    } catch (e) {
      _log.severe("Error scanning photos from MediaStore", e);
    }
  }
  
  /// Replaces the MediaStore photo list and notifies listeners when it changed
  void _publishMediaStorePhotos(List<PhotoEntry> next) {
    final changed = !_samePaths(_mediaStorePhotos, next);
    _mediaStorePhotos = next;
    if (!changed) return;

    _log.info("Scanned ${next.length} photos from MediaStore.");
    _notifyChanged();
  }
  
  bool _samePaths(List<PhotoEntry> left, List<PhotoEntry> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].file.path != right[i].file.path) return false;
    }
    return true;
  }
  
  /// Helper to get all photos from MediaStore
  Future<List<AssetEntity>> _getAllPhotos() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    
    if (albums.isEmpty) {
      _log.info("No photo albums found");
      return [];
    }
    
    // Use "Recent" or first album (contains all photos)
    final allPhotosAlbum = albums.first;
    final count = await allPhotosAlbum.assetCountAsync;
    return allPhotosAlbum.getAssetListRange(start: 0, end: count);
  }
  
  /// Set the album to scan (for Device Photos mode)
  void setSelectedAlbum(String? albumId) {
    _selectedAlbumId = albumId;
    // Store in config for persistence (including null for "all photos")
    _config.setSourceConfig('device_photos', {'albumId': albumId});
    // Trigger rescan with new album selection
    _scanMediaStore();
  }
  
  /// Get available albums (for UI picker)
  Future<List<AssetPathEntity>> getAvailableAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: _devicePhotoPermissionRequest,
    );
    if (!permission.hasAccess) return [];
    
    return PhotoManager.getAssetPathList(type: RequestType.image);
  }

  // ============================================================
  // Common
  // ============================================================

  void _notifyChanged() {
    if (_photosController.isClosed) return;
    _photosController.add(null);
  }

  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    unawaited(_cleanup());
    unawaited(_scannerSubscription?.cancel());
    _scannerSubscription = null;
    _scanner.dispose();
    unawaited(_photosController.close());
  }
}
