import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

class SyncSection extends StatelessWidget {
  final String syncType;
  final bool watchPhotoFolder;
  final int pollIntervalSeconds;
  final List<int> pollIntervalChoices;
  final ValueChanged<String> onSyncTypeChanged;
  final ValueChanged<bool> onWatchPhotoFolderChanged;
  final ValueChanged<int> onPollIntervalChanged;
  final Widget Function() buildSyncTypeSelector;
  final String Function(int) pollIntervalLabel;

  // Nextcloud
  final bool isNextcloud;
  final Widget Function() buildNextcloudSettings;
  final Widget Function() buildSyncIntervalSlider;
  final Widget Function() buildSyncNowButton;
  final Widget Function() buildLastSyncInfo;
  final bool deleteOrphanedFiles;
  final ValueChanged<bool> onDeleteOrphanedFilesChanged;

  const SyncSection({
    super.key,
    required this.syncType,
    required this.watchPhotoFolder,
    required this.pollIntervalSeconds,
    required this.pollIntervalChoices,
    required this.onSyncTypeChanged,
    required this.onWatchPhotoFolderChanged,
    required this.onPollIntervalChanged,
    required this.buildSyncTypeSelector,
    required this.pollIntervalLabel,
    required this.isNextcloud,
    required this.buildNextcloudSettings,
    required this.buildSyncIntervalSlider,
    required this.buildSyncNowButton,
    required this.buildLastSyncInfo,
    required this.deleteOrphanedFiles,
    required this.onDeleteOrphanedFilesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.sectionPhotoSource),
        const SizedBox(height: 8),

        buildSyncTypeSelector(),

        const SizedBox(height: 16),

        SwitchListTile(
          title: Text(l10n.watchPhotoFolder),
          subtitle: Text(l10n.watchPhotoFolderSubtitle),
          secondary: const Icon(Icons.sync),
          value: watchPhotoFolder,
          onChanged: onWatchPhotoFolderChanged,
        ),

        ListTile(
          leading: const Icon(Icons.timer),
          title: Text(l10n.pollInterval),
          subtitle: Text(l10n.pollIntervalSubtitle),
          trailing: boundedDropdown(
            context,
            DropdownButton<int>(
              isExpanded: true,
              value: pollIntervalSeconds,
              underline: const SizedBox(),
              items: [
                for (final seconds in pollIntervalChoices)
                  DropdownMenuItem(
                    value: seconds,
                    child: Text(pollIntervalLabel(seconds)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPollIntervalChanged(value);
                }
              },
            ),
          ),
        ),

        if (isNextcloud) ...[
          const SizedBox(height: 16),
          buildNextcloudSettings(),
        ],

        if (isNextcloud) ...[
          const SizedBox(height: 16),
          buildSyncIntervalSlider(),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.deleteOrphanedFiles),
            subtitle: Text(l10n.deleteOrphanedFilesSubtitle),
            secondary: const Icon(Icons.delete_sweep),
            value: deleteOrphanedFiles,
            onChanged: onDeleteOrphanedFilesChanged,
          ),
          const SizedBox(height: 16),
          buildSyncNowButton(),
          const SizedBox(height: 8),
          buildLastSyncInfo(),
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
}
