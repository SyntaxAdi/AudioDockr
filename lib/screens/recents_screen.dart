import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_provider.dart';
import '../playback/playback_provider.dart';
import '../theme.dart';
import 'library_screen.dart';

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});

  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  bool _musicOnly = false;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final recentTracks = libraryState.recentTracks;
    final recentPlaylists = libraryState.recentPlaylists;
    final activityItems = <_RecentActivityItem>[
      for (final track in recentTracks) _RecentActivityItem.track(track),
      if (!_musicOnly)
        for (final playlist in recentPlaylists)
          _RecentActivityItem.playlist(playlist),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recents',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: textPrimary,
                fontSize: 24,
              ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                FilterChip(
                  label: const Text('Music'),
                  selected: _musicOnly,
                  onSelected: (selected) {
                    setState(() {
                      _musicOnly = selected;
                    });
                  },
                  selectedColor: accentPrimary.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: _musicOnly ? accentPrimary : bgDivider,
                  ),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _musicOnly ? accentPrimary : textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  backgroundColor: bgSurface,
                  checkmarkColor: accentPrimary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (activityItems.isEmpty)
              const _RecentsEmptyState()
            else ...[
              _RecentsSectionHeader(
                title: 'Recently played',
                subtitle: _musicOnly
                    ? 'Showing only music.'
                    : 'Songs and playlists in one place.',
              ),
              const SizedBox(height: 12),
              for (final item in activityItems)
                if (item.track != null)
                  _RecentTrackTile(
                    track: item.track!,
                    onTap: () async {
                      final track = item.track!;
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
                  )
                else if (item.playlist != null)
                  _RecentPlaylistTile(playlist: item.playlist!),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityItem {
  const _RecentActivityItem._({
    this.track,
    this.playlist,
    required this.timestamp,
  });

  factory _RecentActivityItem.track(LibraryTrack track) {
    return _RecentActivityItem._(
      track: track,
      timestamp: track.lastPlayedAt,
    );
  }

  factory _RecentActivityItem.playlist(LibraryPlaylist playlist) {
    return _RecentActivityItem._(
      playlist: playlist,
      timestamp: playlist.lastOpenedAt,
    );
  }

  final LibraryTrack? track;
  final LibraryPlaylist? playlist;
  final int timestamp;
}

class _RecentsSectionHeader extends StatelessWidget {
  const _RecentsSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textPrimary,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textSecondary,
              ),
        ),
      ],
    );
  }
}

class _RecentTrackTile extends StatelessWidget {
  const _RecentTrackTile({
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
                _ArtworkThumb(
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

class _RecentPlaylistTile extends StatelessWidget {
  const _RecentPlaylistTile({
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
                _ArtworkThumb(
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

class _ArtworkThumb extends StatelessWidget {
  const _ArtworkThumb({
    this.artworkUrl,
    this.localArtworkPath,
    this.useAppLogoFallback = false,
    required this.icon,
  });

  final String? artworkUrl;
  final String? localArtworkPath;
  final bool useAppLogoFallback;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (localArtworkPath != null && localArtworkPath!.isNotEmpty) {
      child = Image.file(
        File(localArtworkPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (artworkUrl != null && artworkUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: artworkUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 168,
        memCacheHeight: 168,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 56,
        height: 56,
        child: child,
      ),
    );
  }

  Widget _fallback() {
    if (useAppLogoFallback) {
      return Image.asset(
        'lib/assets/app_icon.png',
        fit: BoxFit.cover,
      );
    }

    return Container(
      color: bgCard,
      child: Icon(icon, color: accentPrimary),
    );
  }
}

class _RecentsEmptyState extends StatelessWidget {
  const _RecentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: accentPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: accentPrimary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nothing in recents yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play music or open a playlist and your activity will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

