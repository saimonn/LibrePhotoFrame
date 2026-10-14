import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;

  const AboutSection({
    super.key,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.about),
      subtitle: Text(
        l10n.aboutSubtitle(
          appVersion.isEmpty ? '...' : appVersion,
        ),
      ),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'LibrePhotoFrame',
          applicationVersion: appVersion.isEmpty ? '...' : appVersion,
          applicationLegalese:
              '© 2026 Michael Wyraz and the LibrePhotoFrame contributors',
        );
      },
    );
  }
}
