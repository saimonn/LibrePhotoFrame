import 'package:flutter/material.dart';
import '../../domain/models/calendar_event.dart';
import '../../l10n/app_localizations.dart';
import 'overlay_position.dart';

/// Shows the events of today and tomorrow in one corner of the frame.
class CalendarOverlay extends StatelessWidget {
  const CalendarOverlay({
    super.key,
    required this.events,
    required this.position,
    this.size = 'medium',
    this.maxEvents = 6,
  });

  final List<CalendarEvent> events;

  /// One of 'bottomRight', 'bottomLeft', 'topRight', 'topLeft'.
  final String position;

  /// One of 'small', 'medium', 'large'.
  final String size;

  /// Upper bound on the event lines, so a busy day cannot cover the photo.
  final int maxEvents;

  double get _fontSize {
    switch (size) {
      case 'large':
        return 32;
      case 'medium':
        return 24;
      case 'small':
      default:
        return 18;
    }
  }

  List<CalendarEvent> _eventsOn(DateTime day) {
    final dayEvents = events
        .where((event) => DateUtils.isSameDay(event.start, day))
        .toList();
    dayEvents.sort((a, b) => a.start.compareTo(b.start));
    return dayEvents;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final lines = <Widget>[];
    var shown = 0;
    var truncated = false;

    void addDay(DateTime day, String label) {
      final dayEvents = _eventsOn(day);
      if (dayEvents.isEmpty || truncated) return;
      lines.add(_buildText(label, bold: true));
      for (final event in dayEvents) {
        if (shown >= maxEvents) {
          truncated = true;
          break;
        }
        lines.add(_buildText(_formatEvent(context, event)));
        shown++;
      }
    }

    addDay(today, l10n.calendarToday);
    addDay(tomorrow, l10n.calendarTomorrow);
    if (lines.isEmpty) return const SizedBox.shrink();
    if (truncated) lines.add(_buildText('…'));

    final screen = MediaQuery.of(context).size;
    final placement = OverlayPosition.of(position);
    return Align(
      alignment: placement.alignment,
      child: Padding(
        padding: placement.padding,
        child: ConstrainedBox(
          // Only the width is capped: the event count is already bounded, so
          // the block stays a corner label instead of covering the photo.
          constraints: BoxConstraints(maxWidth: screen.width * 0.45),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: placement.crossAxisAlignment,
            children: lines,
          ),
        ),
      ),
    );
  }

  String _formatEvent(BuildContext context, CalendarEvent event) {
    if (event.allDay) return event.title;
    final time = TimeOfDay.fromDateTime(event.start).format(context);
    return '$time  ${event.title}';
  }

  Widget _buildText(String text, {bool bold = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.w400,
        color: Colors.white,
        shadows: const [
          // Shadow for readability on any background
          Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black54),
          Shadow(offset: Offset(-1, -1), blurRadius: 4, color: Colors.black26),
        ],
      ),
    );
  }
}
