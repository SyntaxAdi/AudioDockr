import 'package:flutter/material.dart';

import '../../library/library_models.dart';
import '../../theme.dart';
import 'recents_artwork_thumb.dart';

class RecentTrackTile extends StatelessWidget {
  const RecentTrackTile({
    super.key,
    required this.track,
    required this.onTap,
  });

  final LibraryTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: bgDivider),
            ),
            child: Row(
              children: [
                ArtworkThumb(
                  artworkUrl: track.thumbnailUrl,
                  icon: Icons.music_note_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: accentPrimary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
