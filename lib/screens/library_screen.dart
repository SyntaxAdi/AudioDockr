import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: bgBase,
          elevation: 0,
          title: Text(
            'LIBRARY',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          bottom: const TabBar(
            indicatorColor: accentPrimary,
            indicatorWeight: 2,
            labelColor: accentPrimary,
            unselectedLabelColor: textSecondary,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
            tabs: [
              Tab(text: 'TRACKS'),
              Tab(text: 'PLAYLISTS'),
              Tab(text: 'LIKED'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TracksTab(),
            PlaylistsTab(),
            LikedTab(),
          ],
        ),
      ),
    );
  }
}

class TracksTab extends ConsumerWidget {
  const TracksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    if (libraryState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentPrimary),
      );
    }

    if (libraryState.allTracks.isEmpty) {
      return _LibraryEmptyState(
        message: 'PLAY TRACKS TO BUILD YOUR LIBRARY',
      );
    }

    return ListView.separated(
      itemCount: libraryState.allTracks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: bgDivider),
      itemBuilder: (context, index) {
        final track = libraryState.allTracks[index];
        return _LibraryTrackRow(track: track);
      },
    );
  }
}

class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    if (libraryState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentPrimary),
      );
    }

    if (libraryState.playlists.isEmpty) {
      return _LibraryEmptyState(
        message: 'NO PLAYLISTS YET',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: libraryState.playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final playlist = libraryState.playlists[index];
        return Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bgDivider),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  playlist.id == 'liked'
                      ? Icons.favorite
                      : Icons.queue_music_rounded,
                  color: accentPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.trackCount} TRACKS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LikedTab extends ConsumerWidget {
  const LikedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    if (libraryState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentPrimary),
      );
    }

    if (libraryState.likedTracks.isEmpty) {
      return _LibraryEmptyState(
        message: 'LIKE SONGS TO SEE THEM HERE',
      );
    }

    return ListView.separated(
      itemCount: libraryState.likedTracks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: bgDivider),
      itemBuilder: (context, index) {
        final track = libraryState.likedTracks[index];
        return _LibraryTrackRow(track: track);
      },
    );
  }
}

class _LibraryTrackRow extends ConsumerWidget {
  const _LibraryTrackRow({
    required this.track,
  });

  final LibraryTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
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
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: bgDivider,
                child: track.thumbnailUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.music_note, color: textSecondary),
                      )
                    : CachedNetworkImage(
                        imageUrl: track.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.music_note, color: textSecondary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (track.isLiked)
              const Icon(Icons.favorite, color: accentPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
