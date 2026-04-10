import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import 'library_screen.dart';
import '../theme.dart';
import '../widgets/playlist_sheets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onViewMore,
  });

  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final recentlyPlayed = libraryState.recentTracks.take(3).toList();
    final playlists = libraryState.userPlaylists;
    final likedTracks = libraryState.likedTracks;
    final mediaQuery = MediaQuery.of(context);
    final hasContent = recentlyPlayed.isNotEmpty || playlists.isNotEmpty;
    final shortcutItems = <_HomeShortcutData>[
      _HomeShortcutData(
        title: 'Liked Songs',
        subtitle: '',
        artworkUrl: likedTracks.isNotEmpty ? likedTracks.first.thumbnailUrl : null,
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
      _HomeShortcutData(
        title: 'Recents',
        subtitle: '${libraryState.recentTracks.length} tracks',
        artworkUrl: libraryState.recentTracks.isNotEmpty
            ? libraryState.recentTracks.first.thumbnailUrl
            : null,
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
      _HomeShortcutData(
        title: 'Playlists',
        subtitle: '',
        icon: Icons.library_music_rounded,
        onTap: onViewMore,
      ),
    ];

    final remainingSlots = 8 - shortcutItems.length;
    final playlistShortcutCount =
        playlists.length >= remainingSlots ? remainingSlots : playlists.length;

    shortcutItems.addAll([
      for (final playlist in playlists.take(playlistShortcutCount))
        _HomeShortcutData(
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

    final remainingSongSlots = 8 - shortcutItems.length;
    shortcutItems.addAll([
      for (final track in libraryState.recentTracks.take(remainingSongSlots))
        _HomeShortcutData(
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
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message)),
              );
            }
          },
          onLongPress: () => _showTrackActionsSheet(context, ref, track),
        ),
    ]);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _HomeTopBar(),
            if (shortcutItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeCollectionGrid(items: shortcutItems),
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
                  child: const _HomeEmptyState(),
                )
              else ...[
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HomeSectionHeader(
                    eyebrow: 'Jump back in',
                    title: 'Recent songs played',
                  ),
                ),
                const SizedBox(height: 14),
                if (recentlyPlayed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _InlineInfoCard(
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
                        return _RecentlyPlayedCard(
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
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            }
                          },
                          onLongPress: () => _showTrackActionsSheet(
                            context,
                            ref,
                            track,
                          ),
                        );
                      },
                    ),
                  ),
                if (playlists.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HomeSectionHeader(
                      eyebrow: 'Collections',
                      title: 'Your playlists',
                      subtitle: 'Open a playlist or pick up where you left off.',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final playlist in playlists)
                  _PlaylistPreviewSection(playlist: playlist),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeShortcutData {
  const _HomeShortcutData({
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.localArtworkPath,
    this.icon,
    this.isLikedCollection = false,
    this.usesAppLogoFallback = false,
    required this.onTap,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String? artworkUrl;
  final String? localArtworkPath;
  final IconData? icon;
  final bool isLikedCollection;
  final bool usesAppLogoFallback;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentPrimary.withValues(alpha: 0.14),
            bgBase.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentPrimary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Audio Docker',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: textPrimary,
                    fontSize: 22,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCollectionGrid extends StatelessWidget {
  const _HomeCollectionGrid({
    required this.items,
  });

  final List<_HomeShortcutData> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(8).toList();
    final width = MediaQuery.of(context).size.width - 32;
    final isCompact = width < 380;
    final bannerAspectRatio = isCompact ? 2.8 : 3.2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleItems.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: bannerAspectRatio,
      ),
      itemBuilder: (context, index) {
        return _HomeCollectionTile(item: visibleItems[index]);
      },
    );
  }
}

class _HomeCollectionTile extends StatelessWidget {
  const _HomeCollectionTile({
    required this.item,
  });

  final _HomeShortcutData item;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 380;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final artworkCacheSize = (78 * devicePixelRatio).round();
    final tileHeight = isCompact ? 52.0 : 48.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        onLongPress: item.onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: tileHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSubtitle =
                    item.subtitle.isNotEmpty && constraints.maxHeight >= 56;

                return Row(
                  children: [
                    SizedBox(
                      width: isCompact ? 48 : 44,
                      height: double.infinity,
                      child: _HomeCollectionArtwork(
                        item: item,
                        artworkCacheSize: artworkCacheSize,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    fontSize: isCompact ? 10.5 : 10,
                                  ),
                            ),
                            if (showSubtitle) ...[
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: textSecondary,
                                      fontSize: isCompact ? 7.6 : 7.2,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCollectionArtwork extends StatelessWidget {
  const _HomeCollectionArtwork({
    required this.item,
    required this.artworkCacheSize,
  });

  final _HomeShortcutData item;
  final int artworkCacheSize;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (item.isLikedCollection) {
      child = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4FD8),
              Color(0xFFFF003C),
              Color(0xFF6A00FF),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.2),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      );
    } else if (item.localArtworkPath != null && item.localArtworkPath!.isNotEmpty) {
      child = Image.file(
        File(item.localArtworkPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultArtwork(item),
      );
    } else if (item.artworkUrl != null && item.artworkUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: item.artworkUrl!,
        memCacheWidth: artworkCacheSize,
        memCacheHeight: artworkCacheSize,
        maxWidthDiskCache: artworkCacheSize,
        maxHeightDiskCache: artworkCacheSize,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(
          color: bgDivider,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentPrimary,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _defaultArtwork(item),
      );
    } else {
      child = _defaultArtwork(item);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
      child: child,
    );
  }

  Widget _defaultArtwork(_HomeShortcutData item) {
    if (item.usesAppLogoFallback) {
      return Image.asset(
        'lib/assets/app_icon.png',
        fit: BoxFit.cover,
      );
    }

    return Container(
      color: bgDivider,
      child: Icon(
        item.icon ?? Icons.music_note_rounded,
        color: textPrimary,
        size: 24,
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textPrimary,
                      fontSize: 19,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide.none,
            ),
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: bgDivider),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(14),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: bgDivider),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: accentPrimary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your home feed is waiting',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play a few tracks or create a playlist and your recent activity will start showing up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPreviewSection extends ConsumerWidget {
  const _PlaylistPreviewSection({
    required this.playlist,
  });

  final LibraryPlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<LibraryTrack>>(
      future: ref.read(libraryProvider.notifier).fetchPlaylistTracks(playlist.id),
      builder: (context, snapshot) {
        final tracks = snapshot.data?.take(10).toList() ?? const <LibraryTrack>[];

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeSectionHeader(
                  eyebrow: 'Playlist',
                  title: playlist.name,
                  subtitle: '${playlist.trackCount} tracks saved',
                  actionLabel: 'Open',
                  onAction: () {
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
                  child: _InlineInfoCard(
                    icon: Icons.playlist_remove_rounded,
                    title: 'No songs in this playlist yet',
                    subtitle:
                        'Add tracks to this playlist and they will show up here.',
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
                      return _RecentlyPlayedCard(
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
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                        onLongPress: () => _showTrackActionsSheet(
                          context,
                          ref,
                          track,
                        ),
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

Future<void> _showTrackActionsSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final metrics = _SheetMetrics.fromContext(sheetContext);
      final mediaQuery = MediaQuery.of(sheetContext);
      final viewportHeight = mediaQuery.size.height;
      final actionCount = 4;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: metrics.actionsInitialSizeFor(
          viewportHeight: viewportHeight,
          bottomInset: mediaQuery.padding.bottom,
          actionCount: actionCount,
        ),
        minChildSize: metrics.actionsMinSize,
        maxChildSize: metrics.actionsMaxSize,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(metrics.sheetRadius),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: metrics.outerPadding,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: metrics.handleWidth,
                        height: metrics.handleHeight,
                        margin: EdgeInsets.only(bottom: metrics.sectionGap),
                        decoration: BoxDecoration(
                          color: bgDivider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      _SheetTrackHeader(
                        track: track,
                        eyebrow: 'Track actions',
                        title: track.title,
                        subtitle: track.artist,
                        metrics: metrics,
                      ),
                      SizedBox(height: metrics.sectionGap * 0.9),
                      _TrackActionTile(
                        icon: Icons.favorite_rounded,
                        label: 'Add to liked songs',
                        detail: 'Save this track to your favorites',
                        metrics: metrics,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await ref.read(libraryProvider.notifier).setPlaylistMembership(
                                playlistId: likedPlaylistId,
                                shouldSave: true,
                                videoId: track.videoId,
                                videoUrl: track.videoUrl,
                                title: track.title,
                                artist: track.artist,
                                thumbnailUrl: track.thumbnailUrl,
                                durationSeconds: track.durationSeconds,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added "${track.title}" to liked songs')),
                            );
                          }
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        detail: 'Keep it ready for offline listening',
                        metrics: metrics,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download will be added later')),
                          );
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.queue_music_rounded,
                        label: 'Add to queue',
                        detail: 'Play it after your current song',
                        metrics: metrics,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          final added = ref.read(playbackNotifierProvider.notifier).addToQueue(
                                videoId: track.videoId,
                                videoUrl: track.videoUrl,
                                title: track.title,
                                artist: track.artist,
                                thumbnailUrl: track.thumbnailUrl,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Added "${track.title}" to queue'
                                    : '"${track.title}" is already in queue',
                              ),
                            ),
                          );
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.playlist_add_rounded,
                        label: 'Add to playlist',
                        detail: 'File this track into one of your sets',
                        metrics: metrics,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await _showAddTrackToPlaylistSheet(context, ref, track);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showAddTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) async {
  final libraryState = ref.read(libraryProvider);
  final userPlaylists = libraryState.userPlaylists;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final metrics = _SheetMetrics.fromContext(sheetContext);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: metrics.playlistInitialSize,
        minChildSize: metrics.playlistMinSize,
        maxChildSize: metrics.playlistMaxSize,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(metrics.sheetRadius),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: metrics.handleWidth,
                      height: metrics.handleHeight,
                      margin: EdgeInsets.only(
                        top: metrics.outerPadding.top,
                        bottom: metrics.sectionGap,
                      ),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.cardInset,
                        0,
                        metrics.cardInset,
                        metrics.itemGap,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final useStackedHeader =
                              constraints.maxWidth < metrics.headerStackBreakpoint;

                          final headerCard = _SheetTrackHeader(
                            track: track,
                            eyebrow: 'Add to playlist',
                            title: track.title,
                            subtitle: '${track.artist}  •  ${userPlaylists.length} playlists',
                            compact: true,
                            metrics: metrics,
                          );

                          final newPlaylistButton = TextButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              final created = await showCreatePlaylistSheet(context, ref);
                              if (created && context.mounted) {
                                await _showAddTrackToPlaylistSheet(context, ref, track);
                              }
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.symmetric(
                                horizontal: metrics.buttonHorizontalPadding,
                                vertical: metrics.buttonVerticalPadding,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: accentPrimary.withValues(alpha: 0.12),
                              side: BorderSide(
                                color: accentPrimary.withValues(alpha: 0.28),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(metrics.pillRadius),
                              ),
                            ),
                            child: const Text('New playlist'),
                          );

                          if (useStackedHeader) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                headerCard,
                                SizedBox(height: metrics.itemGap),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: newPlaylistButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: headerCard),
                              SizedBox(width: metrics.itemGap),
                              newPlaylistButton,
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: metrics.itemGap),
                    if (userPlaylists.isEmpty)
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          metrics.cardInset,
                          metrics.itemGap,
                          metrics.cardInset,
                          metrics.outerPadding.bottom,
                        ),
                        padding: EdgeInsets.all(metrics.cardPadding),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(metrics.cardRadius),
                          border: Border.all(
                            color: accentPrimary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.library_music_rounded,
                              color: accentPrimary,
                              size: metrics.leadingIconSize,
                            ),
                            SizedBox(width: metrics.itemGap),
                            Expanded(
                              child: Text(
                                'No playlists yet. Create one first.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          metrics.outerPadding.left,
                          0,
                          metrics.outerPadding.right,
                          metrics.outerPadding.bottom,
                        ),
                        child: Column(
                          children: [
                            for (var index = 0; index < userPlaylists.length; index++) ...[
                              _PlaylistSelectionTile(
                                name: userPlaylists[index].name,
                                trackCount: userPlaylists[index].trackCount,
                                metrics: metrics,
                                onTap: () async {
                                  final playlist = userPlaylists[index];
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
                                  if (!context.mounted) {
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
                              ),
                              if (index != userPlaylists.length - 1)
                                SizedBox(height: metrics.itemGap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _RecentlyPlayedCard extends StatelessWidget {
  const _RecentlyPlayedCard({
    required this.track,
    required this.onTap,
    required this.onLongPress,
  });

  final LibraryTrack track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (112 * devicePixelRatio).round();
    return SizedBox(
      width: 112,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 112,
                  height: 112,
                  color: bgDivider,
                  child: track.thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: textSecondary,
                            size: 32,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: track.thumbnailUrl,
                          memCacheWidth: artworkCacheSize,
                          memCacheHeight: artworkCacheSize,
                          maxWidthDiskCache: artworkCacheSize,
                          maxHeightDiskCache: artworkCacheSize,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentPrimary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: textSecondary,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackActionTile extends StatelessWidget {
  const _TrackActionTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.metrics,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final _SheetMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: metrics.itemGap),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(
          color: accentPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: metrics.shadowBlur,
            offset: Offset(0, metrics.shadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.cardPadding,
              vertical: metrics.tileVerticalPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: metrics.leadingSize,
                  height: metrics.leadingSize,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(metrics.leadingRadius),
                  ),
                  child: Icon(
                    icon,
                    color: accentPrimary,
                    size: metrics.leadingIconSize,
                  ),
                ),
                SizedBox(width: metrics.contentGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: metrics.textGap),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: metrics.itemGap),
                Container(
                  width: metrics.trailingSize,
                  height: metrics.trailingSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                    size: metrics.trailingIconSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTrackHeader extends StatelessWidget {
  const _SheetTrackHeader({
    required this.track,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.metrics,
    this.compact = false,
  });

  final LibraryTrack track;
  final String eyebrow;
  final String title;
  final String subtitle;
  final _SheetMetrics metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final artworkSize = compact ? metrics.compactArtworkSize : metrics.artworkSize;

    return Container(
      padding: EdgeInsets.all(compact ? metrics.compactHeaderPadding : metrics.headerPadding),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(metrics.headerRadius),
        border: Border.all(
          color: accentPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(metrics.artworkRadius),
            child: Container(
              width: artworkSize,
              height: artworkSize,
              color: bgDivider,
              child: track.thumbnailUrl.isEmpty
                  ? Icon(
                      Icons.music_note_rounded,
                      color: textSecondary,
                      size: metrics.artworkIconSize,
                    )
                  : CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.music_note_rounded,
                        color: textSecondary,
                        size: metrics.artworkIconSize,
                      ),
                    ),
            ),
          ),
          SizedBox(width: metrics.contentGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                ),
                SizedBox(height: metrics.textGap + 2),
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: metrics.textGap),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistSelectionTile extends StatelessWidget {
  const _PlaylistSelectionTile({
    required this.name,
    required this.trackCount,
    required this.metrics,
    required this.onTap,
  });

  final String name;
  final int trackCount;
  final _SheetMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(metrics.cardRadius),
            border: Border.all(
              color: accentPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.cardPadding,
              vertical: metrics.tileVerticalPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: metrics.leadingSize,
                  height: metrics.leadingSize,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(metrics.leadingRadius),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: accentPrimary,
                    size: metrics.leadingIconSize,
                  ),
                ),
                SizedBox(width: metrics.contentGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: metrics.textGap),
                      Text(
                        '$trackCount tracks',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.selectPillHorizontalPadding,
                    vertical: metrics.selectPillVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(metrics.pillRadius),
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      color: accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetMetrics {
  const _SheetMetrics._({
    required this.scale,
    required this.heightScale,
  });

  final double scale;
  final double heightScale;

  factory _SheetMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = (size.width / 390).clamp(0.88, 1.12);
    final heightScale = (size.height / 844).clamp(0.88, 1.1);
    final scale = ((widthScale + heightScale) / 2).toDouble();

    return _SheetMetrics._(
      scale: scale,
      heightScale: heightScale.toDouble(),
    );
  }

  EdgeInsets get outerPadding =>
      EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 24 * scale);
  double get sheetRadius => 28 * scale;
  double get handleWidth => 44 * scale;
  double get handleHeight => (4 * scale).clamp(3.0, 6.0);
  double get sectionGap => 20 * scale;
  double get itemGap => 10 * scale;
  double get contentGap => 14 * scale;
  double get textGap => 4 * scale;
  double get cardInset => 20 * scale;
  double get cardPadding => 16 * scale;
  double get headerPadding => 14 * scale;
  double get compactHeaderPadding => 12 * scale;
  double get tileVerticalPadding => 14 * scale;
  double get cardRadius => 20 * scale;
  double get headerRadius => 24 * scale;
  double get pillRadius => 999;
  double get leadingSize => 44 * scale;
  double get leadingRadius => 14 * scale;
  double get leadingIconSize => 22 * scale;
  double get trailingSize => 32 * scale;
  double get trailingIconSize => 18 * scale;
  double get artworkSize => 72 * scale;
  double get compactArtworkSize => 56 * scale;
  double get artworkRadius => 18 * scale;
  double get artworkIconSize => 28 * scale;
  double get buttonHorizontalPadding => 14 * scale;
  double get buttonVerticalPadding => 10 * scale;
  double get selectPillHorizontalPadding => 10 * scale;
  double get selectPillVerticalPadding => 6 * scale;
  double get shadowBlur => 18 * scale;
  double get shadowOffsetY => 8 * scale;
  double get headerStackBreakpoint => 360 * scale;
  double get actionsMinSize => (0.34 + ((1.0 - heightScale) * 0.12)).clamp(0.32, 0.42);
  double get actionsMaxSize => 0.92;
  double get playlistMinSize => (0.42 + ((1.0 - heightScale) * 0.12)).clamp(0.4, 0.5);
  double get playlistInitialSize => (0.58 + ((1.0 - heightScale) * 0.18)).clamp(0.56, 0.72);
  double get playlistMaxSize => 0.94;

  double get _estimatedHeaderHeight {
    final textBlockHeight = (textGap + 2) + 28 * scale + textGap + 18 * scale;
    final contentHeight = artworkSize > textBlockHeight ? artworkSize : textBlockHeight;
    return (headerPadding * 2) + contentHeight;
  }

  double get _estimatedActionTileHeight {
    final textBlockHeight = 22 * scale + textGap + 16 * scale;
    final contentHeight = leadingSize > textBlockHeight ? leadingSize : textBlockHeight;
    return (tileVerticalPadding * 2) + contentHeight + itemGap;
  }

  double actionsInitialSizeFor({
    required double viewportHeight,
    double bottomInset = 0,
    required int actionCount,
  }) {
    final desiredHeight = outerPadding.vertical +
        handleHeight +
        sectionGap +
        _estimatedHeaderHeight +
        (sectionGap * 0.9) +
        (_estimatedActionTileHeight * actionCount) +
        bottomInset +
        (12 * scale);

    final desiredFraction = desiredHeight / viewportHeight;
    return desiredFraction.clamp(actionsMinSize, actionsMaxSize).toDouble();
  }
}
