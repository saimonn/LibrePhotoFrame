import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'overlay_position.dart';

/// A beautiful clock overlay widget with customizable size and position.
class ClockOverlay extends StatefulWidget {
  final String size; // 'small', 'medium', 'large'
  final String position; // 'bottomRight', 'bottomLeft', 'topRight', 'topLeft'
  final String format; // 'auto', '12' or '24'

  const ClockOverlay({
    super.key,
    required this.size,
    required this.position,
    this.format = 'auto',
  });

  @override
  State<ClockOverlay> createState() => _ClockOverlayState();
}

class _ClockOverlayState extends State<ClockOverlay> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get _fontSize {
    switch (widget.size) {
      case 'small':
        return 32;
      case 'large':
        return 72;
      case 'medium':
      default:
        return 48;
    }
  }

  String _time(BuildContext context) {
    // 'auto' follows the region of the chosen language, which is 12 h in en.
    final locale = Localizations.localeOf(context).toString();
    final format = switch (widget.format) {
      '12' => DateFormat('h:mm a', locale),
      '24' => DateFormat.Hm(locale),
      _ => DateFormat.jm(locale),
    };
    return format.format(_now);
  }

  @override
  Widget build(BuildContext context) {
    final timeString = _time(context);
    
    final placement = OverlayPosition.of(widget.position);
    return Align(
      alignment: placement.alignment,
      child: Padding(
        padding: placement.padding,
        child: Text(
          timeString,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w300, // Light weight for elegant look
            color: Colors.white,
            shadows: const [
              // Shadow for readability on any background
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 8,
                color: Colors.black54,
              ),
              Shadow(
                offset: Offset(-1, -1),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
