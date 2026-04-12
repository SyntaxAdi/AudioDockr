import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class LibraryDataPage extends StatelessWidget {
  const LibraryDataPage({
    super.key,
    required this.onShowComingSoon,
  });

  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Library & data',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.upload_file_outlined,
              title: 'Export library',
              subtitle: 'Create a backup of your library data',
              onTap: () => onShowComingSoon('Export library'),
            ),
            SettingsActionTile(
              icon: Icons.download_for_offline_outlined,
              title: 'Import library',
              subtitle: 'Restore your songs and playlists',
              onTap: () => onShowComingSoon('Import library'),
            ),
            SettingsActionTile(
              icon: Icons.history_rounded,
              title: 'Listening history',
              subtitle: 'Review and manage your recent activity',
              onTap: () => onShowComingSoon('Listening history'),
            ),
          ],
        ),
      ],
    );
  }
}
