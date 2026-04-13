import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import 'recents_activity_item.dart';
import 'recents_empty_state.dart';
import 'recents_playlist_tile.dart';
import 'recents_section_header.dart';
import 'recents_track_tile.dart';

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
    final activityItems = <RecentActivityItem>[
      for (final track in libraryState.recentTracks)
        RecentActivityItem.track(track),
      if (!_musicOnly)
        for (final playlist in libraryState.recentPlaylists)
          RecentActivityItem.playlist(playlist),
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
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: activityItems.isEmpty ? 3 : 4 + activityItems.length,
          itemBuilder: (context, index) {
            if (index == 0) return _buildFilterChip();
            if (index == 1) return const SizedBox(height: 20);
            if (activityItems.isEmpty && index == 2) {
              return const RecentsEmptyState();
            } else if (index == 2) {
              return RecentsSectionHeader(
                title: 'Recently played',
                subtitle: _musicOnly
                    ? 'Showing only music.'
                    : 'Songs and playlists in one place.',
              );
            }
            if (index == 3) return const SizedBox(height: 12);
            
            final item = activityItems[index - 4];
            if (item.track != null) {
              return RecentTrackTile(
                track: item.track!,
                onTap: () => _playTrack(item.track!),
              );
            } else if (item.playlist != null) {
              return RecentPlaylistTile(playlist: item.playlist!);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    return Row(
      children: [
        FilterChip(
          label: const Text('Music'),
          selected: _musicOnly,
          onSelected: (selected) => setState(() => _musicOnly = selected),
          selectedColor: accentPrimary.withValues(alpha: 0.18),
          side: BorderSide(color: _musicOnly ? accentPrimary : bgDivider),
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _musicOnly ? accentPrimary : textPrimary,
                fontWeight: FontWeight.w700,
              ),
          backgroundColor: bgSurface,
          checkmarkColor: accentPrimary,
        ),
      ],
    );
  }

  Future<void> _playTrack(LibraryTrack track) async {
    try {
      await ref.read(playbackNotifierProvider.notifier).playTrack(
            track.videoId,
            track.videoUrl,
            track.title,
            track.artist,
            track.thumbnailUrl,
          );
    } on PlaybackFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
