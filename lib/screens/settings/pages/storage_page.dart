import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class StoragePage extends StatelessWidget {
  const StoragePage({
    super.key,
    required this.downloadPath,
    required this.pathLabel,
    required this.onPickDownloadPath,
    required this.onShowComingSoon,
  });

  final String downloadPath;
  final String pathLabel;
  final VoidCallback onPickDownloadPath;
  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Storage',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.download_rounded,
              title: 'Download location',
              subtitle: downloadPath,
              trailingText: pathLabel,
              onTap: onPickDownloadPath,
            ),
            SettingsActionTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear cached artwork',
              subtitle: 'Free up album art and temp storage',
              onTap: () => onShowComingSoon('Clear cached artwork'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPickDownloadPath,
            child: const Text('Change download folder'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => onShowComingSoon('Clear all downloads'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: accentRed),
              foregroundColor: accentRed,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Clear all downloads'),
          ),
        ),
      ],
    );
  }
}
