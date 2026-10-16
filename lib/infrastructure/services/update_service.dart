import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/interfaces/config_provider.dart';
import '../../domain/services/version_comparison.dart';
import 'native_updater_service.dart';

/// A release available on GitHub.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tag,
    required this.downloadUrl,
    required this.assetName,
    this.releaseNotes,
  });

  /// Semantic version without leading 'v' (e.g. "1.11.0").
  final String version;
  final String tag;
  final String downloadUrl;
  final String assetName;
  final String? releaseNotes;
}

typedef UpdatePromptCallback = void Function(UpdateInfo info);

/// Opt-in self-update against GitHub releases.
///
/// Checks at most once per [_checkInterval], compares against the installed
/// version, and either installs silently (Device Owner + opt-in) or asks the
/// UI to prompt the user. Not included in Play Store builds.
class UpdateService extends ChangeNotifier with WidgetsBindingObserver {
  UpdateService({required ConfigProvider configProvider, Dio? dio})
    : _config = configProvider,
      _dio = dio ?? Dio();

  static const _owner = 'saimonn';
  static const _repo = 'LibrePhotoFrame';

  /// Periodic fallback interval while the app keeps running.
  static const _checkInterval = Duration(hours: 8);

  /// Minimum gap between opportunistic checks (app start / resume) so frequent
  /// restarts or wake-ups don't hammer GitHub.
  static const _minCheckGap = Duration(hours: 4);

  final ConfigProvider _config;
  final Dio _dio;
  final _log = Logger('UpdateService');

  Timer? _timer;
  bool _busy = false;

  /// Invoked when a (non-silent) update should be presented to the user.
  UpdatePromptCallback? onUpdateAvailable;

  double? _downloadProgress;
  double? get downloadProgress => _downloadProgress;

  bool _installing = false;
  bool get isInstalling => _installing;

  void start() {
    if (!Platform.isAndroid) return;
    _timer?.cancel();
    // 8h periodic fallback while the app stays alive.
    _timer = Timer.periodic(_checkInterval, (_) => checkForUpdate());
    // Check on every resume (e.g. the frame waking from its night schedule),
    // and once at startup.
    WidgetsBinding.instance.addObserver(this);
    unawaited(cleanApkCache());
    unawaited(_maybeCheckOpportunistic());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeCheckOpportunistic());
    }
  }

  /// A check triggered by app start or resume, throttled to at most once per
  /// [_minCheckGap] so restarts/wake-ups don't check too often.
  Future<void> _maybeCheckOpportunistic() async {
    if (!_config.autoUpdateEnabled) return;
    final last = _config.autoUpdateLastCheck;
    if (last != null && DateTime.now().difference(last) < _minCheckGap) {
      return;
    }
    await checkForUpdate();
  }

  /// Checks GitHub for a newer release. Returns the update if a newer one is
  /// available (and not skipped), else null. Triggers the silent install or the
  /// prompt callback as configured.
  Future<UpdateInfo?> checkForUpdate({bool manual = false}) async {
    if (!Platform.isAndroid) return null;
    if (!manual && !_config.autoUpdateEnabled) return null;
    if (_busy) return null;
    _busy = true;
    try {
      final info = await _fetchLatest();
      _config.autoUpdateLastCheck = DateTime.now();
      await _config.save();
      if (info == null) return null;

      final pkg = await PackageInfo.fromPlatform();
      if (compareVersions(info.version, pkg.version) <= 0) {
        _log.info(
          'No newer release (current ${pkg.version}, latest ${info.version})',
        );
        return null;
      }
      if (!manual && _config.autoUpdateSkippedVersion == info.version) {
        _log.info('Update ${info.version} was skipped by user');
        return null;
      }

      if (_config.autoUpdateSilent &&
          await NativeUpdaterService.isDeviceOwner()) {
        _log.info('Silently updating to ${info.version}');
        await downloadAndInstall(info);
      } else {
        onUpdateAvailable?.call(info);
      }
      return info;
    } catch (e, st) {
      _log.warning('Update check failed', e, st);
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<UpdateInfo?> _fetchLatest() async {
    final data = await _fetchRelease();
    if (data == null) return null;

    final version = releaseVersion(data);
    if (version == null) return null;
    final tag = '${data['tag_name'] ?? ''}';

    final assets = (data['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final abis = await NativeUpdaterService.getSupportedAbis();
    final asset = _pickAsset(assets, abis);
    if (asset == null) {
      _log.warning('No installable APK asset found in latest release');
      return null;
    }

    return UpdateInfo(
      version: version,
      tag: tag,
      downloadUrl: '${asset['browser_download_url']}',
      assetName: '${asset['name']}',
      releaseNotes: data['body'] as String?,
    );
  }

  /// Returns the release to install from. The stable channel asks GitHub for
  /// the latest release, which already excludes prereleases; the opt-in beta
  /// channel lists the releases and takes the newest versioned one
  /// (prereleases included, moving tags such as `dev-latest` resolved through
  /// the release name).
  Future<Map<String, dynamic>?> _fetchRelease() async {
    final options = Options(
      responseType: ResponseType.json,
      headers: {'Accept': 'application/vnd.github+json'},
    );

    if (_config.updateChannel == 'beta') {
      final res = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases?per_page=30',
        options: options,
      );
      return newestRelease(res.data as List<dynamic>);
    }

    final res = await _dio.get(
      'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      options: options,
    );
    return res.data as Map<String, dynamic>;
  }

  /// Picks the APK asset matching the device ABI, falling back to a universal
  /// APK (no ABI tag) and finally the first APK.
  Map<String, dynamic>? _pickAsset(
    List<Map<String, dynamic>> assets,
    List<String> abis,
  ) {
    final apks = assets
        .where((a) => '${a['name']}'.toLowerCase().endsWith('.apk'))
        .toList();
    if (apks.isEmpty) return null;

    for (final abi in abis) {
      for (final apk in apks) {
        if ('${apk['name']}'.toLowerCase().contains(abi.toLowerCase())) {
          return apk;
        }
      }
    }
    for (final apk in apks) {
      final name = '${apk['name']}'.toLowerCase();
      if (!name.contains('arm') && !name.contains('x86')) return apk;
    }
    return apks.first;
  }

  /// Remembers [info] as skipped so it is not prompted again.
  Future<void> skip(UpdateInfo info) async {
    _config.autoUpdateSkippedVersion = info.version;
    await _config.save();
  }

  /// Downloads the APK and triggers installation (silent or prompted).
  Future<bool> downloadAndInstall(UpdateInfo info) async {
    if (_installing) return false;
    _installing = true;
    _downloadProgress = 0;
    notifyListeners();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${info.assetName}');
      await _dio.download(
        info.downloadUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );
      _downloadProgress = null;
      notifyListeners();
      return await NativeUpdaterService.installApk(file.path);
    } catch (e, st) {
      _log.warning('Download/install failed', e, st);
      return false;
    } finally {
      _installing = false;
      _downloadProgress = null;
      notifyListeners();
    }
  }

  /// Deletes the update APKs left in the temporary directory.
  ///
  /// Every downloaded APK stays there after the install, so they accumulate
  /// (one per version). Only the newest is kept, and only when it is strictly
  /// newer than the running build: an install that was downloaded but not
  /// applied yet is then not fetched again.
  Future<void> cleanApkCache() async {
    if (!Platform.isAndroid) return;
    try {
      final dir = await getTemporaryDirectory();
      final apks = (await dir.list().toList())
          .whereType<File>()
          .where((file) => apkVersion(_fileName(file)) != null)
          .toList();
      if (apks.isEmpty) return;

      final current = (await PackageInfo.fromPlatform()).version;
      final keep = apkToKeep(apks.map(_fileName), current);
      for (final apk in apks) {
        if (_fileName(apk) == keep) continue;
        await apk.delete();
        _log.info('Deleted cached APK ${apk.path}');
      }
    } catch (e, st) {
      _log.warning('APK cache cleanup failed', e, st);
    }
  }
}

/// File name of a directory entry.
String _fileName(File file) => file.uri.pathSegments.last;

/// Prefix of the update APK names published in the GitHub releases.
const _apkPrefix = 'LibrePhotoFrame-';

/// Suffixes the release workflow appends after the version in an APK name.
const _apkSuffixes = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'debug'];

/// Version carried by an update APK name
/// (`LibrePhotoFrame-1.13.17-arm64-v8a.apk`), or null for another file.
String? apkVersion(String name) {
  if (!name.startsWith(_apkPrefix) || !name.endsWith('.apk')) return null;
  var label = name.substring(_apkPrefix.length, name.length - 4);
  for (final suffix in _apkSuffixes) {
    if (label.endsWith('-$suffix')) {
      label = label.substring(0, label.length - suffix.length - 1);
      break;
    }
  }
  return isVersionTag(label) ? label : null;
}

/// Update APK to keep among the cached [names]: the newest, but only when it is
/// strictly newer than [currentVersion] (an install that is still pending), so
/// that it does not have to be downloaded again. Returns null when all of them
/// can be deleted.
String? apkToKeep(Iterable<String> names, String currentVersion) {
  String? newest;
  String? newestVersion;
  for (final name in names) {
    final version = apkVersion(name);
    if (version == null) continue;
    if (newestVersion == null || compareVersions(version, newestVersion) > 0) {
      newest = name;
      newestVersion = version;
    }
  }
  if (newestVersion == null) return null;
  return compareVersions(newestVersion, currentVersion) > 0 ? newest : null;
}

/// Version carried by a release: its tag when that is a version tag, else its
/// name when that looks like one (moving tags such as `dev-latest` carry the
/// version in the release name instead).
String? releaseVersion(Map<String, dynamic> release) {
  for (final value in [release['tag_name'], release['name']]) {
    final candidate = '${value ?? ''}';
    if (isVersionTag(candidate)) {
      return candidate.startsWith('v') ? candidate.substring(1) : candidate;
    }
  }
  return null;
}

/// Picks the newest non-draft release that carries a version, prereleases
/// included. The list order is not relied upon: versions are compared so the
/// moving `dev-latest` release competes fairly with versioned tags.
Map<String, dynamic>? newestRelease(List<dynamic> releases) {
  Map<String, dynamic>? best;
  String? bestVersion;
  for (final release in releases.whereType<Map<String, dynamic>>()) {
    if (release['draft'] == true) continue;
    final version = releaseVersion(release);
    if (version == null) continue;
    if (bestVersion == null || compareVersions(version, bestVersion) > 0) {
      best = release;
      bestVersion = version;
    }
  }
  return best;
}
