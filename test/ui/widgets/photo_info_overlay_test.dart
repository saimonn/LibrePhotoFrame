import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:libre_photo_frame/domain/models/photo_entry.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/widgets/photo_info_overlay.dart';

/// Photo info overlay (issue 10): the location has to be shown whether or not
/// geocoding resolved a place name.
void main() {
  PhotoEntry photo({DateTime? captureDate, double? latitude, double? longitude}) {
    final entry = PhotoEntry(
      file: File('/fake/frame.jpg'),
      date: DateTime(2026, 6, 1),
      sizeBytes: 1024,
    );
    entry.setExifMetadata(
      captureDate: captureDate,
      latitude: latitude,
      longitude: longitude,
    );
    return entry;
  }

  Future<void> pump(
    WidgetTester tester,
    PhotoEntry entry, {
    String? locationName,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PhotoInfoOverlay(
            photo: entry,
            position: 'topLeft',
            locationName: locationName,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the coordinates when no place name was resolved',
      (tester) async {
    final entry = photo(captureDate: DateTime(2026, 6, 1, 12), latitude: 48.5, longitude: 11.5);

    await pump(tester, entry);

    expect(find.text('June 1, 2026'), findsOneWidget);
    expect(find.text('48.500, 11.500'), findsOneWidget);
  });

  testWidgets('prefers the resolved place name over the coordinates',
      (tester) async {
    final entry = photo(latitude: 48.5, longitude: 11.5);

    await pump(tester, entry, locationName: 'Munich, Bavaria, Germany');

    expect(find.text('Munich, Bavaria, Germany'), findsOneWidget);
    expect(find.text('48.500, 11.500'), findsNothing);
  });

  testWidgets('shows only the date when the photo carries no location',
      (tester) async {
    final entry = photo(captureDate: DateTime(2026, 6, 1, 12));

    await pump(tester, entry);

    expect(find.text('June 1, 2026'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows nothing without a date and without a location',
      (tester) async {
    await pump(tester, photo());

    expect(find.byType(Text), findsNothing);
  });
}
