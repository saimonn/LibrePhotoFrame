import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/photo_entry.dart';

/// Overlay widget that displays photo metadata (date, location).
class PhotoInfoOverlay extends StatelessWidget {
  final PhotoEntry photo;
  final String position; // 'bottomRight', 'bottomLeft', 'topRight', 'topLeft'
  final String size; // 'small', 'medium', 'large'
  final String? locationName; // Resolved location name from geocoding
  final bool useScriptFont; // Use Rouge Script font for elegant handwritten style

  const PhotoInfoOverlay({
    super.key,
    required this.photo,
    required this.position,
    this.size = 'small',
    this.locationName,
    this.useScriptFont = false,
  });

  Alignment get _alignment {
    switch (position) {
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'topLeft':
        return Alignment.topLeft;
      case 'bottomRight':
      default:
        return Alignment.bottomRight;
    }
  }

  EdgeInsets get _padding {
    const base = 24.0;
    switch (position) {
      case 'bottomLeft':
        return const EdgeInsets.only(left: base, bottom: base);
      case 'topRight':
        return const EdgeInsets.only(right: base, top: base);
      case 'topLeft':
        return const EdgeInsets.only(left: base, top: base);
      case 'bottomRight':
      default:
        return const EdgeInsets.only(right: base, bottom: base);
    }
  }

  CrossAxisAlignment get _crossAxisAlignment {
    switch (position) {
      case 'bottomLeft':
      case 'topLeft':
        return CrossAxisAlignment.start;
      case 'bottomRight':
      case 'topRight':
      default:
        return CrossAxisAlignment.end;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    // The date follows the language of the app, not the one of the platform.
    final format = DateFormat.yMMMMd(Localizations.localeOf(context).toString());
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Build info lines
    final List<String> infoLines = [];
    
    // Add capture date only if available from EXIF (no fallback to file date)
    if (photo.captureDate != null) {
      infoLines.add(_formatDate(context, photo.captureDate!));
    }
    
    // Add location if available
    if (locationName != null && locationName!.isNotEmpty) {
      infoLines.add(locationName!);
    }
    
    if (infoLines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: _alignment,
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _crossAxisAlignment,
          children: infoLines.map((line) => _buildTextLine(line)).toList(),
        ),
      ),
    );
  }

  double get _fontSize {
    switch (size) {
      case 'large':
        return 48;
      case 'medium':
        return 39;
      case 'small':
      default:
        return 30;
    }
  }

  Widget _buildTextLine(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: useScriptFont ? 'RougeScript' : null,
        fontSize: _fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        shadows: const [
          // Shadow for readability on any background
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 4,
            color: Colors.black54,
          ),
          Shadow(
            offset: Offset(-1, -1),
            blurRadius: 4,
            color: Colors.black26,
          ),
        ],
      ),
    );
  }
}
