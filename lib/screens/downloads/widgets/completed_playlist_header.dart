import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'staggered_artwork.dart';

class CompletedPlaylistHeader extends StatelessWidget {
  const CompletedPlaylistHeader({
    super.key,
    required this.playlistId,
    required this.title,
    required this.thumbnailUrl,
    required this.height,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  final String playlistId;
  final String title;
  final String thumbnailUrl;
  final double height;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: bgCard,
        child: Row(
          children: [
            PlaylistArtwork(
              thumbnailUrl: thumbnailUrl,
              size: (height * 0.72).clamp(44.0, 64.0),
              staggerIndex: index,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PLAYLIST',
                    style: TextStyle(color: accentCyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
