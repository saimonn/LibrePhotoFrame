import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

class OverlaySection extends StatelessWidget {
  final bool showClock;
  final String clockSize;
  final String clockPosition;
  final String clockFormat;
  final bool clockUseEnhancedContrast;
  final String clockColor;
  final ValueChanged<bool> onShowClockChanged;
  final ValueChanged<String> onClockSizeChanged;
  final ValueChanged<String> onClockPositionChanged;
  final ValueChanged<String> onClockFormatChanged;
  final ValueChanged<bool> onClockUseEnhancedContrastChanged;
  final ValueChanged<String> onClockColorChanged;

  final bool showPhotoInfo;
  final String photoInfoPosition;
  final String photoInfoSize;
  final bool geocodingEnabled;
  final bool useScriptFontForMetadata;
  final bool photoInfoUseEnhancedContrast;
  final String photoInfoColor;
  final ValueChanged<bool> onShowPhotoInfoChanged;
  final ValueChanged<String> onPhotoInfoPositionChanged;
  final ValueChanged<String> onPhotoInfoSizeChanged;
  final ValueChanged<bool> onGeocodingEnabledChanged;
  final ValueChanged<bool> onUseScriptFontForMetadataChanged;
  final ValueChanged<bool> onPhotoInfoUseEnhancedContrastChanged;
  final ValueChanged<String> onPhotoInfoColorChanged;

  final bool showCalendarEvents;
  final String calendarPosition;
  final String calendarSize;
  final bool calendarUseEnhancedContrast;
  final String calendarColor;
  final bool calendarPermissionGranted;
  final Future<bool> Function() onRequestCalendarPermission;
  final void Function() onCalendarSettingsOpen;
  final ValueChanged<bool> onShowCalendarEventsChanged;
  final ValueChanged<String> onCalendarPositionChanged;
  final ValueChanged<String> onCalendarSizeChanged;
  final ValueChanged<bool> onCalendarUseEnhancedContrastChanged;
  final ValueChanged<String> onCalendarColorChanged;

  final Widget Function(String, ValueChanged<String>) buildSizeSelector;
  final Widget Function(String, ValueChanged<String>) buildPositionSelector;
  final Widget Function(String, ValueChanged<String>, String) buildColorSelector;

  const OverlaySection({
    super.key,
    required this.showClock,
    required this.clockSize,
    required this.clockPosition,
    required this.clockFormat,
    required this.clockUseEnhancedContrast,
    required this.clockColor,
    required this.onShowClockChanged,
    required this.onClockSizeChanged,
    required this.onClockPositionChanged,
    required this.onClockFormatChanged,
    required this.onClockUseEnhancedContrastChanged,
    required this.onClockColorChanged,
    required this.showPhotoInfo,
    required this.photoInfoPosition,
    required this.photoInfoSize,
    required this.geocodingEnabled,
    required this.useScriptFontForMetadata,
    required this.photoInfoUseEnhancedContrast,
    required this.photoInfoColor,
    required this.onShowPhotoInfoChanged,
    required this.onPhotoInfoPositionChanged,
    required this.onPhotoInfoSizeChanged,
    required this.onGeocodingEnabledChanged,
    required this.onUseScriptFontForMetadataChanged,
    required this.onPhotoInfoUseEnhancedContrastChanged,
    required this.onPhotoInfoColorChanged,
    required this.showCalendarEvents,
    required this.calendarPosition,
    required this.calendarSize,
    required this.calendarUseEnhancedContrast,
    required this.calendarColor,
    required this.calendarPermissionGranted,
    required this.onRequestCalendarPermission,
    required this.onCalendarSettingsOpen,
    required this.onShowCalendarEventsChanged,
    required this.onCalendarPositionChanged,
    required this.onCalendarSizeChanged,
    required this.onCalendarUseEnhancedContrastChanged,
    required this.onCalendarColorChanged,
    required this.buildSizeSelector,
    required this.buildPositionSelector,
    required this.buildColorSelector,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === CLOCK SETTINGS ===
        _buildSectionHeader(context, l10n.sectionClock),
        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.showClock),
          subtitle: Text(l10n.showClockSubtitle),
          secondary: const Icon(Icons.access_time),
          value: showClock,
          onChanged: onShowClockChanged,
        ),

        if (showClock) ...[
          const SizedBox(height: 8),
          buildSizeSelector(clockSize, onClockSizeChanged),
          const SizedBox(height: 8),
          buildPositionSelector(clockPosition, onClockPositionChanged),
          const SizedBox(height: 8),
          _buildClockFormatSelector(context),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.enhancedTextContrast),
            subtitle: Text(l10n.enhancedTextContrastSubtitle),
            secondary: const Icon(Icons.format_color_text),
            value: clockUseEnhancedContrast,
            onChanged: onClockUseEnhancedContrastChanged,
          ),
          const SizedBox(height: 8),
          buildColorSelector(clockColor, onClockColorChanged, l10n.textColorClock),
        ],

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // === PHOTO INFO SETTINGS ===
        _buildSectionHeader(context, l10n.sectionPhotoInfo),
        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.showPhotoInfo),
          subtitle: Text(l10n.showPhotoInfoSubtitle),
          secondary: const Icon(Icons.info_outline),
          value: showPhotoInfo,
          onChanged: onShowPhotoInfoChanged,
        ),

        if (showPhotoInfo) ...[
          const SizedBox(height: 8),
          buildPositionSelector(photoInfoPosition, onPhotoInfoPositionChanged),
          const SizedBox(height: 8),
          buildSizeSelector(photoInfoSize, onPhotoInfoSizeChanged),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.useScriptFont),
            subtitle: Text(l10n.useScriptFontSubtitle),
            secondary: const Icon(Icons.font_download),
            value: useScriptFontForMetadata,
            onChanged: onUseScriptFontForMetadataChanged,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.enhancedTextContrast),
            subtitle: Text(l10n.enhancedTextContrastSubtitle),
            secondary: const Icon(Icons.format_color_text),
            value: photoInfoUseEnhancedContrast,
            onChanged: onPhotoInfoUseEnhancedContrastChanged,
          ),
          const SizedBox(height: 8),
          buildColorSelector(photoInfoColor, onPhotoInfoColorChanged, l10n.textColorPhotoInfo),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.resolveLocationNames),
            subtitle: Text(l10n.resolveLocationNamesSubtitle),
            secondary: const Icon(Icons.location_on),
            value: geocodingEnabled,
            onChanged: onGeocodingEnabledChanged,
          ),
          if (geocodingEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.nominatimHint,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // === CALENDAR SETTINGS ===
        _buildSectionHeader(context, l10n.sectionCalendar),
        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.showCalendarEvents),
          subtitle: Text(l10n.showCalendarEventsSubtitle),
          secondary: const Icon(Icons.calendar_month),
          value: showCalendarEvents,
          onChanged: (value) async {
            if (!value) {
              onShowCalendarEventsChanged(false);
              return;
            }
            final granted = await onRequestCalendarPermission();
            if (!granted) {
              return;
            }
            onShowCalendarEventsChanged(true);
          },
        ),

        if (showCalendarEvents) ...[
          if (!calendarPermissionGranted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.calendarPermissionDenied,
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: onCalendarSettingsOpen,
                    child: Text(l10n.calendarOpenSettings),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          buildPositionSelector(calendarPosition, onCalendarPositionChanged),
          const SizedBox(height: 8),
          buildSizeSelector(calendarSize, onCalendarSizeChanged),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.enhancedTextContrast),
            subtitle: Text(l10n.enhancedTextContrastSubtitle),
            secondary: const Icon(Icons.format_color_text),
            value: calendarUseEnhancedContrast,
            onChanged: onCalendarUseEnhancedContrastChanged,
          ),
          const SizedBox(height: 8),
          buildColorSelector(calendarColor, onCalendarColorChanged, l10n.textColorCalendar),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildClockFormatSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String getClockFormatLabel(String value) {
      switch (value) {
        case '12':
          return l10n.clockFormat12;
        case '24':
          return l10n.clockFormat24;
        default:
          return l10n.clockFormatAuto;
      }
    }

    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(l10n.clockFormat),
      subtitle: Text(getClockFormatLabel(clockFormat)),
      trailing: boundedDropdown(
        context,
        DropdownButton<String>(
          isExpanded: true,
          value: clockFormat,
          underline: const SizedBox(),
          items: [
            for (final format in ['auto', '12', '24'])
              DropdownMenuItem(
                value: format,
                child: Text(
                  getClockFormatLabel(format),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onClockFormatChanged(value);
            }
          },
        ),
      ),
    );
  }
}
