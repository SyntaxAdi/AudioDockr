import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/profile_provider.dart';
import '../../../services/app_info_service.dart';
import '../../../services/app_update_service.dart';
import '../../../theme.dart';

const Color _cpTopbarLine = Color(0xFF1A1A26);
const Color _cpWarmText = Color(0xFFE0D5B0);

TextStyle _techStyle({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  Color color = _cpWarmText,
  double spacing = 0.0,
  double? height,
}) {
  return GoogleFonts.shareTechMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class AppUpdatesPage extends ConsumerStatefulWidget {
  const AppUpdatesPage({super.key});

  @override
  ConsumerState<AppUpdatesPage> createState() => _AppUpdatesPageState();
}

class _AppUpdatesPageState extends ConsumerState<AppUpdatesPage> {
  final AppInfoService _appInfoService = AppInfoService();
  final AppUpdateService _appUpdateService = AppUpdateService();

  late Future<(_PageStateData, List<RemoteReleaseInfo>)> _pageFuture;

  @override
  void initState() {
    super.initState();
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
            const _CyberpunkTopBar(),
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
                        _UpdateStateCard(
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

                  // Merge all changelogs from all new releases into one list
                  final allChangelogItems = releases
                      .expand((r) => r.changelog)
                      .toSet() // Dedupe if same commit appears
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
                        _FrameHeader(versionCode: installed.displayBuildNumber),
                        const SizedBox(height: 14),
                        const _SectionLabel('System identity'),
                        _IdentityCard(
                          installed: installed,
                          displayName: displayName,
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel(
                            hasPatch ? 'Patch available' : 'Update status'),
                        if (!hasPatch)
                          _UpdateStateCard(
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
                          _PatchAvailableCard(
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
                                  : _formatDateTime(latestRelease?.publishedAt),
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

class _CompactReleaseCard extends StatelessWidget {
  const _CompactReleaseCard({required this.release});

  final RemoteReleaseInfo release;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border.all(color: bgDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: accentCyan.withValues(alpha: 0.5)),
                  color: accentCyan.withValues(alpha: 0.05),
                ),
                child: Text(
                  release.version,
                  style: _techStyle(
                    size: 11,
                    weight: FontWeight.w700,
                    color: accentCyan,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  release.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _techStyle(
                    size: 11,
                    weight: FontWeight.w700,
                    color: textPrimary,
                    spacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in release.changelog.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·',
                    style: TextStyle(
                      color: accentPrimary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                            height: 1.3,
                          ),
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

class _CyberpunkTopBar extends StatelessWidget {
  const _CyberpunkTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _cpTopbarLine),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: ClipPath(
                clipper: _ParallelogramButtonClipper(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(color: accentPrimary),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: accentPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'UPDATES',
            style: _techStyle(
              size: 20,
              weight: FontWeight.w700,
              color: accentPrimary,
              spacing: 3.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallelogramButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 6.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PageStateData {
  const _PageStateData({
    required this.installed,
    required this.displayName,
  });

  final InstalledBuildInfo installed;
  final String displayName;
}

class _FrameHeader extends StatelessWidget {
  const _FrameHeader({required this.versionCode});

  final String versionCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accentPrimary, width: 1.2),
        borderRadius: BorderRadius.circular(8),
        color: bgSurface,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _corner(alignment: Alignment.topLeft),
              Expanded(
                child: Center(
                  child: Text(
                    'SYS::UPDATE_MODULE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary.withValues(alpha: 0.36),
                          letterSpacing: 2.6,
                        ),
                  ),
                ),
              ),
              _corner(alignment: Alignment.topRight),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: accentPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 28,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: textPrimary.withValues(alpha: 0.22)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ABOUT & UPDATES',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: bgBase,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                  ),
                ),
                Text(
                  'v$versionCode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: bgBase.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({required Alignment alignment}) {
    const borderSide = BorderSide(color: accentPrimary, width: 2);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: borderSide,
          left: alignment == Alignment.topLeft ? borderSide : BorderSide.none,
          right: alignment == Alignment.topRight ? borderSide : BorderSide.none,
        ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        '//  ${label.toUpperCase()}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentPrimary.withValues(alpha: 0.76),
              letterSpacing: 3.2,
            ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.installed,
    required this.displayName,
  });

  final InstalledBuildInfo installed;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border.all(color: accentPrimary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _IdentityRow(
              label: 'App',
              value: displayName.toUpperCase(),
              valueColor: accentPrimary),
          _IdentityRow(
            label: 'Installed build',
            value: installed.versionName,
          ),
          _IdentityRow(
            label: 'ABI / arch',
            value: installed.abi,
            valueColor: accentCyan,
          ),
          _IdentityRow(
            label: 'Package type',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 1),
                color: const Color(0x332A1500),
              ),
              child: Text(
                installed.packageType.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      letterSpacing: 2.2,
                    ),
              ),
            ),
          ),
          if (installed.isDirty)
            _IdentityRow(
              label: 'Local changes',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: accentCyan, width: 1),
                  color: accentCyan.withValues(alpha: 0.08),
                ),
                child: Text(
                  'DIRTY BUILD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentCyan,
                        letterSpacing: 2.2,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.label,
    this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: bgDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textSecondary,
                    letterSpacing: 2.4,
                  ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? textPrimary,
                    letterSpacing: 1.0,
                  ),
            ),
        ],
      ),
    );
  }
}

class _PatchAvailableCard extends StatelessWidget {
  const _PatchAvailableCard({
    required this.installedVersion,
    required this.release,
    required this.mergedChangelog,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final String installedVersion;
  final RemoteReleaseInfo release;
  final List<String> mergedChangelog;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final preferredAsset = release.preferredAsset;
    final displayChangelog = mergedChangelog.take(15).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D12),
        border: Border.all(color: accentPrimary, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: accentCyan, width: 4),
                bottom: BorderSide(color: bgDivider),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: accentCyan),
                    color: accentCyan.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NEW PATCH DETECTED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: accentCyan,
                              letterSpacing: 2.6,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _VersionChip(
                      text: installedVersion,
                      background: bgCard,
                      foreground: textSecondary,
                      crossed: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '▶',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: accentPrimary,
                            ),
                      ),
                    ),
                    _VersionChip(
                      text: release.version,
                      background: accentCyan.withValues(alpha: 0.08),
                      foreground: accentCyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: bgDivider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '> CHANGELOG',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentPrimary.withValues(alpha: 0.78),
                        letterSpacing: 2.8,
                      ),
                ),
                const SizedBox(height: 12),
                for (final line in displayChangelog)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[+]',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: accentCyan,
                                    fontSize: 13,
                                  ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: textSecondary,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (mergedChangelog.length > 15)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      '... and ${mergedChangelog.length - 15} more updates',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Latest Build: ${_formatDate(release.publishedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary.withValues(alpha: 0.46),
                          letterSpacing: 1.4,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${preferredAsset?.name ?? 'No asset'} · ${_formatBytes(preferredAsset?.sizeBytes ?? 0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary.withValues(alpha: 0.46),
                          letterSpacing: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: FilledButton(
              onPressed: onPrimaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: accentPrimary,
                foregroundColor: bgBase,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                '▼  DOWNLOAD & INSTALL PATCH',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: bgBase,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
              ),
            ),
          ),
          if (onSecondaryAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OutlinedButton(
                onPressed: onSecondaryAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: bgDivider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OPEN WORKFLOW RUN'),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.text,
    required this.background,
    required this.foreground,
    this.crossed = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool crossed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.7)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              decoration: crossed ? TextDecoration.lineThrough : null,
              decorationColor: foreground,
            ),
      ),
    );
  }
}

class _UpdateStateCard extends StatelessWidget {
  const _UpdateStateCard({
    required this.title,
    required this.details,
    this.dangerTitle = false,
  });

  final String title;
  final List<String> details;
  final bool dangerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border.all(color: bgDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dangerTitle)
            _WarningFlickerTitle(text: title)
          else
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accentPrimary,
                    fontSize: 20,
                  ),
            ),
          const SizedBox(height: 10),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                detail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      height: 1.45,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WarningFlickerTitle extends StatefulWidget {
  const _WarningFlickerTitle({required this.text});

  final String text;

  @override
  State<_WarningFlickerTitle> createState() => _WarningFlickerTitleState();
}

class _WarningFlickerTitleState extends State<_WarningFlickerTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  late final Animation<double> _intensity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.82), weight: 18),
    TweenSequenceItem(tween: ConstantTween(0.46), weight: 3),
    TweenSequenceItem(tween: ConstantTween(0.96), weight: 6),
    TweenSequenceItem(tween: ConstantTween(0.68), weight: 3),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
    TweenSequenceItem(tween: ConstantTween(0.58), weight: 2),
    TweenSequenceItem(tween: ConstantTween(0.92), weight: 8),
    TweenSequenceItem(tween: ConstantTween(0.74), weight: 2),
    TweenSequenceItem(tween: ConstantTween(0.98), weight: 16),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dimColor = Color(0xFFFF6B6B);
    const brightColor = Color(0xFFFF3030);

    return AnimatedBuilder(
      animation: _intensity,
      builder: (context, child) {
        final level = _intensity.value;
        final color = Color.lerp(dimColor, brightColor, level) ?? brightColor;

        return Text(
          widget.text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.28 + (level * 0.18)),
                blurRadius: 5 + (level * 6),
              ),
              Shadow(
                color: brightColor.withValues(alpha: 0.12 + (level * 0.12)),
                blurRadius: 14 + (level * 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Unknown';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'UNKNOWN';
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}.${utc.month.toString().padLeft(2, '0')}.${utc.day.toString().padLeft(2, '0')} · ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')} UTC';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size >= 100 || unitIndex == 0 ? 0 : 1;
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}
