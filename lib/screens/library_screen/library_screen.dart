import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../providers/spotify_import_provider.dart';
import '../../theme.dart';
import '../../widgets/playlist_sheets.dart';
import 'library_playlist_card.dart';
import 'library_playlist_cover_art.dart';
import 'library_playlist_option_tile.dart';
import 'playlist_details_screen.dart';

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
                      'Add Playlist',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: textPrimary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LibraryPlaylistOptionTile(
                    icon: Icons.add_box_rounded,
                    title: 'Create Playlist',
                    subtitle: 'Start a fresh playlist in your library',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await showCreatePlaylistSheet(parentContext, ref);
                    },
                  ),
                  LibraryPlaylistOptionTile(
                    icon: Icons.queue_music_rounded,
                    title: 'Import Playlist from Spotify',
                    subtitle: 'Paste a Spotify playlist URL',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final spotifyUrl = await showSpotifyPlaylistImportSheet(
                          parentContext);
                      if (spotifyUrl == null || !parentContext.mounted) return;
                      await ref
                          .read(spotifyImportProvider.notifier)
                          .importPlaylist(spotifyUrl);
                      if (!parentContext.mounted) return;
                      final importState = ref.read(spotifyImportProvider);
                      final message = importState.errorMessage ??
                          (importState.importedPlaylistName == null
                              ? null
                              : 'Imported into ${importState.importedPlaylistName}');
                      if (message == null) return;
                      ScaffoldMessenger.of(parentContext)
                          .showSnackBar(SnackBar(content: Text(message)));
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
        title: Text('LIBRARY', style: titleStyle),
        actions: [
          IconButton(
            onPressed: () => _showPlaylistOptions(context, ref),
            icon: const Icon(Icons.add_rounded, color: accentPrimary),
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
                LibraryPlaylistCard(
                  title: 'Liked Songs',
                  subtitle: '${libraryState.likedTracks.length} tracks',
                  icon: Icons.favorite,
                  leading: const LibraryCyberpunkPlaylistBadge(
                    variant: LibraryCyberpunkPlaylistBadgeVariant.liked,
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
                LibraryPlaylistCard(
                  title: 'Recents',
                  subtitle: '${libraryState.recentTracks.length} tracks',
                  icon: Icons.history,
                  leading: const LibraryCyberpunkPlaylistBadge(
                    variant: LibraryCyberpunkPlaylistBadgeVariant.recents,
                  ),
                  onTap: _openRecents,
                ),
                for (final playlist in libraryState.userPlaylists) ...[
                  const SizedBox(height: 12),
                  LibraryPlaylistCard(
                    title: playlist.name,
                    subtitle: '',
                    icon: Icons.queue_music_rounded,
                    leading: LibraryPlaylistCoverArt(
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
