import 'package:flutter/material.dart';

import '../../library/library_models.dart';
import '../library_screen/playlist_details_screen.dart';
import '../../theme.dart';
import 'recents_artwork_thumb.dart';

class RecentPlaylistTile extends StatelessWidget {
  const RecentPlaylistTile({
    super.key,
    required this.playlist,
  });

  final LibraryPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistDetailsScreen(
                  title: playlist.name,
                  playlistId: playlist.id,
                ),
              ),
            );
          },
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
                  localArtworkPath: playlist.coverImagePath,
                  useAppLogoFallback: true,
                  icon: Icons.queue_music_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.trackCount} tracks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Open',
                  style: TextStyle(
                    color: accentPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
