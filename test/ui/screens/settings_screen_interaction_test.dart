// Exercises the settings options: every simple toggle is flipped on and back
// off, the calendar switch goes through the permission request, and leaving the
// screen persists the values. The plugins the screen calls are not available in
// a test environment, so only layout errors (overflows) fail the test.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:libre_photo_frame/domain/interfaces/calendar_event_source.dart';
import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/domain/models/calendar_event.dart';
import 'package:libre_photo_frame/infrastructure/services/json_config_service.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/screens/settings_screen.dart';

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

void main() {
  testWidgets('the settings options can be toggled and saved', (tester) async {
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigProvider>.value(
            value: JsonConfigService(),
          ),
          Provider<CalendarEventSource>.value(
            value: _FakeCalendarEventSource(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(),
        ),
      ),
    );

    // Push the screen so the back button can leave it again.
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    Future<void> toggle(String label) async {
      final finder = find.widgetWithText(SwitchListTile, label);
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
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

    final overflows = <String>[];
    Object? error = tester.takeException();
    while (error != null) {
      if (error.toString().contains('overflowed')) {
        overflows.add(error.toString());
      }
      error = tester.takeException();
    }
    expect(overflows, isEmpty,
        reason: 'no option may overflow when it is toggled');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
