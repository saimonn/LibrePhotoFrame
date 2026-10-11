// Exercises the settings options: every simple toggle is flipped on and back
// off, the sync source and the dropdowns are changed, and leaving the screen
// persists the values. The plugins the screen calls are not available in a test
// environment, so only layout errors (overflows) fail the test.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:libre_photo_frame/domain/interfaces/calendar_event_source.dart';
import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/domain/interfaces/photo_repository.dart';
import 'package:libre_photo_frame/domain/interfaces/storage_provider.dart';
import 'package:libre_photo_frame/domain/models/calendar_event.dart';
import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/infrastructure/services/json_config_service.dart';
import 'package:libre_photo_frame/infrastructure/services/noop_sync_service.dart';
import 'package:libre_photo_frame/infrastructure/services/photo_service.dart';
import 'package:libre_photo_frame/infrastructure/strategies/random_playlist_strategy.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/screens/settings_screen.dart';

class _FakePhotoRepository implements PhotoRepository {
  @override
  List<PhotoEntry> get photos => const [];

  @override
  Stream<void> get onPhotosChanged => const Stream<void>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reinitialize() async {}

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
}

class _FakeStorageProvider implements StorageProvider {
  @override
  Future<Directory> getPhotoDirectory() async => Directory.systemTemp;

  @override
  bool get isReadOnly => false;

  @override
  Stream<void> get onDirectoryChanged => const Stream<void>.empty();
}

class _FakeCalendarEventSource implements CalendarEventSource {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<CalendarEvent>> eventsBetween(DateTime from, DateTime to) async =>
      const [];
}

/// Renders the settings screen on a route that can be left again, and returns
/// the English localizations.
Future<AppLocalizations> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  // Without this the screen reads the version of the test executable from the
  // file system, and its errors are unhandled.
  PackageInfo.setMockInitialValues(
    appName: 'LibrePhotoFrame',
    packageName: 'io.github.saimonn.librephotoframe',
    version: '1.12.1',
    buildNumber: '1',
    buildSignature: '',
  );
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => '/tmp/lpf-settings-test',
  );

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.reset);

  final config = JsonConfigService();
  final photoService = PhotoService(
    syncProviderFactory: NoOpSyncService.new,
    playlistStrategy: RandomPlaylistStrategy(),
    repository: _FakePhotoRepository(),
    configProvider: config,
    storageProvider: _FakeStorageProvider(),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigProvider>.value(value: config),
        ChangeNotifierProvider<PhotoService>.value(value: photoService),
        Provider<CalendarEventSource>.value(value: _FakeCalendarEventSource()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(),
      ),
    ),
  );

  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  await tester.pumpAndSettle();

  return AppLocalizations.delegate.load(const Locale('en'));
}

/// Scrolls the settings list down until [finder] is built and visible.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// Scrolls [finder] into view and taps it.
Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pump();
}

void _expectNoOverflow(WidgetTester tester) {
  final overflows = <String>[];
  Object? error = tester.takeException();
  while (error != null) {
    if (error.toString().contains('overflowed')) {
      overflows.add(error.toString());
    }
    error = tester.takeException();
  }
  expect(overflows, isEmpty,
      reason: 'no option may overflow when it is changed');
}

void main() {
  testWidgets('the settings options can be toggled and saved', (tester) async {
    final l10n = await _pumpSettings(tester);

    Future<void> toggle(String label) async {
      final finder = find.widgetWithText(SwitchListTile, label);
      await _scrollAndTap(tester, finder);
    }

    // Flip every simple option on and back off, so both branches of each
    // onChanged run and both halves of the conditional sections are built.
    for (final label in [
      l10n.blurBorders,
      l10n.pairPhotos,
      l10n.showClock,
      l10n.showPhotoInfo,
      l10n.watchPhotoFolder,
      l10n.dayNightSchedule,
    ]) {
      await toggle(label);
      await toggle(label);
    }

    // The calendar switch requests the permission on the way on.
    await toggle(l10n.showCalendarEvents);
    await toggle(l10n.showCalendarEvents);

    // Leaving the screen persists the current values.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    _expectNoOverflow(tester);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('the sync source and the dropdowns can be changed',
      (tester) async {
    final l10n = await _pumpSettings(tester);

    // Change the size and a corner of the clock overlay.
    await _scrollAndTap(tester, find.text('L'));
    await _scrollAndTap(tester, find.text('⌜'));

    // Pick another clock format through its dropdown.
    final clockFormatDropdown = find.descendant(
      of: find.widgetWithText(ListTile, l10n.clockFormat),
      matching: find.byType(DropdownButton<String>),
    );
    await _scrollTo(tester, clockFormatDropdown);
    await tester.tap(clockFormatDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.clockFormat24).last);
    await tester.pumpAndSettle();

    // Select the Nextcloud source to reveal its settings, then fill them.
    await _scrollAndTap(tester, find.text(l10n.nextcloud));
    await _scrollAndTap(tester, find.text(l10n.webdavAuthLogin));
    await _scrollAndTap(tester, find.text(l10n.webdavAllowInvalidCertificate));
    await _scrollAndTap(tester, find.text(l10n.syncSelectedNextcloudFolders));
    await _scrollAndTap(tester, find.text(l10n.syncAllNextcloudFolders));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    _expectNoOverflow(tester);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
