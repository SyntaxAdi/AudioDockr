import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/spotify_import_provider.dart';
import '../theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/playlist_sheets.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({
    super.key,
    this.onNavigateToTab,
    this.openRecentsToken = 0,
  });

  final ValueChanged<int>? onNavigateToTab;
  final int openRecentsToken;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int? _lastHandledOpenRecentsToken;

  @override
  void initState() {
    super.initState();
    _scheduleOpenRecentsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
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
      if (!mounted ||
          _lastHandledOpenRecentsToken == widget.openRecentsToken) {
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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

  bool get _isEditableCustomPlaylist => widget.playlistId != null;

  @override
  void initState() {
    super.initState();
    _refreshPlaylistTracksFuture();
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _refreshPlaylistTracksFuture();
    }
  }

  void _refreshPlaylistTracksFuture() {
    if (widget.playlistId == null) {
      _playlistTracksFuture = null;
      return;
    }
    _playlistTracksFuture =
        ref.read(libraryProvider.notifier).fetchPlaylistTracks(widget.playlistId!);
  }

  Future<void> _playPlaylistTracks(
    BuildContext context,
    List<LibraryTrack> tracks,
  ) async {
    if (tracks.isEmpty) {
      return;
    }

    try {
      await ref.read(playbackNotifierProvider.notifier).playTracks(
            tracks,
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
    LibraryPlaylist playlist,
    {
    bool allowCoverArt = true,
    String title = 'Edit Playlist',
    String submitLabel = 'Save',
  }
  ) async {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          ? _PlaylistTrackList(tracks: widget.tracks ?? const [])
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
                            child: _LibraryTrackRow(track: track),
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
    final targetCacheSize = (size * MediaQuery.of(context).devicePixelRatio).round();
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
  });

  final List<LibraryTrack> tracks;

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
          child: _LibraryTrackRow(track: track),
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
    final frameColor = isLiked ? accentRed : accentCyan;
    final glowColor = isLiked ? accentPrimary : accentCyan;
    final icon = isLiked ? Icons.favorite_rounded : Icons.bolt_rounded;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glowColor.withValues(alpha: 0.22),
            bgSurface,
          ],
        ),
        border: Border.all(
          color: frameColor.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: frameColor.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 7,
            left: 7,
            right: 7,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: accentPrimary.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: frameColor.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              color: frameColor,
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
  });

  final LibraryTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (56 * devicePixelRatio).round();
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
