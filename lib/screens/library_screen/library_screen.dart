import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download_manager/download_provider.dart';
import '../../library/library_provider.dart';
import '../../providers/playlist_import_provider.dart';
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
      CupertinoPageRoute(
        builder: (_) => PlaylistDetailsScreen(
          title: 'Recents',
          tracks: libraryState.recentTracks,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  void _openDownloads() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => PlaylistDetailsScreen(
          title: 'Downloads',
          tracksLoader: () => ref.refresh(downloadedLibraryTracksProvider.future),
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  void _showImportResult(BuildContext parentContext) {
    if (!parentContext.mounted) return;
    final importState = ref.read(playlistImportProvider);
    final message = importState.errorMessage ??
        (importState.importedPlaylistName == null
            ? null
            : 'Imported into ${importState.importedPlaylistName}');
    if (message == null) return;
    ScaffoldMessenger.of(parentContext)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.sizeOf(sheetContext).height;
        final systemBottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final bottomOffset = bottomInset > 0 ? bottomInset : systemBottomInset;
        final maxHeight = screenHeight * (screenHeight < 700 ? 0.72 : 0.58);

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: bottomOffset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                decoration: const BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12 + systemBottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (spotifyUrl == null || !parentContext.mounted) {
                              return;
                            }
                            await ref
                                .read(playlistImportProvider.notifier)
                                .importSpotifyPlaylist(spotifyUrl);
                            if (!parentContext.mounted) return;
                            _showImportResult(parentContext);
                          },
                        ),
                        LibraryPlaylistOptionTile(
                          icon: Icons.video_library_rounded,
                          title: 'Import Playlist from YouTube',
                          subtitle: 'Paste a YouTube playlist URL',
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            final youtubeUrl = await showYoutubePlaylistImportSheet(
                              parentContext,
                            );
                            if (youtubeUrl == null || !parentContext.mounted) {
                              return;
                            }
                            await ref
                                .read(playlistImportProvider.notifier)
                                .importYoutubePlaylist(youtubeUrl);
                            if (!parentContext.mounted) return;
                            _showImportResult(parentContext);
                          },
                        ),
                      ],
                    ),
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
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final downloadedTracksAsync = ref.watch(downloadedLibraryTracksProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 18 : 20,
          letterSpacing: 1.2,
        );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text('LIBRARY', style: titleStyle),
        actions: [
          IconButton(
            onPressed: () => _showPlaylistOptions(context, ref),
            icon: const Icon(Icons.add_rounded, color: accentPrimary, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: libraryState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentPrimary),
            )
            : LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight - 24; // 12px padding tb
                // Display exactly 7 items before scrolling
                const targetVisible = 7.0;
                const itemSpacing = 8.0;
                const spacingHeight = (targetVisible - 1) * itemSpacing;
                final dynamicCardHeight = ((availableHeight - spacingHeight) / targetVisible).clamp(64.0, 100.0);

                final leadingSize = (dynamicCardHeight * 0.76).clamp(42.0, 58.0);

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    LibraryPlaylistCard(
                      title: 'Liked Songs',
                      subtitle: '${libraryState.likedTracks.length} tracks',
                      icon: Icons.favorite,
                      height: dynamicCardHeight,
                      leading: LibraryCyberpunkPlaylistBadge(
                        variant: LibraryCyberpunkPlaylistBadgeVariant.liked,
                        size: leadingSize,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => PlaylistDetailsScreen(
                              title: 'Liked Songs',
                              tracks: libraryState.likedTracks,
                              onNavigateToTab: widget.onNavigateToTab,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: itemSpacing),
                    LibraryPlaylistCard(
                      title: 'Recents',
                      subtitle: '${libraryState.recentTracks.length} tracks',
                      icon: Icons.history,
                      height: dynamicCardHeight,
                      leading: LibraryCyberpunkPlaylistBadge(
                        variant: LibraryCyberpunkPlaylistBadgeVariant.recents,
                        size: leadingSize,
                      ),
                      onTap: _openRecents,
                    ),
                    const SizedBox(height: itemSpacing),
                    LibraryPlaylistCard(
                      title: 'Downloads',
                      subtitle:
                          '${downloadedTracksAsync.valueOrNull?.length ?? 0} tracks',
                      icon: Icons.download_done_rounded,
                      height: dynamicCardHeight,
                      leading: LibraryCyberpunkPlaylistBadge(
                        variant: LibraryCyberpunkPlaylistBadgeVariant.downloads,
                        size: leadingSize,
                      ),
                      onTap: _openDownloads,
                    ),
                    for (final playlist in libraryState.userPlaylists) ...[
                      const SizedBox(height: itemSpacing),
                      LibraryPlaylistCard(
                        title: playlist.name,
                        subtitle: playlist.isPinned ? 'PINNED' : '',
                        icon: Icons.queue_music_rounded,
                        height: dynamicCardHeight,
                        leading: Stack(
                          children: [
                            LibraryPlaylistCoverArt(
                              imagePath: playlist.coverImagePath,
                              imageUrl: '',
                              size: leadingSize,
                              borderRadius: 8,
                            ),
                            if (playlist.isPinned)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.push_pin_rounded,
                                    size: 10,
                                    color: accentPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => PlaylistDetailsScreen(
                                title: playlist.name,
                                playlistId: playlist.id,
                                onNavigateToTab: widget.onNavigateToTab,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => showPlaylistActionsSheet(
                          context,
                          ref,
                          playlist,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
