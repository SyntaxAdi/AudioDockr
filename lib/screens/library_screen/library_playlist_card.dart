import 'package:flutter/material.dart';

import '../../theme.dart';

enum LibraryCyberpunkPlaylistBadgeVariant { liked, recents }

class LibraryPlaylistCard extends StatelessWidget {
  const LibraryPlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bgDivider),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentPrimary),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
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
  });

  final LibraryCyberpunkPlaylistBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isLiked = variant == LibraryCyberpunkPlaylistBadgeVariant.liked;
    final icon = isLiked
        ? Icons.favorite_rounded
        : Icons.history_toggle_off_rounded;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLiked
              ? const [
                  Color(0xFFFF4D6D),
                  Color(0xFFFF003C),
                  Color(0xFF1B0A12),
                ]
              : const [
                  Color(0xFFF5E642),
                  Color(0xFFE0B400),
                  Color(0xFF382B00),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isLiked ? accentRed : accentPrimary).withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: -10,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 36,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: isLiked ? 0 : -8,
            top: isLiked ? 0 : null,
            bottom: isLiked ? null : 8,
            child: Container(
              width: isLiked ? 1.3 : 32,
              height: isLiked ? 56 : 5,
              decoration: BoxDecoration(
                color: isLiked
                    ? accentPrimary.withValues(alpha: 0.75)
                    : accentCyan.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (isLiked)
            Positioned(
              bottom: 7,
              right: 6,
              child: Container(
                width: 14,
                height: 3,
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
              left: 18,
              child: Container(
                width: 1.4,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          Center(
            child: Icon(
              icon,
              color: isLiked ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
