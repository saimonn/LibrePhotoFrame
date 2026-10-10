import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/photo_entry.dart';
import 'overlay_position.dart';

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

  String _formatDate(BuildContext context, DateTime date) {
    // The date follows the language of the app, not the one of the platform.
    final format = DateFormat.yMMMMd(Localizations.localeOf(context).toString());
    return format.format(date);
  }

  /// Coordinates as shown when no place name is known: readable without a map,
  /// and always available, geocoding or not.
  String _formatCoordinates() {
    final latitude = photo.latitude!.toStringAsFixed(3);
    final longitude = photo.longitude!.toStringAsFixed(3);
    return '$latitude, $longitude';
  }

  @override
  Widget build(BuildContext context) {
    // Build info lines
    final List<String> infoLines = [];
    
    // Add capture date only if available from EXIF (no fallback to file date)
    if (photo.captureDate != null) {
      infoLines.add(_formatDate(context, photo.captureDate!));
    }
    
    // Add location if available: the place name when geocoding resolved one,
    // the coordinates otherwise, so a photo carrying GPS is never silent.
    if (locationName != null && locationName!.isNotEmpty) {
      infoLines.add(locationName!);
    } else if (photo.hasLocation) {
      infoLines.add(_formatCoordinates());
    }
    
    if (infoLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final placement = OverlayPosition.of(position);
    return Align(
      alignment: placement.alignment,
      child: Padding(
        padding: placement.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: placement.crossAxisAlignment,
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
