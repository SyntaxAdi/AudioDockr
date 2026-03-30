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
    final libraryState = ref.watch(libraryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text(
          'LIBRARY',
          style: titleStyle,
        ),
      ),
      body: libraryState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentPrimary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PlaylistCard(
                  title: 'Liked Songs',
                  subtitle: '${libraryState.likedTracks.length} tracks',
                  icon: Icons.favorite,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: 'Liked Songs',
                          tracks: libraryState.likedTracks,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _PlaylistCard(
                  title: 'Recents',
                  subtitle: '${libraryState.recentTracks.length} tracks',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: 'Recents',
                          tracks: libraryState.recentTracks,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class PlaylistDetailsScreen extends StatelessWidget {
  const PlaylistDetailsScreen({
    super.key,
    required this.title,
    required this.tracks,
  });

  final String title;
  final List<LibraryTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text(
          title.toUpperCase(),
          style: titleStyle,
        ),
      ),
      body: tracks.isEmpty
          ? Center(
              child: Text(
                'NO TRACKS YET',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          : ListView.separated(
              itemCount: tracks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: bgDivider),
              itemBuilder: (context, index) {
                final track = tracks[index];
                return _LibraryTrackRow(track: track);
              },
            ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              child: Icon(icon, color: accentPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: accentPrimary),
          ],
        ),
      ),
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
