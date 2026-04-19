import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../download_manager/download_provider.dart';
import '../../settings/app_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import 'pages/library_data_page.dart';
import 'pages/notifications_page.dart';
import 'pages/playback_page.dart';
import 'pages/profile_pages.dart';
import 'pages/storage_page.dart';
import 'pages/support_pages.dart';
import 'widgets/section_label.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tiles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _resumeOnStartKey = 'resume_on_start';
  static const String _backgroundPlaybackKey = 'background_playback';
  static const String _releaseNotificationsKey = 'release_notifications';

  String _downloadPath = AppPreferences.defaultDownloadPath;
  bool _resumeOnStart = true;
  bool _backgroundPlayback = true;
  bool _downloadOngoingNotifications = true;
  bool _downloadCompletedNotifications = true;
  bool _releaseNotifications = false;

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
      _downloadPath = AppPreferences.readDownloadPath(preferences);
      _resumeOnStart = preferences.getBool(_resumeOnStartKey) ?? true;
      _backgroundPlayback = preferences.getBool(_backgroundPlaybackKey) ?? true;
      _downloadOngoingNotifications =
          AppPreferences.readDownloadOngoingNotifications(preferences);
      _downloadCompletedNotifications =
          AppPreferences.readDownloadCompletedNotifications(preferences);
      _releaseNotifications =
          preferences.getBool(_releaseNotificationsKey) ?? false;
    });
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
    await preferences.setString(AppPreferences.downloadPathKey, selectedPath);
    if (!mounted) {
      return;
    }

    setState(() {
      _downloadPath = selectedPath;
    });
    ref.invalidate(downloadPathProvider);
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
            const SectionLabel('Account'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Manage your personal and privacy settings',
                  onTap: () => _openSettingsPage(const AccountProfilePage()),
                ),
                SettingsActionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Downloads, releases and account alerts',
                  onTap: () => _openSettingsPage(
                    NotificationsPage(
                      downloadOngoingNotifications:
                          _downloadOngoingNotifications,
                      downloadCompletedNotifications:
                          _downloadCompletedNotifications,
                      releaseNotifications: _releaseNotifications,
                      onDownloadOngoingNotificationsChanged: (value) {
                        setState(() => _downloadOngoingNotifications = value);
                        _updateBoolPreference(
                          AppPreferences.downloadOngoingNotificationsKey,
                          value,
                        );
                        if (!value) {
                          NotificationService.instance
                              .cancelDownloadNotification();
                        }
                      },
                      onDownloadCompletedNotificationsChanged: (value) {
                        setState(() => _downloadCompletedNotifications = value);
                        _updateBoolPreference(
                          AppPreferences.downloadCompletedNotificationsKey,
                          value,
                        );
                      },
                      onReleaseNotificationsChanged: (value) {
                        setState(() => _releaseNotifications = value);
                        _updateBoolPreference(_releaseNotificationsKey, value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('App settings'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Playback',
                  subtitle: 'Queue, resume and background behavior',
                  onTap: () => _openSettingsPage(
                    PlaybackPage(
                      resumeOnStart: _resumeOnStart,
                      backgroundPlayback: _backgroundPlayback,
                      onResumeOnStartChanged: (value) {
                        setState(() => _resumeOnStart = value);
                        _updateBoolPreference(_resumeOnStartKey, value);
                      },
                      onBackgroundPlaybackChanged: (value) {
                        setState(() => _backgroundPlayback = value);
                        _updateBoolPreference(_backgroundPlaybackKey, value);
                      },
                      onShowComingSoon: _showComingSoonMessage,
                    ),
                  ),
                ),
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: 'Storage',
                  subtitle: 'Downloads, cache and local device storage',
                  onTap: () => _openSettingsPage(
                    StoragePage(
                      downloadPath: _downloadPath,
                      pathLabel: _pathLabel(_downloadPath),
                      onPickDownloadPath: _pickDownloadPath,
                      onShowComingSoon: _showComingSoonMessage,
                    ),
                  ),
                ),
                SettingsActionTile(
                  icon: Icons.storage_rounded,
                  title: 'Library & data',
                  subtitle: 'Import, export and manage local metadata',
                  onTap: () => _openSettingsPage(
                    LibraryDataPage(
                      onShowComingSoon: _showComingSoonMessage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('Support'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  subtitle: 'FAQs, contact options and troubleshooting',
                  onTap: () => _openSettingsPage(const HelpSupportPage()),
                ),
                SettingsActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'App version, acknowledgements and legal info',
                  onTap: () => _openSettingsPage(const AboutPage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
