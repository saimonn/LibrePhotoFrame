import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/widgets/photo_info_layers.dart';
import 'package:libre_photo_frame/ui/widgets/photo_info_overlay.dart';

/// Regression test for issue 12.
///
/// The overlay of the second photo of a split screen was positioned with the
/// physical frame size, so on a 1.5x display it landed in the middle of the
/// frame instead of the second half, and a right/bottom corner fell off the
/// frame entirely. The placement must use the logical frame, the space
/// `Positioned` works in.
void main() {
  PhotoEntry photo(String path) {
    final entry = PhotoEntry(
      file: File(path),
      date: DateTime(2026, 6, 1),
      sizeBytes: 1024,
    );
    entry.setExifMetadata(captureDate: DateTime(2026, 6, 1, 12));
    return entry;
  }

  Future<void> pumpLayers(
    WidgetTester tester, {
    required Size logicalFrame,
    required double devicePixelRatio,
    PhotoEntry? partner,
  }) async {
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.physicalSize = logicalFrame * devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PhotoInfoLayers(
            photo: photo('/first.jpg'),
            partner: partner,
            overlayBuilder: (entry) => PhotoInfoOverlay(
              photo: entry,
              position: 'topLeft',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect overlayRect(WidgetTester tester, int index) =>
      tester.getRect(find.byType(PhotoInfoOverlay).at(index));

  testWidgets('a stacked split puts the second date in the second half',
      (tester) async {
    // 1.5x display: the density of the tablet that reported the bug.
    const logical = Size(800, 1280);
    await pumpLayers(
      tester,
      logicalFrame: logical,
      devicePixelRatio: 1.5,
      partner: photo('/second.jpg'),
    );

    expect(find.byType(PhotoInfoOverlay), findsNWidgets(2));

    // The first photo takes the top half, the second the bottom one.
    expect(overlayRect(tester, 0).top, 0);
    expect(overlayRect(tester, 1).top, closeTo(logical.height / 2, 2));
    // The physical-size bug hid it at 1.5 * height / 2 = 960.
    expect(overlayRect(tester, 1).top, lessThan(logical.height / 2 + 5));
  });

  testWidgets('a side by side split puts the second date in the second half',
      (tester) async {
    const logical = Size(1280, 800);
    await pumpLayers(
      tester,
      logicalFrame: logical,
      devicePixelRatio: 1.5,
      partner: photo('/second.jpg'),
    );

    expect(find.byType(PhotoInfoOverlay), findsNWidgets(2));

    expect(overlayRect(tester, 0).left, 0);
    expect(overlayRect(tester, 1).left, closeTo(logical.width / 2, 2));
    expect(overlayRect(tester, 1).left, lessThan(logical.width / 2 + 5));
  });

  testWidgets('a single photo fills the frame', (tester) async {
    const logical = Size(800, 1280);
    await pumpLayers(
      tester,
      logicalFrame: logical,
      devicePixelRatio: 1.5,
    );

    expect(find.byType(PhotoInfoOverlay), findsOneWidget);
    expect(overlayRect(tester, 0), Offset.zero & logical);
  });
}
