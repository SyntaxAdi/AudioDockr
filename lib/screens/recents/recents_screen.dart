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

enum _RecentFilter { all, music, playlist }

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  _RecentFilter _filter = _RecentFilter.all;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final activityItems = <RecentActivityItem>[
      if (_filter == _RecentFilter.all || _filter == _RecentFilter.music)
        for (final track in libraryState.recentTracks)
          RecentActivityItem.track(track),
      if (_filter == _RecentFilter.all || _filter == _RecentFilter.playlist)
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
            if (index == 0) return _buildFilterChips();
            if (index == 1) return const SizedBox(height: 20);
            if (activityItems.isEmpty && index == 2) {
              return const RecentsEmptyState();
            } else if (index == 2) {
              final subtitle = switch (_filter) {
                _RecentFilter.all => 'Songs and playlists in one place.',
                _RecentFilter.music => 'Showing only music.',
                _RecentFilter.playlist => 'Showing only playlists.',
              };
              return RecentsSectionHeader(
                title: 'Recently played',
                subtitle: subtitle,
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == _RecentFilter.all,
            onSelected: () => setState(() => _filter = _RecentFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Music',
            selected: _filter == _RecentFilter.music,
            onSelected: () => setState(() => _filter = _RecentFilter.music),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Playlist',
            selected: _filter == _RecentFilter.playlist,
            onSelected: () => setState(() => _filter = _RecentFilter.playlist),
          ),
        ],
      ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: accentPrimary.withValues(alpha: 0.18),
      side: BorderSide(color: selected ? accentPrimary : bgDivider),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? accentPrimary : textPrimary,
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: bgSurface,
      checkmarkColor: accentPrimary,
    );
  }
}
