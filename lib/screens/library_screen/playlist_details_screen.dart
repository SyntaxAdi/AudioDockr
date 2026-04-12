import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/playlist_sheets.dart';
import 'library_edit_playlist_sheet.dart';
import 'library_editable_playlist_header.dart';
import 'library_empty_playlist_state.dart';
import 'library_playlist_option_tile.dart';
import 'library_playlist_track_list.dart';
import 'library_track_row.dart';

enum _PlaylistMenuAction { modify, rename, changeCoverArt, delete }

class PlaylistDetailsScreen extends ConsumerStatefulWidget {
  const PlaylistDetailsScreen({
    super.key,
    required this.title,
    this.tracks,
    this.playlistId,
    this.onNavigateToTab,
  });

  final String title;
  final List<LibraryTrack>? tracks;
  final String? playlistId;
  final ValueChanged<int>? onNavigateToTab;

  @override
  ConsumerState<PlaylistDetailsScreen> createState() =>
      _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends ConsumerState<PlaylistDetailsScreen> {
  Future<List<LibraryTrack>>? _playlistTracksFuture;

  bool get _isEditableCustomPlaylist =>
      widget.playlistId != null && widget.playlistId != likedPlaylistId;

  @override
  void initState() {
    super.initState();
    _refreshPlaylistTracksFuture();
    _recordPlaylistOpen();
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _refreshPlaylistTracksFuture();
      _recordPlaylistOpen();
    }
  }

  void _recordPlaylistOpen() {
    final playlistId = widget.playlistId;
    if (playlistId == null || playlistId.isEmpty) return;
    unawaited(
        ref.read(libraryProvider.notifier).recordPlaylistOpened(playlistId));
  }

  void _refreshPlaylistTracksFuture() {
    if (widget.playlistId == null) {
      _playlistTracksFuture = null;
      return;
    }
    _playlistTracksFuture = ref
        .read(libraryProvider.notifier)
        .fetchPlaylistTracks(widget.playlistId!);
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> _playPlaylistTracks(
    BuildContext context,
    List<LibraryTrack> tracks,
  ) async {
    final playableTracks =
        tracks.where((t) => !t.hiddenInPlaylist).toList(growable: false);
    if (playableTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No visible songs available to play in this playlist')),
      );
      return;
    }
    try {
      await ref.read(playbackNotifierProvider.notifier).playTracks(playableTracks);
    } on PlaybackFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  // ── Queue sheet ───────────────────────────────────────────────────────────

  Future<void> _showQueueSheet(BuildContext context) async {
    final queue = ref.read(playbackNotifierProvider).queue;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 18),
                    decoration: BoxDecoration(
                      color: bgDivider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Queue',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: textPrimary),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: queue.isEmpty
                              ? null
                              : () {
                                  ref
                                      .read(playbackNotifierProvider.notifier)
                                      .clearQueue();
                                  Navigator.of(sheetContext).pop();
                                },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (queue.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text('NO SONGS IN QUEUE',
                            style: Theme.of(context).textTheme.labelSmall),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: queue.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: bgDivider),
                        itemBuilder: (context, index) {
                          final queuedTrack = queue[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              color: bgDivider,
                              child: queuedTrack.thumbnailUrl.isEmpty
                                  ? const Icon(Icons.music_note,
                                      color: textSecondary)
                                  : CachedNetworkImage(
                                      imageUrl: queuedTrack.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 132,
                                      memCacheHeight: 132,
                                    ),
                            ),
                            title: Text(queuedTrack.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(queuedTrack.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Add-to-another-playlist sheet ─────────────────────────────────────────

  Future<void> _showAddToAnotherPlaylistSheet(
    BuildContext context, {
    required String currentPlaylistId,
    required LibraryTrack track,
  }) async {
    final userPlaylists = ref
        .read(libraryProvider)
        .userPlaylists
        .where((p) => p.id != currentPlaylistId)
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.56,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin:
                          const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Add to another playlist',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: textPrimary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (userPlaylists.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'NO OTHER PLAYLISTS YET',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: textSecondary),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await showCreatePlaylistSheet(
                                      context, ref);
                                  if (!mounted || !context.mounted) return;
                                  await _showAddToAnotherPlaylistSheet(
                                    context,
                                    currentPlaylistId: currentPlaylistId,
                                    track: track,
                                  );
                                },
                                child: const Text('CREATE PLAYLIST'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: userPlaylists.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final playlist = userPlaylists[index];
                          return InkWell(
                            onTap: () async {
                              final added = await ref
                                  .read(libraryProvider.notifier)
                                  .addTrackToPlaylist(
                                    playlistId: playlist.id,
                                    videoId: track.videoId,
                                    videoUrl: track.videoUrl,
                                    title: track.title,
                                    artist: track.artist,
                                    thumbnailUrl: track.thumbnailUrl,
                                    durationSeconds:
                                        track.durationSeconds,
                                  );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? 'Added "${track.title}" to ${playlist.name}'
                                        : '"${track.title}" is already in ${playlist.name}',
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: bgDivider),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accentPrimary
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.queue_music_rounded,
                                      color: accentPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      playlist.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Track visibility ──────────────────────────────────────────────────────

  Future<void> _toggleTrackHidden(
    BuildContext context, {
    required String playlistId,
    required LibraryTrack track,
  }) async {
    final hidden = !track.hiddenInPlaylist;
    await ref.read(libraryProvider.notifier).setTrackHiddenInPlaylist(
          playlistId: playlistId,
          videoId: track.videoId,
          hidden: hidden,
        );
    setState(_refreshPlaylistTracksFuture);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hidden
              ? 'Hidden "${track.title}" in this playlist'
              : 'Showing "${track.title}" in this playlist again',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _handleBottomNavigation(BuildContext context, int index) {
    if (index == 2) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onNavigateToTab?.call(index);
  }

  // ── Playlist management sheets ────────────────────────────────────────────

  Future<void> _showEditPlaylistSheet(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylist playlist, {
    bool allowCoverArt = true,
    String title = 'Edit Playlist',
    String submitLabel = 'Save',
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LibraryEditPlaylistSheet(
        playlist: playlist,
        title: title,
        submitLabel: submitLabel,
        allowCoverArt: allowCoverArt,
        onSave: (trimmedName, coverImagePath) async {
          await ref.read(libraryProvider.notifier).updatePlaylist(
                playlistId: playlist.id,
                name: trimmedName,
                coverImagePath: coverImagePath,
              );
        },
      ),
    );
    setState(_refreshPlaylistTracksFuture);
  }

  Future<void> _renamePlaylist(
      BuildContext context, LibraryPlaylist playlist) async {
    await _showEditPlaylistSheet(
      context,
      ref,
      playlist,
      allowCoverArt: false,
      title: 'Rename Playlist',
      submitLabel: 'Rename',
    );
  }

  Future<void> _changePlaylistCoverArt(
      BuildContext context, LibraryPlaylist playlist) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) return;

    await ref.read(libraryProvider.notifier).updatePlaylist(
          playlistId: playlist.id,
          name: playlist.name,
          coverImagePath: selectedPath,
        );
    setState(_refreshPlaylistTracksFuture);
  }

  Future<void> _deletePlaylist(
      BuildContext context, LibraryPlaylist playlist) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: bgSurface,
            title: const Text('Delete playlist'),
            content: Text(
              'Delete "${playlist.name}"? This removes the playlist and its saved order.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: accentPrimary,
                  side: BorderSide.none,
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: accentPrimary,
                  side: BorderSide.none,
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${playlist.name}')),
    );
  }

  Future<void> _handlePlaylistMenuAction(
    BuildContext context,
    _PlaylistMenuAction action,
    LibraryPlaylist playlist,
  ) async {
    switch (action) {
      case _PlaylistMenuAction.modify:
        await _showEditPlaylistSheet(context, ref, playlist);
        return;
      case _PlaylistMenuAction.rename:
        await _renamePlaylist(context, playlist);
        return;
      case _PlaylistMenuAction.changeCoverArt:
        await _changePlaylistCoverArt(context, playlist);
        return;
      case _PlaylistMenuAction.delete:
        await _deletePlaylist(context, playlist);
        return;
    }
  }

  Future<void> _showPlaylistActionSheet(
    BuildContext context,
    LibraryPlaylist playlist,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Future<void> handleAction(_PlaylistMenuAction action) async {
          Navigator.of(sheetContext).pop();
          await _handlePlaylistMenuAction(context, action, playlist);
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin:
                          const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  LibraryPlaylistOptionTile(
                    icon: Icons.tune_rounded,
                    title: 'Modify playlist',
                    subtitle: 'Update the name and cover art',
                    onTap: () => handleAction(_PlaylistMenuAction.modify),
                  ),
                  LibraryPlaylistOptionTile(
                    icon: Icons.drive_file_rename_outline_rounded,
                    title: 'Rename playlist',
                    subtitle: 'Change the playlist name only',
                    onTap: () => handleAction(_PlaylistMenuAction.rename),
                  ),
                  LibraryPlaylistOptionTile(
                    icon: Icons.image_outlined,
                    title: 'Change cover art',
                    subtitle: 'Pick a new image for this playlist',
                    onTap: () =>
                        handleAction(_PlaylistMenuAction.changeCoverArt),
                  ),
                  LibraryPlaylistOptionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete playlist',
                    subtitle: 'Remove this playlist and its saved order',
                    onTap: () => handleAction(_PlaylistMenuAction.delete),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shuffleEnabled = ref.watch(
      playbackNotifierProvider.select((s) => s.shuffleEnabled),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );
    final playlists = ref.watch(libraryProvider).playlists;
    LibraryPlaylist? playlist;
    for (final entry in playlists) {
      if (entry.id == widget.playlistId) {
        playlist = entry;
        break;
      }
    }
    final canEdit = _isEditableCustomPlaylist && playlist != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: canEdit
            ? null
            : Text(widget.title.toUpperCase(), style: titleStyle),
      ),
      body: widget.playlistId == null
          ? LibraryPlaylistTrackList(
              tracks: widget.tracks ?? const [],
              enableQueueActions: true,
            )
          : FutureBuilder<List<LibraryTrack>>(
              future: _playlistTracksFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: accentPrimary),
                  );
                }
                final playlistTracks = snapshot.data!;
                if (!canEdit) {
                  return LibraryPlaylistTrackList(tracks: playlistTracks);
                }
                final editablePlaylist = playlist!;

                if (playlistTracks.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LibraryEditablePlaylistHeader(
                          playlist: editablePlaylist,
                          tracks: playlistTracks,
                          shuffleEnabled: shuffleEnabled,
                          onPlayPressed: () =>
                              _playPlaylistTracks(context, playlistTracks),
                          onShufflePressed: () => ref
                              .read(playbackNotifierProvider.notifier)
                              .setShuffleEnabled(!shuffleEnabled),
                          onMenuPressed: () => _showPlaylistActionSheet(
                              context, editablePlaylist),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: LibraryEmptyPlaylistState(),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: playlistTracks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: LibraryEditablePlaylistHeader(
                              playlist: editablePlaylist,
                              tracks: playlistTracks,
                              shuffleEnabled: shuffleEnabled,
                              onPlayPressed: () =>
                                  _playPlaylistTracks(context, playlistTracks),
                              onShufflePressed: () => ref
                                  .read(playbackNotifierProvider.notifier)
                                  .setShuffleEnabled(!shuffleEnabled),
                              onMenuPressed: () => _showPlaylistActionSheet(
                                  context, editablePlaylist),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }

                    if (index == playlistTracks.length + 1) {
                      return const SizedBox(height: 0);
                    }

                    final track = playlistTracks[index - 1];
                    return SizedBox(
                      height: 77,
                      child: Column(
                        children: [
                          Expanded(
                            child: LibraryTrackRow(
                              track: track,
                              playlistId: editablePlaylist.id,
                              onAddToAnotherPlaylist: () =>
                                  _showAddToAnotherPlaylistSheet(
                                context,
                                currentPlaylistId: editablePlaylist.id,
                                track: track,
                              ),
                              onToggleHidden: () => _toggleTrackHidden(
                                context,
                                playlistId: editablePlaylist.id,
                                track: track,
                              ),
                              onGoToQueue: () => _showQueueSheet(context),
                            ),
                          ),
                          if (index != playlistTracks.length)
                            const Divider(height: 1, color: bgDivider),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 2,
        onTap: (index) => _handleBottomNavigation(context, index),
      ),
    );
  }
}
