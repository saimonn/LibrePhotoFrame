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

/// Channel names the plugins of the screen may use. Registering a handler for a
/// channel that is never called is harmless.
const _pathProviderChannels = [
  'plugins.flutter.io/path_provider',
  'xyz.luan.flutter/path_provider',
  'xyz.luan.flutter/path_provider_linux',
  'xyz.luan.flutter/path_provider_android',
];

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final screen in _screenSizes.entries) {
      testWidgets(
        'the settings rows fit on ${screen.key} in ${locale.languageCode}',
        (tester) async {
          final messenger = tester.binding.defaultBinaryMessenger;
          SharedPreferences.setMockInitialValues({});
          messenger.setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            (call) async => <String, Object?>{
              'appName': 'LibrePhotoFrame',
              'packageName': 'io.github.saimonn.librephotoframe',
              'version': '1.12.1',
              'buildNumber': '1',
            },
          );
          for (final name in _pathProviderChannels) {
            messenger.setMockMethodCallHandler(
              MethodChannel(name),
              (call) async =>
                  call.method.startsWith('getExternal') ? null : '/tmp/lpf-test',
            );
          }

          // Only the rendering errors matter here: the screen calls plugins
          // that do not exist in a test, and those must not fail the test.
          final overflows = <String>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              overflows.add(details.exceptionAsString());
            }
          };
          addTearDown(() => FlutterError.onError = previousOnError);

          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = screen.value;
          addTearDown(tester.view.reset);

          final l10n = await AppLocalizations.delegate.load(locale);
          print('lpf-layout ${locale.languageCode} ${screen.key}: l10n loaded');
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
          print('lpf-layout ${locale.languageCode} ${screen.key}: pumped widget');
          await tester.pump();
          print('lpf-layout ${locale.languageCode} ${screen.key}: pumped frame');

          // Scroll the whole list: a row is only laid out when it is reached.
          final title = find.text(l10n.photoOrder);
          final scrollable = find.byType(Scrollable).first;
          for (var i = 0; i < 24 && title.evaluate().isEmpty; i++) {
            await tester.drag(scrollable, const Offset(0, -350));
            await tester.pump();
            print('lpf-layout ${locale.languageCode} ${screen.key}: drag $i');
          }

          expect(title, findsOneWidget,
              reason: 'the photo order row must be reachable');
          expect(tester.getSize(title).width,
              greaterThanOrEqualTo(_minimumTitleWidth),
              reason: 'the photo order title must keep a usable width');
          expect(overflows, isEmpty);
          print('lpf-layout ${locale.languageCode} ${screen.key}: measured '
              '${tester.getSize(title).width} px wide, ${overflows.length} overflow');
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }
  }
}