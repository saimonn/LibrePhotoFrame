import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:libre_photo_frame/domain/models/calendar_event.dart';
import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/widgets/calendar_overlay.dart';

/// Calendar overlay (issue 11): today's and tomorrow's events, in the chosen
/// corner, with all-day events shown without a time.
void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));

  CalendarEvent event(
    String title, {
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    bool allDay = false,
  }) {
    return CalendarEvent(
      title: title,
      start: start,
      end: start.add(duration),
      allDay: allDay,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    List<CalendarEvent> events, {
    String position = 'topRight',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: CalendarOverlay(events: events, position: position),
        ),
      ),
    );
  }

  testWidgets('shows nothing without events', (tester) async {
    await pump(tester, const []);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('groups the events of today and tomorrow under their day',
      (tester) async {
    await pump(tester, [
      event('Standup', start: today.add(const Duration(hours: 9))),
      event('Dentist', start: tomorrow.add(const Duration(hours: 14))),
    ]);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.textContaining('Standup'), findsOneWidget);
    expect(find.textContaining('Dentist'), findsOneWidget);
  });

  testWidgets('shows an all-day event without a time', (tester) async {
    await pump(tester, [
      event('Holiday', start: today, allDay: true),
    ]);

    expect(find.text('Holiday'), findsOneWidget);
  });

  testWidgets('ignores the events outside the two days', (tester) async {
    await pump(tester, [
      event('Yesterday', start: today.subtract(const Duration(days: 1))),
      event('Next week', start: today.add(const Duration(days: 7))),
    ]);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('caps the number of events and marks the overflow',
      (tester) async {
    final events = List.generate(
      8,
      (index) => event('Event $index', start: today.add(Duration(hours: index))),
    );

    await pump(tester, events);

    expect(find.text('Today'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(8)); // header + 6 events + ellipsis
    expect(find.text('…'), findsOneWidget);
  });
}
