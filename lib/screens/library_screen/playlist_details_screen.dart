import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download_manager/download_provider.dart';
import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/playlist_sheets.dart';
import 'library_edit_playlist_sheet.dart';
import 'library_editable_playlist_header.dart';
import 'library_empty_playlist_state.dart';
import 'library_playlist_card.dart';
import 'library_playlist_option_tile.dart';
import 'library_track_row.dart';

enum _PlaylistMenuAction { modify, rename, changeCoverArt, download, delete }

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
  late final ScrollController _scrollController;
  double _appBarTitleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Delay fetching slightly to allow navigation transition to start at 120fps
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _refreshPlaylistTracksFuture();
        });
      }
    });
    _recordPlaylistOpen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // Start appearing at 240px, fully visible at 290px
    // (Total collapse is at ~284px: 340 expanded - 56 toolbar)
    final double newOpacity = ((offset - 240) / (290 - 240)).clamp(0.0, 1.0);
    if (newOpacity != _appBarTitleOpacity) {
      setState(() {
        _appBarTitleOpacity = newOpacity;
      });
    }
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
      _playlistTracksFuture = Future.value(widget.tracks ?? []);
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

  Future<void> _downloadPlaylist(
    BuildContext context,
    LibraryPlaylist playlist,
  ) async {
    final tracks = await ref
        .read(libraryProvider.notifier)
        .fetchPlaylistTracks(playlist.id);

    if (tracks.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks to download in this playlist')),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download of ${tracks.length} tracks...'),
        duration: const Duration(seconds: 2),
      ),
    );

    for (final track in tracks) {
      unawaited(ref.read(downloadNotifierProvider.notifier).startDownload(
            videoId: track.videoId,
            videoUrl: track.videoUrl,
            title: track.title,
            artist: track.artist,
            thumbnailUrl: track.thumbnailUrl,
          ));
    }
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
      case _PlaylistMenuAction.download:
        await _downloadPlaylist(context, playlist);
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
                    icon: Icons.download_rounded,
                    title: 'Download playlist',
                    subtitle: 'Save all tracks for offline listening',
                    onTap: () => handleAction(_PlaylistMenuAction.download),
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
    final displayTracks = widget.tracks;
    final playlists = ref.watch(libraryProvider).playlists;
    LibraryPlaylist? playlist;
    
    if (widget.playlistId != null) {
      for (final entry in playlists) {
        if (entry.id == widget.playlistId) {
          playlist = entry;
          break;
        }
      }
    } else {
      // It might be Liked Songs or Recents without a playlistId
      playlist = LibraryPlaylist(
        id: widget.title == 'Liked Songs' ? likedPlaylistId : 'recents',
        name: widget.title,
        coverImagePath: '',
        trackCount: displayTracks?.length ?? 0,
      );
    }

    final currentPlaylist = playlist!;
    final isLikedOrRecents = currentPlaylist.id == likedPlaylistId || currentPlaylist.id == 'recents';

    return Scaffold(
      backgroundColor: bgBase,
      body: FutureBuilder<List<LibraryTrack>>(
        future: widget.playlistId != null 
          ? _playlistTracksFuture 
          : Future.value(displayTracks ?? []),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _PlaylistSkeleton(
              title: currentPlaylist.name,
              isLikedOrRecents: isLikedOrRecents,
              playlistId: currentPlaylist.id,
              coverImagePath: currentPlaylist.coverImagePath,
            );
          }
          final playlistTracks = snapshot.data!;
          final subtitleText = '${playlistTracks.length} songs';

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                elevation: 0,
                backgroundColor: bgBase,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  title: AnimatedOpacity(
                    opacity: _appBarTitleOpacity,
                    duration: const Duration(milliseconds: 100),
                    child: Text(
                      currentPlaylist.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  background: RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Large background image
                        if (currentPlaylist.coverImagePath.isNotEmpty)
                          Image.file(
                            File(currentPlaylist.coverImagePath),
                            fit: BoxFit.cover,
                          )
                        else if (isLikedOrRecents)
                          LibraryCyberpunkPlaylistBadge(
                            variant: currentPlaylist.id == likedPlaylistId 
                              ? LibraryCyberpunkPlaylistBadgeVariant.liked 
                              : LibraryCyberpunkPlaylistBadgeVariant.recents,
                            size: 400,
                          )
                        else
                          Container(
                            color: bgSurface,
                            child: Image.asset(
                              'lib/assets/app_icon.png',
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.24),
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                size: 100,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        // Gradient overlay
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.6, 1.0],
                              colors: [
                                Colors.black26,
                                Colors.transparent,
                                bgBase,
                              ],
                            ),
                          ),
                        ),
                        // Title at the bottom
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 24,
                          child: Text(
                            currentPlaylist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitleText,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LibraryPlaylistHeaderActions(
                        hasTracks: playlistTracks.isNotEmpty,
                        shuffleEnabled: shuffleEnabled,
                        onPlayPressed: () => _playPlaylistTracks(
                            context, playlistTracks),
                        onShufflePressed: () => ref
                            .read(playbackNotifierProvider.notifier)
                            .setShuffleEnabled(!shuffleEnabled),
                        onMenuPressed: isLikedOrRecents 
                          ? () {} // No menu for liked/recents or define actions
                          : () => _showPlaylistActionSheet(context, currentPlaylist),
                        showMenu: !isLikedOrRecents,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (playlistTracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: LibraryEmptyPlaylistState(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = playlistTracks[index];
                      return RepaintBoundary(
                        child: SizedBox(
                          height: 64,
                          child: LibraryTrackRow(
                            track: track,
                            playlistId: currentPlaylist.id,
                            enableQueueActions: true, // Enable swipe to queue
                            onAddToAnotherPlaylist: () =>
                                _showAddToAnotherPlaylistSheet(
                              context,
                              currentPlaylistId: currentPlaylist.id,
                              track: track,
                            ),
                            onToggleHidden: () => _toggleTrackHidden(
                              context,
                              playlistId: currentPlaylist.id,
                              track: track,
                            ),
                            onGoToQueue: () => _showQueueSheet(context),
                          ),
                        ),
                      );
                    },
                    childCount: playlistTracks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
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

class _PlaylistSkeleton extends StatefulWidget {
  const _PlaylistSkeleton({
    required this.title,
    required this.isLikedOrRecents,
    required this.playlistId,
    required this.coverImagePath,
  });

  final String title;
  final bool isLikedOrRecents;
  final String playlistId;
  final String coverImagePath;

  @override
  State<_PlaylistSkeleton> createState() => _PlaylistSkeletonState();
}

class _PlaylistSkeletonState extends State<_PlaylistSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          elevation: 0,
          backgroundColor: bgBase,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.coverImagePath.isNotEmpty)
                  Image.file(
                    File(widget.coverImagePath),
                    fit: BoxFit.cover,
                  )
                else if (widget.isLikedOrRecents)
                  LibraryCyberpunkPlaylistBadge(
                    variant: widget.playlistId == likedPlaylistId 
                      ? LibraryCyberpunkPlaylistBadgeVariant.liked 
                      : LibraryCyberpunkPlaylistBadgeVariant.recents,
                    size: 400,
                  )
                else
                  Container(
                    color: bgSurface,
                    child: Image.asset(
                      'lib/assets/app_icon.png',
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.24),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.6, 1.0],
                      colors: [
                        Colors.black26,
                        Colors.transparent,
                        bgBase,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(controller: _controller, width: 60, height: 12),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ShimmerBlock(controller: _controller, width: 100, height: 42, radius: 21),
                    const SizedBox(width: 12),
                    _ShimmerBlock(controller: _controller, width: 42, height: 42, radius: 21),
                    const Spacer(),
                    _ShimmerBlock(controller: _controller, width: 32, height: 32, radius: 16),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _ShimmerBlock(controller: _controller, width: 44, height: 44, radius: 4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBlock(controller: _controller, width: double.infinity, height: 14),
                        const SizedBox(height: 6),
                        _ShimmerBlock(controller: _controller, width: 120, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ShimmerBlock(controller: _controller, width: 24, height: 24, radius: 12),
                  const SizedBox(width: 14),
                  _ShimmerBlock(controller: _controller, width: 20, height: 20, radius: 4),
                ],
              ),
            ),
            childCount: 8,
          ),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.controller,
    required this.width,
    required this.height,
    this.radius = 2,
  });

  final AnimationController controller;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgDivider.withValues(alpha: 0.4),
                bgDivider.withValues(alpha: 0.8),
                bgDivider.withValues(alpha: 0.4),
              ],
              stops: [
                (controller.value - 0.3).clamp(0.0, 1.0),
                controller.value,
                (controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
