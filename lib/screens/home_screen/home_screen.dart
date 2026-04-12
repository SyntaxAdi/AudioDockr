import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/horizontal_track_card.dart';
import '../library_screen/playlist_details_screen.dart';
import 'home_collection_grid.dart';
import 'home_empty_state.dart';
import 'home_inline_info_card.dart';
import 'home_playlist_preview_section.dart';
import 'home_section_header.dart';
import 'home_shortcut_data.dart';
import 'home_top_bar.dart';
import 'home_track_sheets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onViewMore,
    required this.onOpenMenu,
  });

  final VoidCallback onViewMore;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final recentlyPlayed = libraryState.recentTracks.take(3).toList();
    final latestPlayedTrack =
        libraryState.recentTracks.isNotEmpty ? libraryState.recentTracks.first : null;
    final playlists = libraryState.userPlaylists;
    final likedTracks = libraryState.likedTracks;
    final mediaQuery = MediaQuery.of(context);
    final hasContent = recentlyPlayed.isNotEmpty || playlists.isNotEmpty;

    final shortcutItems = _buildShortcutItems(
      context: context,
      ref: ref,
      libraryState: libraryState,
      latestPlayedTrack: latestPlayedTrack,
      likedTracks: likedTracks,
      playlists: playlists,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            HomeTopBar(onProfileTap: onOpenMenu),
            if (shortcutItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomeCollectionGrid(items: shortcutItems),
              ),
            ],
            if (libraryState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: accentPrimary),
                ),
              )
            else ...[
              if (!hasContent)
                SizedBox(
                  height: mediaQuery.size.height * 0.42,
                  child: const HomeEmptyState(),
                )
              else ...[
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: HomeSectionHeader(
                    eyebrow: 'Jump back in',
                    title: 'Recent songs played',
                  ),
                ),
                const SizedBox(height: 14),
                if (recentlyPlayed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: HomeInlineInfoCard(
                      icon: Icons.history_rounded,
                      title: 'No recent tracks yet',
                      subtitle:
                          'Start a song and it will appear here for quick access.',
                    ),
                  )
                else
                  SizedBox(
                    height: 208,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyPlayed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final track = recentlyPlayed[index];
                        return HorizontalTrackCard(
                          track: track,
                          onTap: () async {
                            try {
                              await ref
                                  .read(playbackNotifierProvider.notifier)
                                  .playTrack(
                                    track.videoId,
                                    track.videoUrl,
                                    track.title,
                                    track.artist,
                                    track.thumbnailUrl,
                                  );
                            } on PlaybackFailure catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            }
                          },
                          onLongPress: () =>
                              showTrackActionsSheet(context, ref, track),
                        );
                      },
                    ),
                  ),
                if (playlists.isNotEmpty) const SizedBox(height: 1),
                for (final playlist in playlists)
                  HomePlaylistPreviewSection(playlist: playlist),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<HomeShortcutData> _buildShortcutItems({
    required BuildContext context,
    required WidgetRef ref,
    required LibraryState libraryState,
    required LibraryTrack? latestPlayedTrack,
    required List<LibraryTrack> likedTracks,
    required List<LibraryPlaylist> playlists,
  }) {
    final items = <HomeShortcutData>[
      HomeShortcutData(
        title: 'Liked Songs',
        subtitle: '',
        icon: Icons.favorite_rounded,
        isLikedCollection: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailsScreen(
                title: 'Liked Songs',
                tracks: likedTracks,
              ),
            ),
          );
        },
      ),
      HomeShortcutData(
        title: 'Recents',
        subtitle: '${libraryState.recentTracks.length} tracks',
        isCyberpunkRecents: true,
        icon: Icons.history_rounded,
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
      HomeShortcutData(
        title: latestPlayedTrack?.title ?? 'Recently played',
        subtitle: latestPlayedTrack?.artist ?? 'Your latest song will appear here',
        artworkUrl: latestPlayedTrack?.thumbnailUrl,
        icon: Icons.history_rounded,
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
        onLongPress: latestPlayedTrack == null
            ? null
            : () => showTrackActionsSheet(context, ref, latestPlayedTrack),
      ),
    ];

    final remainingSlots = 8 - items.length;
    final playlistCount =
        playlists.length >= remainingSlots ? remainingSlots : playlists.length;

    items.addAll([
      for (final playlist in playlists.take(playlistCount))
        HomeShortcutData(
          title: playlist.name,
          subtitle: '${playlist.trackCount} tracks',
          localArtworkPath: playlist.coverImagePath,
          icon: Icons.queue_music_rounded,
          usesAppLogoFallback: true,
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
        ),
    ]);

    final remainingSongSlots = 8 - items.length;
    final gridRecentTracks = latestPlayedTrack == null
        ? libraryState.recentTracks
        : libraryState.recentTracks.skip(1).toList();

    items.addAll([
      for (final track in gridRecentTracks.take(remainingSongSlots))
        HomeShortcutData(
          title: track.title,
          subtitle: track.artist,
          artworkUrl: track.thumbnailUrl,
          icon: Icons.music_note_rounded,
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
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message)),
              );
            }
          },
          onLongPress: () => showTrackActionsSheet(context, ref, track),
        ),
    ]);

    return items;
  }
}
