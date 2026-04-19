import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme.dart';
import '../../../download_manager/download_models.dart';
import '../../../download_manager/download_provider.dart';
import 'staggered_artwork.dart';
import 'cyberpunk_action_button.dart';

class ActivePlaylistTile extends ConsumerWidget {
  const ActivePlaylistTile({
    super.key,
    required this.playlist,
    required this.height,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  final PlaylistDownloadRecord playlist;
  final double height;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              thumbnailUrl: playlist.thumbnailUrl,
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
                    playlist.title,
                    style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${playlist.completedCount} / ${playlist.trackCount} tracks',
                    style: const TextStyle(color: textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: bgDivider,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: playlist.averageProgress.clamp(0, 1).toDouble(),
                            child: Container(color: accentPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(playlist.averageProgress * 100).round()}%',
                        style: const TextStyle(color: accentPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CyberpunkActionButton(
                  label: 'CANCEL',
                  color: accentRed,
                  onTap: () {
                    ref.read(downloadNotifierProvider.notifier).cancelPlaylistDownload(playlist.playlistId);
                  },
                ),
                const SizedBox(height: 4),
                CyberpunkActionButton(
                  label: playlist.isPaused ? 'RESUME' : 'PAUSE',
                  color: accentCyan,
                  onTap: () {
                    ref.read(downloadNotifierProvider.notifier).togglePausePlaylistDownload(playlist.playlistId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
