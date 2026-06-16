import 'package:flutter/material.dart';

import '../../../../../services/app_update_service.dart';
import '../../../../../theme.dart';
import 'app_updates_components.dart';

class PatchAvailableCard extends StatelessWidget {
  const PatchAvailableCard({
    super.key,
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
                    VersionChip(
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
                    VersionChip(
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
                    'Latest Build: ${formatDate(release.publishedAt)}',
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
                    '${preferredAsset?.name ?? 'No asset'} · ${formatBytes(preferredAsset?.sizeBytes ?? 0)}',
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

class VersionChip extends StatelessWidget {
  const VersionChip({
    super.key,
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
