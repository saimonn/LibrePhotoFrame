import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_widgets.dart';

class LanguageSection extends StatelessWidget {
  final String language;
  final ValueChanged<String?> onLanguageChanged;
  final List<Map<String, String>> supportedLocales;

  const LanguageSection({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.supportedLocales,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          subtitle: Text(_getLanguageName(language)),
          trailing: boundedDropdown(
            context,
            DropdownButton<String>(
              value: language,
              underline: const SizedBox(),
              items: [
                for (final locale in supportedLocales)
                  DropdownMenuItem(
                    value: locale['code']!,
                    child: Text(locale['name']!),
                  ),
              ],
              onChanged: onLanguageChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _getLanguageName(String code) {
    for (final locale in supportedLocales) {
      if (locale['code'] == code) {
        return locale['name']!;
      }
    }
    return code;
  }
}
