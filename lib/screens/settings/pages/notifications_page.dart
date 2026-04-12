import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.downloadNotifications,
    required this.releaseNotifications,
    required this.onDownloadTriggerChanged,
    required this.onReleaseNotificationsChanged,
  });

  final bool downloadNotifications;
  final bool releaseNotifications;
  final ValueChanged<bool> onDownloadTriggerChanged;
  final ValueChanged<bool> onReleaseNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Notifications',
      children: [
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              icon: Icons.download_done_rounded,
              title: 'Download complete',
              subtitle: 'Alert me when a download finishes',
              value: downloadNotifications,
              onChanged: onDownloadTriggerChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.new_releases_outlined,
              title: 'New releases',
              subtitle: 'Highlights from artists you follow',
              value: releaseNotifications,
              onChanged: onReleaseNotificationsChanged,
            ),
          ],
        ),
      ],
    );
  }
}
