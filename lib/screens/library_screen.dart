import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../theme.dart';
import '../widgets/playlist_sheets.dart';
import '../widgets/app_bottom_bar.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    this.onNavigateToTab,
  });

  final ValueChanged<int>? onNavigateToTab;

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
                    subtitle: 'Coming next',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsScreen(
                          title: 'Liked Songs',
                          tracks: libraryState.likedTracks,
                          onNavigateToTab: onNavigateToTab,
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
                          onNavigateToTab: onNavigateToTab,
                        ),
                      ),
                    );
                  },
                ),
                for (final playlist in libraryState.userPlaylists) ...[
                    const SizedBox(height: 12),
                    _PlaylistCard(
                      title: playlist.name,
                      subtitle: '${playlist.trackCount} tracks',
                      icon: Icons.queue_music_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailsScreen(
                              title: playlist.name,
                              playlistId: playlist.id,
                              onNavigateToTab: onNavigateToTab,
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

class PlaylistDetailsScreen extends ConsumerWidget {
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

  bool get _isEditableCustomPlaylist => playlistId != null;

  void _handleBottomNavigation(BuildContext context, int index) {
    if (index == 2) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    onNavigateToTab?.call(index);
  }

  Future<void> _showEditPlaylistSheet(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylist playlist,
  ) async {
    final nameController = TextEditingController(text: playlist.name);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
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
                        'Edit Playlist',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: textPrimary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Playlist name',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        autofocus: true,
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
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final trimmedName = nameController.text.trim();
                                if (trimmedName.isEmpty) {
                                  return;
                                }
                                await ref
                                    .read(libraryProvider.notifier)
                                    .updatePlaylist(
                                      playlistId: playlist.id,
                                      name: trimmedName,
                                      coverImagePath: playlist.coverImagePath,
                                    );
                                if (!sheetContext.mounted) {
                                  return;
                                }
                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Save'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );
    final playlists = ref.watch(libraryProvider).playlists;
    LibraryPlaylist? playlist;
    for (final entry in playlists) {
      if (entry.id == playlistId) {
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
                title.toUpperCase(),
                style: titleStyle,
              ),
      ),
      body: playlistId == null
          ? _PlaylistTrackList(tracks: tracks ?? const [])
          : FutureBuilder<List<LibraryTrack>>(
              future:
                  ref.read(libraryProvider.notifier).fetchPlaylistTracks(playlistId!),
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

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _EditablePlaylistHeader(
                      playlist: editablePlaylist,
                      onChangePressed: () =>
                          _showEditPlaylistSheet(
                        context,
                        ref,
                        editablePlaylist,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (playlistTracks.isEmpty)
                      _EmptyPlaylistState(
                        playlistName: editablePlaylist.name,
                        onChangePressed: () =>
                            _showEditPlaylistSheet(
                          context,
                          ref,
                          editablePlaylist,
                        ),
                      )
                    else
                      ...[
                        Text(
                          'Songs',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          playlistTracks.length,
                          (index) => Column(
                            children: [
                              _LibraryTrackRow(track: playlistTracks[index]),
                              if (index != playlistTracks.length - 1)
                                const Divider(height: 1, color: bgDivider),
                            ],
                          ),
                        ),
                      ],
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

class _EditablePlaylistHeader extends StatelessWidget {
  const _EditablePlaylistHeader({
    required this.playlist,
    required this.onChangePressed,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onChangePressed;

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        color: textPrimary,
                      ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onChangePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: bgCard,
                    foregroundColor: textPrimary,
                  ),
                  child: const Text('Edit name'),
                ),
                const SizedBox(height: 12),
                Text(
                  '${playlist.trackCount} tracks',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  const _EmptyPlaylistState({
    required this.playlistName,
    required this.onChangePressed,
  });

  final String playlistName;
  final VoidCallback onChangePressed;

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
            'Add songs from the player using the add to playlist button, or update the cover art and name now.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onChangePressed,
            child: Text('Edit $playlistName'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCoverArt extends StatelessWidget {
  const _PlaylistCoverArt({
    required this.imagePath,
    required this.imageUrl,
    required this.size,
  });

  final String imagePath;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    Widget child;

    if (imagePath.isNotEmpty) {
      child = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _playlistFallbackArt(),
      );
    } else if (imageUrl.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
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
    return Container(
      color: bgCard,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: textSecondary,
          size: 42,
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

    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: bgDivider),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _LibraryTrackRow(track: track);
      },
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
