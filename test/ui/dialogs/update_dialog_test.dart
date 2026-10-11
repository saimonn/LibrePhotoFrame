import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/config_provider.dart';
import 'package:libre_photo_frame/infrastructure/services/update_service.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/dialogs/update_dialog.dart';

class FakeConfig extends ChangeNotifier implements ConfigProvider {
  @override
  String? autoUpdateSkippedVersion;

  @override
  Future<void> save() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const info = UpdateInfo(
    version: '9.9.9',
    tag: 'v9.9.9',
    downloadUrl: 'https://example.com/app.apk',
    assetName: 'app.apk',
  );

  testWidgets('shows the update and remembers a skip', (tester) async {
    final config = FakeConfig();
    final service = UpdateService(configProvider: config);

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const Scaffold();
          },
        ),
      ),
    );

    showUpdateDialog(context, info, service);
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.textContaining('9.9.9'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Download & install'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(config.autoUpdateSkippedVersion, '9.9.9');
    expect(find.text('Update available'), findsNothing);
  });
}
