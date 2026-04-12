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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibraryPlaylistCoverArt(
          imagePath: playlist.coverImagePath,
          imageUrl: '',
          size: 120,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shouldStack = constraints.maxWidth < 230;
                final title = Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        color: textPrimary,
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

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: actions,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: title),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: actions,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
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
  });

  final bool hasTracks;
  final bool shuffleEnabled;
  final VoidCallback onPlayPressed;
  final VoidCallback onShufflePressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = IconButton.styleFrom(
      minimumSize: const Size(52, 52),
      fixedSize: const Size(52, 52),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Playlist options',
          onPressed: onMenuPressed,
          style: buttonStyle,
          iconSize: 28,
          color: textPrimary,
          icon: const Icon(Icons.more_vert_rounded),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: hasTracks ? onShufflePressed : null,
          style: buttonStyle,
          iconSize: 28,
          color: shuffleEnabled ? accentPrimary : textPrimary,
          icon: const Icon(Icons.shuffle_rounded),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: hasTracks ? onPlayPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accentPrimary,
            foregroundColor: bgBase,
            minimumSize: const Size(52, 52),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 28),
        ),
      ],
    );
  }
}
