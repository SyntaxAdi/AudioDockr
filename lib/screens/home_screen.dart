import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import 'library_screen.dart';
import '../theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onViewMore,
  });

  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final recentlyPlayed = libraryState.recentTracks.take(10).toList();
    final playlists = libraryState.userPlaylists;
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          color: accentPrimary,
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'AUDIO DOCKR',
                style: titleStyle,
              ),
            ),
            if (libraryState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: accentPrimary),
                ),
              )
            else ...[
              if (recentlyPlayed.isEmpty && playlists.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Center(
                    child: Text(
                      'PLAY SOMETHING TO SEE IT HERE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                )
              else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recents',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewMore,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                      ),
                      child: Text(
                        'Show all',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (recentlyPlayed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No recent tracks yet',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              if (recentlyPlayed.isNotEmpty)
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: recentlyPlayed.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final track = recentlyPlayed[index];
                      return _RecentlyPlayedCard(
                        track: track,
                        onTap: () async {
                          try {
                            await ref.read(playbackNotifierProvider.notifier).playTrack(
                                  track.videoId,
                                  track.videoUrl,
                                  track.title,
                                  track.artist,
                                  track.thumbnailUrl,
                                );
                          } on PlaybackFailure catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              for (final playlist in playlists)
                _PlaylistPreviewSection(playlist: playlist),
            ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaylistPreviewSection extends ConsumerWidget {
  const _PlaylistPreviewSection({
    required this.playlist,
  });

  final LibraryPlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<LibraryTrack>>(
      future: ref.read(libraryProvider.notifier).fetchPlaylistTracks(playlist.id),
      builder: (context, snapshot) {
        final tracks = snapshot.data?.take(10).toList() ?? const <LibraryTrack>[];

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accentPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: accentPrimary),
                  ),
                )
              else if (tracks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No songs in this playlist yet',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                )
              else
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return _RecentlyPlayedCard(
                        track: track,
                        onTap: () async {
                          try {
                            await ref.read(playbackNotifierProvider.notifier).playTrack(
                                  track.videoId,
                                  track.videoUrl,
                                  track.title,
                                  track.artist,
                                  track.thumbnailUrl,
                                );
                          } on PlaybackFailure catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: playlist.name,
                          playlistId: playlist.id,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
                  child: Text(
                    'Show playlist',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accentPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentlyPlayedCard extends StatelessWidget {
  const _RecentlyPlayedCard({
    required this.track,
    required this.onTap,
  });

  final LibraryTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (112 * devicePixelRatio).round();
    return SizedBox(
      width: 112,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 112,
                  height: 112,
                  color: bgDivider,
                  child: track.thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: textSecondary,
                            size: 32,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: track.thumbnailUrl,
                          memCacheWidth: artworkCacheSize,
                          memCacheHeight: artworkCacheSize,
                          maxWidthDiskCache: artworkCacheSize,
                          maxHeightDiskCache: artworkCacheSize,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentPrimary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: textSecondary,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
