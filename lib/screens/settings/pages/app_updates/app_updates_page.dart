import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/profile_provider.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/app_update_service.dart';
import '../../../../theme.dart';
import 'widgets/app_updates_components.dart';
import 'widgets/cyberpunk_top_bar.dart';
import 'widgets/frame_header.dart';
import 'widgets/identity_card.dart';
import 'widgets/patch_available_card.dart';
import 'widgets/update_state_card.dart';

class AppUpdatesPage extends ConsumerStatefulWidget {
  const AppUpdatesPage({
    super.key,
    this.appInfoService,
    this.appUpdateService,
  });

  final AppInfoService? appInfoService;
  final AppUpdateService? appUpdateService;

  @override
  ConsumerState<AppUpdatesPage> createState() => _AppUpdatesPageState();
}

class _PageStateData {
  const _PageStateData({
    required this.installed,
    required this.displayName,
  });

  final InstalledBuildInfo installed;
  final String displayName;
}

class _AppUpdatesPageState extends ConsumerState<AppUpdatesPage> {
  late final AppInfoService _appInfoService;
  late final AppUpdateService _appUpdateService;

  late Future<(_PageStateData, List<RemoteReleaseInfo>)> _pageFuture;

  @override
  void initState() {
    super.initState();
    _appInfoService = widget.appInfoService ?? AppInfoService();
    _appUpdateService = widget.appUpdateService ?? AppUpdateService();
    _pageFuture = _loadData();
  }

  Future<(_PageStateData, List<RemoteReleaseInfo>)> _loadData() async {
    final installed = await _appInfoService.loadInstalledBuildInfo();
    final displayName = ref.read(displayNameProvider);
    List<RemoteReleaseInfo> releases = [];
    try {
      final allReleases = await _appUpdateService.fetchAllReleases();
      for (final r in allReleases) {
        if (r.version == installed.normalizedVersion) break;
        releases.add(r);
        if (releases.length >= 7) break;
      }
    } catch (_) {
      releases = [];
    }
    return (
      _PageStateData(installed: installed, displayName: displayName),
      releases,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }

  Future<void> _openSyntaxAdiProfile() =>
      _openUrl('https://github.com/SyntaxAdi');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Column(
          children: [
            const CyberpunkTopBar(),
            Expanded(
              child: FutureBuilder<(_PageStateData, List<RemoteReleaseInfo>)>(
                future: _pageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentPrimary),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: const [
                        UpdateStateCard(
                          title: 'Update module unavailable',
                          details: [
                            'The App Updates screen could not load right now.',
                            'Try reopening the page or restarting the app once.',
                          ],
                        ),
                      ],
                    );
                  }

                  final (pageState, releases) = snapshot.data!;
                  final installed = pageState.installed;
                  final displayName = ref.watch(displayNameProvider);
                  final hasPatch = releases.isNotEmpty;
                  final latestRelease = hasPatch ? releases.first : null;

                  final allChangelogItems = releases
                      .expand((r) => r.changelog)
                      .toSet()
                      .toList();

                  return RefreshIndicator(
                    color: accentPrimary,
                    onRefresh: () async {
                      final future = _loadData();
                      setState(() {
                        _pageFuture = future;
                      });
                      await future;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        FrameHeader(versionCode: installed.displayBuildNumber),
                        const SizedBox(height: 14),
                        const SectionLabel('System identity'),
                        IdentityCard(
                          installed: installed,
                          displayName: displayName,
                        ),
                        const SizedBox(height: 18),
                        SectionLabel(
                            hasPatch ? 'Patch available' : 'Update status'),
                        if (!hasPatch)
                          UpdateStateCard(
                            title: installed.isDirty
                                ? 'Local modified build detected'
                                : 'System up to date',
                            dangerTitle: installed.isDirty,
                            details: [
                              if (installed.isDirty) ...[
                                'Installed build ${installed.versionName} contains local modifications and may differ from the latest published release.',
                                'Installing the latest clean release will replace this dirty local build.',
                              ] else ...[
                                'Installed build ${installed.versionName} already matches the latest published release.',
                              ],
                            ],
                          )
                        else ...[
                          PatchAvailableCard(
                            installedVersion: installed.normalizedVersion,
                            release: latestRelease!,
                            mergedChangelog: allChangelogItems,
                            onPrimaryAction: latestRelease.preferredAsset ==
                                    null
                                ? null
                                : () => _openUrl(
                                    latestRelease.preferredAsset!.downloadUrl),
                            onSecondaryAction:
                                latestRelease.workflowRunUrl == null
                                    ? null
                                    : () =>
                                        _openUrl(latestRelease.workflowRunUrl!),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Divider(color: bgDivider, height: 1),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          children: [
                            InkWell(
                              onTap: _openSyntaxAdiProfile,
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: textSecondary
                                            .withValues(alpha: 0.56),
                                        letterSpacing: 1.2,
                                      ),
                                  children: const [
                                    TextSpan(text: 'Made With '),
                                    TextSpan(text: '💛'),
                                    TextSpan(text: ' by '),
                                    TextSpan(
                                      text: 'SyntaxAdi',
                                      style: TextStyle(
                                        color: accentPrimary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              !hasPatch
                                  ? 'UP TO DATE'
                                  : formatDateTime(latestRelease?.publishedAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: textSecondary.withValues(alpha: 0.42),
                                    letterSpacing: 1.6,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
