import 'dart:io';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:logging/logging.dart';
import '../../domain/interfaces/calendar_event_source.dart';
import '../../domain/models/calendar_event.dart';

/// Reads the events already stored in the Android calendar (Nextcloud through
/// DAVx5, Google, local accounts...).
///
/// Android only: no other platform has a device calendar to show, so there the
/// source reports no access and no events instead of failing.
class DeviceCalendarEventSource implements CalendarEventSource {
  final _log = Logger('DeviceCalendarEventSource');

  @override
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await DeviceCalendar.instance.hasPermissions() ==
          CalendarPermissionStatus.granted;
    } on Exception catch (e) {
      _log.warning('Calendar permission check failed', e);
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await DeviceCalendar.instance.requestPermissions() ==
          CalendarPermissionStatus.granted;
    } on Exception catch (e) {
      _log.warning('Calendar permission request failed', e);
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    if (!Platform.isAndroid) return;
    await DeviceCalendar.instance.openAppSettings();
  }

  @override
  Future<List<CalendarEvent>> eventsBetween(DateTime from, DateTime to) async {
    if (!Platform.isAndroid) return const [];
    // listEvents returns the occurrences overlapping [from, to), sorted by
    // start, so recurring events are already expanded.
    final events = await DeviceCalendar.instance.listEvents(from, to);
    return events
        .map(
          (event) => CalendarEvent(
            title: event.title,
            start: event.startDate,
            end: event.endDate,
            allDay: event.isAllDay,
          ),
        )
        .toList();
  }
}
