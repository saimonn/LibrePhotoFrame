// Regression test for the settings layout.
//
// The trailing dropdown of a ListTile is measured with the width of its widest
// item, which squeezed the row titles until they wrapped one letter per line
// (issue 05). The settings screen is rendered here at two screen sizes and in
// the four shipped languages, so a translation that no longer fits fails the
// test instead of the frame.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:test_api/scaffolding.dart' show Timeout;

import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/json_config_service.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/screens/settings_screen.dart';

/// Sizes the settings are used at, in logical pixels.
const _screenSizes = <String, Size>{
  'phone portrait': Size(392, 873),
  'tablet landscape': Size(1280, 800),
};

/// Width the row titles must keep, whatever the length of the labels.
const _minimumTitleWidth = 100.0;

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final screen in _screenSizes.entries) {
      testWidgets(
        'the settings rows fit on ${screen.key} in ${locale.languageCode}',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          // Without this the screen reads the version of the test executable
          // from the file system, and its errors are unhandled.
          PackageInfo.setMockInitialValues(
            appName: 'LibrePhotoFrame',
            packageName: 'io.github.saimonn.librephotoframe',
            version: '1.12.1',
            buildNumber: '1',
            buildSignature: '',
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/lpf-layout-test',
          );

          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = screen.value;
          addTearDown(tester.view.reset);

          final l10n = await AppLocalizations.delegate.load(locale);
          await tester.pumpWidget(
            ChangeNotifierProvider<ConfigProvider>.value(
              value: JsonConfigService(),
              child: MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const SettingsScreen(),
              ),
            ),
          );
          await tester.pump();

          // Scroll the whole list: a row is only laid out when it is reached.
          final title = find.text(l10n.photoOrder);
          final scrollable = find.byType(Scrollable).first;
          for (var i = 0; i < 24 && title.evaluate().isEmpty; i++) {
            await tester.drag(scrollable, const Offset(0, -350));
            await tester.pump();
          }

          expect(title, findsOneWidget,
              reason: 'the photo order row must be reachable');
          expect(tester.getSize(title).width,
              greaterThanOrEqualTo(_minimumTitleWidth),
              reason: 'the photo order title must keep a usable width');

          // The plugins of the screen fail in a test environment, only the
          // rendering errors have to fail the test.
          final overflows = <String>[];
          Object? error = tester.takeException();
          while (error != null) {
            if (error.toString().contains('overflowed')) overflows.add('$error');
            error = tester.takeException();
          }
          expect(overflows, isEmpty);
        },
        // A broken widget test used to stall the whole suite for the default
        // ten minutes per test instead of failing.
        timeout: const Timeout(Duration(seconds: 60)),
      );
    }
  }
}
