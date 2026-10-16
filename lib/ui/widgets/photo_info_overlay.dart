import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/photo_entry.dart';
import 'overlay_position.dart';
import 'outlined_text.dart';

/// Overlay widget that displays photo metadata (date, location).
class PhotoInfoOverlay extends StatelessWidget {
  final PhotoEntry photo;
  final String position; // 'bottomRight', 'bottomLeft', 'topRight', 'topLeft'
  final String size; // 'small', 'medium', 'large'
  final String? locationName; // Resolved location name from geocoding
  final bool useScriptFont; // Use Rouge Script font for elegant handwritten style
  final bool enhancedContrast;
  final Color textColor;

  const PhotoInfoOverlay({
    super.key,
    required this.photo,
    required this.position,
    this.size = 'small',
    this.locationName,
    this.useScriptFont = false,
    this.enhancedContrast = false,
    this.textColor = Colors.white,
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
    
    // The file's own timestamps are the sync time for a synced photo, so the
    // date shown is the EXIF one or, failing that, the one in the file name.
    final captureDate = photo.bestCaptureDate;
    if (captureDate != null) {
      infoLines.add(_formatDate(context, captureDate));
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
    final style = TextStyle(
      fontFamily: useScriptFont ? 'RougeScript' : null,
      fontSize: _fontSize,
      fontWeight: FontWeight.w400,
      color: textColor,
    );

    return enhancedContrast
        ? OutlinedText(
            text,
            style: style,
            outlineColor: Colors.black,
            outlineWidth: 2.5,
          )
        : Text(
            text,
            style: style.copyWith(
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black54),
                Shadow(offset: Offset(-1, -1), blurRadius: 4, color: Colors.black26),
              ],
            ),
          );
  }
}
