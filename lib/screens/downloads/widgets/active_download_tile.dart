import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../../../download_manager/download_models.dart';
import '../../../download_manager/download_provider.dart';
import 'staggered_artwork.dart';
import 'cyberpunk_action_button.dart';

class ActiveDownloadTile extends ConsumerWidget {
  const ActiveDownloadTile({
    super.key,
    required this.download,
    required this.height,
    required this.index,
  });

  final DownloadRecord download;
  final double height;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: bgCard,
      child: Row(
        children: [
          TrackArtwork(
            thumbnailUrl: download.thumbnailUrl,
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
                  download.title,
                  style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (download.isDownloading)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: bgDivider,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: download.progress.clamp(0, 1).toDouble(),
                            child: Container(color: accentPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(download.progress * 100).round()}%',
                        style: const TextStyle(color: accentPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  Text(
                    download.isPaused ? 'PAUSED' : 'ADDED TO QUEUE',
                    style: GoogleFonts.rajdhani(
                      color: download.isPaused ? accentCyan : textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CyberpunkActionButton(
                label: 'CANCEL',
                color: accentRed,
                onTap: () {
                  ref.read(downloadNotifierProvider.notifier).cancelDownload(download.videoId);
                },
              ),
              const SizedBox(height: 4),
              CyberpunkActionButton(
                label: download.isPaused ? 'RESUME' : 'PAUSE',
                color: accentCyan,
                onTap: () {
                  ref.read(downloadNotifierProvider.notifier).togglePauseDownload(download.videoId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
