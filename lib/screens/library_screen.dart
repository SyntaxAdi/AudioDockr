import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/spotify_import_provider.dart';
import '../theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/playlist_sheets.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    this.onNavigateToTab,
    this.openRecentsToken = 0,
  });

  final ValueChanged<int>? onNavigateToTab;
  final int openRecentsToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LibraryScreenContent(
      onNavigateToTab: onNavigateToTab,
      openRecentsToken: openRecentsToken,
    );
  }
}

class _LibraryScreenContent extends ConsumerStatefulWidget {
  const _LibraryScreenContent({
    this.onNavigateToTab,
    this.openRecentsToken = 0,
  });

  final ValueChanged<int>? onNavigateToTab;
  final int openRecentsToken;

  @override
  ConsumerState<_LibraryScreenContent> createState() =>
      _LibraryScreenContentState();
}

class _LibraryScreenContentState extends ConsumerState<_LibraryScreenContent> {
  int? _lastHandledOpenRecentsToken;

  @override
  void initState() {
    super.initState();
    _scheduleOpenRecentsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LibraryScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openRecentsToken != widget.openRecentsToken) {
      _scheduleOpenRecentsIfNeeded();
    }
  }

  void _scheduleOpenRecentsIfNeeded() {
    if (widget.openRecentsToken == 0 ||
        _lastHandledOpenRecentsToken == widget.openRecentsToken) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastHandledOpenRecentsToken == widget.openRecentsToken) {
        return;
      }
      _lastHandledOpenRecentsToken = widget.openRecentsToken;
      _openRecents();
    });
  }

  void _openRecents() {
    final libraryState = ref.read(libraryProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailsScreen(
          title: 'Recents',
          tracks: libraryState.recentTracks,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.5,
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
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Add Playlist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PlaylistOptionTile(
                    icon: Icons.add_box_rounded,
                    title: 'Create Playlist',
                    subtitle: 'Start a fresh playlist in your library',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await showCreatePlaylistSheet(parentContext, ref);
                    },
                  ),
                  _PlaylistOptionTile(
                    icon: Icons.queue_music_rounded,
                    title: 'Import Playlist from Spotify',
                    subtitle: 'Paste a Spotify playlist URL',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final spotifyUrl =
                          await showSpotifyPlaylistImportSheet(parentContext);
                      if (spotifyUrl == null || !parentContext.mounted) {
                        return;
                      }
                      await ref
                          .read(spotifyImportProvider.notifier)
                          .importPlaylist(spotifyUrl);
                      if (!parentContext.mounted) {
                        return;
                      }
                      final importState = ref.read(spotifyImportProvider);
                      final message = importState.errorMessage ??
                          (importState.importedPlaylistName == null
                              ? null
                              : 'Imported into ${importState.importedPlaylistName}');
                      if (message == null) {
                        return;
                      }
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            onPressed: () => _showPlaylistOptions(context, ref),
            icon: const Icon(
              Icons.add_rounded,
              color: accentPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                  leading: const _CyberpunkPlaylistBadge(
                    variant: _CyberpunkPlaylistBadgeVariant.liked,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: 'Liked Songs',
                          tracks: libraryState.likedTracks,
                          onNavigateToTab: widget.onNavigateToTab,
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
                  leading: const _CyberpunkPlaylistBadge(
                    variant: _CyberpunkPlaylistBadgeVariant.recents,
                  ),
                  onTap: () {
                    _openRecents();
                  },
                ),
                for (final playlist in libraryState.userPlaylists) ...[
                  const SizedBox(height: 12),
                  _PlaylistCard(
                    title: playlist.name,
                    subtitle: '',
                    icon: Icons.queue_music_rounded,
                    leading: _PlaylistCoverArt(
                      imagePath: playlist.coverImagePath,
                      imageUrl: '',
                      size: 56,
                      borderRadius: 12,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailsScreen(
                            title: playlist.name,
                            playlistId: playlist.id,
                            onNavigateToTab: widget.onNavigateToTab,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _PlaylistOptionTile extends StatelessWidget {
  const _PlaylistOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.plain = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    if (plain) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(icon, color: accentPrimary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  color: accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
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
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: accentPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

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
    if (playlistId == null || playlistId.isEmpty) {
      return;
    }
    unawaited(ref.read(libraryProvider.notifier).recordPlaylistOpened(playlistId));
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

  Future<void> _playPlaylistTracks(
    BuildContext context,
    List<LibraryTrack> tracks,
  ) async {
    final playableTracks =
        tracks.where((track) => !track.hiddenInPlaylist).toList(growable: false);
    if (playableTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No visible songs available to play in this playlist'),
        ),
      );
      return;
    }

    try {
      await ref.read(playbackNotifierProvider.notifier).playTracks(
            playableTracks,
          );
    } on PlaybackFailure catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: textPrimary,
                                  ),
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
                        child: Text(
                          'NO SONGS IN QUEUE',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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
                                  ? const Icon(
                                      Icons.music_note,
                                      color: textSecondary,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: queuedTrack.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 132,
                                      memCacheHeight: 132,
                                    ),
                            ),
                            title: Text(
                              queuedTrack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              queuedTrack.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Future<void> _showAddToAnotherPlaylistSheet(
    BuildContext context, {
    required String currentPlaylistId,
    required LibraryTrack track,
  }) async {
    final userPlaylists = ref
        .read(libraryProvider)
        .userPlaylists
        .where((playlist) => playlist.id != currentPlaylistId)
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
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (userPlaylists.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                  await showCreatePlaylistSheet(context, ref);
                                  if (!mounted || !context.mounted) {
                                    return;
                                  }
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
                                    durationSeconds: track.durationSeconds,
                                  );
                              if (!sheetContext.mounted) {
                                return;
                              }
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
                                      color:
                                          accentPrimary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
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
    setState(() {
      _refreshPlaylistTracksFuture();
    });
    if (!context.mounted) {
      return;
    }
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

  void _handleBottomNavigation(BuildContext context, int index) {
    if (index == 2) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onNavigateToTab?.call(index);
  }

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
      builder: (context) => _EditPlaylistSheet(
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

    setState(() {
      _refreshPlaylistTracksFuture();
    });
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    LibraryPlaylist playlist,
  ) async {
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
    BuildContext context,
    LibraryPlaylist playlist,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    await ref.read(libraryProvider.notifier).updatePlaylist(
          playlistId: playlist.id,
          name: playlist.name,
          coverImagePath: selectedPath,
        );

    setState(() {
      _refreshPlaylistTracksFuture();
    });
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    LibraryPlaylist playlist,
  ) async {
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

    if (!shouldDelete) {
      return;
    }

    await ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
    if (!context.mounted) {
      return;
    }
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
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  _PlaylistOptionTile(
                    icon: Icons.tune_rounded,
                    title: 'Modify playlist',
                    subtitle: 'Update the name and cover art',
                    onTap: () => handleAction(_PlaylistMenuAction.modify),
                  ),
                  _PlaylistOptionTile(
                    icon: Icons.drive_file_rename_outline_rounded,
                    title: 'Rename playlist',
                    subtitle: 'Change the playlist name only',
                    onTap: () => handleAction(_PlaylistMenuAction.rename),
                  ),
                  _PlaylistOptionTile(
                    icon: Icons.image_outlined,
                    title: 'Change cover art',
                    subtitle: 'Pick a new image for this playlist',
                    onTap: () => handleAction(_PlaylistMenuAction.changeCoverArt),
                  ),
                  _PlaylistOptionTile(
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

  @override
  Widget build(BuildContext context) {
    final shuffleEnabled = ref.watch(
      playbackNotifierProvider.select((state) => state.shuffleEnabled),
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
            : Text(
                widget.title.toUpperCase(),
                style: titleStyle,
              ),
      ),
      body: widget.playlistId == null
          ? _PlaylistTrackList(
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
                  return _PlaylistTrackList(tracks: playlistTracks);
                }
                final editablePlaylist = playlist!;

                if (playlistTracks.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _EditablePlaylistHeader(
                        playlist: editablePlaylist,
                        tracks: playlistTracks,
                        shuffleEnabled: shuffleEnabled,
                        onPlayPressed: () => _playPlaylistTracks(
                          context,
                          playlistTracks,
                        ),
                        onShufflePressed: () => ref
                            .read(playbackNotifierProvider.notifier)
                            .setShuffleEnabled(!shuffleEnabled),
                        onMenuPressed: () =>
                            _showPlaylistActionSheet(context, editablePlaylist),
                      ),
                      const SizedBox(height: 28),
                      const _EmptyPlaylistState(),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: playlistTracks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EditablePlaylistHeader(
                            playlist: editablePlaylist,
                            tracks: playlistTracks,
                            shuffleEnabled: shuffleEnabled,
                            onPlayPressed: () => _playPlaylistTracks(
                              context,
                              playlistTracks,
                            ),
                            onShufflePressed: () => ref
                                .read(playbackNotifierProvider.notifier)
                                .setShuffleEnabled(!shuffleEnabled),
                            onMenuPressed: () => _showPlaylistActionSheet(
                              context,
                              editablePlaylist,
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
                            child: _LibraryTrackRow(
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

class _EditablePlaylistHeader extends StatelessWidget {
  const _EditablePlaylistHeader({
    required this.playlist,
    required this.tracks,
    required this.shuffleEnabled,
    required this.onPlayPressed,
    required this.onShufflePressed,
    required this.onMenuPressed,
  });

  final LibraryPlaylist playlist;
  final List<LibraryTrack> tracks;
  final bool shuffleEnabled;
  final VoidCallback onPlayPressed;
  final VoidCallback onShufflePressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final hasTracks = tracks.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaylistCoverArt(
          imagePath: playlist.coverImagePath,
          imageUrl: '',
          size: 120,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shouldStack = constraints.maxWidth < 230;
                final title = Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        color: textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                final actions = _PlaylistHeaderActions(
                  hasTracks: hasTracks,
                  shuffleEnabled: shuffleEnabled,
                  onPlayPressed: onPlayPressed,
                  onShufflePressed: onShufflePressed,
                  onMenuPressed: onMenuPressed,
                );

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: actions,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: title),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: actions,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaylistHeaderActions extends StatelessWidget {
  const _PlaylistHeaderActions({
    required this.hasTracks,
    required this.shuffleEnabled,
    required this.onPlayPressed,
    required this.onShufflePressed,
    required this.onMenuPressed,
  });

  final bool hasTracks;
  final bool shuffleEnabled;
  final VoidCallback onPlayPressed;
  final VoidCallback onShufflePressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = IconButton.styleFrom(
      minimumSize: const Size(52, 52),
      fixedSize: const Size(52, 52),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Playlist options',
          onPressed: onMenuPressed,
          style: buttonStyle,
          iconSize: 28,
          color: textPrimary,
          icon: const Icon(Icons.more_vert_rounded),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: hasTracks ? onShufflePressed : null,
          style: buttonStyle,
          iconSize: 28,
          color: shuffleEnabled ? accentPrimary : textPrimary,
          icon: const Icon(Icons.shuffle_rounded),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: hasTracks ? onPlayPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accentPrimary,
            foregroundColor: bgBase,
            minimumSize: const Size(52, 52),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 28),
        ),
      ],
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  const _EmptyPlaylistState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This playlist is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs from the player using the add to playlist button, then use the actions above to rename it, change cover art, or tidy it up.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

enum _PlaylistMenuAction {
  modify,
  rename,
  changeCoverArt,
  delete,
}

class _PlaylistCoverArt extends StatelessWidget {
  const _PlaylistCoverArt({
    required this.imagePath,
    required this.imageUrl,
    required this.size,
    this.borderRadius = 18,
  });

  final String imagePath;
  final String imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final targetCacheSize =
        (size * MediaQuery.of(context).devicePixelRatio).round();
    Widget child;

    if (imagePath.isNotEmpty) {
      child = Image(
        image: ResizeImage(
          FileImage(File(imagePath)),
          width: targetCacheSize,
          height: targetCacheSize,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _playlistFallbackArt(),
      );
    } else if (imageUrl.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        memCacheWidth: targetCacheSize,
        memCacheHeight: targetCacheSize,
        maxWidthDiskCache: targetCacheSize,
        maxHeightDiskCache: targetCacheSize,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _playlistFallbackArt(),
      );
    } else {
      child = _playlistFallbackArt();
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: bgCard,
        child: child,
      ),
    );
  }

  Widget _playlistFallbackArt() {
    return Image.asset(
      'lib/assets/app_icon.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: bgCard,
        child: const Center(
          child: Icon(
            Icons.music_note_rounded,
            color: textSecondary,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _EditPlaylistSheet extends StatefulWidget {
  const _EditPlaylistSheet({
    required this.playlist,
    required this.title,
    required this.submitLabel,
    required this.allowCoverArt,
    required this.onSave,
  });

  final LibraryPlaylist playlist;
  final String title;
  final String submitLabel;
  final bool allowCoverArt;
  final Future<void> Function(String name, String coverImagePath) onSave;

  @override
  State<_EditPlaylistSheet> createState() => _EditPlaylistSheetState();
}

class _EditPlaylistSheetState extends State<_EditPlaylistSheet> {
  late final TextEditingController _nameController;
  final FocusNode _focusNode = FocusNode();
  late String _coverImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _coverImagePath = widget.playlist.coverImagePath;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    setState(() {
      _coverImagePath = selectedPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.viewInsets.bottom
            : mediaQuery.viewPadding.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.7,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 20),
                  if (widget.allowCoverArt) ...[
                    Text(
                      'Cover art',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _PlaylistCoverArt(
                          imagePath: _coverImagePath,
                          imageUrl: '',
                          size: 72,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickCoverArt,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Change cover art'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Playlist name',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: false,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Give your playlist a name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final trimmedName = _nameController.text.trim();
                            if (trimmedName.isEmpty) {
                              return;
                            }

                            await widget.onSave(trimmedName, _coverImagePath);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(widget.submitLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistTrackList extends StatelessWidget {
  const _PlaylistTrackList({
    required this.tracks,
    this.enableQueueActions = false,
  });

  final List<LibraryTrack> tracks;
  final bool enableQueueActions;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'NO TRACKS YET',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return SizedBox(
          height: 76,
          child: _LibraryTrackRow(
            track: track,
            enableQueueActions: enableQueueActions,
          ),
        );
      },
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? leading;
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
            leading ??
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
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
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

enum _CyberpunkPlaylistBadgeVariant {
  liked,
  recents,
}

class _CyberpunkPlaylistBadge extends StatelessWidget {
  const _CyberpunkPlaylistBadge({
    required this.variant,
  });

  final _CyberpunkPlaylistBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isLiked = variant == _CyberpunkPlaylistBadgeVariant.liked;
    final icon = isLiked
        ? Icons.favorite_rounded
        : Icons.history_toggle_off_rounded;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLiked
              ? const [
                  Color(0xFFFF4D6D),
                  Color(0xFFFF003C),
                  Color(0xFF1B0A12),
                ]
              : const [
                  Color(0xFFF5E642),
                  Color(0xFFE0B400),
                  Color(0xFF382B00),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isLiked ? accentRed : accentPrimary).withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: -10,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 36,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: isLiked ? 0 : -8,
            top: isLiked ? 0 : null,
            bottom: isLiked ? null : 8,
            child: Container(
              width: isLiked ? 1.3 : 32,
              height: isLiked ? 56 : 5,
              decoration: BoxDecoration(
                color: isLiked
                    ? accentPrimary.withValues(alpha: 0.75)
                    : accentCyan.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (isLiked)
            Positioned(
              bottom: 7,
              right: 6,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (!isLiked)
            Positioned(
              top: 0,
              bottom: 0,
              left: 18,
              child: Container(
                width: 1.4,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          Center(
            child: Icon(
              icon,
              color: isLiked ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTrackRow extends ConsumerWidget {
  const _LibraryTrackRow({
    required this.track,
    this.enableQueueActions = false,
    this.playlistId,
    this.onAddToAnotherPlaylist,
    this.onToggleHidden,
    this.onGoToQueue,
  });

  final LibraryTrack track;
  final bool enableQueueActions;
  final String? playlistId;
  final Future<void> Function()? onAddToAnotherPlaylist;
  final Future<void> Function()? onToggleHidden;
  final Future<void> Function()? onGoToQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (56 * devicePixelRatio).round();
    final isPlaylistTrack = playlistId != null;
    final isHidden = track.hiddenInPlaylist;
    final effectiveTextColor = isHidden ? textSecondary : textPrimary;
    final effectiveSubtitleColor =
        isHidden ? textSecondary.withValues(alpha: 0.72) : textSecondary;

    Future<void> queueTrack() async {
      final added = ref.read(playbackNotifierProvider.notifier).addToQueue(
            videoId: track.videoId,
            videoUrl: track.videoUrl,
            title: track.title,
            artist: track.artist,
            thumbnailUrl: track.thumbnailUrl,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Added "${track.title}" to queue'
                : '"${track.title}" is already in queue',
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }

    Future<void> toggleLiked() async {
      await ref.read(libraryProvider.notifier).toggleLike(
            videoId: track.videoId,
            videoUrl: track.videoUrl,
            title: track.title,
            artist: track.artist,
            thumbnailUrl: track.thumbnailUrl,
            durationSeconds: track.durationSeconds,
          );
    }

    Future<void> showTrackOptionsSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          Future<void> handleAction(_PlaylistTrackMenuAction action) async {
            Navigator.of(sheetContext).pop();
            switch (action) {
              case _PlaylistTrackMenuAction.addToAnotherPlaylist:
                await onAddToAnotherPlaylist?.call();
                return;
              case _PlaylistTrackMenuAction.toggleHidden:
                await onToggleHidden?.call();
                return;
              case _PlaylistTrackMenuAction.addToQueue:
                await queueTrack();
                return;
              case _PlaylistTrackMenuAction.goToQueue:
                await onGoToQueue?.call();
                return;
            }
          }

          return SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(context);
                final availableHeight =
                    constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : mediaQuery.size.height;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: bgSurface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(top: 12, bottom: 20),
                              decoration: BoxDecoration(
                                color: bgDivider,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          _PlaylistOptionTile(
                            icon: Icons.playlist_add_rounded,
                            title: 'Add to another playlist',
                            subtitle: 'Save this song to a different playlist',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.addToAnotherPlaylist,
                            ),
                          ),
                          _PlaylistOptionTile(
                            icon: isHidden
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            title: isHidden
                                ? 'Show in this playlist'
                                : 'Hide in this playlist',
                            subtitle: isHidden
                                ? 'Bring this song back into playlist playback'
                                : 'Gray it out and skip it during playlist playback',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.toggleHidden,
                            ),
                          ),
                          _PlaylistOptionTile(
                            icon: Icons.queue_music_rounded,
                            title: 'Add to queue',
                            subtitle: 'Play this song after the current queue',
                            plain: true,
                            onTap: () =>
                                handleAction(_PlaylistTrackMenuAction.addToQueue),
                          ),
                          _PlaylistOptionTile(
                            icon: Icons.format_list_bulleted_rounded,
                            title: 'Go to queue',
                            subtitle: 'Open the current playback queue',
                            plain: true,
                            onTap: () =>
                                handleAction(_PlaylistTrackMenuAction.goToQueue),
                          ),
                          SizedBox(height: mediaQuery.viewPadding.bottom + 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    final row = InkWell(
      onTap: isHidden
          ? null
          : () async {
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
              child: Opacity(
                opacity: isHidden ? 0.42 : 1,
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
                          memCacheWidth: artworkCacheSize,
                          memCacheHeight: artworkCacheSize,
                          maxWidthDiskCache: artworkCacheSize,
                          maxHeightDiskCache: artworkCacheSize,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.music_note, color: textSecondary),
                          ),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: effectiveTextColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHidden ? '${track.artist} • Hidden' : track.artist,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: effectiveSubtitleColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPlaylistTrack) ...[
              IconButton(
                onPressed: toggleLiked,
                tooltip: track.isLiked
                    ? 'Remove from liked songs'
                    : 'Add to liked songs',
                icon: Icon(
                  track.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: track.isLiked ? accentPrimary : textSecondary,
                ),
              ),
              IconButton(
                onPressed: showTrackOptionsSheet,
                tooltip: 'Track options',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: textPrimary,
                ),
              ),
            ] else if (enableQueueActions)
              IconButton(
                onPressed: queueTrack,
                tooltip: 'Add to queue',
                icon: const Icon(
                  Icons.queue_music_rounded,
                  color: accentPrimary,
                ),
              ),
            if (!isPlaylistTrack && track.isLiked)
              const Icon(Icons.favorite, color: accentPrimary, size: 20),
          ],
        ),
      ),
    );

    if (!enableQueueActions) {
      return row;
    }

    return _LibraryQueueSwipeWrapper(
      onQueued: queueTrack,
      child: row,
    );
  }
}

enum _PlaylistTrackMenuAction {
  addToAnotherPlaylist,
  toggleHidden,
  addToQueue,
  goToQueue,
}

class _LibraryQueueSwipeWrapper extends StatefulWidget {
  const _LibraryQueueSwipeWrapper({
    required this.onQueued,
    required this.child,
  });

  final Future<void> Function() onQueued;
  final Widget child;

  @override
  State<_LibraryQueueSwipeWrapper> createState() =>
      _LibraryQueueSwipeWrapperState();
}

class _LibraryQueueSwipeWrapperState extends State<_LibraryQueueSwipeWrapper> {
  double _dragOffset = 0;
  bool _queueTriggered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxReveal = screenWidth * 0.46;
    final triggerThreshold = maxReveal * 0.62;
    final revealWidth = _dragOffset.clamp(0.0, maxReveal).toDouble();
    final actionReady = revealWidth >= triggerThreshold;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: revealWidth,
              color: actionReady ? accentPrimary : bgDivider,
              alignment: Alignment.center,
              child: Opacity(
                opacity: revealWidth <= 8 ? 0 : 1,
                child: Icon(
                  Icons.playlist_add_rounded,
                  color: actionReady ? Colors.black : textPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(revealWidth, 0, 0),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _queueTriggered = false;
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dx)
                    .clamp(0.0, maxReveal)
                    .toDouble();
              });
            },
            onHorizontalDragEnd: (_) {
              final shouldQueue =
                  _dragOffset >= triggerThreshold && !_queueTriggered;
              if (shouldQueue) {
                _queueTriggered = true;
                unawaited(widget.onQueued());
              }
              setState(() {
                _dragOffset = 0;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragOffset = 0;
              });
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
