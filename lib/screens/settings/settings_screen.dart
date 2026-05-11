import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../download_manager/download_provider.dart';
import '../../playback/playback_provider.dart';
import '../../providers/search_provider.dart';
import '../../recommendations/recommendation_provider.dart';
import '../../settings/app_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import 'pages/app_updates_page.dart';
import 'pages/notifications_page.dart';
import 'pages/playback_page.dart';
import 'pages/recommendation_page.dart';
import 'pages/profile_pages.dart';
import 'pages/search_page.dart';
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
  String _downloadPath = AppPreferences.defaultDownloadPath;
  bool _downloadOngoingNotifications = true;
  bool _downloadCompletedNotifications = true;
  int _searchResultLimit = AppPreferences.defaultSearchResultLimit;
  SearchThumbnailQuality _searchThumbnailQuality =
      AppPreferences.defaultSearchThumbnailQuality;
  String _lastFmApiKey = '';
  RecommendationSeedStrategy _recommendationSeedStrategy =
      AppPreferences.defaultRecommendationSeedStrategy;
  bool _sessionRestore = true;
  bool _backgroundPlayback = true;
  AudioSource _audioSource = AppPreferences.defaultAudioSource;

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
      _downloadOngoingNotifications =
          AppPreferences.readDownloadOngoingNotifications(preferences);
      _downloadCompletedNotifications =
          AppPreferences.readDownloadCompletedNotifications(preferences);
      _searchResultLimit = AppPreferences.readSearchResultLimit(preferences);
      _searchThumbnailQuality =
          AppPreferences.readSearchThumbnailQuality(preferences);
      _lastFmApiKey = AppPreferences.readLastFmApiKey(preferences);
      _recommendationSeedStrategy =
          AppPreferences.readRecommendationSeedStrategy(preferences);
      _sessionRestore = AppPreferences.readResumeOnStart(preferences);
      _backgroundPlayback = AppPreferences.readBackgroundPlayback(preferences);
      _audioSource = AppPreferences.readAudioSource(preferences);
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
    final segments =
        normalized.split('/').where((segment) => segment.isNotEmpty);
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('Playback'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Playback',
                  subtitle: 'Session restore, background audio',
                  onTap: () => _openSettingsPage(
                    PlaybackPage(
                      sessionRestore: _sessionRestore,
                      backgroundPlayback: _backgroundPlayback,
                      onSessionRestoreChanged: (value) async {
                        setState(() => _sessionRestore = value);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                            AppPreferences.resumeOnStartKey, value);
                        if (!value) {
                          await ref
                              .read(playbackNotifierProvider.notifier)
                              .clearSavedSession();
                        }
                      },
                      onBackgroundPlaybackChanged: (value) async {
                        setState(() => _backgroundPlayback = value);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                            AppPreferences.backgroundPlaybackKey, value);
                      },
                      onShowComingSoon: _showComingSoonMessage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('Audio Engine'),
            SettingsGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          color: accentPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audio source',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _audioSource == AudioSource.youtube
                                  ? 'Streaming from YouTube'
                                  : 'Streaming from JioSaavn',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SegmentedButton<AudioSource>(
                        segments: const [
                          ButtonSegment(
                            value: AudioSource.youtube,
                            label: Text('YouTube'),
                          ),
                          ButtonSegment(
                            value: AudioSource.jioSaavn,
                            label: Text('JioSaavn'),
                          ),
                        ],
                        selected: {_audioSource},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (states) => states.contains(WidgetState.selected)
                                ? accentPrimary
                                : bgSurface,
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : textSecondary,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: bgDivider),
                          ),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onSelectionChanged: (Set<AudioSource> selected) async {
                          final value = selected.first;
                          setState(() => _audioSource = value);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                              AppPreferences.audioSourceKey, value.name);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('App settings'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Recommendations',
                  subtitle: 'Autoplay and discovery preferences',
                  onTap: () => _openSettingsPage(
                    RecommendationPage(
                      lastFmApiKey: _lastFmApiKey,
                      recommendationSeedStrategy: _recommendationSeedStrategy,
                      onLastFmApiKeyChanged: (value) {
                        setState(() => _lastFmApiKey = value);
                        ref
                            .read(recommendationPreferencesProvider.notifier)
                            .setApiKey(value);
                      },
                      onRecommendationSeedStrategyChanged: (value) {
                        setState(() => _recommendationSeedStrategy = value);
                        ref
                            .read(recommendationPreferencesProvider.notifier)
                            .setSeedStrategy(value);
                      },
                      onValidateApiKey: (key) =>
                          ref.read(lastFmServiceProvider).validateApiKey(key),
                    ),
                  ),
                ),
                SettingsActionTile(
                  icon: Icons.search_rounded,
                  title: 'Search',
                  subtitle: 'Results limit and thumbnail quality',
                  onTap: () => _openSettingsPage(
                    SearchPage(
                      resultLimit: _searchResultLimit,
                      thumbnailQuality: _searchThumbnailQuality,
                      onResultLimitChanged: (value) {
                        setState(() => _searchResultLimit = value);
                        ref
                            .read(searchPreferencesProvider.notifier)
                            .setResultLimit(value);
                      },
                      onThumbnailQualityChanged: (value) {
                        setState(() => _searchThumbnailQuality = value);
                        ref
                            .read(searchPreferencesProvider.notifier)
                            .setThumbnailQuality(value);
                      },
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
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('Updates'),
            SettingsGroup(
              children: [
                SettingsActionTile(
                  icon: Icons.system_update_alt_rounded,
                  title: 'App updates',
                  subtitle:
                      'Installed build, release notes and APK patch downloads',
                  onTap: () => _openSettingsPage(const AppUpdatesPage()),
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
