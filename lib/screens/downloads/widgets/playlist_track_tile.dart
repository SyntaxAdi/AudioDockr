import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../../../download_manager/download_models.dart';
import 'staggered_artwork.dart';

class PlaylistTrackTile extends StatelessWidget {
  const PlaylistTrackTile({
    super.key,
    required this.track,
    required this.height,
    required this.index,
  });

  final DownloadRecord track;
  final double height;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: bgSurface,
        border: Border(left: BorderSide(color: bgDivider, width: 2)),
      ),
      child: Row(
        children: [
          TrackArtwork(
            thumbnailUrl: track.thumbnailUrl,
            size: height * 0.6,
            staggerIndex: index,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(color: textPrimary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (track.isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: bgDivider,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: track.progress.clamp(0, 1).toDouble(),
                              child: Container(color: accentCyan),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(track.progress * 100).round()}%',
                          style: const TextStyle(color: accentCyan, fontSize: 10),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'ADDED TO QUEUE',
                    style: GoogleFonts.rajdhani(
                      color: textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
