/// A calendar event the overlay shows, independent of the plugin that reads it.
class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
}
