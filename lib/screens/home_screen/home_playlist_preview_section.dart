import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/horizontal_track_card.dart';
import '../library_screen/playlist_details_screen.dart';
import 'home_inline_info_card.dart';
import 'home_section_header.dart';
import 'home_track_sheets.dart';

class HomePlaylistPreviewSection extends ConsumerStatefulWidget {
  const HomePlaylistPreviewSection({super.key, required this.playlist});

  final LibraryPlaylist playlist;

  @override
  ConsumerState<HomePlaylistPreviewSection> createState() =>
      _HomePlaylistPreviewSectionState();
}

class _HomePlaylistPreviewSectionState
    extends ConsumerState<HomePlaylistPreviewSection> {
  late Future<List<LibraryTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = _loadTracks();
  }

  @override
  void didUpdateWidget(covariant HomePlaylistPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.id != widget.playlist.id ||
        oldWidget.playlist.trackCount != widget.playlist.trackCount) {
      _tracksFuture = _loadTracks();
    }
  }

  Future<List<LibraryTrack>> _loadTracks() {
    return ref
        .read(libraryProvider.notifier)
        .fetchPlaylistTracks(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryTrack>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        final tracks =
            snapshot.data?.take(10).toList() ?? const <LibraryTrack>[];

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomeSectionHeader(
                  eyebrow: 'Playlist',
                  title: widget.playlist.name,
                  subtitle: '${widget.playlist.trackCount} tracks saved',
                  actionLabel: 'Open',
                  onAction: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: widget.playlist.name,
                          playlistId: widget.playlist.id,
                        ),
                      ),
                    );
                  },
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: HomeInlineInfoCard(
                    icon: Icons.playlist_remove_rounded,
                    title: 'No songs in this playlist yet',
                    subtitle: 'Add tracks to this playlist and they will show up here.',
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
            ],
          ),
        );
      },
    );
  }
}
