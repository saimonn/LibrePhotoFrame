import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../domain/interfaces/storage_provider.dart';
import '../../domain/models/photo_entry.dart';

/// Keeps a [PhotoEntry] list in sync with the content of a photo directory.
///
/// Two independent mechanisms feed the scan, because neither is sufficient on
/// its own:
///
///  * [Directory.watch] reacts within milliseconds, but inotify is unreliable
///    for the folders this app cares about: on Android external storage and SD
///    cards are mounted through FUSE, and files written by *other* apps (sync
///    clients, camera apps, SMB/NFS mounts) frequently produce no event at
///    all. A watcher also dies when the directory or the card is remounted.
///  * A periodic rescan is the safety net. It picks up new files and removals
///    that produced no event, which is exactly the "new incoming pictures
///    show up, deleted ones disappear" behaviour a photo folder needs.
///
/// Newly appearing files are only published once they stopped growing, so a
/// photo that is still being copied into the folder is never displayed
/// half-written. [onPhotosChanged] only fires when the published list really
/// changed, so consumers do not churn on every tick.
class FileSystemPhotoScanner {
  FileSystemPhotoScanner({
    required StorageProvider storageProvider,
    this.pollInterval = defaultPollInterval,
    this.debounceInterval = defaultDebounceInterval,
    this.settleAge = defaultSettleAge,
    this.settleRecheckInterval = defaultSettleRecheckInterval,
    bool watchForChanges = true,
  })  : _storageProvider = storageProvider,
        _watchForChanges = watchForChanges,
        // Start with the configured recheck delay instead of the static default.
        _settleDelay = settleRecheckInterval;

  /// Fallback rescan interval. The watcher is normally much faster, this only
  /// guarantees that changes are noticed at all.
  static const Duration defaultPollInterval = Duration(seconds: 60);

  /// Copying a single photo produces a burst of create/modify events; scanning
  /// on each of them is pure waste.
  static const Duration defaultDebounceInterval = Duration(milliseconds: 400);

  /// A file modified less than this ago is considered "possibly still being
  /// written" and waits until its size stopped changing.
  static const Duration defaultSettleAge = Duration(seconds: 5);

  /// Delay before re-scanning to find out whether pending files stopped growing.
  static const Duration defaultSettleRecheckInterval = Duration(seconds: 1);

  static const Set<String> _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  /// Suffix used for in-progress downloads (see WebDavSyncService).
  static const String _incompleteSuffix = '.part';

  final StorageProvider _storageProvider;
  final Duration pollInterval;
  final Duration debounceInterval;
  final Duration settleAge;
  final Duration settleRecheckInterval;

  bool _watchForChanges;

  /// Whether to react to file system events. Turning it off cancels a running
  /// watcher, which leaves only the periodic rescan. Turning it back on lets
  /// the next scan recreate the watcher.
  bool get watchForChanges => _watchForChanges;

  set watchForChanges(bool value) {
    if (_watchForChanges == value) return;
    _watchForChanges = value;
    if (!value) {
      unawaited(_cancelWatcher());
    }
  }

  final _log = Logger('FileSystemPhotoScanner');
  final _changedController = StreamController<void>.broadcast();

  List<PhotoEntry> _photos = [];

  /// File size per path as observed during the previous scan, used to detect
  /// that a new file stopped growing.
  final Map<String, int> _observedSizes = {};

  /// Paths seen on disk but not published yet because they may still grow.
  final Set<String> _pendingPaths = {};

  /// When a pending file was first seen, used to stop waiting after [settleAge]
  /// so a file can never stay invisible forever.
  final Map<String, DateTime> _pendingSince = {};

  /// Whether at least one scan of the current folder succeeded. Until then
  /// there is no baseline to judge "still being written" against.
  bool _hasBaseline = false;

  StreamSubscription<FileSystemEvent>? _watcher;
  String? _watchedPath;
  Timer? _pollTimer;
  Timer? _debounceTimer;
  Timer? _settleTimer;
  Duration _settleDelay = defaultSettleRecheckInterval;
  Future<void>? _runningScan;
  bool _rescanRequested = false;
  bool _disposed = false;

  /// The current photo list (newest scan wins).
  List<PhotoEntry> get photos => List.unmodifiable(_photos);

  /// Fires whenever [photos] actually changed (files added, removed or
  /// replaced by a newer version of the same file).
  Stream<void> get onPhotosChanged => _changedController.stream;

  /// Performs the initial scan and arms the watcher plus the periodic rescan.
  ///
  /// Calling it again (for instance via [initialize]) reloads the folder from
  /// scratch: everything present is published, and the settle check only
  /// applies to files that turn up afterwards.
  Future<void> start() async {
    if (_disposed) return;

    _hasBaseline = false;

    final dir = await _resolveDirectory();
    if (dir != null) {
      _log.info("Watching photo directory: ${dir.path}");
    }
    _pollTimer ??= Timer.periodic(
      pollInterval,
      (_) => unawaited(scan()),
    );
    await scan();
  }

  /// Cancels watcher and timers. The photo list is kept so the UI does not
  /// flash an empty slideshow while a rescan is pending.
  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _settleDelay = settleRecheckInterval;
    _observedSizes.clear();
    _pendingPaths.clear();
    _pendingSince.clear();
    await _cancelWatcher();
  }

  /// Rescans the directory now. Concurrent calls collapse into a single
  /// follow-up run, so a burst of file system events cannot pile up scans.
  Future<void> scan() {
    if (_disposed) return Future<void>.value();

    final running = _runningScan;
    if (running != null) {
      _rescanRequested = true;
      return running;
    }

    final completer = Completer<void>();
    _runningScan = completer.future;
    unawaited(
      _runScans().then(
        (_) {
          _runningScan = null;
          completer.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          _runningScan = null;
          _log.warning("Rescan failed", error, stackTrace);
          completer.complete();
        },
      ),
    );
    return completer.future;
  }

  Future<void> _runScans() async {
    do {
      _rescanRequested = false;
      await _scanOnce();
    } while (_rescanRequested && !_disposed);
  }

  Future<void> _scanOnce() async {
    final dir = await _resolveDirectory();
    if (dir == null) return;

    if (!await dir.exists()) {
      _log.fine("Photo directory does not exist yet: ${dir.path}");
      _observedSizes.clear();
      _pendingPaths.clear();
      _publish(const []);
      return;
    }

    // (Re)create the watcher: it is missing after start(), after a remount or
    // after the previous watcher reported an error.
    _ensureWatcher(dir);

    final List<File> files;
    try {
      files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
    } catch (e) {
      // Directory vanished or is unreadable while scanning (unmounted card,
      // revoked permission). Keep the current list, the next tick retries.
      _log.warning("Could not list photo directory ${dir.path}", e);
      return;
    }

    final now = DateTime.now();
    final previous = {for (final photo in _photos) photo.file.path: photo};
    final observed = <String, int>{};
    final stillPending = <String>{};
    final stillPendingSince = <String, DateTime>{};
    final next = <PhotoEntry>[];

    for (final file in files) {
      if (!_isImage(file.path)) continue;

      final FileStat stat;
      try {
        stat = await file.stat();
      } catch (e) {
        // Disappeared between listing and stat - just skip it this round.
        _log.fine("Skipping ${file.path}: $e");
        continue;
      }

      final path = file.path;
      observed[path] = stat.size;

      final existing = previous[path];
      if (existing != null && existing.sizeBytes == stat.size) {
        // Untouched file: keep the instance so runtime state (lastShown,
        // weight, lazily loaded EXIF) survives rescans.
        next.add(existing);
        continue;
      }

      // New file, or an existing one whose content changed.
      if (!_hasSettled(path, stat, now)) {
        stillPending.add(path);
        stillPendingSince[path] = _pendingSince[path] ?? now;
        // Keep showing the previous version until the new one is complete.
        if (existing != null) next.add(existing);
        continue;
      }

      next.add(
        PhotoEntry(
          file: file,
          date: stat.modified, // File date for shuffle algorithm
          createdAt: stat.changed,
          sizeBytes: stat.size,
        ),
      );
    }

    _observedSizes
      ..clear()
      ..addAll(observed);
    _pendingPaths
      ..clear()
      ..addAll(stillPending);
    _pendingSince
      ..clear()
      ..addAll(stillPendingSince);
    _hasBaseline = true;

    if (stillPending.isNotEmpty) {
      _log.fine(
        "Waiting for ${stillPending.length} file(s) to finish writing: "
        "${stillPending.join(', ')}",
      );
    }
    _scheduleSettleRecheck(stillPending.isNotEmpty);
    _publish(next);
  }

  Future<Directory?> _resolveDirectory() async {
    try {
      return await _storageProvider.getPhotoDirectory();
    } catch (e, stackTrace) {
      _log.warning("Could not resolve photo directory", e, stackTrace);
      return null;
    }
  }

  /// Decides whether a file that is new to the list (or whose content changed)
  /// can be shown right away.
  ///
  /// The very first scan of a folder is always trusted: there is no previous
  /// observation to compare against, and holding the whole slideshow back for
  /// [settleAge] on every start would be far more noticeable than briefly
  /// showing a photo that another app happens to be writing at that moment.
  ///
  /// Afterwards a file counts as complete when it was not touched for
  /// [settleAge] (an old file, or the copy already finished) or when its size
  /// did not change since the previous scan. A file that keeps changing for
  /// longer than [settleAge] is published anyway so it cannot stay invisible
  /// forever; the next scan then replaces it with the finished version.
  bool _hasSettled(String path, FileStat stat, DateTime now) {
    if (!_hasBaseline) return true;
    if (now.difference(stat.modified) >= settleAge) return true;
    if (_observedSizes[path] == stat.size) return true;

    final firstSeen = _pendingSince[path];
    return firstSeen != null && now.difference(firstSeen) >= settleAge;
  }

  void _scheduleSettleRecheck(bool hasPendingFiles) {
    _settleTimer?.cancel();
    if (!hasPendingFiles) {
      _settleDelay = settleRecheckInterval;
      return;
    }

    // Back off while a file keeps growing so a slow transfer does not turn
    // into a full directory listing every couple of seconds.
    _settleTimer = Timer(_settleDelay, () {
      if (_disposed) return;
      unawaited(scan());
    });
    final next = _settleDelay * 2;
    _settleDelay = next > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : next;
  }

  void _publish(List<PhotoEntry> next) {
    final changed = !_samePhotos(_photos, next);
    _photos = next;
    if (!changed) return;

    if (_disposed || _changedController.isClosed) return;
    _log.info("Photo list changed: ${next.length} photo(s).");
    _changedController.add(null);
  }

  bool _samePhotos(List<PhotoEntry> left, List<PhotoEntry> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!identical(left[i], right[i])) return false;
    }
    return true;
  }

  // ============================================================
  // Directory watching
  // ============================================================

  void _ensureWatcher(Directory dir) {
    if (_disposed) return;
    if (!watchForChanges) return;
    if (_watcher != null && _watchedPath == dir.path) return;
    unawaited(_cancelWatcher());

    try {
      _watcher = dir
          .watch(events: FileSystemEvent.all, recursive: true)
          .listen(
            _onFileSystemEvent,
            onError: (Object error, StackTrace stackTrace) {
              _log.warning(
                "Watcher for ${dir.path} stopped working, relying on periodic rescans",
                error,
                stackTrace,
              );
              _watcher = null;
            },
            onDone: () {
              // Watched directory was removed or unmounted. The next scan
              // recreates the watcher.
              _watcher = null;
            },
          );
      _watchedPath = dir.path;
      _log.fine("Watching ${dir.path} for file changes");
    } catch (e) {
      // Directory does not exist (yet) or the platform/file system does not
      // support watching. The periodic rescan still keeps the list fresh.
      _log.warning(
        "File watching unavailable for ${dir.path}, using periodic rescans only",
        e,
      );
      _watcher = null;
    }
  }

  Future<void> _cancelWatcher() async {
    final watcher = _watcher;
    _watcher = null;
    _watchedPath = null;
    await watcher?.cancel();
  }

  void _onFileSystemEvent(FileSystemEvent event) {
    if (_disposed) return;
    if (!_affectsPhotoList(event)) return;

    _log.fine("File change: ${event.type} ${event.path}");
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceInterval, () {
      unawaited(scan());
    });
  }

  bool _affectsPhotoList(FileSystemEvent event) {
    if (event.isDirectory) return true;
    if (event is FileSystemMoveEvent) {
      // For a move the interesting path is the destination: a finished
      // download is renamed *from* .part *to* an image extension and has to
      // trigger a scan, while a rename *to* .part is an in-progress download.
      final destination = event.destination;
      return destination == null || !_isIncomplete(destination);
    }
    return !_isIncomplete(event.path);
  }

  static bool _isImage(String path) {
    final lower = path.toLowerCase();
    for (final extension in _imageExtensions) {
      if (lower.endsWith(extension)) return true;
    }
    return false;
  }

  static bool _isIncomplete(String path) => path.endsWith(_incompleteSuffix);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(stop());
    unawaited(_changedController.close());
  }
}
