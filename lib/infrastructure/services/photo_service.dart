import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../domain/interfaces/config_provider.dart';
import '../../domain/interfaces/playlist_strategy.dart';
import '../../domain/interfaces/sync_provider.dart';
import '../../domain/interfaces/storage_provider.dart';
import '../../domain/interfaces/photo_repository.dart';
import '../../domain/models/photo_entry.dart';

/// Factory function type that creates a SyncProvider from current config
typedef SyncProviderFactory = SyncProvider Function();

enum SyncStatusKind {
  success,
  cancelled,
  error,
}

class SyncStatus {
  const SyncStatus.success()
    : kind = SyncStatusKind.success,
      error = null;

  const SyncStatus.cancelled()
    : kind = SyncStatusKind.cancelled,
      error = null;

  const SyncStatus.error(this.error) : kind = SyncStatusKind.error;

  final SyncStatusKind kind;
  final Object? error;
}

class PhotoService extends ChangeNotifier {
  final SyncProviderFactory _syncProviderFactory;
  PlaylistStrategy _playlistStrategy;
  final PhotoRepository _repository;
  final ConfigProvider _configProvider;
  final StorageProvider _storageProvider;
  final _log = Logger('PhotoService');

  bool _isInitialized = false;
  bool _syncLoopRunning = false;
  
  // Sync state management
  bool _isSyncing = false;
  bool _cancelRequested = false;
  Completer<void>? _currentSyncCompleter;
  SyncProgress? _syncProgress;
  SyncStatus? _syncStatus;
  
  // History management
  final List<PhotoEntry> _history = [];
  int _historyIndex = -1;
  
  // Directory change subscription
  StreamSubscription? _directoryChangeSubscription;

  PhotoService({
    required SyncProviderFactory syncProviderFactory,
    required PlaylistStrategy playlistStrategy,
    required PhotoRepository repository,
    required ConfigProvider configProvider,
    required StorageProvider storageProvider,
  })  : _syncProviderFactory = syncProviderFactory,
        _playlistStrategy = playlistStrategy,
        _repository = repository,
        _configProvider = configProvider,
        _storageProvider = storageProvider;

  /// Applies the playlist strategy of the configured photo order.
  ///
  /// Called when the photo order setting changes, so a new order takes effect
  /// without restarting the app. The strategy holding the shuffle history is
  /// kept as long as the order does not change.
  void updatePlaylistStrategy(PlaylistStrategy strategy) {
    if (_playlistStrategy.id == strategy.id) return;
    _playlistStrategy = strategy;
  }

  /// Records what the frame is showing, so an order can take the recently
  /// shown photos into account.
  ///
  /// [partner] is the photo sharing the frame in split mode; both are recorded
  /// as one rank.
  void noteDisplayed(PhotoEntry photo, [PhotoEntry? partner]) {
    _playlistStrategy.recordShown(
      partner == null ? [photo] : [photo, partner],
    );
  }

  Stream<void> get onPhotosChanged => _repository.onPhotosChanged;

  /// Re-checks the photo source immediately.
  ///
  /// In local folder mode this re-reads the directory, so pictures that
  /// appeared or disappeared there are shown/removed without waiting for the
  /// next periodic refresh. Called e.g. when the app comes back to the
  /// foreground, because file system events are unreliable while suspended.
  Future<void> refreshPhotos() async {
    try {
      await _repository.refresh();
    } catch (e, stackTrace) {
      _log.warning("Manual photo refresh failed", e, stackTrace);
    }
  }
  
  /// Returns true if a sync is currently in progress
  bool get isSyncing => _isSyncing;
  SyncProgress? get syncProgress => _syncProgress;
  SyncStatus? get syncStatus => _syncStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _log.info("Initializing PhotoService...");
    
    // 1. Initialize Repository (Load local photos)
    await _repository.initialize();
    
    // 2. Listen for directory changes
    _directoryChangeSubscription = _storageProvider.onDirectoryChanged.listen((_) {
      _onDirectoryChanged();
    });
    
    // 3. Start Sync in Background
    _startBackgroundSync();
    
    _isInitialized = true;
  }

  void _updateSyncState({
    bool? isSyncing,
    SyncProgress? progress,
    bool clearProgress = false,
    SyncStatus? status,
    bool clearStatus = false,
  }) {
    var changed = false;

    if (isSyncing != null && _isSyncing != isSyncing) {
      _isSyncing = isSyncing;
      changed = true;
    }

    if (clearProgress) {
      if (_syncProgress != null) {
        _syncProgress = null;
        changed = true;
      }
    } else if (progress != null) {
      _syncProgress = progress;
      changed = true;
    }

    if (clearStatus) {
      if (_syncStatus != null) {
        _syncStatus = null;
        changed = true;
      }
    } else if (status != null && _syncStatus != status) {
      _syncStatus = status;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
  
  /// Called when the photo directory changes (e.g., user selected different folder)
  Future<void> _onDirectoryChanged() async {
    _log.info("Photo directory changed, reinitializing...");
    
    // 1. Reset slideshow state (history is no longer valid)
    _resetState();
    
    // 2. Reinitialize repository with new directory
    await _repository.reinitialize();
    
    _log.info("Directory change complete");
  }
  
  /// Resets slideshow state (history, current position)
  void _resetState() {
    _history.clear();
    _historyIndex = -1;
    _log.info("Slideshow state reset");
  }

  void _startBackgroundSync() {
    if (_syncLoopRunning) return;
    _syncLoopRunning = true;

    unawaited(() async {
      while (_syncLoopRunning) {
      // Read current config values (they might change via settings)
        final intervalMinutes = _configProvider.syncIntervalMinutes;

        // If interval is 0, sync is disabled
        if (intervalMinutes <= 0) {
          _log.info("Auto-sync is disabled. Checking again in 1 minute...");
          await Future.delayed(const Duration(minutes: 1));
          continue;
        }

        // Skip if a sync is already running (e.g., manual sync from settings)
        if (_isSyncing) {
          _log.info("Sync already in progress, skipping scheduled sync");
          await Future.delayed(Duration(minutes: intervalMinutes));
          continue;
        }

        try {
          await _executeSync();
        } catch (e, stackTrace) {
          _log.warning("Scheduled sync failed, will retry on next interval", e, stackTrace);
        }

        // Wait for configured interval before next sync
        await Future.delayed(Duration(minutes: intervalMinutes));
      }
    }());
  }
  
  /// Triggers a manual sync. If a sync is already running, it will be cancelled first.
  /// Returns a Future that completes when the new sync is done.
  Future<void> triggerSync() async {
    _log.info("Manual sync triggered");
    
    // If a sync is already running, request cancellation and wait for it
    if (_isSyncing) {
      _log.info("Cancelling current sync...");
      _cancelRequested = true;
      
      // Wait for the current sync to finish
      if (_currentSyncCompleter != null) {
        await _currentSyncCompleter!.future;
      }
    }
    
    // Now execute the new sync
    await _executeSync();
  }
  
  /// Internal method that actually executes the sync
  Future<void> _executeSync() async {
    // Skip sync if storage is read-only (external user folder)
    if (_storageProvider.isReadOnly) {
      _log.info("Storage is read-only (local folder mode), skipping sync");
      return;
    }
    
    if (_isSyncing) return; // Double-check
    
    _cancelRequested = false;
    _currentSyncCompleter = Completer<void>();
    _updateSyncState(
      isSyncing: true,
      clearProgress: true,
      clearStatus: true,
    );
    
    final deleteOrphaned = _configProvider.deleteOrphanedFiles;
    
    try {
      // Create a fresh SyncProvider with current config settings
      final syncProvider = _syncProviderFactory();
      _log.info("Starting sync (delete orphaned: $deleteOrphaned)");
      await syncProvider.sync(
        deleteOrphanedFiles: deleteOrphaned,
        onProgress: (progress) {
          _updateSyncState(progress: progress);
        },
      );
      
      // Save timestamp of successful sync
      _configProvider.lastSuccessfulSync = DateTime.now();
      await _configProvider.save();
      
      _log.info("Sync completed successfully");
      _updateSyncState(status: const SyncStatus.success());
      // Repository watcher will pick up changes automatically
    } catch (e, stackTrace) {
      if (_cancelRequested) {
        _log.info("Sync was cancelled");
        _updateSyncState(status: const SyncStatus.cancelled());
      } else {
        _log.warning("Sync failed", e, stackTrace);
        _updateSyncState(status: SyncStatus.error(e));
        rethrow;
      }
    } finally {
      _cancelRequested = false;
      _currentSyncCompleter?.complete();
      _currentSyncCompleter = null;
      _updateSyncState(isSyncing: false, clearProgress: true);
    }
  }

  PhotoEntry? nextPhoto() {
    // Photos can vanish from the list at any time (deleted from a local
    // folder). Drop them from the history first, otherwise walking forward
    // through the history could return a file that no longer exists.
    _pruneHistory();

    // 1. If we are in the past, move forward in history
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      return _history[_historyIndex];
    }

    // 2. Otherwise, generate new photo
    final photos = _repository.photos;
    final photo = _playlistStrategy.nextPhoto(photos);
    
    if (photo != null) {
      photo.lastShown = DateTime.now();
      _history.add(photo);
      _historyIndex++;
      
      // Limit history size to prevent memory leaks (keep last 50)
      if (_history.length > 50) {
        _history.removeAt(0);
        _historyIndex--;
      }
    }
    return photo;
  }

  PhotoEntry? previousPhoto() {
    _pruneHistory();

    if (_historyIndex > 0) {
      _historyIndex--;
      return _history[_historyIndex];
    }
    // If we are at the start, stay there
    return _history.isNotEmpty ? _history[_historyIndex] : null;
  }

  /// Removes history entries whose files are no longer part of the photo list
  /// and keeps [_historyIndex] on a valid position.
  void _pruneHistory() {
    if (_history.isEmpty) return;

    final current = (_historyIndex >= 0 && _historyIndex < _history.length)
        ? _history[_historyIndex]
        : null;

    final available = {for (final photo in _repository.photos) photo.file.path};
    final before = _history.length;
    _history.removeWhere((photo) => !available.contains(photo.file.path));
    if (_history.length == before) return;

    _log.info(
      "Pruned ${before - _history.length} photo(s) that left the photo list "
      "from the slideshow history",
    );
    if (_history.isEmpty) {
      _historyIndex = -1;
      return;
    }

    // Continue from the new end of the history, unless the photo we were on
    // is still available.
    final newIndex = current == null
        ? -1
        : _history.indexWhere((photo) => identical(photo, current));
    _historyIndex = newIndex == -1 ? _history.length - 1 : newIndex;
  }
  
  /// All photos currently available for the slideshow.
  ///
  /// Exposed so the UI can look for a second photo to pair with the one on
  /// screen without reaching into the repository.
  List<PhotoEntry> get availablePhotos => _repository.photos;

  /// Check if a photo is still in the current photo list
  bool containsPhoto(PhotoEntry photo) {
    return _repository.photos.any((p) => p.file.path == photo.file.path);
  }
  
  @override
  void dispose() {
    _syncLoopRunning = false;
    _directoryChangeSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
