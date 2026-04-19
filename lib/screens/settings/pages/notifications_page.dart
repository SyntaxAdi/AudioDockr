import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.downloadOngoingNotifications,
    required this.downloadCompletedNotifications,
    required this.releaseNotifications,
    required this.onDownloadOngoingNotificationsChanged,
    required this.onDownloadCompletedNotificationsChanged,
    required this.onReleaseNotificationsChanged,
  });

  final bool downloadOngoingNotifications;
  final bool downloadCompletedNotifications;
  final bool releaseNotifications;
  final ValueChanged<bool> onDownloadOngoingNotificationsChanged;
  final ValueChanged<bool> onDownloadCompletedNotificationsChanged;
  final ValueChanged<bool> onReleaseNotificationsChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late bool _downloadOngoingNotifications;
  late bool _downloadCompletedNotifications;
  late bool _releaseNotifications;

  @override
  void initState() {
    super.initState();
    _downloadOngoingNotifications = widget.downloadOngoingNotifications;
    _downloadCompletedNotifications = widget.downloadCompletedNotifications;
    _releaseNotifications = widget.releaseNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Notifications',
      children: [
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              icon: Icons.downloading_rounded,
              title: 'Download ongoing notification',
              subtitle: 'Show progress while songs are downloading',
              value: _downloadOngoingNotifications,
              onChanged: (value) {
                setState(() => _downloadOngoingNotifications = value);
                widget.onDownloadOngoingNotificationsChanged(value);
              },
            ),
            SettingsSwitchTile(
              icon: Icons.download_done_rounded,
              title: 'Download completed notification',
              subtitle: 'Show heads-up alert when all downloads finish',
              value: _downloadCompletedNotifications,
              onChanged: (value) {
                setState(() => _downloadCompletedNotifications = value);
                widget.onDownloadCompletedNotificationsChanged(value);
              },
            ),
            SettingsSwitchTile(
              icon: Icons.new_releases_outlined,
              title: 'New releases',
              subtitle: 'Highlights from artists you follow',
              value: _releaseNotifications,
              onChanged: (value) {
                setState(() => _releaseNotifications = value);
                widget.onReleaseNotificationsChanged(value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
