import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class AndroidSection extends StatelessWidget {
  final bool autostartOnBoot;
  final bool keepAliveEnabled;
  final bool autoUpdateEnabled;
  final bool autoUpdateSilent;
  final bool isDeviceOwner;
  final ValueChanged<bool> onAutostartOnBootChanged;
  final Future<bool> Function() onShowKeepAliveExplanation;
  final Future<bool> Function() onRequestNotificationPermission;
  final ValueChanged<bool> onKeepAliveChanged;
  final Widget Function() buildAutoUpdateSection;

  const AndroidSection({
    super.key,
    required this.autostartOnBoot,
    required this.keepAliveEnabled,
    required this.autoUpdateEnabled,
    required this.autoUpdateSilent,
    required this.isDeviceOwner,
    required this.onAutostartOnBootChanged,
    required this.onShowKeepAliveExplanation,
    required this.onRequestNotificationPermission,
    required this.onKeepAliveChanged,
    required this.buildAutoUpdateSection,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.sectionAndroid),
        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.startOnBoot),
          subtitle: Text(l10n.startOnBootSubtitle),
          secondary: const Icon(Icons.power_settings_new),
          value: autostartOnBoot,
          onChanged: onAutostartOnBootChanged,
        ),

        const SizedBox(height: 8),

        SwitchListTile(
          title: Text(l10n.keepAppRunning),
          subtitle: Text(l10n.keepAppRunningSubtitle),
          secondary: const Icon(Icons.memory),
          value: keepAliveEnabled,
          onChanged: (value) async {
            if (value) {
              final confirmed = await onShowKeepAliveExplanation();
              if (!confirmed) return;
              final permissionGranted = await onRequestNotificationPermission();
              if (!permissionGranted) return;
            }
            onKeepAliveChanged(value);
          },
        ),

        const SizedBox(height: 8),
        buildAutoUpdateSection(),
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
