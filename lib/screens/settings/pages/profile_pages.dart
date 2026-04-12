import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class ProfileOverviewPage extends StatelessWidget {
  const ProfileOverviewPage({
    super.key,
    required this.privateSession,
    required this.showActivityStatus,
    required this.onPrivateSessionChanged,
    required this.onShowActivityChanged,
    required this.onShowComingSoon,
  });

  final bool privateSession;
  final bool showActivityStatus;
  final ValueChanged<bool> onPrivateSessionChanged;
  final ValueChanged<bool> onShowActivityChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Profile',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.account_circle_outlined,
              title: 'Account info',
              subtitle: 'Name, email, avatar and connected services',
              onTap: () => onShowComingSoon('Account info'),
            ),
            SettingsActionTile(
              icon: Icons.graphic_eq_rounded,
              title: 'Listening profile',
              subtitle: 'Personalization and taste preferences',
              onTap: () => onShowComingSoon('Listening profile'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Privacy',
          children: [
            SettingsSwitchTile(
              icon: Icons.visibility_off_outlined,
              title: 'Private session',
              subtitle: 'Hide your current listening activity',
              value: privateSession,
              onChanged: onPrivateSessionChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.people_outline_rounded,
              title: 'Show activity status',
              subtitle: 'Let other devices show what you are playing',
              value: showActivityStatus,
              onChanged: onShowActivityChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class AccountProfilePage extends StatelessWidget {
  const AccountProfilePage({
    super.key,
    required this.privateSession,
    required this.showActivityStatus,
    required this.onPrivateSessionChanged,
    required this.onShowActivityChanged,
    required this.onShowComingSoon,
  });

  final bool privateSession;
  final bool showActivityStatus;
  final ValueChanged<bool> onPrivateSessionChanged;
  final ValueChanged<bool> onShowActivityChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Profile',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.badge_outlined,
              title: 'Display name',
              subtitle: 'AudioDockr Listener',
              onTap: () => onShowComingSoon('Display name'),
            ),
            SettingsActionTile(
              icon: Icons.alternate_email_rounded,
              title: 'Email',
              subtitle: 'listener@audiodockr.app',
              onTap: () => onShowComingSoon('Email'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Profile preferences',
          children: [
            SettingsSwitchTile(
              icon: Icons.visibility_off_outlined,
              title: 'Private session',
              subtitle: 'Hide your current listening activity',
              value: privateSession,
              onChanged: onPrivateSessionChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.people_outline_rounded,
              title: 'Show activity status',
              subtitle: 'Let other devices show what you are playing',
              value: showActivityStatus,
              onChanged: onShowActivityChanged,
            ),
          ],
        ),
      ],
    );
  }
}
