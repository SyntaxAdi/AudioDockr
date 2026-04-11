import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _defaultDownloadPath = '/storage/emulated/0/Music';
  static const String _downloadPathKey = 'download_path';
  static const String _resumeOnStartKey = 'resume_on_start';
  static const String _backgroundPlaybackKey = 'background_playback';
  static const String _downloadNotificationsKey = 'download_notifications';
  static const String _releaseNotificationsKey = 'release_notifications';
  static const String _privateSessionKey = 'private_session';
  static const String _showActivityKey = 'show_activity_status';

  String _downloadPath = _defaultDownloadPath;
  bool _resumeOnStart = true;
  bool _backgroundPlayback = true;
  bool _downloadNotifications = true;
  bool _releaseNotifications = false;
  bool _privateSession = false;
  bool _showActivityStatus = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _downloadPath =
          _readStringPreference(preferences, _downloadPathKey, _defaultDownloadPath);
      _resumeOnStart = preferences.getBool(_resumeOnStartKey) ?? true;
      _backgroundPlayback = preferences.getBool(_backgroundPlaybackKey) ?? true;
      _downloadNotifications =
          preferences.getBool(_downloadNotificationsKey) ?? true;
      _releaseNotifications =
          preferences.getBool(_releaseNotificationsKey) ?? false;
      _privateSession = preferences.getBool(_privateSessionKey) ?? false;
      _showActivityStatus = preferences.getBool(_showActivityKey) ?? true;
    });
  }

  String _readStringPreference(
    SharedPreferences preferences,
    String key,
    String fallback,
  ) {
    final value = preferences.getString(key);
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value;
  }

  Future<void> _updateBoolPreference(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> _pickDownloadPath() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
    );
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_downloadPathKey, selectedPath);
    if (!mounted) {
      return;
    }

    setState(() {
      _downloadPath = selectedPath;
    });
  }

  String _pathLabel(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalized = trimmed.endsWith('/') && trimmed.length > 1
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) {
      return normalized;
    }
    return segments.last;
  }

  Future<void> _openSettingsPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _showComingSoonMessage(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 24,
          color: textPrimary,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text('Settings', style: titleStyle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileHeaderCard(
              onTap: () => _openSettingsPage(
                _SettingsDetailScaffold(
                  title: 'Profile',
                  children: [
                    _SettingsGroup(
                      children: [
                        _SettingsActionTile(
                          icon: Icons.account_circle_outlined,
                          title: 'Account info',
                          subtitle: 'Name, email, avatar and connected services',
                          onTap: () => _showComingSoonMessage('Account info'),
                        ),
                        _SettingsActionTile(
                          icon: Icons.graphic_eq_rounded,
                          title: 'Listening profile',
                          subtitle: 'Personalization and taste preferences',
                          onTap: () => _showComingSoonMessage('Listening profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SettingsGroup(
                      title: 'Privacy',
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.visibility_off_outlined,
                          title: 'Private session',
                          subtitle: 'Hide your current listening activity',
                          value: _privateSession,
                          onChanged: (value) {
                            setState(() {
                              _privateSession = value;
                            });
                            _updateBoolPreference(_privateSessionKey, value);
                          },
                        ),
                        _SettingsSwitchTile(
                          icon: Icons.people_outline_rounded,
                          title: 'Show activity status',
                          subtitle: 'Let other devices show what you are playing',
                          value: _showActivityStatus,
                          onChanged: (value) {
                            setState(() {
                              _showActivityStatus = value;
                            });
                            _updateBoolPreference(_showActivityKey, value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Account'),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Manage your personal and privacy settings',
                  onTap: () => _openSettingsPage(
                    _SettingsDetailScaffold(
                      title: 'Profile',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsActionTile(
                              icon: Icons.badge_outlined,
                              title: 'Display name',
                              subtitle: 'AudioDockr Listener',
                              onTap: () =>
                                  _showComingSoonMessage('Display name'),
                            ),
                            _SettingsActionTile(
                              icon: Icons.alternate_email_rounded,
                              title: 'Email',
                              subtitle: 'listener@audiodockr.app',
                              onTap: () => _showComingSoonMessage('Email'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SettingsGroup(
                          title: 'Profile preferences',
                          children: [
                            _SettingsSwitchTile(
                              icon: Icons.visibility_off_outlined,
                              title: 'Private session',
                              subtitle: 'Hide your current listening activity',
                              value: _privateSession,
                              onChanged: (value) {
                                setState(() {
                                  _privateSession = value;
                                });
                                _updateBoolPreference(_privateSessionKey, value);
                              },
                            ),
                            _SettingsSwitchTile(
                              icon: Icons.people_outline_rounded,
                              title: 'Show activity status',
                              subtitle:
                                  'Let other devices show what you are playing',
                              value: _showActivityStatus,
                              onChanged: (value) {
                                setState(() {
                                  _showActivityStatus = value;
                                });
                                _updateBoolPreference(_showActivityKey, value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _SettingsActionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Downloads, releases and account alerts',
                  onTap: () => _openSettingsPage(
                    _SettingsDetailScaffold(
                      title: 'Notifications',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsSwitchTile(
                              icon: Icons.download_done_rounded,
                              title: 'Download complete',
                              subtitle: 'Alert me when a download finishes',
                              value: _downloadNotifications,
                              onChanged: (value) {
                                setState(() {
                                  _downloadNotifications = value;
                                });
                                _updateBoolPreference(
                                  _downloadNotificationsKey,
                                  value,
                                );
                              },
                            ),
                            _SettingsSwitchTile(
                              icon: Icons.new_releases_outlined,
                              title: 'New releases',
                              subtitle: 'Highlights from artists you follow',
                              value: _releaseNotifications,
                              onChanged: (value) {
                                setState(() {
                                  _releaseNotifications = value;
                                });
                                _updateBoolPreference(
                                  _releaseNotificationsKey,
                                  value,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('App settings'),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Playback',
                  subtitle: 'Queue, resume and background behavior',
                  onTap: () => _openSettingsPage(
                    _SettingsDetailScaffold(
                      title: 'Playback',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsSwitchTile(
                              icon: Icons.play_circle_outline_rounded,
                              title: 'Resume on start',
                              subtitle: 'Continue from your last session',
                              value: _resumeOnStart,
                              onChanged: (value) {
                                setState(() {
                                  _resumeOnStart = value;
                                });
                                _updateBoolPreference(_resumeOnStartKey, value);
                              },
                            ),
                            _SettingsSwitchTile(
                              icon: Icons.headphones_outlined,
                              title: 'Background playback',
                              subtitle: 'Keep audio running while using other apps',
                              value: _backgroundPlayback,
                              onChanged: (value) {
                                setState(() {
                                  _backgroundPlayback = value;
                                });
                                _updateBoolPreference(
                                  _backgroundPlaybackKey,
                                  value,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SettingsGroup(
                          title: 'Advanced',
                          children: [
                            _SettingsActionTile(
                              icon: Icons.shuffle_rounded,
                              title: 'Autoplay recommendations',
                              subtitle: 'Play similar songs when the queue ends',
                              onTap: () => _showComingSoonMessage(
                                'Autoplay recommendations',
                              ),
                            ),
                            _SettingsActionTile(
                              icon: Icons.tune_rounded,
                              title: 'Crossfade',
                              subtitle: 'Smooth transitions between tracks',
                              onTap: () =>
                                  _showComingSoonMessage('Crossfade'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: 'Storage',
                  subtitle: 'Downloads, cache and local device storage',
                  onTap: () => _openSettingsPage(
                    _SettingsDetailScaffold(
                      title: 'Storage',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsActionTile(
                              icon: Icons.download_rounded,
                              title: 'Download location',
                              subtitle: _downloadPath,
                              trailingText: _pathLabel(_downloadPath),
                              onTap: _pickDownloadPath,
                            ),
                            _SettingsActionTile(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Clear cached artwork',
                              subtitle: 'Free up album art and temp storage',
                              onTap: () =>
                                  _showComingSoonMessage('Clear cached artwork'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _pickDownloadPath,
                            child: const Text('Change download folder'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                _showComingSoonMessage('Clear all downloads'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: accentRed),
                              foregroundColor: accentRed,
                              minimumSize: const Size(0, 48),
                            ),
                            child: const Text('Clear all downloads'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _SettingsActionTile(
                  icon: Icons.storage_rounded,
                  title: 'Library & data',
                  subtitle: 'Import, export and manage local metadata',
                  onTap: () => _openSettingsPage(
                    _SettingsDetailScaffold(
                      title: 'Library & data',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsActionTile(
                              icon: Icons.upload_file_outlined,
                              title: 'Export library',
                              subtitle: 'Create a backup of your library data',
                              onTap: () => _showComingSoonMessage('Export library'),
                            ),
                            _SettingsActionTile(
                              icon: Icons.download_for_offline_outlined,
                              title: 'Import library',
                              subtitle: 'Restore your songs and playlists',
                              onTap: () => _showComingSoonMessage('Import library'),
                            ),
                            _SettingsActionTile(
                              icon: Icons.history_rounded,
                              title: 'Listening history',
                              subtitle: 'Review and manage your recent activity',
                              onTap: () =>
                                  _showComingSoonMessage('Listening history'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Support'),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  subtitle: 'FAQs, contact options and troubleshooting',
                  onTap: () => _openSettingsPage(
                    const _SettingsDetailScaffold(
                      title: 'Help & support',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsStaticTile(
                              icon: Icons.question_answer_outlined,
                              title: 'FAQs',
                              subtitle: 'Common playback, search and download questions',
                            ),
                            _SettingsStaticTile(
                              icon: Icons.mail_outline_rounded,
                              title: 'Contact support',
                              subtitle: 'support@audiodockr.app',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _SettingsActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'App version, acknowledgements and legal info',
                  onTap: () => _openSettingsPage(
                    const _SettingsDetailScaffold(
                      title: 'About',
                      children: [
                        _SettingsGroup(
                          children: [
                            _SettingsStaticTile(
                              icon: Icons.music_note_rounded,
                              title: 'AudioDockr',
                              subtitle: 'Version 1.0.0',
                            ),
                            _SettingsStaticTile(
                              icon: Icons.shield_outlined,
                              title: 'Privacy policy',
                              subtitle: 'How your data is handled inside the app',
                            ),
                            _SettingsStaticTile(
                              icon: Icons.description_outlined,
                              title: 'Open-source licenses',
                              subtitle: 'Libraries and attributions used by the app',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: bgDivider),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: accentPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: bgBase,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AudioDockr Listener',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textPrimary,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your profile, privacy and account settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDetailScaffold extends StatelessWidget {
  const _SettingsDetailScaffold({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textPrimary,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bgDivider),
          ),
          child: Column(children: _withDividers(children)),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final widgets = <Widget>[];
    for (var index = 0; index < items.length; index++) {
      widgets.add(items[index]);
      if (index != items.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: bgDivider,
          ),
        );
      }
    }
    return widgets;
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (trailingText != null) ...[
                Flexible(
                  child: Text(
                    trailingText!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accentPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsStaticTile extends StatelessWidget {
  const _SettingsStaticTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accentPrimary,
            activeTrackColor: accentPrimary.withValues(alpha: 0.35),
            inactiveThumbColor: textSecondary,
            inactiveTrackColor: bgDivider,
          ),
        ],
      ),
    );
  }
}
