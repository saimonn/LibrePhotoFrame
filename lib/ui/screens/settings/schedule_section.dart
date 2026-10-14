import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ScheduleSection extends StatelessWidget {
  final bool scheduleEnabled;
  final ValueChanged<bool> onScheduleEnabledChanged;
  final List<Widget> scheduleSettings;

  const ScheduleSection({
    super.key,
    required this.scheduleEnabled,
    required this.onScheduleEnabledChanged,
    required this.scheduleSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.sectionDisplaySchedule),
        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.dayNightSchedule),
          subtitle: Text(l10n.dayNightScheduleSubtitle),
          secondary: const Icon(Icons.nightlight_round),
          value: scheduleEnabled,
          onChanged: onScheduleEnabledChanged,
        ),

        if (scheduleEnabled) ...scheduleSettings,
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
}
