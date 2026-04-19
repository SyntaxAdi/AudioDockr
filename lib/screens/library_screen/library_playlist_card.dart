import 'package:flutter/material.dart';

import '../../theme.dart';

enum LibraryCyberpunkPlaylistBadgeVariant { liked, recents, downloads }

class LibraryPlaylistCard extends StatelessWidget {
  const LibraryPlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
    required this.onTap,
    this.onLongPress,
    this.height = 88,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? leading;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing based on height
    final bool isCompact = height < 70;
    final double iconSize = isCompact ? 36 : 56;
    final double padding = isCompact ? 12 : 16;
    final double titleFontSize = isCompact ? 13 : 16;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
          border: Border.all(color: bgDivider),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                  ),
                  child: Icon(icon, color: accentPrimary, size: isCompact ? 20 : 24),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: titleFontSize,
                          ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 2 : 4),
                    Flexible(
                      child: Text(
                        subtitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: isCompact ? 9 : 11,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: accentPrimary),
          ],
        ),
      ),
    );
  }
}

class LibraryCyberpunkPlaylistBadge extends StatelessWidget {
  const LibraryCyberpunkPlaylistBadge({
    super.key,
    required this.variant,
    this.size = 56,
  });

  final LibraryCyberpunkPlaylistBadgeVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLiked = variant == LibraryCyberpunkPlaylistBadgeVariant.liked;
    final isDownloads =
        variant == LibraryCyberpunkPlaylistBadgeVariant.downloads;
    final icon = isLiked
        ? Icons.favorite_rounded
        : isDownloads
            ? Icons.download_done_rounded
            : Icons.history_toggle_off_rounded;
    final isCompact = size < 45;
    final scale = size / 56.0; // Base size is 56

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLiked
              ? const [
                  Color(0xFFFF4D6D),
                  Color(0xFFFF003C),
                  Color(0xFF1B0A12),
                ]
              : isDownloads
                  ? const [
                      Color(0xFF53E6C1),
                      Color(0xFF0DBA8B),
                      Color(0xFF07231E),
                    ]
              : const [
                  Color(0xFFF5E642),
                  Color(0xFFE0B400),
                  Color(0xFF382B00),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isLiked
                    ? accentRed
                    : isDownloads
                        ? accentCyan
                        : accentPrimary)
                .withValues(alpha: 0.18),
            blurRadius: 14 * scale,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8 * scale,
            left: -10 * scale,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 36 * scale,
                height: 6 * scale,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: isLiked ? 0 : -8 * scale,
            top: isLiked ? 0 : null,
            bottom: isLiked ? null : 8 * scale,
            child: Container(
              width: isLiked ? 1.3 : 32 * scale,
              height: isLiked ? size : 5 * scale,
              decoration: BoxDecoration(
                color: isLiked
                    ? accentPrimary.withValues(alpha: 0.75)
                    : isDownloads
                        ? accentPrimary.withValues(alpha: 0.95)
                        : accentCyan.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (isLiked)
            Positioned(
              bottom: 7 * scale,
              right: 6 * scale,
              child: Container(
                width: 14 * scale,
                height: 3 * scale,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (!isLiked)
            Positioned(
              top: 0,
              bottom: 0,
              left: 18 * scale,
              child: Container(
                width: 1.4,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          Center(
            child: Icon(
              icon,
              color: isLiked ? Colors.white : Colors.black,
              size: 24 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
