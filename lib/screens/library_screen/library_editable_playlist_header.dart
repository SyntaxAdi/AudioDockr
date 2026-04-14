import 'package:flutter/material.dart';

import '../../library/library_provider.dart';
import '../../theme.dart';
import 'library_playlist_cover_art.dart';

class LibraryEditablePlaylistHeader extends StatelessWidget {
  const LibraryEditablePlaylistHeader({
    super.key,
    required this.playlist,
    required this.tracks,
    required this.shuffleEnabled,
    required this.onPlayPressed,
    required this.onShufflePressed,
    required this.onMenuPressed,
  });

  final LibraryPlaylist playlist;
  final List<LibraryTrack> tracks;
  final bool shuffleEnabled;
  final VoidCallback onPlayPressed;
  final VoidCallback onShufflePressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final hasTracks = tracks.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 380;
        
        final title = Text(
          playlist.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

        final actions = LibraryPlaylistHeaderActions(
          hasTracks: hasTracks,
          shuffleEnabled: shuffleEnabled,
          onPlayPressed: onPlayPressed,
          onShufflePressed: onShufflePressed,
          onMenuPressed: onMenuPressed,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LibraryPlaylistCoverArt(
                imagePath: playlist.coverImagePath,
                imageUrl: '',
                size: 100,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Vertical layout for smaller screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LibraryPlaylistCoverArt(
                  imagePath: playlist.coverImagePath,
                  imageUrl: '',
                  size: 80,
                  borderRadius: 10,
                ),
                const SizedBox(width: 14),
                Expanded(child: title),
              ],
            ),
            const SizedBox(height: 12),
            actions,
          ],
        );
      },
    );
  }
}

class LibraryPlaylistHeaderActions extends StatelessWidget {
  const LibraryPlaylistHeaderActions({
    super.key,
    required this.hasTracks,
    required this.shuffleEnabled,
    required this.onPlayPressed,
    required this.onShufflePressed,
    required this.onMenuPressed,
    this.showMenu = true,
  });

  final bool hasTracks;
  final bool shuffleEnabled;
  final VoidCallback onPlayPressed;
  final VoidCallback onShufflePressed;
  final VoidCallback onMenuPressed;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMenu)
          IconButton(
            onPressed: onMenuPressed,
            iconSize: 26,
            color: textSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        const Spacer(),
        IconButton(
          onPressed: hasTracks ? onShufflePressed : null,
          iconSize: 26,
          color: shuffleEnabled ? accentPrimary : textSecondary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.shuffle_rounded),
        ),
        const SizedBox(width: 20),
        FilledButton(
          onPressed: hasTracks ? onPlayPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accentPrimary,
            foregroundColor: Colors.black,
            minimumSize: const Size(56, 56),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            elevation: 0,
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 38),
        ),
      ],
    );
  }
}
