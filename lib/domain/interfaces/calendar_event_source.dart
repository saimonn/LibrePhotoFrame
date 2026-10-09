import '../models/calendar_event.dart';

/// Reads the events of the calendar the device already holds, for example the
/// ones Nextcloud synced through DAVx5, so the frame can show them.
abstract class CalendarEventSource {
  /// Whether calendar access is granted, without showing any system dialog.
  Future<bool> hasPermission();

  /// Asks for calendar access, showing the system dialog when it can.
  Future<bool> requestPermission();

  /// Opens the system settings page of the app, so the user can grant access
  /// again after a permanent denial.
  Future<void> openAppSettings();

  /// Events overlapping the half-open range [from, to), sorted by start.
  Future<List<CalendarEvent>> eventsBetween(DateTime from, DateTime to);
}
